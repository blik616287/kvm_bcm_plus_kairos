#!/usr/bin/env python3
"""Write the variable set a profile renders with, merged in Ansible's order.

  role defaults (deploy_dd, kairos_build)
    < inventory/hosts.yml `all.vars` (the committed local-KVM defaults)
    < tests/fixtures/render-vars.yml (stand-ins for run-time facts)
    < the profile or variant file

inventory/group_vars/all.yml is deliberately NOT read: it is gitignored and
site-specific, so reading it would make a local render differ from CI's.

Usage: merge_vars.py <repo_root> <profile.yml> <out.yml>
"""

import os
import sys

import yaml


def load(path):
    with open(path) as fh:
        return yaml.safe_load(fh) or {}


def main():
    if len(sys.argv) != 4:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    root, profile, out = sys.argv[1:]
    merged = {}
    for role in ("deploy_dd", "kairos_build"):
        merged.update(load(os.path.join(root, "roles", role, "defaults", "main.yml")))
    merged.update(load(os.path.join(root, "inventory", "hosts.yml"))["all"]["vars"])
    merged.update(load(os.path.join(root, "tests", "fixtures", "render-vars.yml")))
    merged.update(load(profile))
    with open(out, "w") as fh:
        yaml.safe_dump(merged, fh, sort_keys=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
