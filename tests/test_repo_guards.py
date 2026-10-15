"""The guards in scripts/repo-guards.py catch the failure shapes they exist for.

Each case reproduces a defect that reached a branch while integrating PR #65.
"""

import importlib.util
import os

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = importlib.util.spec_from_file_location(
    "repo_guards", os.path.join(HERE, "..", "scripts", "repo-guards.py"))
guards = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guards)


def test_sibling_duplicate_is_caught():
    # A conflict-free merge where both sides added the same block kept both.
    tasks = yaml.safe_load("""
- name: Configure the profile category
  ansible.builtin.command: cmsh -c true
- name: Reconcile the category disksetup with the dd-install
  when: deploy_dd_finalize_install | bool
  block: []
- name: Reconcile the category disksetup with the dd-install
  when:
    - deploy_dd_finalize_install | bool
    - dd_disksetup_reconcile | bool
  block: []
""")
    assert guards.duplicate_names(tasks) == ["Reconcile the category disksetup with the dd-install"]


def test_block_named_like_its_child_is_not_a_duplicate():
    doc = yaml.safe_load("""
- name: Download BCM ISO from JFrog
  block:
    - name: Download BCM ISO from JFrog
      ansible.builtin.command: curl -K cfg
""")
    assert all(guards.duplicate_names(tasks) == [] for tasks in guards.task_lists(doc))


def test_same_name_in_separate_plays_is_not_a_duplicate():
    doc = yaml.safe_load("""
- hosts: localhost
  tasks:
    - name: Register the BCM as a managed host
      ansible.builtin.add_host: {name: bcm}
- hosts: bcm
  tasks:
    - name: Register the BCM as a managed host
      ansible.builtin.add_host: {name: bcm}
""")
    assert all(guards.duplicate_names(tasks) == [] for tasks in guards.task_lists(doc))


def test_bare_dict_conditional_is_caught():
    names = {"kairos_os_raid", "kairos_data_raid"}
    assert guards.bare_collection_items(
        ["kairos_build_mdraid | bool", "kairos_os_raid is defined and kairos_os_raid"], names) == ["kairos_os_raid"]
    assert guards.bare_collection_items("not kairos_data_raid", names) == ["kairos_data_raid"]


def test_boolean_collection_conditional_passes():
    names = {"kairos_os_raid"}
    assert guards.bare_collection_items("(kairos_os_raid | default({})) | length > 0", names) == []
    assert guards.bare_collection_items("kairos_os_raid is defined", names) == []


def test_conflict_marker_is_caught(tmp_path, monkeypatch):
    (tmp_path / "f.yml").write_text("a: 1\n<<<<<<< HEAD\nb: 2\n=======\nb: 3\n>>>>>>> pr65\n")
    (tmp_path / "rule.md").write_text("Title\n=======\n")
    monkeypatch.setattr(guards, "ROOT", str(tmp_path))
    found = guards.check_conflict_markers(["f.yml", "rule.md"])
    assert [f.split(":")[0] for f in found] == ["f.yml", "f.yml", "f.yml"]
