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
- `zstd`, `bsdtar`, `xxd`, `openssl` — only for the optional [self-hosted Palette appliance](#self-hosted-palette-optional-local-kvm)
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

`inventory/group_vars/all.yml` is gitignored. `inventory/group_vars/all.example.yml` is the committable **remote/customer-BCM** template and documents every variable.

## Quick Start — Local KVM (dev / demo)

```bash
# Minimal local-KVM config: most values default from inventory/hosts.yml,
# so you only fill jfrog_token + kairos_target_disk (+ optional Palette).
cp inventory/group_vars/all.local-kvm.example.yml inventory/group_vars/all.yml
$EDITOR inventory/group_vars/all.yml

make all   # runs the full 6-stage pipeline (~100-120 min)
```

To build/deploy/validate **specific Ubuntu versions** (e.g. 24.04 and 26.04) with
reproducible, committed extra-vars, use the per-OS profiles — full per-profile
instructions in [`profiles/README.md`](profiles/README.md):

```bash
make kairos-build ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"   # 24.04 → node001
make kairos-build ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"   # 26.04 → node002 (self-built base)
```

## Day-2 ops — container publish + Palette rolling upgrade

Once a Kairos cluster is bootstrapped (via the day-1 `kairos-build` + `deploy-dd`
+ `kairos-vm` flow above), ongoing upgrades — new k8s version, new kernel, new
apt packages, OS-stage tweaks — flow through Palette pulling a new container
image from `kairos_container_registry`. The same pipeline can build and publish
*just* the container image, skipping the OVMF QEMU install + raw disk
generation that day-1 PXE bootstrap needs.

### Step 1 — Publish provider images

```bash
make kairos-image
```

Wraps `ansible-playbook playbooks/03-kairos-build.yml -e kairos_build_raw_disk=false`,
which switches the `kairos_build` role from the day-1 path
(`./earthly.sh +iso`) to the day-2 path
(`./earthly.sh --push +build-provider-images --ARCH=<arch>`).

What happens during the run:

1. CanvOS's `+build-provider-images` target reads `CanvOS/k8s_version.json` —
   the role renders this from the `kairos_k8s_versions` inventory variable
   (empty dict = use upstream file unmodified).
2. For each `(distribution, version)` entry, Earthly invokes
   `+provider-image --K8S_VERSION=<version>`, which contains a
   `SAVE IMAGE --push <full image ref>`.
3. The `--push` CLI flag — passed by the role specifically for this day-2 path —
   tells Earthly to actually upload. Without it, `SAVE IMAGE --push` in the
   Earthfile is a no-op (image only goes to the local Docker daemon). Day-1's
   `+iso` target intentionally doesn't push because dd-install never pulls
   from a registry; only `make kairos-image` adds `--push`.

Tag format: `<registry>/<repo>:<distribution>-<version>-<PE_VERSION>-<CUSTOM_TAG>`,
e.g. `ttl.sh/ubuntu:k3s-1.31.6-v4.8.10-bcm-test`.
`PE_VERSION` is set in the CanvOS Earthfile (currently `v4.8.10`). `CUSTOM_TAG`
is from `.arg`.

For a **multi-version matrix push**, use bare version strings (CanvOS appends
the flavor tag itself):

```yaml
# inventory/group_vars/all.yml
kairos_k8s_versions:
  k3s:
    - "1.31.6"
    - "1.32.1"
  rke2:
    - "1.32.1"
```

Empty dict (default) leaves the file untouched, so the upstream CanvOS k8s
version list is used.

### Step 2 — Roll the cluster in Palette

In the Palette UI for the cluster's project:

1. **Profiles → \<cluster profile\> → Edit** the OS layer.
   - Pack: `edge-native-byoi` (the BYOOS pack — its only meaningful field).
   - Values:
     ```yaml
     options:
       system.uri: "<new image ref>"
     ```
2. **Save** — produces a new profile version (or updates the cluster's applied
   override values, depending on which path you take).
3. **Clusters → \<your cluster\>** — Palette detects the image drift and pushes
   a plan-job (`apply-control-plan-on-edge-<id>` in the `spectro-task-<cluster-uid>`
   namespace).
4. The plan-job pulls the new provider image, hands it to `kairos-agent`, which:
   - extracts the OS layer to `/usr/local/spectrocloud/content/provider_extract/`
   - rotates `cOS/active.img` (current → passive, new → active)
   - reboots the node
5. After reboot the node boots from the new active.img → k3s comes up on the
   new version → cluster goes back to `Running`. Kubernetes objects (deployments,
   etc.) are preserved — etcd is on `COS_PERSISTENT`, which is not touched by
   the OS layer rotation.

End-to-end time: ~5–10 min per node for the image pull + reboot.

BCM stays out of this path entirely. The pre-installed cmd integration on each
Kairos node keeps working through the upgrade because `/oem/*.yaml` lives on
`COS_OEM`, which is preserved across image rotations.

## Pipeline Stages

| Stage | Target | Duration | Description |
|-------|--------|----------|-------------|
| 1 | `make bcm-prepare` | ~2 min | Download BCM ISO from JFrog, patch rootfs, remaster for auto-install *(local-KVM only)* |
| 2 | `make bcm-vm` | ~60–90 min | Launch BCM in KVM, auto-install, boot from disk, wait for services *(local-KVM only)* |
| 3 | `make kairos-build` | ~30 min | Clone CanvOS, build Kairos ISO via Earthly, generate **UEFI** raw disk image under OVMF |
| 4 | `make deploy-dd` | ~3–5 min | SSH to BCM (direct or via jumphost), upload lz4 image, install `kairos-installer`, configure `kairos` category + nodeexecutionfilters |
| 5 | `make kairos-vm` | ~10 min | PXE boot compute VM, dd Kairos to disk, reboot into Kairos *(local-KVM only)* |
| 6 | `make validate` | ~15 sec | ~40-point validation across BCM and Kairos (works for remote BCM + remote compute node through jumphost) |

```
                   ┌──> bcm-prepare ──> bcm-vm ─┐            (local-KVM only)
Remote-BCM deploy ─┤                            ├─> deploy-dd ──> validate
                   └──> kairos-build ───────────┘              (kairos-vm only in local-KVM mode)
```

Stages **bcm-vm** and **kairos-build** can run in parallel.

Optionally, a **self-hosted Palette appliance** slots between stages 2 and 3 —
see [Self-hosted Palette](#self-hosted-palette-optional-local-kvm) below.

## Make Targets

```bash
# Pipeline
make bcm-prepare        # Stage 1 — local-KVM only
make bcm-vm             # Stage 2 — local-KVM only
make kairos-build       # Stage 3 — builds Kairos raw image via CanvOS + OVMF (day-1)
make kairos-image       # Stage 3 image-only — push container image only (day-2 upgrade)
make deploy-dd          # Stage 4 — push to BCM, configure PXE + kairos category
make kairos-vm          # Stage 5 — local-KVM only (PXE boots a local compute VM)
make validate           # Stage 6 — ~40-point health check
make all                # Stages 1–6 (local-KVM mode)

# Discovery
make discover           # Interactive: prompts for BCM IP/user/pass + optional jumphost,
                        # emits bcm-discovery-<hostname>.yml with suggested group_vars

# Self-hosted Palette appliance (optional; local-KVM only)
make palette-appliance  # Build appliance ISO + install VM + deploy cluster + create tenant
make palette-iso        # ISO only            (--tags build)
make palette-vm         # Install + boot only (--tags vm)
make palette-cluster    # Content + cluster   (--tags cluster)
make palette-tenant     # First tenant only   (--tags tenant)
make palette-stop       # Stop the appliance VM
make palette-serial     # Tail the appliance serial log

# VM management (local-KVM mode)
make bcm-stop           # Stop BCM VM
make kairos-stop        # Stop Kairos compute VM
make stop               # Stop all VMs
make bcm-serial         # Tail BCM serial log
make kairos-serial      # Tail Kairos serial log

# Cleanup
make clean              # Stop VMs, then remove build/, logs/
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
| `bcm_manage_cluster_defaults` | **Default `false`** — don't make cluster-wide changes on a customer's BCM: flip `defaultcategory` / `nodebasename`, **or** rewrite `/etc/dhcpd.conf` (make dhcpd authoritative + set the pool range). Local-KVM sets this `true` (it owns its BCM). |

### Target compute node

| Variable | Description |
|----------|-------------|
| `bcm_target_node` | Existing cmsh device name to move into the profile's category (e.g. `edge-4c4c454400485610804bc3c04f4e4434`) |
| `bcm_source_category` | Existing BCM category to clone when creating the profile category (carries over disksetup, mon templates, etc.) |
| `kairos_target_disk` | Disk device on the node to `dd` onto (e.g. `/dev/nvme0n1` or `/dev/sda`). Pinned — not auto-detected |
| `kairos_wipe_disks` | Space-separated list of sibling disks to `wipefs -a -f` before `dd` (cleans LVM/DRBD residue from previous installs) |
| `kairos_target_mac` | **Optional.** Provisioning-NIC MAC; when set, deploy-dd does `set mac` on `bcm_target_node` so the deploy owns the MAC mapping rather than relying on prior cmsh registration |
| `kairos_target_ip` | **Optional.** IP for the device on `bcm_internal_cidr`; when set, deploy-dd does `set ip` on `bcm_target_node`. Must be outside the DHCP pool (`.16`–`.250`) |

### Kairos profile + build customization

| Variable | Description |
|----------|-------------|
| `kairos_profile` | **Default `default-kairos`.** Namespaces the local artifact (`build/<profile>-disk.raw`), the BCM upload (`/cm/shared/kairos/<profile>/disk.raw.lz4`), the `<profile>-installer` software image, the `<profile>` cmsh category, and the `exclude-<profile>` health-check filter. Multiple profiles coexist on the same BCM |
| `kairos_canvos_args` | **Open-ended dict** merged over `roles/kairos_build/defaults/main.yml`. Override any subset of CanvOS `.arg` keys (e.g. `OS_VERSION`, `UPDATE_KERNEL`, `CIS_HARDENING`, `UBUNTU_PRO_KEY`, `IMAGE_REGISTRY`, `CUSTOM_TAG`); arbitrary new keys flow through to `.arg` verbatim |
| `kairos_extra_apt_packages` | **Open-ended list.** Extra apt packages installed in the Kairos image via a Dockerfile RUN block. Empty list = no extra packages |
| `kairos_user_data` | **Open-ended raw YAML block.** Written to `/oem/99_userdata.yaml` inside the built image, layered on top of `/oem/90_custom.yaml` (which carries BCM/Palette integration). Empty string = no extra userdata file |

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

## Self-hosted Palette appliance (optional, local-KVM)

`make palette-appliance` builds a **Palette management appliance** image and has **BCM
provision it** onto a managed node — the same PXE + `dd` path BCM uses for Kairos edge nodes.
The rig then has its own Palette, so edge nodes register against it instead of SaaS. The
local-KVM defaults otherwise ship `palette_*` placeholders.

The appliance is a **build profile**, not a parallel pipeline:

```
make palette-build    # stage 3: build/palette-appliance-disk.raw
make palette-deploy   # stage 4: BCM software image + category + PXE + node registration
make palette-node     # stage 5: PXE boot; BCM dd's the image onto the node
make palette-appliance  # all of the above, then the mgmt cluster + first tenant
```

Each stage can also be run directly with `-e @profiles/palette-appliance.yml`. BCM must
already be up (stages 1–2) — it is what provisions the node.

`roles/deploy_dd` needed **no changes**: it was already generic over `kairos_profile`.

### What makes an appliance build differ from an edge build

Five profile settings, each required:

| Setting | Why |
|---|---|
| `kairos_cloud_config_template` | swaps the image's cloud-config wholesale — `kairos_user_data` only layers on top |
| `kairos_build_self_install` | the appliance image boots its own installer; an injected `kairos-agent install` races the labels it writes and fails `device or resource busy` |
| `deploy_dd_finalize_install` | dd from the node-installer NFS root, else the post-`dd` GPT fix / grow / `efibootmgr` all silently fail and the disk is unbootable |
| `kairos_edge_custom_config` | bakes in the content-signing public key, else the bundle upload fails `public key to verify content not found` |
| `kairos_vm_probe_user` / `_password` | the post-boot probe defaults to the edge image's `kairos` account, which an appliance does not have |

### Addressing

`deploy_dd` **derives** the local-KVM node address as `bcm_internal_ip` prefix + `(9 + node
number)` — node002 is always `192.168.98.11` — and ignores `kairos_target_ip` there (that is
remote-BCM only). The VIP must avoid BCM's DHCP pool (`.16`–`.250`), `bcm_internal_ip`, and
that derived address; `.251` clears all three, and `palette_cluster` asserts it.

Everything reaches the appliance **through BCM** (`delegate_to: bcm`), including the ~10 GB
bundle, which is staged under `/cm/shared/kairos/<profile>/` and removed afterwards.

Credentials are **sticky** (`inventory > .run-credentials.yml > generated`): the image carries
a *hash* of the Local UI password, so a regenerated one strands the appliance.

Full detail, including the failure signatures for each of the five settings, is in
[`docs/stage-palette-appliance.md`](docs/stage-palette-appliance.md).

## Documentation

- `docs/POC_Client_Deployment.md` — client-facing POC deployment document (also rendered to `docs/POC_Client_Deployment.pdf`)
- `docs/pipeline-deep-dive.md` — engineer-level walkthrough of every stage, including the exact commands each role issues and why
- `docs/stage-palette-appliance.md` — the optional self-hosted Palette appliance (networking, ordering, troubleshooting)

## Key Design Points

### Additive, reversible changes to BCM

`deploy-dd` **never** flips cluster-wide BCM settings on a customer's head node. The profile's category (default `default-kairos`) is cloned from `bcm_source_category` (inheriting disksetup and mon templates); only the target device from `bcm_target_node` is moved into it. Existing categories, nodes, and cluster defaults are untouched. Move the device back to its original category and it reverts to standard HPC provisioning on next PXE boot.

### Multiple profiles on one BCM

Build artifact + BCM-side state are namespaced by `kairos_profile`. To stand up a second profile:

```bash
# Build profile A
make kairos-build deploy-dd                                    # uses default-kairos

# Build profile B
ANSIBLE_ARGS="-e kairos_profile=gpu-kairos -e 'kairos_canvos_args={\"OS_VERSION\":\"22.04\",\"UPDATE_KERNEL\":\"true\"}'" \
    make kairos-build deploy-dd
```

Both `default-kairos` and `gpu-kairos` categories, software images, image directories, and `/cm/shared/kairos/<profile>/` upload trees coexist on BCM. Each device is assigned to one profile (its `category` in cmsh).

### UEFI raw image + post-`dd` boot entry

The Kairos raw image is built under **OVMF firmware** (not SeaBIOS), producing a real EFI System Partition with `\EFI\BOOT\bootx64.efi`. `run-dd.sh` (the dd-installer program `install-kairos.sh` stages into RAM and execs — see `roles/deploy_dd/files/run-dd.sh`) runs `efibootmgr --create --disk $DISK --part 1 --label Kairos --loader '\EFI\BOOT\bootx64.efi'` after `dd` so UEFI firmware boots the freshly-written disk on next power-up — no manual OneTimeBoot dance required.

### Idempotent re-deploys

Palette won't re-register an edge host with a UID that's already on file. The image ships with `/usr/bin/palette-cleanup-stale.sh`, hooked via `systemd ExecStartPre` before `stylus-agent`:

1. Gates on registration mode (no-op if the node is already registered).
2. Queries Palette admin API with `palette_api_key`, deletes any stale record matching this node's SMBIOS-UUID-derived UID, freeing the UID.
3. Auto-mints a fresh `edgeHostToken` via `POST /v1/edgehosts/tokens` if one wasn't baked in.
4. Fail-open — never blocks stylus-agent startup.

This makes reimaging a previously-provisioned node a one-command operation (`make deploy-dd` + power-cycle).

### Category-scoped health-check suppression

BCM's `mounts`, `interfaces`, and `ntp` measurables flag Kairos's immutable-OS architecture as health failures (read-only root, no `/etc/fstab` in the expected form, no `ntp.conf`). `deploy-dd` installs `nodeexecutionfilters` with `Exclude + category=kairos` for those three measurables so the `kairos` category reports clean `[ UP ]` in cmsh without affecting any other category.

### NFS exports auto-scoped to the target node's network

`deploy-dd` queries cmsh for `bcm_target_node`'s BOOTIF interface network and adds NFS export ACLs for that CIDR — in addition to `bcm_internal_cidr`. Required when target devices live on a separate provisioning VLAN (e.g. tenant-net) reached via DHCP relay; the cloud-config's `mount -t nfs /cm/images/default-image` would otherwise be rejected by the kernel NFS server. Existing managementnet ACLs are left intact.

### Last-partition auto-grow after `dd`

Right after `sgdisk -e` fixes the GPT backup header, `run-dd.sh` deletes and recreates the **last** GPT partition (typically `COS_PERSISTENT`) from its current start sector to the disk end, then `partprobe` + `partx -u` + `e2fsck -fy` + `resize2fs`. Without this, a Kairos image dd'd from an 80 GB build VM onto a 400+ GB physical disk leaves `COS_PERSISTENT` capped at the original 30 GB (Kairos's own `Grow persistent` boot stage has a math bug that silently skips the grow on disks much larger than the source image).

### Dynamic Palette label push

`metadata.name` on Palette edge hosts is locked to the SMBIOS-UUID-derived `edge-<uuid>` (Palette uses it to track the box across re-deploys). For a friendly hostname, the cloud-config's BCM-integration boot stage queries cmsh for the device's BCM-side name + category + service tag and `PUT`s them as `metadata.labels` on the edge-host record via the Palette admin API. Runs in the background after stylus has registered, polling for the edge-host to exist before the PUT. No build-time bake-in of node-specific values — same image deploys to many hosts, each registers in Palette with its own labels.

### Other details

- **lz4** compression (not gzip) — faster decompression than the dd write
- **`oflag=direct`** — bypasses page cache, prevents thin-pool overflow on LVM-backed disks
- **sysrq poweroff from RAM** — binaries staged to `/dev/shm/kinstall/` before `dd` overwrites the running rootfs
- **`sgdisk -e` + `partprobe`** — fixes the GPT backup header after `dd` onto a differently-sized disk, then re-reads the partition table
- **Squashfs patching** — `net.ifnames=0 biosdevname=0` + `ifcfg-eth0` injected into active/passive/recovery images for BCM compatibility
- **Jumphost-aware tooling** — `deploy-dd`, `validate`, and `discover` all build a per-run SSH config file with a `ProxyCommand` line when `bcm_ssh_proxy_jump` is set
- **Validate IP-lookup hardening** — `validate.sh` falls back to `cmsh device interfaces use BOOTIF get ip` when the device-level IP is `0.0.0.0` (common when the BOOTIF lives on a different network than the device's `Network` field), and refuses to probe if the lookup resolves to `0.0.0.0`, `127.0.0.1`, or BCM's own IP (which OpenSSH would otherwise treat as localhost, silently probing BCM and reporting BCM's state as the "Kairos" half of the report)

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
│   ├── palette-appliance.yml    # optional self-hosted Palette (unnumbered)
│   ├── site.yml                 # full pipeline
│   ├── teardown.yml
│   └── install-dependencies.yml
├── roles/
│   ├── bcm_prepare/             # ISO download, patch, remaster (local-KVM)
│   ├── bcm_vm/                  # Two-phase KVM install + disk boot (local-KVM)
│   ├── kairos_build/            # CanvOS ISO + OVMF raw disk
│   ├── deploy_dd/               # Upload + configure BCM for PXE deploy
│   ├── kairos_vm/               # PXE boot compute VM (local-KVM)
│   ├── validate/                # ~40-point health checks
│   ├── dependencies/
│   ├── appliance_iso/           # Palette appliance ISO (CanvOS, separate checkout)
│   ├── appliance_vm/            # Palette appliance QEMU VM (raw QEMU, socket net)
│   ├── palette_cluster/         # content bundle + management cluster
│   └── palette_tenant/          # first tenant
├── files/canvos/                # CanvOS overlay
│   └── overlay/files/usr/bin/palette-cleanup-stale.sh   # pre-registration hook
├── artifacts/                   # licensed Spectro downloads for the appliance — gitignored
├── docs/
│   ├── POC_Client_Deployment.md   # client-facing POC doc
│   ├── POC_Client_Deployment.pdf  # rendered via weasyprint
│   └── pipeline-deep-dive.md      # engineer walkthrough
├── build/   dist/   logs/       # generated artifacts — gitignored
├── CanvOS/                      # cloned at build time (Kairos edge image) — gitignored
└── CanvOS-appliance/            # cloned at build time (Palette appliance) — gitignored
```

## Logs

Each stage run writes to a **timestamped per-run directory** so reruns never
clobber a prior run's evidence, with `logs/latest` pointing at the newest:

```
logs/run-<YYYYmmdd-HHMMSS>/
  <stage>.console.log      # full console output (tee'd)
  <stage>.ansible.log      # structured per-task log incl. delegated hosts +
                           #   a slowest-tasks timing summary (profile_tasks)
logs/latest -> run-<...>/   # symlink to the most recent run
```

The flat per-stage paths are still written too (back-compat with `make *-serial`
and older docs):

```
logs/01-bcm-prepare.log   logs/04-deploy-dd.log   logs/bcm-serial.log
logs/02-bcm-vm.log         logs/05-kairos-vm.log    logs/kairos-serial.log
logs/03-kairos-build.log   logs/06-validate.log     logs/qemu-install.log
```

Bump verbosity for any stage with `V`, e.g. `make deploy-dd V=-vv` (or
`V=-vvvv` for connection-level ssh detail).

**Pull on-target logs for troubleshooting** — `make collect-logs` fetches the
logs that actually explain failures off the BCM and the Kairos node (which you
otherwise can't reach without a live SSH session, especially via a jumphost)
into `logs/collected/`:

```
logs/collected/bcm/      cmd.log · dhcpd.log · named.log · nfs-exports.txt · cmsh-devices.txt
logs/collected/kairos/   stylus-agent.log · kairos-agent.log · cmdline.txt ·
                         kairos-release.txt · oem-listing.txt · dmesg-tail.txt
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

## Changelog

Milestones and notable changes, newest first. Each entry links its JIRA ticket
(project `IN`) and PR. New milestones append here as part of the same PR.

### 2026-09-23

- **Fix: the appliance shipped a stylus hook whose scripts it does not carry** (IN-TBD · #TBD) —
  the overlay's `bcm-sync.conf` adds `ExecStartPre=/usr/bin/palette-cleanup-stale.sh` (and
  `bcm-sync-userdata.sh`) to `stylus-agent`. Those arrive only via the Dockerfile `COPY`, and an
  appliance build installs a **different rootfs** than the one CanvOS customises — the ISO's
  `rootfs.squashfs` has all three scripts, the deployed system (`KAIROS_VARIANT="core"`) has
  none. systemd then failed the unit `203/EXEC` and restarted it forever (675 attempts when
  this was found), so stylus never ran and Palette never deployed. Nothing pointed at it: the
  node booted clean, the Local UI answered 200, the 11 GB bundle uploaded, `spc.tgz` landed,
  and the cluster simply sat at `Provisioning`. Clearing `ExecStartPre` on the box brought
  stylus `active` instantly, which then created kube-vip and the VIP came up. The hook is now
  gated behind `kairos_build_bcm_integration` (default true; false for the appliance, which is
  not a BCM-registered edge node and needs neither hostname sync nor Palette pre-registration
  cleanup).
- **Fix: the cluster→tenant hand-off green-lit on the static UI** (same ticket) — the VIP
  readiness probe was `GET <vip>/system` expecting 200, which the static frontend answers the
  moment ingress is up: roughly **half an hour** before Palette's API exists. The tenant role
  therefore started against a server that answers `405` to every POST, and its 10×15 s budget
  expired long before the API appeared — surfacing as a censored `no_log` timeout that said
  nothing about the cause. `palette_cluster` now also waits for the API itself, using POST as
  the discriminator (static handler → `405`; real API → `401/403` to a credential-less login),
  bounded by `appliance_api_timeout`. Verified both ways against a live appliance. The tenant
  login keeps its `no_log` but gets a larger budget, since readiness is now proven upstream.
- **Licensed Palette artifacts move through JFrog** (IN-TBD · #TBD) — the ~10 GB content
  bundle, its detached signature and the content-signing key are mirrored to JFrog and fetched
  the same way stage 1 fetches the BCM ISO, instead of someone hand-copying them onto each rig.
  `make palette-artifacts-push` publishes (deliberately explicit — it pushes licensed Spectro
  Cloud content to a shared repo, which no ordinary build should do as a side effect);
  `make palette-artifacts-pull` fetches, and an appliance build pulls automatically for whatever
  `artifacts/` is missing, so a fresh rig runs `make palette-appliance` and proceeds. Same
  credential and instance as the BCM ISO (`jfrog_token`), different repo (`palette-content`) —
  a content bundle is not an ISO release. The JFrog path and the local filename are deliberately
  identical, which is what lets the existing extension-based discovery find a pulled file with
  no further configuration. The credential goes in a `0600` curl config read with `-K`, removed
  in an `always:`, for the same `/proc` reason as `bcm_prepare`.
- **Fix: a cloud-config stage key with no entries crashed the installer** (same ticket) —
  `cloud-config.yaml.j2` always emitted `stages.initramfs:`, but only ever wrote into it when
  `palette_api_key` *and* `palette_project_uid` were both set. An empty mapping key is YAML
  null, and kairos-sdk's collector dereferences it — `kairos-agent` segfaults in `DeepMerge`
  (`collector.go:201`) before the install begins, three retries deep. The visible symptom is
  90 seconds later and points somewhere else entirely: a blank disk and
  `no EFI System Partition (vfat) found` from the verify step. `projectUid:` had the same shape
  (`is defined` is true for an empty string). Both keys are now emitted only when populated,
  and `check-cloud-config.py` fails the build at **render** time, naming the offending key —
  where it still has a name and a line number.
- **`kairos_vm`: several disks, any bus, optional boot disk** (same ticket) — `kairos_vm_disks`
  replaces the single `kairos_vm_data_disk_size` with a list of `{size, bus}`, where `bus: nvme`
  attaches an emulated NVMe controller rather than virtio. `kairos_vm_disk_size: ""` omits the
  boot disk entirely. Together these let a local-KVM VM stand in for a DGX, where **every**
  drive is NVMe and the OS mirror *is* the boot target — a separate boot disk would also break
  array selection, since finalize takes the smallest N drives as the mirror.
  `profiles/dgx-raid-kvm.yml` is that emulation: four NVMe namespaces (2 × 24 G mirror,
  2 × 48 G stripe), no boot disk, exercising the RAID path from `profiles/dgx-raid.yml`
  against something other than real DGX hardware.
- **`kairos_raw_disk_size` + a pre-`dd` capacity check** (same ticket) — the raw image size was
  hardcoded at 80 GiB, and stage 4 `dd`s it onto the target byte for byte. On a RAID profile
  the target is the **array**, which is easy to undersize: members look roomy individually
  while a mirror is one member wide. `kairos-finalize.sh` now compares the two before writing
  and fails naming both numbers, rather than hitting `No space left on device` minutes in with
  a half-written GPT. The size is a profile knob (default unchanged), so a test rig can build a
  small image instead of dd'ing 56 GiB of empty `COS_PERSISTENT` twice into a mirror.
  `profiles/dgx-raid-kvm.yml` also grew its members 24G → 96G, against **three** floors that
  each fail somewhere other than the profile that set the size: a mirror member must first
  hold **BCM's own installer environment** (disksetup is 100M ESP + 16G swap + the ~9.4G
  software image — under ~28G the run dies mid-provision with *"An error occurred while
  provisioning. Ran out of disk space!"*, pointing at BCM); the **array** must hold the whole
  image; and the image itself cannot go much below ~56 GiB, because the edge layout asks for
  OEM 5120 + recovery 20200 + state 25576 MiB before `COS_PERSISTENT` gets anything, and
  kairos-agent refuses with *"the requested partitions size (50960MiB) does not fit in the
  target disk"*. All three are documented where the sizes are set.
- **Fix: the compute VM's NIC name moved when the disk layout changed** (same ticket) — QEMU
  hands out PCI slots to `-device` entries in command-line order, and the launcher wrote the
  disks first. Four `-device nvme` namespaces therefore pushed the NIC from `enp0s2` to
  `enp0s6`, while `roles/deploy_dd` registers the node against a fixed provisioning interface
  name. PXE succeeded and the node-installer then refused the node: *"booted using an interface
  (enp0s6) which is not defined in the node object"* — which reads as a BCM misconfiguration,
  three layers from the cause. The NIC is now declared before any disk, so it takes the first
  free slot whatever the layout is. (`-drive ... if=virtio` disks never disturbed it, which is
  why this only appeared with the NVMe profile.) Stage 5 also polls BCM's device status during
  the dd wait and fails on `INSTALLER_FAILED` with BCM's own reason, instead of treating "the
  VM is still up" as progress for the full 30-minute timeout.
- **`deploy_dd` checks `bcm_target_node` actually exists** (same ticket) — the cmsh assign
  carries `failed_when: false` (cmsh reports benign conditions on stderr), so a device name
  that is not on this BCM passed silently and the run went on to PXE a node it had never put
  in the category.
- **Fix: two compute VMs cannot share the provisioning link** (same ticket) — the local-KVM
  provisioning "network" is a QEMU socket netdev (BCM `listen=`, each node `connect=`), which
  is point-to-point: it carries **one** compute VM at a time. Starting a second while another
  is attached gives it no carrier at all, and it dies twenty minutes later with
  `PXE-E18: Server response timeout` — which reads like broken DHCP/TFTP on BCM. Nothing in
  the role said so; its comments assumed concurrent nodes worked ("so a second concurrent node
  gets a non-colliding set"). Stage 5 now refuses to start, naming the VM that holds the link
  and the `make kairos-stop NODE=<it>` to free it. `make kairos-stop` gained that `NODE=`
  argument so one node can be stopped without killing the rest, and the port is now
  `bcm_internal_socket_port` rather than three separate literals.
  **Note for anyone debugging this by hand:** an unprivileged `ss -ltn` does not show a
  root-owned listening socket, so BCM looks like it has stopped listening when it has not —
  check as root. Separately, a freshly booted node takes roughly two minutes to answer on the
  network; `No route to host` before then is normal, not a failed deploy.
- **`make palette-console`** (same ticket) — the appliance sits on the provisioning network and
  the build host has no interface on it, so `https://<vip>/` from a desktop browser reaches
  nothing even when the appliance is perfectly healthy and `ansible bcm -m uri` gets a 200.
  That is indistinguishable from a failed deploy, and the workaround was a hand-rolled `ssh -L`.
  The target tunnels the VIP and the node's Local UI through BCM, which *is* on that network,
  asking BCM for the node's current IP rather than trusting a var. Read-only; Ctrl-C closes it.
- **Fix: `deploy_dd` wrote into a software image that was still being cloned** (same ticket) —
  `cmsh`'s clone returns long before the copy does, and the readiness gate only stat'd the
  image's `/usr`, which appears a second or two into a clone that takes minutes. The next task
  then failed with `Destination directory /cm/images/<profile>-installer/usr/local/bin does not
  exist`. A race, so it passed on a re-run and on any profile whose image already existed —
  which is how it survived this long, and why it first appeared on a brand-new profile. The
  gate now waits for the image size to stop moving, which is true of a finished clone and of a
  pre-existing image alike.
- **`deploy_dd` stops checksumming 80 GB to compare two timestamps** (same ticket) — the stat
  that decides whether the lz4 archive is stale read only `.exists` and `.mtime`, but the
  module checksums by default, so every stage-4 run began with a SHA-1 pass over the raw image
  and its archive.
- **`palette_cluster`: the appliance password stops riding in argv** (same ticket) — the
  `spc.tgz` placement passed it to `sshpass -p`, so it was readable via `/proc` and the task
  needed `no_log: true` — which is what made its one real failure unreadable (a censored
  `FAILED!` and nothing else). It now goes in a `0600` file on BCM consumed with `sshpass -f`
  and removed in an `always:`, and the task logs normally.

### 2026-09-22

- **Self-hosted Palette appliance, provisioned BY BCM** (IN-TBD · #TBD) — brings
  [palette-appliance-automation](https://github.com/blik616287/palette-appliance-automation)
  (`8f29a40`) in as `make palette-appliance`. The appliance is a **build profile**
  (`profiles/palette-appliance.yml`) flowing through the ordinary stage 3 → 4 → 5 pipeline, so
  BCM provisions it over PXE + `dd` exactly as it provisions Kairos edge nodes.
  `roles/deploy_dd` needed **no changes** — it was already generic over `kairos_profile`.
  Upstream drove libvirt; nothing libvirt-shaped survives, and no libvirt dependency is added.
  Validated end to end on the local-KVM rig: image built and verified bootable, BCM deployed it
  to node002, the node booted Kairos, and the appliance Local UI answered with the seeded
  admin account.
- **`kairos_build` gains four profile hooks** (same ticket), each with defaults that leave
  every existing edge profile byte-identical: `kairos_cloud_config_template` (swap the image's
  cloud-config wholesale — `kairos_user_data` only layers on top, so it cannot express a
  non-edge image); `kairos_build_self_install` (let an image that boots its own installer
  install itself, instead of injecting `kairos-agent install` — a stylus image mounts
  `COS_PERSISTENT` the instant those labels appear, so the injected installer loses a race
  against the labels it just wrote and fails `device or resource busy` on every retry);
  `kairos_dockerfile_extra` (raw Dockerfile instructions `kairos_extra_apt_packages` cannot
  express, e.g. the DRBD kernel-headers `COPY`); and `kairos_edge_custom_config` (bake the
  content-signing public key in, else the appliance rejects the bundle with
  `public key to verify content not found`).
- **`kairos_vm`: optional data disk + profile-overridable boot probe** (same ticket) —
  `kairos_vm_data_disk_size` gives a node a second disk (the appliance keeps its
  Piraeus/LINSTOR storage pool there, and that disk is wiped at deploy). The post-boot probe
  no longer hardcodes the edge image's `kairos`/`kairos` account, which an appliance image does
  not have; it would otherwise burn its whole 10-minute timeout while the appliance sat there
  serving.
- **Fix Dockerfile-block leakage between profiles** (same ticket) — `kairos_extra_apt_packages`
  guarded its `blockinfile` with `when:`, so the block stayed in the **shared** CanvOS checkout
  when the next profile set none. Live as soon as the appliance became the first profile to use
  it: building the appliance then an edge profile would have shipped `lvm2`/`drbd-utils` in the
  edge image. Both that block and the new one now use `state: present/absent`.
- **`kairos_build`: deactivate LVM before the install teardown** (same ticket) — an image that
  ships `lvm2` starts LVM2 monitoring in the live installer environment, which holds the target
  disk; `kairos-agent`'s own `blkdeactivate` then fails `device or resource busy`. Guarded on
  the binaries existing, so images without `lvm2` are unaffected.
- **`bcm_prepare`: keep the JFrog token out of `ps`** (same ticket) — the ISO download passed
  the credential in `curl`'s argv, and process arguments are world-readable via `/proc`, so any
  local user could read it off `ps` for the whole multi-GB download. It now goes in a `0600`
  curl config consumed with `-K`, removed in an `always:` block.
- **Defects found by running it** (same ticket), none visible to review: `make setup` checked
  the invoking user's PATH while the tasks run under `become: true`, so a conda-shadowed
  `bsdtar` reported green while root had none; `zstd` silently refuses a **symlinked** bundle
  and exits 0 having written nothing, surfacing as `tarfile.ReadError: empty file`
  (`extract_spc.py` now resolves with `realpath`); an unanchored `pkill` could match the shell
  running it; and `appliance_pe_version` is the **stylus agent** version, not the bundle
  filename — a `…-4.10.17.tar.zst` bundle ships stylus `v4.10.4`.

### 2026-07-05

- **Opt-in software-RAID: OS mirror + striped data** ([IN-2346](https://insightsoftmax.atlassian.net/browse/IN-2346) · [#50](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/50); [IN-2347](https://insightsoftmax.atlassian.net/browse/IN-2347) · [#51](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/51)) — two gated flags let a profile put the Kairos OS on a **RAID1 mirror** and data on any-level arrays, driven entirely by profile vars (default off = single-disk, byte-identical). Stage 3 `kairos_build_mdraid` builds a RAID-capable image (`mdadm` + the dracut `mdraid` module + `rd.auto=1`) so the raw image can be `dd`'d onto `/dev/md0` and still boot. Stage 4 `kairos_os_raid`/`kairos_data_raid` has the finalize script create the OS mirror with `--metadata=1.0` (superblock at the *end* so UEFI can read the mirrored ESP off a single member — a `dd`-to-RAID otherwise has no bootable ESP), `dd` onto it, write a per-member `efibootmgr` entry, then create each data array (mkfs + stable LABEL) and inject a systemd `.mount` unit into the cOS root images so it auto-mounts read-write, fail-open (a dead member never blocks boot). `finalize.yml` asserts the OS array is RAID1 — only a mirror gives each member a complete bootable ESP; RAID0/5/6/10 for the *root* can't boot, so those go in `kairos_data_raid`. Validated end-to-end in local-KVM on a real 5-disk UEFI boot (OS running on the mirror + `/raid` data stripe mounted rw). `profiles/dgx-raid.yml` is the worked DGX A100 example (2-drive OS mirror + 8-drive `/raid` stripe); schema docs in `profiles/README.md`.

### 2026-06-30

- **Local-KVM keeps managing its own DHCP** ([IN-2324](https://insightsoftmax.atlassian.net/browse/IN-2324) · [#45](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/45)) — IN-2322 gated deploy-dd's DHCP-pool tasks behind `bcm_manage_cluster_defaults` (default `false`, for customer-BCM safety), but the minimal `all.local-kvm.example.yml` never set it, so `make all` would now *skip* them. Local-KVM stands up its own dedicated BCM, so the example now sets `bcm_manage_cluster_defaults: true`; the global default stays `false` so remote/customer deploys remain fail-safe.
- **Opt-in finalize-stage dd install** ([IN-2323](https://insightsoftmax.atlassian.net/browse/IN-2323) · [#44](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/44)) — new `deploy_dd_finalize_install` (default `false`) runs the Kairos dd as the BCM node-installer's category **finalize** script instead of the stage-2 `kairos-install` unit in the booted installer image. On a real BCM the stage-2 dd overwrites its own *running* rootfs, so the post-dd GPT fix / COS_PERSISTENT grow / efibootmgr silently fail ("timeout: not found", "couldn't detect last partition") and the console floods with XFS errors. The finalize stage runs from the node-installer NFS root (never the disk being overwritten): the grow fills the disk, the tooling runs, the console stays clean, and the script forces a reboot so firmware boots the freshly-written Kairos (BCM would otherwise `switch_root` into the overwritten disk → emergency shell). Adds `kairos-finalize.sh.j2` (dd + grow + efibootmgr + `dd status=progress` + quieted console) and `finalize.yml` (stages `lz4` into `/cm/node-installer`, sets `finalizescript` + `installbootrecord=no`). Validated live on a Proxmox VM (Kairos v4.0.4, COS_PERSISTENT grown to 150 G). Requires the node's firmware boot order to be disk-first with PXE fallback.
- **Harden deploy_dd for remote multi-subnet/UEFI BCM** ([IN-2322](https://insightsoftmax.atlassian.net/browse/IN-2322) · [#43](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/43)) — five fixes surfaced deploying Kairos to a Proxmox VM through a live customer-style BCM over an SSH broker. `add_bcm_host` gains optional key-auth as a non-root sudoer (`bcm_ssh_user`/`bcm_ssh_private_key`; global `become` sudo's to root) plus a 60 s `ConnectTimeout` + `ServerAlive` keepalives for a slow ProxyJump. `nfs.yml` gates the cluster-wide `/etc/dhcpd.conf` pool rewrite behind `bcm_manage_cluster_defaults` (its global `range .*` replace clobbered every subnet's range with an invalid `.250` and took dhcpd down cluster-wide) and rejects cmsh error text from the BOOTIF-network CIDR detection so it can no longer corrupt `/etc/exports`. `installer_image.yml`'s `exportfs -ra` now only fails on genuine errors, tolerating the benign `requires fsid=` / `duplicated` warnings a real BCM emits for re-exported NFS. `run-dd.sh` gains `dd status=progress`, a quieted kernel console, and a RAM-pinned ELF loader.

### 2026-06-27

- **Fix lz4 install on a fresh BCM** ([IN-2306](https://insightsoftmax.atlassian.net/browse/IN-2306) · [#40](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/40)) — deploy-dd's `apt: lz4` used `cache_valid_time: 3600`, which skipped the apt-update on a freshly-installed BCM (recent-but-incomplete cache) → "No package matching lz4". Dropped it so `update_cache` always refreshes (matching the original's unconditional `apt-get update`). Found by a from-scratch clean E2E.
- **Fix `kairos_build` verify under dash** ([IN-2305](https://insightsoftmax.atlassian.net/browse/IN-2305) · [#39](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/39)) — the install-verify task (IN-2303) used a bash array but `shell:` defaults to `/bin/sh` (dash), which can't parse `errs=()`; added `executable: /bin/bash`. Validated by running the fixed block against the real built disk.
- **`make clean` stops VMs first** ([IN-2304](https://insightsoftmax.atlassian.net/browse/IN-2304) · [#38](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/38)) — `clean` deleted `build/` (the pid files) before stopping the VMs, orphaning any running VM; and `stop`/`bcm-stop`/`kairos-stop` used a bare user `kill` that can't reap the root-owned (Ansible-`become`) qemu. `clean` now runs `stop` first, and `stop` uses `sudo kill` + an anchored `sudo pkill`.
- **`kairos_build`: array for the install-verify errors** ([IN-2303](https://insightsoftmax.atlassian.net/browse/IN-2303) · [#37](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/37)) — the read-only "bootable disk" verify block now collects failures in a bash array instead of string concatenation. (The delicate image-mutating blocks are intentionally left as-is.)
- **`bcm_prepare`: extract `render-config.py`** ([IN-2302](https://insightsoftmax.atlassian.net/browse/IN-2302) · [#36](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/36)) — the 44-line python heredoc in `bcm-autoinstall.sh.j2` that renders `build-config.xml` is now a real bandit-clean `files/render-config.py` (reads inputs from env). Verified byte-identical output to the heredoc.
- **Extract `run-dd.sh` from the install-kairos heredoc** ([IN-2301](https://insightsoftmax.atlassian.net/browse/IN-2301) · [#35](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/35)) — the 168-line dd-installer program (quiesce → dd → grow → efibootmgr → poweroff) was a `\$`-escaped heredoc inside `install-kairos.sh.j2` (221 lines); now a real shellcheck-clean `files/run-dd.sh` (install-kairos drops to 58 lines). Verified byte-faithful + validated end-to-end (fresh PXE install booted Kairos, 0 FAIL).
- **`bcm_vm`: shared QEMU launcher** ([IN-2300](https://insightsoftmax.atlassian.net/browse/IN-2300) · [#34](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/34)) — deduped the two ~24-line `qemu-system` blocks (install + boot) into one `bcm-qemu.sh.j2` taking a phase arg; centralized the BCM NIC MACs. Boot phase validated live via `make bcm-vm`.
- **Fix multi-node teardown** ([IN-2298](https://insightsoftmax.atlassian.net/browse/IN-2298) · [#32](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/32)) — `teardown.yml` only killed `node001`'s pid, so `node002` survived `make teardown`; now loops over every `*-qemu.pid` + an anchored `pkill` catch-all (deduped the two hardcoded kill tasks). Passes ansible-lint at `production` profile.
- **Harden on-node overlay hooks** ([IN-2297](https://insightsoftmax.atlassian.net/browse/IN-2297) · [#31](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/31)) — `bcm-sync-userdata.sh`: fix a sed-injection (validate the hostname is sed-safe) + dedup 3 seds into one `update_field()` helper; `bcm-compat-fixes.sh`: `log()` helper + UUOC fix. Both add `set -u` while keeping fail-open (boot hooks must never block boot). Validated live on the node + shellcheck.
- **`make collect-logs`** ([IN-2296](https://insightsoftmax.atlassian.net/browse/IN-2296) · [#30](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/30)) — pull the on-target logs that explain failures (BCM `cmd`/`dhcpd`/`named` journals + exports + cmsh devices; Kairos `stylus-agent`/`kairos-agent`/`cmdline`/`dmesg`/oem) into `logs/collected/`, so troubleshooting (esp. remote/jumphost) doesn't need a live SSH session. Reuses the `add_host` foundation; works for both modes.
- **Inventory example consolidation** ([IN-2295](https://insightsoftmax.atlassian.net/browse/IN-2295) · [#29](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/29)) — collapsed 3 overlapping example files to 2 (one per mode: `all.local-kvm.example.yml` local, `all.example.yml` remote/full-reference) with a clear "which file?" header; fixed stale comments that the rearchitecture invalidated (now describe `add_host`/`delegate_to`, not the deleted `*.sh.j2` scripts).
- **`kairos_vm`: shared QEMU launcher** ([IN-2294](https://insightsoftmax.atlassian.net/browse/IN-2294) · [#28](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/28)) — the ~24-line `qemu-system` invocation was copy-pasted 3× (PXE-install launch, disk-boot fact, non-blocking finisher); extracted to one `kairos-qemu.sh.j2` taking a boot-spec arg. Validated live (`kairos-vm` + `validate`, 0 FAIL).
- **`validate` → native Ansible** ([IN-2293](https://insightsoftmax.atlassian.net/browse/IN-2293) · [#27](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/27)) — replaced the 303-line `validate.sh.j2` with native assertion tasks: BCM checks run delegated to the `add_host` managed BCM; each check records a `{name, status, detail}` result that `report.j2` renders as a PASS/WARN/FAIL summary gated by an `assert`. (Kairos checks run per-check via the BCM — the node is password-only and Ansible can't cleanly proxy-password a password jumphost, and key injection would plant persistent access.) Validated live: 29 PASS / 1 WARN / 0 FAIL.
- **`deploy_dd` → native Ansible** ([IN-2292](https://insightsoftmax.atlassian.net/browse/IN-2292) · [#26](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/26)) — replaced the 417-line `deploy-dd.sh.j2` orchestration script with native delegated tasks (the BCM as an `add_host` managed host): 8 task files mirroring the old `[N/7]` steps, systemd units extracted to `files/`, idempotent modules replacing hand-rolled `grep -qF || echo`, and an explicit assertion on the load-bearing category→installer-image end-state (was a silent `|| true`). Fixed 5 latent bugs the old script masked by running without `set -e`. Validated end-to-end on local-KVM (`deploy-dd` + `kairos-vm` + `validate`, 0 FAIL).
- **BCM-as-managed-host foundation** ([IN-2291](https://insightsoftmax.atlassian.net/browse/IN-2291) · [#25](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/25)) — `playbooks/tasks/add_bcm_host.yml` registers the BCM as a runtime-managed Ansible host (`add_host`), one connection model for both local-KVM and remote/jumphost, so stages can run native delegated tasks (`delegate_to: bcm`) instead of shelling in through rendered bash. The groundwork for dissolving the 300–400-line orchestration scripts into idempotent tasks. Validated against the live BCM.
- **Logging & observability** ([IN-2290](https://insightsoftmax.atlassian.net/browse/IN-2290) · [#24](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/24)) — per-run timestamped `logs/run-<ts>/` directories with a `latest` symlink (reruns no longer clobber a prior run's evidence), a structured `*.ansible.log` capturing per-task detail incl. delegated hosts, `profile_tasks` slowest-step timings, failed-task stderr surfaced to the console, and a `V=-vv` verbosity knob.
- **Lint + static-analysis + CI quality gates** ([IN-2289](https://insightsoftmax.atlassian.net/browse/IN-2289) · [#23](https://github.com/blik616287/kvm_bcm_plus_kairos/pull/23)) — the repo's first code-quality gates: shellcheck/shfmt, yamllint, ansible-lint, checkov, gitleaks (blocking), bandit/vulture, pre-commit, `make lint/fmt/analyze`, GitHub Actions CI, and a render-bridge to lint bash embedded in `.sh.j2` templates. Lax baseline-then-ratchet so the existing tree is green; CI runs the same `make` targets as a local checkout for local↔CI parity.

## License

[MIT](LICENSE) © 2026 Martin Forde <mforde84@gmail.com>, [Blik Labs](https://bliklabs.com).
