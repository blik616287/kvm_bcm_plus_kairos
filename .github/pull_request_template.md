## What and why

<!-- What changes, what broke or was missing without it. One topic per PR. -->

## Profiles affected

<!-- From `git diff tests/golden/`: which profiles render differently, and why
     each one should. "None" is a valid answer for refactors. -->

## Checklist (see CONTRIBUTING.md)

- [ ] Branched from / rebased onto current upstream `main`; no commits that already landed
- [ ] `make check` passes locally
- [ ] New behaviour is opt-in; its default is pinned in `tests/safe-defaults.yml`
- [ ] Site/lab-specific settings live in a profile, not a shared template or role default
- [ ] RAID/DGX-only logic is gated (templates, tasks and validate checks)
- [ ] `tests/golden/` updated only for profiles this change should affect
- [ ] Local-KVM run for finalize / installer / cloud-config / deploy_dd changes (paste the validate summary)
- [ ] Docs updated (README variables/targets/changelog, stage docs)
