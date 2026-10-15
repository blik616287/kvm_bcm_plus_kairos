#!/usr/bin/env python3
"""Print the provider-image refs a CanvOS day-2 build produces, one per line.

Mirrors the Earthfile so the day-2 upload pushes exactly what +build-provider-images
built and loaded into the local Docker daemon:

  IMAGE_PATH = $IMAGE_REGISTRY/$IMAGE_REPO:$K8S_DISTRIBUTION-$K8S_VERSION-$IMAGE_TAG
  IMAGE_TAG  = $PE_VERSION-$CUSTOM_TAG   (just $PE_VERSION when CUSTOM_TAG is empty)

and +build-provider-images builds ONE distribution (.arg K8S_DISTRIBUTION): either
the single .arg K8S_VERSION, or every version listed for that distribution in
k8s_version.json. PE_VERSION comes from .arg when set (profiles pin it there),
else from the Earthfile's `ARG PE_VERSION=` default.

Exits non-zero, naming what is missing, rather than printing nothing: an empty
list would make the upload loop push nothing and report success.

Usage: provider-image-refs.py <canvos_dir>
"""

import json
import os
import re
import sys


def read_arg(path):
    args = {}
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            args[key.strip()] = value.strip()
    return args


def main():
    if len(sys.argv) != 2:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    canvos = sys.argv[1]
    args = read_arg(os.path.join(canvos, ".arg"))

    missing = [k for k in ("IMAGE_REGISTRY", "IMAGE_REPO", "K8S_DISTRIBUTION") if not args.get(k)]
    if missing:
        print("missing from .arg: %s" % ", ".join(missing), file=sys.stderr)
        return 1

    pe_version = args.get("PE_VERSION", "")
    if not pe_version:
        with open(os.path.join(canvos, "Earthfile")) as fh:
            match = re.search(r"(?m)^\s*ARG\s+PE_VERSION=(\S+)", fh.read())
        if not match:
            print("no PE_VERSION in .arg and no `ARG PE_VERSION=` in the Earthfile", file=sys.stderr)
            return 1
        pe_version = match.group(1)

    dist = args["K8S_DISTRIBUTION"]
    if args.get("K8S_VERSION"):
        versions = [args["K8S_VERSION"]]
    else:
        with open(os.path.join(canvos, "k8s_version.json")) as fh:
            versions = json.load(fh).get(dist, [])
        if not versions:
            print("k8s_version.json lists no versions for K8S_DISTRIBUTION=%s" % dist, file=sys.stderr)
            return 1

    tag = pe_version + ("-" + args["CUSTOM_TAG"] if args.get("CUSTOM_TAG") else "")
    for version in versions:
        print("%s/%s:%s-%s-%s" % (args["IMAGE_REGISTRY"], args["IMAGE_REPO"], dist, version, tag))
    return 0


if __name__ == "__main__":
    sys.exit(main())
