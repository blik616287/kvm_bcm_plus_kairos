# Contributing

This repo provisions real hardware (customer BCM head nodes, DGX systems) and
every profile shares the same roles and templates. A change that is correct for
the node you tested can silently change every other profile, so the rules below
are about one thing: **land your change without changing anyone else's node.**

The upstream repo is `blik616287/kvm_bcm_plus_kairos`. Lab or site work happens
in forks (e.g. `jbergfeld/bcm-kairos-contrib`) and comes back as pull requests.

---

## 1. Work from current upstream, not a long-lived local copy

Most integration pain so far came from branches cut from an old upstream and
developed for weeks in a lab checkout. When such a branch finally comes back,
git merges it against months of upstream changes it never saw.

```bash
# once, in your fork's checkout
git remote add upstream https://github.com/blik616287/kvm_bcm_plus_kairos.git

# for every piece of work
git fetch upstream
git switch -c <topic> upstream/main          # never branch from a stale main

# before opening (and while the PR is open), bring upstream in
git fetch upstream
git rebase upstream/main                     # or: git merge upstream/main
```

- **One topic per PR.** A PR titled "final local commits" with 20 unrelated
  commits cannot be reviewed or reverted piecemeal. Split it.
- **Never re-submit commits that already landed.** If an earlier PR of yours was
  merged (often squashed), rebase onto upstream so its commits drop out, instead
  of carrying them into the next PR.
- **Open the PR early as a draft** if the work is long; CI then runs against
  current upstream on every push.

## 2. Resolving conflicts

A conflict-free merge is not a correct merge. On #65, git auto-merged a
template into invalid YAML and silently kept two copies of the same task block.
When you resolve a merge or rebase:

- **Read both sides; never take "ours" or "theirs" for a whole file.** On
  `.gitignore`, taking one side would have dropped the rules that keep secrets
  and licensed artifacts out of git.
- **Prefer upstream's version of anything upstream already fixed**, then
  re-apply only your actual change on top.
- **Look for duplicates.** If both sides added a similar block, delete the
  stale one. `make guards` catches duplicated sibling tasks.
- **Re-render and review.** `make render-check` shows exactly how each profile
  changed. If a profile you did not touch changed, the merge is wrong.

## 3. Rules for changes

**New behaviour is opt-in.** A new feature adds a variable whose default keeps
today's behaviour, and the profile that needs it sets it. Pin the default in
`tests/safe-defaults.yml` (CI enforces it). Examples:
`kairos_wipe_all_nvme`, `dd_disksetup_reconcile`,
`deploy_dd_autoconfirm_install`, all off by default and set by the DGX profiles.

**Site or lab facts go in profiles, never in shared templates or role
defaults.** "eth2 gets a duplicate DHCP address in our lab" is a profile
setting, not a change to the cloud-config every image ships.

**Gate RAID-only and DGX-only logic** on `kairos_build_mdraid`,
`(kairos_os_raid | default({})) | length > 0`, or a dedicated opt-in, in
templates, tasks *and* validate checks. A single-disk node (ubuntu-24.04, the
Palette appliance) must render exactly as before.

**Patches to the shared CanvOS checkout use `state:`, not `when:`.** Every
profile builds in one `CanvOS/` tree, so a patch skipped with `when:` leaves the
previous profile's change in place for the next image. Drive
`state: present/absent` from the profile.

**Conditionals are booleans.** ansible-core 2.19+ rejects a dict or list as a
condition: write `(var | default({})) | length > 0`, not `var is defined and var`.

**BCM changes stay additive and reversible**: clone categories, touch only the
target node, never flip cluster-wide settings on a head node you do not own (see
README "Key Design Points").

**Never commit** `inventory/group_vars/all.yml`, anything under `artifacts/`,
keys, certificates or credentials. `make analyze` runs gitleaks.

## 4. Before you open the PR

```bash
make check     # = fmt-check lint analyze guards render-check test (what CI runs)
```

If `render-check` fails because you changed behaviour **on purpose**:

```bash
make render-update
git diff tests/golden/        # read it profile by profile
```

Commit `tests/golden/` with the change, and say in the PR **which profiles
change and why each one should**. A golden diff in a profile your change has no
business touching is a bug, not a golden to update.

### When you also need the local-KVM end-to-end run

Static checks cannot see a node boot. Run the local-KVM pipeline (see
`docs/LOCAL_KVM_DEPLOYMENT.md`) for any change to the finalize script, the
installer, the cloud-config, or `deploy_dd`'s BCM-side tasks. Cover both shapes:

```bash
# RAID path (local stand-in for a DGX); diskless provisioning needs RAM > the installer image
make kairos-build deploy-dd kairos-vm validate \
  ANSIBLE_ARGS="-e @profiles/dgx-raid-kvm.yml -e dd_disksetup_reconcile=true -e kairos_vm_ram=20480"

# single-disk path through the finalize installer (the shape palette-appliance uses)
make kairos-build deploy-dd kairos-vm validate \
  ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml -e deploy_dd_finalize_install=true"
```

Also check what static checks miss: that BCM still calls the node by its device
name a few minutes after boot (`cmsh -c "device; list"`), and, for RAID, a
re-image over existing arrays (PXE the node again without wiping its disks).
Paste the validate summary into the PR.

## 5. What CI guards and why

`.github/workflows/lint.yml` runs on every push to `main` and on every PR,
against the PR **merged into current main**:

| Check | Catches |
|---|---|
| `make fmt-check` / `make lint` | shell formatting, shellcheck (scripts and rendered `*.sh.j2`), yamllint, ansible-lint |
| `make analyze` | committed secrets (gitleaks, blocking), IaC and Python findings |
| `make guards` | conflict markers; duplicated sibling tasks; `.gitignore` losing secret patterns; opt-in defaults drifting from `tests/safe-defaults.yml`; CanvOS patches gated by `when:`; dict/list conditionals; profile keys nothing reads (typos) |
| `make render-check` | every profile's finalize script, installer and cloud-config must render, pass `bash -n` + shellcheck and the cloud-config validator, and match `tests/golden/` |
| `make test` | unit tests for the repo's own scripts |

Each guard maps to a defect that reached a branch; the history is in the README
changelog. When you find a new class of regression, add a guard for it in the
same PR as the fix.

## 6. Commits and PR mechanics

- Maintainers ship through `/gpp` (`gp.py`), which creates or updates the JIRA
  ticket in project `IN` and opens the PR; merged PRs are squashed with an
  `[IN-xxxx] ... (#NN)` subject. External contributors: open the PR normally and
  a maintainer attaches the ticket.
- Commit messages say **what changed and why**, including what broke without it.
- Keep each commit buildable; the PR is squashed on merge, but reviewers read
  the commits.
- Fill in the PR template's checklist.

## 7. For maintainers

Recommended branch protection on `main`: require a pull request, require the
`quality-gates` and `regression-guards` checks, **require branches to be up to
date before merging** (so CI has run against the exact main being merged into),
and disallow force-pushes.
