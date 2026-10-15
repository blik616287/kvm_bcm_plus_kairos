#!/usr/bin/env python3
"""Structural guards for changes that lint and the render check cannot see.

Each check exists because a merge or a change that looked fine broke a
profile (see CONTRIBUTING.md, "What CI guards and why"):

  conflict-markers   leftover <<<<<<< / >>>>>>> in a tracked file
  duplicate-tasks    two sibling tasks with the same name in one task list --
                     a conflict-free merge where both sides added the same
                     block keeps BOTH, and the stale copy runs first
  gitignore          the secrets / licensed-artifact patterns are still ignored
  safe-defaults      opt-in role defaults still hold the values pinned in
                     tests/safe-defaults.yml
  canvos-state       a task patching the shared CanvOS checkout uses
                     `state: present/absent` driven by the profile, not `when:`
                     (every profile builds in one checkout, so a skipped patch
                     leaks the previous profile's change into the next image)
  bare-collection    a `when:` item that is a bare dict/list variable
                     (ansible-core >= 2.19 rejects non-boolean conditionals)
  profile-keys       every top-level key a profile sets is read somewhere in
                     roles/, playbooks/ or inventory/ -- catches typos that
                     would otherwise be silently ignored

Usage: scripts/repo-guards.py            (from anywhere; exits 1 on findings)
"""

import os
import re
import subprocess
import sys

import yaml

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

REQUIRED_IGNORES = [
    "inventory/group_vars/all.yml",
    "artifacts/*",
    "*.pem",
    "*.key",
    ".run-credentials.yml",
    ".jfrog-curl.cfg",
    "bcm-kairos-key",
]

# Known, pre-existing exceptions. Each entry must name its removal plan; delete
# the entry in the change that fixes it.
CANVOS_WHEN_ALLOWLIST = {
    # Converted to state: present/absent by the PR #65 port.
    "Patch Earthfile — include dracut mdraid module (kairos_build_mdraid)",
}

PATCH_MODULES = ("lineinfile", "blockinfile", "replace")
MARKER = re.compile(r"^(<<<<<<< |>>>>>>> |=======$)", re.M)


def tracked_files():
    out = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True)
    return [f for f in out.stdout.splitlines() if f]


def load_yaml(path):
    with open(os.path.join(ROOT, path)) as fh:
        return yaml.safe_load(fh)


def task_lists(doc):
    """Yield every list of sibling tasks in a playbook or task file."""
    if not isinstance(doc, list):
        return
    if any(isinstance(item, dict) and "hosts" in item for item in doc):
        for play in doc:
            if not isinstance(play, dict):
                continue
            for key in ("pre_tasks", "tasks", "post_tasks", "handlers"):
                yield from _nested(play.get(key))
    else:
        yield from _nested(doc)


def _nested(tasks):
    if not isinstance(tasks, list):
        return
    yield tasks
    for task in tasks:
        if isinstance(task, dict):
            for key in ("block", "rescue", "always"):
                yield from _nested(task.get(key))


def all_tasks(doc):
    for tasks in task_lists(doc):
        for task in tasks:
            if isinstance(task, dict):
                yield task


def task_files(files):
    return [f for f in files if f.endswith(".yml") and (
        re.match(r"roles/[^/]+/(tasks|handlers)/", f) or f.startswith("playbooks/"))]


def check_conflict_markers(files):
    found = []
    for f in files:
        path = os.path.join(ROOT, f)
        try:
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
        except (UnicodeDecodeError, IsADirectoryError, FileNotFoundError):
            continue
        for m in MARKER.finditer(text):
            line = text.count("\n", 0, m.start()) + 1
            # A YAML/Markdown rule line of exactly 7 '=' is legitimate only
            # outside a <<<<<<< ... >>>>>>> region; require the opener too.
            if m.group(1) == "=======" and "<<<<<<< " not in text:
                continue
            found.append("%s:%d: merge conflict marker" % (f, line))
    return found


def duplicate_names(tasks):
    seen, dups = set(), []
    for task in tasks:
        if not isinstance(task, dict) or "name" not in task:
            continue
        name = str(task["name"]).strip()
        if name in seen:
            dups.append(name)
        seen.add(name)
    return dups


def check_duplicate_tasks(files):
    found = []
    for f in task_files(files):
        for tasks in task_lists(load_yaml(f)):
            for name in duplicate_names(tasks):
                found.append("%s: two sibling tasks named %r (a merge kept both copies?)" % (f, name))
    return found


def check_gitignore():
    with open(os.path.join(ROOT, ".gitignore")) as fh:
        lines = {l.strip() for l in fh if l.strip() and not l.lstrip().startswith("#")}
    return [".gitignore: no longer ignores %r" % p for p in REQUIRED_IGNORES if p not in lines]


def check_safe_defaults():
    found = []
    pinned = load_yaml("tests/safe-defaults.yml") or {}
    for path, expected in pinned.items():
        actual = load_yaml(path) or {}
        for var, value in expected.items():
            if var not in actual:
                found.append("%s: %s is no longer defined (pinned in tests/safe-defaults.yml)" % (path, var))
            elif actual[var] != value:
                found.append("%s: %s is %r, pinned to %r in tests/safe-defaults.yml"
                             % (path, var, actual[var], value))
    return found


def check_canvos_state(files):
    found = []
    for f in task_files(files):
        for task in all_tasks(load_yaml(f)):
            mod = next((k for k in task if k.split(".")[-1] in PATCH_MODULES), None)
            if not mod or not isinstance(task[mod], dict):
                continue
            if "canvos_dir" not in str(task[mod].get("path", "")):
                continue
            if "when" in task and "state" not in task[mod] and task.get("name") not in CANVOS_WHEN_ALLOWLIST:
                found.append("%s: %r patches the shared CanvOS checkout behind `when:`; drive "
                             "`state: present/absent` from the profile instead" % (f, task.get("name")))
    return found


def collection_vars():
    """Variables whose default/profile value is a dict or list."""
    names = set()
    sources = [p for p in tracked_files() if re.match(r"(roles/[^/]+/defaults/main\.yml|profiles/[^/]+\.yml)$", p)]
    for src in sources:
        for k, v in (load_yaml(src) or {}).items():
            if isinstance(v, (dict, list)):
                names.add(k)
    inv = (load_yaml("inventory/hosts.yml") or {}).get("all", {}).get("vars", {})
    names.update(k for k, v in inv.items() if isinstance(v, (dict, list)))
    return names


def bare_collection_items(when, names):
    items = when if isinstance(when, list) else [when]
    bad = []
    for item in items:
        if not isinstance(item, str):
            continue
        for part in re.split(r"\s+(?:and|or)\s+", item.strip()):
            operand = re.sub(r"^(not\s+|\()+|\)+$", "", part.strip())
            if operand in names:
                bad.append(operand)
    return bad


def check_bare_collections(files):
    names = collection_vars()
    found = []
    for f in task_files(files):
        for task in all_tasks(load_yaml(f)):
            for var in bare_collection_items(task.get("when"), names):
                found.append("%s: %r uses %s as a conditional; write (%s | default({})) | length > 0"
                             % (f, task.get("name"), var, var))
    return found


def check_profile_keys(files):
    corpus = []
    for f in files:
        if f.startswith(("roles/", "playbooks/", "inventory/", "scripts/")) and not f.endswith((".png", ".jpg")):
            try:
                with open(os.path.join(ROOT, f), encoding="utf-8") as fh:
                    corpus.append(fh.read())
            except (UnicodeDecodeError, FileNotFoundError):
                pass
    text = "\n".join(corpus)
    found = []
    for f in files:
        if re.match(r"profiles/[^/]+\.yml$", f):
            for key in (load_yaml(f) or {}):
                if not re.search(r"\b%s\b" % re.escape(key), text):
                    found.append("%s: sets %r, which nothing in roles/, playbooks/, inventory/ or "
                                 "scripts/ reads (typo?)" % (f, key))
    return found


def main():
    files = tracked_files()
    checks = [
        ("conflict-markers", check_conflict_markers(files)),
        ("duplicate-tasks", check_duplicate_tasks(files)),
        ("gitignore", check_gitignore()),
        ("safe-defaults", check_safe_defaults()),
        ("canvos-state", check_canvos_state(files)),
        ("bare-collection", check_bare_collections(files)),
        ("profile-keys", check_profile_keys(files)),
    ]
    failed = False
    for name, findings in checks:
        if findings:
            failed = True
            print("FAIL %s" % name)
            for line in findings:
                print("  " + line)
        else:
            print("ok   %s" % name)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
