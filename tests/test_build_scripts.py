"""Unit tests for the kairos_build helper scripts.

scripts/provider-image-refs.py   day-2: which provider images to push
scripts/mdadm-initrd-audit.py    RAID build: does the initramfs pin md0
"""

import gzip
import os
import subprocess
import sys

import pytest

SCRIPTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "scripts")
EARTHFILE = "VERSION 0.6\nARG PE_VERSION=v4.10.0-rc.2\n"


def run(script, *args):
    return subprocess.run([sys.executable, "-I", os.path.join(SCRIPTS, script), *map(str, args)],
                          capture_output=True, text=True)


# ---- provider-image-refs.py -------------------------------------------------

@pytest.fixture
def canvos(tmp_path):
    def make(arg, matrix='{"k3s": ["1.35.6", "1.36.2"], "kubeadm": ["1.35.3"]}'):
        (tmp_path / ".arg").write_text(arg)
        (tmp_path / "Earthfile").write_text(EARTHFILE)
        (tmp_path / "k8s_version.json").write_text(matrix)
        return tmp_path
    return make


BASE_ARG = "IMAGE_REGISTRY=ttl.sh\nIMAGE_REPO=ubuntu\nCUSTOM_TAG=bcm-test\n"


def test_refs_cover_only_the_built_distribution(canvos):
    out = run("provider-image-refs.py", canvos(BASE_ARG + "K8S_DISTRIBUTION=k3s\n"))
    assert out.returncode == 0, out.stderr
    assert out.stdout.split() == [
        "ttl.sh/ubuntu:k3s-1.35.6-v4.10.0-rc.2-bcm-test",
        "ttl.sh/ubuntu:k3s-1.36.2-v4.10.0-rc.2-bcm-test",
    ]


def test_pe_version_from_arg_wins_over_earthfile(canvos):
    out = run("provider-image-refs.py", canvos(BASE_ARG + "K8S_DISTRIBUTION=kubeadm\nPE_VERSION=v4.10.4\n"))
    assert out.stdout.split() == ["ttl.sh/ubuntu:kubeadm-1.35.3-v4.10.4-bcm-test"]


def test_pinned_k8s_version_and_empty_custom_tag(canvos):
    arg = "IMAGE_REGISTRY=r\nIMAGE_REPO=ubuntu\nCUSTOM_TAG=\nK8S_DISTRIBUTION=kubeadm\nK8S_VERSION=1.35.3\n"
    assert run("provider-image-refs.py", canvos(arg)).stdout.split() == ["r/ubuntu:kubeadm-1.35.3-v4.10.0-rc.2"]


def test_no_versions_fails_instead_of_pushing_nothing(canvos):
    out = run("provider-image-refs.py", canvos(BASE_ARG + "K8S_DISTRIBUTION=rke2\n"))
    assert out.returncode != 0 and out.stdout == ""
    assert "no versions for K8S_DISTRIBUTION=rke2" in out.stderr


def test_missing_arg_keys_fail(canvos):
    out = run("provider-image-refs.py", canvos("CUSTOM_TAG=x\n"))
    assert out.returncode != 0 and "IMAGE_REGISTRY" in out.stderr


# ---- mdadm-initrd-audit.py --------------------------------------------------

def newc(entries):
    """A newc cpio archive of {name: bytes}, TRAILER-terminated."""
    out = b""
    for ino, (name, data) in enumerate(list(entries.items()) + [("TRAILER!!!", b"")], 1):
        nm = name.encode() + b"\0"
        fields = [ino, 0o100644, 0, 0, 1, 0, len(data), 0, 0, 0, 0, len(nm), 0]
        hdr = b"070701" + b"".join(b"%08X" % f for f in fields)
        out += hdr + nm + b"\0" * ((4 - (len(hdr) + len(nm)) % 4) % 4)
        out += data + b"\0" * ((4 - len(data) % 4) % 4)
    return out


def initrd(tmp_path, entries):
    early = newc({"kernel/x86/microcode/GenuineIntel.bin": b"ucode"})
    path = tmp_path / "initrd"
    path.write_bytes(early + gzip.compress(newc(entries)))
    return path


GOOD_CONF = b"HOMEHOST none\nARRAY /dev/md0 metadata=1.0 name=md0\n"


def test_audit_passes_with_module_and_pinned_array(tmp_path):
    path = initrd(tmp_path, {"usr/sbin/mdadm": b"\x7fELF", "usr/lib/dracut/hooks/mdraid_start.sh": b"",
                             "etc/mdadm.conf": GOOD_CONF})
    out = run("mdadm-initrd-audit.py", path, "/dev/md0")
    assert out.returncode == 0, out.stderr
    assert "audit OK" in out.stdout


def test_audit_fails_without_mdadm_conf(tmp_path):
    # dracut drops mdadm.conf from a non-hostonly initramfs unless mdadmconf=yes.
    path = initrd(tmp_path, {"usr/sbin/mdadm": b"\x7fELF"})
    out = run("mdadm-initrd-audit.py", path)
    assert out.returncode == 1 and "no /etc/mdadm.conf" in out.stderr


def test_audit_fails_when_array_line_names_another_device(tmp_path):
    path = initrd(tmp_path, {"usr/sbin/mdadm": b"\x7fELF", "etc/mdadm.conf": b"ARRAY /dev/md127 name=x\n"})
    out = run("mdadm-initrd-audit.py", path, "/dev/md0")
    assert out.returncode == 1 and "no 'ARRAY /dev/md0' line" in out.stderr
