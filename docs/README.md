# Documentation index

BCM + Kairos provisioning pipeline. Start with the runbook; drop into a stage doc when something breaks.

## Start here
- **[Architecture & troubleshooting runbook](architecture-and-troubleshooting.md)** — all the pieces, the end-to-end workflow, diagrams, the logging map, and a "[where did it break?](architecture-and-troubleshooting.md#where-did-it-break)" decision flow. Has a **fast-triage** block at the top.

## Per-stage deep-dives
`make <target>` → `playbooks/0N-<stage>.yml` → `roles/<role>`. Each doc: flow → inputs → artifacts → logging → validate → troubleshooting.

| Stage | Doc | Mode |
|---|---|---|
| 1 — `bcm-prepare` | [stage-1-bcm-prepare.md](stage-1-bcm-prepare.md) | local-KVM |
| 2 — `bcm-vm` | [stage-2-bcm-vm.md](stage-2-bcm-vm.md) | local-KVM only |
| 3 — `kairos-build` | [stage-3-kairos-build.md](stage-3-kairos-build.md) | local + remote |
| 4 — `deploy-dd` | [stage-4-deploy-dd.md](stage-4-deploy-dd.md) | local + remote |
| 5 — `kairos-vm` | [stage-5-kairos-vm.md](stage-5-kairos-vm.md) | local-KVM only |
| 6 — `validate` | [stage-6-validate.md](stage-6-validate.md) | local + remote |

> Local-KVM (`make all`) runs all six; remote-BCM runs 3, 4, 6 against an existing head node.

## Targeted troubleshooting
- [Node booted the BCM image, not Kairos](troubleshoot-node-booted-bcm-image.md) — the most common "it didn't become Kairos" failure.

## Reference
- [pipeline-deep-dive.md](pipeline-deep-dive.md) — engineer-level per-stage walkthrough.
- [LOCAL_KVM_DEPLOYMENT.md](LOCAL_KVM_DEPLOYMENT.md) · [POC_Client_Deployment.md](POC_Client_Deployment.md) · [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Repo root `README.md` — variables, make targets, modes. `inventory/group_vars/all.example.yml` — full variable reference; `all.local-kvm.example.yml` — minimal local-KVM config.

## Partner / field notes (NVIDIA DGX)
- [nvidia-dgx-fixes-and-asks.md](nvidia-dgx-fixes-and-asks.md) — consolidated fixes + open asks.
- [nvidia-dgx-superpod-install-fix.md](nvidia-dgx-superpod-install-fix.md) — post-`dd` EBUSY quiesce.
- [nvidia-dgx-disksetup-raid-loop-fix.md](nvidia-dgx-disksetup-raid-loop-fix.md) — RAID-vs-single-disk-`dd` loop.
