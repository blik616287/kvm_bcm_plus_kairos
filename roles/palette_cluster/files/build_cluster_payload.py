#!/usr/bin/env python3
"""Build the create-cluster payload from an extracted cluster definition.

Profile variables come from the definition itself; defaults are used unless
overridden on the command line.

Usage:
  build_cluster_payload.py --spc-dir DIR --out FILE --name NAME --vip IP \
      --host-uid UID --host-ip IP [--arch amd64] \
      [--set name=value ...]
"""
import argparse
import glob
import json
import os
import sys
import tarfile


def load_profiles(spc_dir):
    """Return {profile id: [variable, ...]} from the unpacked definition."""
    profiles = {}
    pattern = os.path.join(spc_dir, "spc", "app", "profiles", "*", "variables.json")
    for path in sorted(glob.glob(pattern)):
        uid = os.path.basename(os.path.dirname(path))
        with open(path) as fh:
            profiles[uid] = json.load(fh).get("variables", [])
    return profiles


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spc-dir", required=True)
    ap.add_argument("--spc-archive")
    ap.add_argument("--out", required=True)
    ap.add_argument("--name", required=True)
    ap.add_argument("--vip", required=True)
    ap.add_argument("--host-uid", required=True)
    ap.add_argument("--host-ip", required=True)
    ap.add_argument("--arch", default="amd64")
    ap.add_argument("--archive-path", default="/usr/local/spectrocloud/clusterconfig/override/spc.tgz")
    ap.add_argument("--set", action="append", default=[], metavar="NAME=VALUE")
    args = ap.parse_args()

    if args.spc_archive and not os.path.isdir(os.path.join(args.spc_dir, "spc")):
        os.makedirs(args.spc_dir, exist_ok=True)
        with tarfile.open(args.spc_archive, "r:gz") as tar:
            try:
                tar.extractall(args.spc_dir, filter="data")
            except TypeError:  # filter= added in 3.12
                tar.extractall(args.spc_dir)

    overrides = {}
    for item in args.set:
        if "=" not in item:
            sys.exit("--set expects NAME=VALUE, got %r" % item)
        k, v = item.split("=", 1)
        overrides[k] = v

    profiles = load_profiles(args.spc_dir)
    if not profiles:
        sys.exit("no profile variables found under %s" % args.spc_dir)

    profile_vars, missing = [], []
    for uid, variables in profiles.items():
        for v in variables:
            name = v["name"]
            value = overrides.get(name, v.get("defaultValue"))
            if value is None:
                value = ""
            if v.get("required") and value == "":
                missing.append(name)
            profile_vars.append({"name": name, "value": str(value), "profileUid": uid})

    if missing:
        sys.exit("required profile variables have no value: %s" % ", ".join(sorted(missing)))

    payload = {
        "metadata": {"name": args.name, "labels": {}},
        "spec": {
            "archiveUploadPath": args.archive_path,
            "cloudConfig": {
                "spec": {
                    "clusterConfig": {
                        "controlPlaneEndpoint": {"host": args.vip, "type": "VIP"},
                        "ntpServers": [],
                        "sshKeys": [],
                        "overlayNetworkConfiguration": {"enable": False, "cidr": ""},
                    },
                    "machinePoolConfig": [
                        {
                            "labels": ["master"],
                            "useControlPlaneAsWorker": True,
                            "additionalLabels": {},
                            "hosts": [
                                {
                                    "hostUid": args.host_uid,
                                    "hostAddress": args.host_ip,
                                    "hostName": args.host_uid,
                                    "IsCandidateCaption": True,
                                    "isTwoNodeCandidate": False,
                                }
                            ],
                            "name": "master-pool",
                            "taints": [],
                            "isControlPlane": True,
                            "size": 1,
                            "machinePoolProperties": {"archType": args.arch},
                        }
                    ],
                }
            },
            "profileVariables": profile_vars,
        },
    }

    with open(args.out, "w") as fh:
        json.dump(payload, fh, indent=1)
    print("%s (%d profile variables across %d profiles)" % (args.out, len(profile_vars), len(profiles)))


if __name__ == "__main__":
    main()
