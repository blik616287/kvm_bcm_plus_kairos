#!/usr/bin/env python3
"""Reject a cloud-config that kairos-agent would refuse to install from.

The kairos-sdk collector merges every /oem/*.yaml it scans. A mapping key
written with nothing under it parses as null, and the merge then dereferences
that nil -- kairos-agent segfaults in DeepMerge (collector.go:201) before the
install starts, three retries deep, leaving a blank disk and an opaque
"no EFI System Partition found" from the verify step. Catch it at render time,
where the offending key still has a name and a line number.
"""

import sys

import yaml


def null_paths(node, path=""):
    if isinstance(node, dict):
        for key, value in node.items():
            here = f"{path}.{key}" if path else str(key)
            if value is None:
                yield here
            else:
                yield from null_paths(value, here)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            here = f"{path}[{index}]"
            if value is None:
                yield here
            else:
                yield from null_paths(value, here)


def main():
    path = sys.argv[1]
    with open(path, encoding="utf-8") as handle:
        text = handle.read()

    if not text.startswith("#cloud-config"):
        sys.exit(f"{path}: missing '#cloud-config' header -- the collector would skip it")

    try:
        doc = yaml.safe_load(text)
    except yaml.YAMLError as exc:
        sys.exit(f"{path}: not valid YAML: {exc}")

    if not isinstance(doc, dict):
        sys.exit(f"{path}: top level is {type(doc).__name__}, expected a mapping")

    nulls = list(null_paths(doc))
    if nulls:
        sys.exit(
            f"{path}: null-valued keys would crash the kairos collector: "
            + ", ".join(nulls)
        )

    print(f"{path}: OK ({len(doc)} top-level keys, no null values)")


if __name__ == "__main__":
    main()
