#!/usr/bin/env python3
"""Extract the cluster definition (spc.tgz) from a Palette content bundle.

The bundle is a zstd-compressed tar holding an OCI image layout; the cluster
definition is one of its artifacts.

Usage: extract_spc.py <bundle.tar.zst> <out-dir>
Prints the path of the written spc.tgz.
"""
import json
import os
# Fixed argv below, shell=False throughout; see the call site.
import subprocess  # nosec B404
import sys
import tarfile


def stream_members(bundle, names=None, prefix=None):
    """Yield (name, bytes) for selected members without unpacking the archive."""
    # realpath: zstd REFUSES to read a symlink ("is a symbolic link, ignoring")
    # and exits 0 having written nothing, which surfaces here as a baffling
    # "tarfile.ReadError: empty file". Sharing one ~10 GB bundle between repos
    # by symlinking it into artifacts/ is the obvious thing to do, so resolve
    # the link rather than letting that fail obscurely.
    #
    # Literal argv with shell=False; `bundle` is an operator-supplied path
    # from artifacts/, not untrusted input. zstd is resolved from PATH on
    # purpose: roles/dependencies installs it and its location differs
    # across the distros this repo supports.
    proc = subprocess.Popen(  # nosec B603 B607
        ["zstd", "-dc", os.path.realpath(bundle)], stdout=subprocess.PIPE
    )
    try:
        with tarfile.open(fileobj=proc.stdout, mode="r|") as tar:
            for member in tar:
                if not member.isfile():
                    continue
                base = os.path.basename(member.name)
                if (names and base in names) or (prefix and member.name.startswith(prefix)):
                    fh = tar.extractfile(member)
                    if fh:
                        yield member.name, fh.read()
                        if names:
                            names.discard(base)
                            if not names:
                                return
    finally:
        proc.stdout.close()
        proc.wait()


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    bundle, out_dir = sys.argv[1], sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)

    index = None
    for _, data in stream_members(bundle, names={"index.json"}):
        index = json.loads(data)
        break
    if index is None:
        sys.exit("index.json not found: is this an appliance content bundle?")

    manifest_digest = None
    for m in index.get("manifests", []):
        ann = m.get("annotations", {})
        ref = ann.get("org.opencontainers.image.ref.name", "")
        if ann.get("io.image.ref.spectrocloud.type") == "spc" or "cluster-definition" in ref:
            manifest_digest = m["digest"].split(":", 1)[1]
            break
    if not manifest_digest:
        sys.exit("no cluster-definition (spc) manifest in bundle index")

    manifest = None
    for _, data in stream_members(bundle, names={manifest_digest}):
        manifest = json.loads(data)
        break
    if manifest is None:
        sys.exit("cluster-definition manifest blob %s missing" % manifest_digest)

    layers = manifest.get("layers", [])
    if not layers:
        sys.exit("cluster-definition manifest has no layers")
    layer_digest = layers[0]["digest"].split(":", 1)[1]

    out_path = os.path.join(out_dir, "spc.tgz")
    for _, data in stream_members(bundle, names={layer_digest}):
        with open(out_path, "wb") as fh:
            fh.write(data)
        break
    else:
        sys.exit("cluster-definition layer blob %s missing" % layer_digest)

    # Sanity check: it must be a gzipped tar containing the spc/ tree.
    with tarfile.open(out_path, "r:gz") as tar:
        if not any(n.startswith("spc/") for n in tar.getnames()[:20]):
            sys.exit("extracted archive does not look like a cluster definition")

    print(out_path)


if __name__ == "__main__":
    main()
