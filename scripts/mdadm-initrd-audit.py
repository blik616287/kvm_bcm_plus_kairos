#!/usr/bin/env python3
"""Verify a Kairos/dracut initramfs carries the mdraid module and the pinned ARRAY line.

dracut's 90mdraid module installs the rootfs mdadm.conf into the initrd under the
name /etc/mdadm.conf, and only when $hostonly is set or mdadmconf="yes". Kairos
images are built non-hostonly (one image must boot on any node), so the conf is
absent unless the build writes mdadmconf="yes" to /etc/dracut.conf.d/. Without
it, boot-time auto-assembly names the array md127 instead of md0 and the
finalize dd target and the stage-6 checks find nothing.

lsinitrd is not installed on the build host, so this parses the initrd directly:
an uncompressed early cpio followed by a compressed cpio (xz, gzip, bzip2 or
zstd). Exits 0 when the module and the ARRAY line are both present, else 1 with
the missing items on stderr.

Usage: mdadm-initrd-audit.py <initrd> [array]
"""

import bz2
import gzip
import lzma
import shutil
import subprocess
import sys

CPIO_MAGICS = (b"070701", b"070702")


def _find_magic(buf, start):
    """Offset of the next cpio newc/crc header at or after start, or -1."""
    best = -1
    for magic in CPIO_MAGICS:
        i = buf.find(magic, start)
        if i != -1 and (best == -1 or i < best):
            best = i
    return best


def _walk(buf, start, collect):
    """Walk a newc cpio buffer from start, calling collect(name, data)."""
    off = start
    n = len(buf)
    while off < n - 6:
        hdr_at = _find_magic(buf, off)
        if hdr_at == -1:
            return off
        hdr = buf[hdr_at:hdr_at + 110]
        if len(hdr) < 110:
            return off
        try:
            namesize = int(hdr[94:102], 16)
            filesize = int(hdr[54:62], 16)
        except ValueError:
            off = hdr_at + 1
            continue
        # A malformed header means we are looking at file data, not a header.
        if namesize <= 0 or namesize > 4096 or filesize > n:
            off = hdr_at + 1
            continue
        name = buf[hdr_at + 110:hdr_at + 110 + namesize - 1].decode("utf-8", "replace")
        pad = (4 - ((110 + namesize) % 4)) % 4
        dstart = hdr_at + 110 + namesize + pad
        if name == "TRAILER!!!":
            return dstart
        collect(name, buf[dstart:dstart + filesize])
        off = dstart + filesize + (4 - (filesize % 4)) % 4
    return off


def _early_archive_end(buf):
    """Offset just past the early (uncompressed microcode) cpio archive."""
    return _walk(buf, 0, lambda name, data: None)


def _zstd_decompress(data):
    if shutil.which("zstd") is None:
        raise RuntimeError("zstd payload but no zstd binary available")
    proc = subprocess.run(["zstd", "-dc"], input=data, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)
    if proc.returncode != 0:
        raise RuntimeError("zstd -dc failed: %s" % proc.stderr.decode("utf-8", "replace").strip())
    return proc.stdout


def main_archive(buf):
    """Return the decompressed main cpio buffer."""
    start = _early_archive_end(buf)
    while start < len(buf) and buf[start] == 0:
        start += 1
    head = buf[start:start + 8]
    if head.startswith(b"\xfd7zXZ"):
        return lzma.decompress(buf[start:])
    if head.startswith(b"\x1f\x8b\x08"):
        return gzip.decompress(buf[start:])
    if head.startswith(b"BZh"):
        return bz2.decompress(buf[start:])
    if head.startswith(b"\x28\xb5\x2f\xfd"):
        return _zstd_decompress(buf[start:])
    if head[:6] in CPIO_MAGICS:
        return buf[start:]
    # Unknown framing: treat the remainder as the archive so the checks below
    # still run and report what is genuinely missing.
    return buf[start:]


def main():
    if len(sys.argv) < 2:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    path = sys.argv[1]
    array = sys.argv[2] if len(sys.argv) > 2 else "/dev/md0"

    try:
        with open(path, "rb") as fh:
            buf = fh.read()
    except OSError as exc:
        print("cannot read %s: %s" % (path, exc), file=sys.stderr)
        return 1

    if not buf:
        print("%s is empty" % path, file=sys.stderr)
        return 1

    try:
        main_buf = main_archive(buf)
    except (lzma.LZMAError, OSError, EOFError, RuntimeError) as exc:
        print("cannot decode %s: %s" % (path, exc), file=sys.stderr)
        return 1

    state = {"conf": None, "conf_path": None, "mdadm_bin": 0, "mdraid": 0, "entries": 0}

    def collect(name, data):
        state["entries"] += 1
        if name.endswith("etc/mdadm.conf") or name.endswith("etc/mdadm/mdadm.conf"):
            state["conf"] = data
            state["conf_path"] = name
        if name.endswith("sbin/mdadm") or name.endswith("sbin/mdmon"):
            state["mdadm_bin"] += 1
        if "mdraid" in name:
            state["mdraid"] += 1

    _walk(main_buf, 0, collect)

    errs = []
    if state["mdadm_bin"] == 0 and state["mdraid"] == 0:
        errs.append("initramfs has no mdraid module (no mdadm/mdmon, no mdraid hooks)")
    if state["conf"] is None:
        errs.append("initramfs has no /etc/mdadm.conf — dracut omits it unless "
                    "mdadmconf=\"yes\" is set for the (non-hostonly) build")
    elif ("ARRAY %s" % array).encode() not in state["conf"]:
        errs.append("initramfs %s has no 'ARRAY %s' line" % (state["conf_path"], array))

    if errs:
        print("initramfs audit FAILED for %s:" % path, file=sys.stderr)
        for e in errs:
            print("  - %s" % e, file=sys.stderr)
        return 1

    print("initramfs audit OK — %d entries, mdraid module present, "
          "'ARRAY %s' in %s" % (state["entries"], array, state["conf_path"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
