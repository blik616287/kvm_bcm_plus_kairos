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

## Optional — self-hosted Palette
- **[REPRODUCE.md](REPRODUCE.md)** — **start here to reproduce the experiment from scratch**: host requirements, the licensed inputs you must obtain, the complete `group_vars/all.yml`, every command in order with timings, and how to confirm the result. Self-contained; assumes only a bare Linux host.
- **[e2e-appliance-and-edge.md](e2e-appliance-and-edge.md)** — **the runbook**: stand up the appliance, then provision a Kairos edge node that registers to *it* instead of Palette SaaS. Exact commands, timings, node/IP/MAC layout, how to prove registration went to the local appliance, re-run recipes, and the failure signatures. Start here for the full flow.
- **[stage-palette-appliance.md](stage-palette-appliance.md)** — `make palette-appliance` builds a **Palette management appliance** image and has **BCM provision it** onto a managed node, over the same PXE + `dd` path used for edge nodes. It is a build profile (`profiles/palette-appliance.yml`) flowing through stages 3 → 4 → 5, not a parallel pipeline; `deploy_dd` needed no changes. BCM must already be up. The doc lists the five profile settings that make an appliance build differ from an edge build, and the failure signature of each.

## Targeted troubleshooting
- [Node booted the BCM image, not Kairos](troubleshoot-node-booted-bcm-image.md) — the most common "it didn't become Kairos" failure.

## Reference
- [pipeline-deep-dive.md](pipeline-deep-dive.md) — engineer-level per-stage walkthrough.
- [LOCAL_KVM_DEPLOYMENT.md](LOCAL_KVM_DEPLOYMENT.md) · [POC_Client_Deployment.md](POC_Client_Deployment.md) · [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Repo root `README.md` — variables, make targets, modes. `profiles/README.md` — per-profile schema, RAID layouts, and the local-KVM RAID emulation. `artifacts/README.md` — the licensed Spectro downloads the appliance needs. `inventory/group_vars/all.example.yml` — full variable reference; `all.local-kvm.example.yml` — minimal local-KVM config.

## Partner / field notes (NVIDIA DGX)
- [nvidia-dgx-fixes-and-asks.md](nvidia-dgx-fixes-and-asks.md) — consolidated fixes + open asks.
- [nvidia-dgx-superpod-install-fix.md](nvidia-dgx-superpod-install-fix.md) — post-`dd` EBUSY quiesce.
- [nvidia-dgx-disksetup-raid-loop-fix.md](nvidia-dgx-disksetup-raid-loop-fix.md) — RAID-vs-single-disk-`dd` loop.
