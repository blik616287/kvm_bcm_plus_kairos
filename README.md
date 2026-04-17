# BCM + Kairos Deployment

Automated end-to-end pipeline that provisions **Spectro Cloud Kairos edge nodes** through an existing **Bright Cluster Manager (BCM) 11.0** head node. Supports two deployment modes from the same repo:

1. **Remote BCM** — deploy Kairos to bare-metal compute nodes managed by an already-running BCM head node, optionally reached through an SSH jumphost. This is the primary mode for customer sites.
2. **Local KVM** — stand up a full BCM head node + Kairos compute node entirely in QEMU VMs for development / demo / regression testing.

End state in both cases: compute nodes PXE boot from BCM, `dd` a pre-built Kairos raw disk onto their OS disk, reboot into Kairos under UEFI, and register with Palette.

## Architecture

```
                       ┌──────────────────┐
                       │  Build Host      │
                       │  (this repo)     │
                       └────────┬─────────┘
                                │ ansible + ssh (optional jumphost)
                                ▼
┌───────────────────────────────────────────────────────────────┐
│ BCM head node (remote metal OR local KVM VM)                  │
│   • cmd, dhcpd, named, nfs-server, rsyncd                     │
│   • HTTP server on :8888 serving /cm/shared/kairos/disk.raw.lz4│
│   • software image:   kairos-installer  (dd + efibootmgr)     │
│   • category:         kairos            (FULL install mode)   │
│   • nodeexecutionfilters: Exclude mounts/interfaces/ntp       │
│                            scoped to category=kairos          │
└──────────────────────────────┬────────────────────────────────┘
                               │ PXE + rsync + HTTP (provisioning net)
                               ▼
                     ┌─────────────────────┐
                     │  Compute node       │
                     │  (bare metal or VM) │
                     │   UEFI → Kairos     │
                     │   stylus-agent →    │
                     │   Palette           │
                     └─────────────────────┘
```

- **Provisioning network**: flat L2 where BCM runs DHCP/PXE/TFTP/NFS/HTTP and the compute nodes live. On remote sites this is the customer's existing BCM internal VLAN; locally it's a QEMU socket bridge.
- **Palette**: reached from the compute node once it's booted Kairos. Can be public SaaS or on-prem (self-signed CA supported via `palette_ca_cert`).

## Prerequisites

- Ansible
- `sshpass`, `jq` (always)
- `qemu-system-x86_64` + `/dev/kvm`, Docker, `xorriso`, `p7zip`, `lz4`, `mtools`, `dosfstools`, OVMF (UEFI) firmware — required for the **kairos-build** stage (CanvOS + Earthly + UEFI raw-image generator). Also required for all stages when running in **local KVM** mode.

```bash
make install-deps   # auto-install on Debian/Fedora/Ubuntu
make setup          # verify prerequisites
```

## Quick Start — Remote BCM

```bash
# 1. Discover an existing BCM (prompts for IP, user/pass, optional jumphost)
make discover
#    → writes bcm-discovery-<bcm-hostname>.yml with suggested group_vars

# 2. Copy the example and fill in values from the discovery output
cp inventory/group_vars/all.example.yml inventory/group_vars/all.yml
$EDITOR inventory/group_vars/all.yml
#    → bcm_ssh_host, bcm_ssh_proxy_jump/key, bcm_target_node,
#      bcm_source_category, kairos_target_disk, palette_*

# 3. Build the Kairos raw image once (runs locally, ~30 min)
make kairos-build

# 4. Push to BCM + configure PXE + kairos category
make deploy-dd

# 5. Power-cycle the target node to PXE boot (via iDRAC / IPMI / Redfish).
#    BCM's installer writes Kairos via dd + efibootmgr, then powers off.
#    Power on again — node boots Kairos from its own disk.

# 6. Validate
make validate
```

`inventory/group_vars/all.yml` is gitignored. `inventory/group_vars/all.example.yml` is the committable template and documents every variable.

## Quick Start — Local KVM (dev / demo)

```bash
cp inventory/group_vars/all.example.yml inventory/group_vars/all.yml
# Uncomment the local-KVM section; set jfrog_token, palette_api_key, etc.

make all   # runs the full 6-stage pipeline (~100-120 min)
```

## Pipeline Stages

| Stage | Target | Duration | Description |
|-------|--------|----------|-------------|
| 1 | `make bcm-prepare` | ~2 min | Download BCM ISO from JFrog, patch rootfs, remaster for auto-install *(local-KVM only)* |
| 2 | `make bcm-vm` | ~60–90 min | Launch BCM in KVM, auto-install, boot from disk, wait for services *(local-KVM only)* |
| 3 | `make kairos-build` | ~30 min | Clone CanvOS, build Kairos ISO via Earthly, generate **UEFI** raw disk image under OVMF |
| 4 | `make deploy-dd` | ~3–5 min | SSH to BCM (direct or via jumphost), upload lz4 image, install `kairos-installer`, configure `kairos` category + nodeexecutionfilters |
| 5 | `make kairos-vm` | ~10 min | PXE boot compute VM, dd Kairos to disk, reboot into Kairos *(local-KVM only)* |
| 6 | `make validate` | ~15 sec | 41-point validation across BCM and Kairos (works for remote BCM + remote compute node through jumphost) |

```
                   ┌──> bcm-prepare ──> bcm-vm ─┐            (local-KVM only)
Remote-BCM deploy ─┤                            ├─> deploy-dd ──> validate
                   └──> kairos-build ───────────┘              (kairos-vm only in local-KVM mode)
```

Stages **bcm-vm** and **kairos-build** can run in parallel.

## Make Targets

```bash
# Pipeline
make bcm-prepare        # Stage 1 — local-KVM only
make bcm-vm             # Stage 2 — local-KVM only
make kairos-build       # Stage 3 — builds Kairos raw image via CanvOS + OVMF
make deploy-dd          # Stage 4 — push to BCM, configure PXE + kairos category
make kairos-vm          # Stage 5 — local-KVM only (PXE boots a local compute VM)
make validate           # Stage 6 — 41-point health check
make all                # Stages 1–6 (local-KVM mode)

# Discovery
make discover           # Interactive: prompts for BCM IP/user/pass + optional jumphost,
                        # emits bcm-discovery-<hostname>.yml with suggested group_vars

# VM management (local-KVM mode)
make bcm-stop           # Stop BCM VM
make kairos-stop        # Stop Kairos compute VM
make stop               # Stop all VMs
make bcm-serial         # Tail BCM serial log
make kairos-serial      # Tail Kairos serial log

# Cleanup
make clean              # Remove build/, logs/
make clean-dist         # Remove downloaded ISOs
make clean-canvos       # Remove cloned CanvOS repo
make clean-all          # Stop VMs + remove everything
make teardown           # Stop VMs + remove build artifacts

# Dependencies
make setup              # Verify prerequisites
make install-deps       # Install build dependencies
```

## Configuration

Single source of truth: `inventory/group_vars/all.yml` (copied from `all.example.yml`). Key variables:

### Connection to BCM

| Variable | Description |
|----------|-------------|
| `bcm_ssh_host` / `bcm_ssh_port` | BCM's SSH endpoint |
| `bcm_password` | Root SSH password |
| `bcm_ssh_proxy_jump` | `user@host` form for a jumphost (blank = direct). Applied via OpenSSH `ProxyCommand` to every SSH/SCP invocation |
| `bcm_ssh_proxy_key` | Path to the jumphost key (`~` expanded at render time) |
| `bcm_internal_ip` / `bcm_internal_cidr` | BCM's IP on the provisioning network (baked into the installer's HTTP URL and NFS exports) |
| `bcm_manage_dns` | **Default `false`** on remote BCM — don't rewrite the site's cluster DNS. Set `true` only when you own the whole BCM |
| `bcm_manage_cluster_defaults` | **Default `false`** — don't flip `defaultcategory` / `nodebasename` cluster-wide on a customer's BCM |

### Target compute node

| Variable | Description |
|----------|-------------|
| `bcm_target_node` | Existing cmsh device name to move into the `kairos` category (e.g. `edge-4c4c454400485610804bc3c04f4e4434`) |
| `bcm_source_category` | Existing BCM category to clone when creating `kairos` (carries over disksetup, mon templates, etc.) |
| `kairos_target_disk` | Disk device on the node to `dd` onto (e.g. `/dev/nvme0n1` or `/dev/sda`). Pinned — not auto-detected |
| `kairos_wipe_disks` | Space-separated list of sibling disks to `wipefs -a -f` before `dd` (cleans LVM/DRBD residue from previous installs) |

### Palette

| Variable | Description |
|----------|-------------|
| `palette_endpoint` | Palette API hostname (SaaS or on-prem) |
| `palette_project_name` / `palette_project_uid` | Project identity |
| `palette_api_key` | Admin API key with `edgeToken.create` + `edgehost.delete` permissions. Used by the on-node pre-registration hook |
| `palette_ca_cert` | PEM block for a private CA signing the Palette endpoint (optional) |
| `palette_installation_mode` | `connected` or `airgap` |
| `palette_management_mode` | `central` or `local` |
| `palette_token` | **Optional.** Pre-minted edge-host registration token. If omitted, the node mints one on first boot using `palette_api_key` |

See `inventory/group_vars/all.example.yml` for the complete list with inline commentary.

## Documentation

- `docs/POC_Client_Deployment.md` — client-facing POC deployment document (also rendered to `docs/POC_Client_Deployment.pdf`)
- `docs/pipeline-deep-dive.md` — engineer-level walkthrough of every stage, including the exact commands each role issues and why

## Key Design Points

### Additive, reversible changes to BCM

`deploy-dd` **never** flips cluster-wide BCM settings on a customer's head node. The `kairos` category is cloned from `bcm_source_category` (inheriting disksetup and mon templates); only the target device from `bcm_target_node` is moved into it. Existing categories, nodes, and cluster defaults are untouched. Move the device back to its original category and it reverts to standard HPC provisioning on next PXE boot.

### UEFI raw image + post-`dd` boot entry

The Kairos raw image is built under **OVMF firmware** (not SeaBIOS), producing a real EFI System Partition with `\EFI\BOOT\bootx64.efi`. `install-kairos.sh` runs `efibootmgr --create --disk $DISK --part 1 --label Kairos --loader '\EFI\BOOT\bootx64.efi'` after `dd` so UEFI firmware boots the freshly-written disk on next power-up — no manual OneTimeBoot dance required.

### Idempotent re-deploys

Palette won't re-register an edge host with a UID that's already on file. The image ships with `/usr/bin/palette-cleanup-stale.sh`, hooked via `systemd ExecStartPre` before `stylus-agent`:

1. Gates on registration mode (no-op if the node is already registered).
2. Queries Palette admin API with `palette_api_key`, deletes any stale record matching this node's SMBIOS-UUID-derived UID, freeing the UID.
3. Auto-mints a fresh `edgeHostToken` via `POST /v1/edgehosts/tokens` if one wasn't baked in.
4. Fail-open — never blocks stylus-agent startup.

This makes reimaging a previously-provisioned node a one-command operation (`make deploy-dd` + power-cycle).

### Category-scoped health-check suppression

BCM's `mounts`, `interfaces`, and `ntp` measurables flag Kairos's immutable-OS architecture as health failures (read-only root, no `/etc/fstab` in the expected form, no `ntp.conf`). `deploy-dd` installs `nodeexecutionfilters` with `Exclude + category=kairos` for those three measurables so the `kairos` category reports clean `[ UP ]` in cmsh without affecting any other category.

### Other details

- **lz4** compression (not gzip) — faster decompression than the dd write
- **`oflag=direct`** — bypasses page cache, prevents thin-pool overflow on LVM-backed disks
- **sysrq poweroff from RAM** — binaries staged to `/dev/shm/kinstall/` before `dd` overwrites the running rootfs
- **`sgdisk -e` + `partprobe`** — fixes the GPT backup header after `dd` onto a differently-sized disk, then re-reads the partition table
- **Squashfs patching** — `net.ifnames=0 biosdevname=0` + `ifcfg-eth0` injected into active/passive/recovery images for BCM compatibility
- **Jumphost-aware tooling** — `deploy-dd`, `validate`, and `discover` all build a per-run SSH config file with a `ProxyCommand` line when `bcm_ssh_proxy_jump` is set

## File Layout

```
kvm_bcm_plus_kairos/
├── Makefile
├── ansible.cfg
├── inventory/
│   ├── hosts.yml
│   └── group_vars/
│       ├── all.example.yml      # template — committed
│       └── all.yml              # your values — gitignored
├── playbooks/
│   ├── 01-bcm-prepare.yml  …  06-validate.yml
│   ├── discover-bcm.yml         # remote BCM discovery (supports jumphost)
│   ├── site.yml                 # full pipeline
│   ├── teardown.yml
│   └── install-dependencies.yml
├── roles/
│   ├── bcm_prepare/             # ISO download, patch, remaster (local-KVM)
│   ├── bcm_vm/                  # Two-phase KVM install + disk boot (local-KVM)
│   ├── kairos_build/            # CanvOS ISO + OVMF raw disk
│   ├── deploy_dd/               # Upload + configure BCM for PXE deploy
│   ├── kairos_vm/               # PXE boot compute VM (local-KVM)
│   ├── validate/                # 41-point health checks
│   └── dependencies/
├── files/canvos/                # CanvOS overlay
│   └── overlay/files/usr/bin/palette-cleanup-stale.sh   # pre-registration hook
├── docs/
│   ├── POC_Client_Deployment.md   # client-facing POC doc
│   ├── POC_Client_Deployment.pdf  # rendered via weasyprint
│   └── pipeline-deep-dive.md      # engineer walkthrough
├── build/   dist/   logs/       # generated artifacts — gitignored
└── CanvOS/                      # cloned at build time — gitignored
```

## Logs

```
logs/01-bcm-prepare.log
logs/02-bcm-vm.log
logs/03-kairos-build.log
logs/04-deploy-dd.log
logs/05-kairos-vm.log
logs/06-validate.log
logs/bcm-serial.log
logs/kairos-serial.log
logs/qemu-install.log
```

## Re-running Stages

Stages are idempotent:

- **bcm-prepare** — skips ISO download and remaster if artifacts exist
- **bcm-vm** — skips Phase 1 if disk exists, resumes from Phase 2
- **kairos-build** — skips ISO build and raw image generation if artifacts exist
- **deploy-dd** — always re-runs (reconfigures BCM; skips SCP if the remote image matches size); safe to re-run for every re-deploy
- **kairos-vm** — kills existing VM, resets node to FULL install mode, creates fresh disk
- **validate** — always re-runs

Force a full rebuild with `make clean && make all` (local-KVM) or `make clean && make kairos-build deploy-dd` (remote BCM).
