#!/usr/bin/env python3
"""Print the STYLUS AGENT version shipped in a Palette content bundle.

That version is what appliance_pe_version must equal, and it is NOT the bundle
filename: palette-enterprise-appliance-4.10.17.tar.zst ships stylus v4.10.4.
The filename carries the manifest version instead, which is a different number.

Reads only index.json out of the (~10 GB) zstd tar stream and stops there, so
it costs a few seconds rather than a full decompress.

Usage: bundle_stylus_version.py <bundle.tar.zst>
Prints e.g. v4.10.4, or nothing at all if the bundle cannot be read — callers
treat empty as "unverified" rather than as a mismatch.
"""
# Fixed argv below, shell=False; see the call site.
import json  # nosec B404
import os
import subprocess  # nosec B404
import sys
import tarfile


def index_json(bundle):
    """Return the bundle's OCI index.json, or None."""
    # Literal argv with shell=False; `bundle` is an operator-supplied path from
    # artifacts/, not untrusted input. realpath because zstd refuses to read a
    # symlink and exits 0 having written nothing.
    proc = subprocess.Popen(  # nosec B603 B607
        ["zstd", "-dc", os.path.realpath(bundle)], stdout=subprocess.PIPE
    )
    try:
        with tarfile.open(fileobj=proc.stdout, mode="r|") as tar:
            for member in tar:
                if member.isfile() and os.path.basename(member.name) == "index.json":
                    fh = tar.extractfile(member)
                    if fh:
                        return json.loads(fh.read())
    except Exception:
        return None
    finally:
        if proc.stdout:
            proc.stdout.close()
        proc.wait()
    return None


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    idx = index_json(sys.argv[1])
    if not idx:
        return  # unreadable: print nothing, caller treats as unverified
    for m in idx.get("manifests", []):
        ann = m.get("annotations", {}) or {}
        if ann.get("io.image.ref.spectrocloud.type") != "stylus":
            continue
        ref = ann.get("org.opencontainers.image.ref.name", "")
        # e.g. us-docker.pkg.dev/palette-images/edge/stylus:v4.10.4
        if ":" in ref:
            print(ref.rsplit(":", 1)[1])
            return


if __name__ == "__main__":
    main()
