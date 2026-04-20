# Kairos Edge Deployment on BCM — POC

## Executive Summary

We propose deploying Spectro Cloud's Kairos OS to bare-metal compute nodes using your existing Bright Cluster Manager (BCM) infrastructure. The solution leverages BCM's native PXE, TFTP, and provisioning pipeline, adding a Kairos-specific software image that writes an immutable Kairos root filesystem via `dd` directly from BCM's HTTP server.

The entire deployment is automated with Ansible. A one-time Kairos image build takes approximately 30 minutes; each subsequent compute node is provisioned in 10–15 minutes. Re-registration of previously-provisioned edge hosts is fully automated: no manual Palette UI steps are required on re-deploys.

---

## Why This Approach

### The Problem

Kairos and BCM use fundamentally different installation processes:

- **BCM's provisioning** writes a traditional Linux root filesystem to the node's disk via rsync, backed by NFS and a systemd-managed chroot.
- **Kairos requires** a specific GPT partition layout (`COS_GRUB`, `COS_OEM`, `COS_RECOVERY`, `COS_STATE`, `COS_PERSISTENT`), an EFI System Partition with a GRUB-EFI loader, and an immutable squashfs root booted via cos-img.

The two approaches are incompatible out of the box. Running `kairos-agent install` inside BCM's installer environment isn't viable — kairos-agent expects to boot from its own ISO and partition disks on its own terms.

Typical alternatives all have serious downsides:

- **Manual USB/ISO installation per node** — doesn't scale, requires physical presence.
- **Custom PXE infrastructure separate from BCM** — duplicates what BCM already provides, requires separate DHCP/TFTP, creates network conflicts with existing BCM provisioning.
- **Replacing BCM entirely** — loses HPC cluster management capabilities.

### Our Solution

We inject Kairos into BCM's existing provisioning pipeline. BCM already knows how to PXE boot nodes, rsync software images, and manage node lifecycle. We create a new BCM software image (`kairos-installer`) whose only job is to boot once, download a pre-built Kairos raw disk image over HTTP from BCM, and `dd` it onto the node's disk. After that, the node powers off and subsequently boots Kairos directly from its own disk via UEFI.

### Why This Is Better

1. **Leverages existing infrastructure** — builds on your existing BCM DHCP, TFTP, NFS, and rsync pipeline. No new provisioning servers, no new networks.
2. **Additive, not destructive** — all changes to BCM are additions: a new software image, a new category, a target-device reconfiguration. Existing images, categories, and nodes are untouched. Cluster-wide defaults are not flipped.
3. **Reversible** — change a node's category back in cmsh and it reverts to standard HPC provisioning on next PXE boot.
4. **Repeatable** — the Kairos image is built once and deployed to any number of nodes.
5. **Immutable** — Kairos boots from a read-only ext2 loop-mount of `COS_ACTIVE`, immune to configuration drift.
6. **Idempotent re-deploys** — a dedicated pre-registration hook on the node deletes stale Palette edge-host records and auto-mints a fresh registration token when needed, so re-imaging a previously-provisioned node doesn't get stuck in Palette's "UID already registered" state.

---

## Prerequisites

### What We Need From You

| Requirement | Detail |
| --- | --- |
| **BCM head node** | Running BCM 11.0. Accessible via SSH with root credentials — either directly from the build host or through an SSH jumphost (ProxyCommand supported). |
| **BCM services** | `cmd`, `dhcpd`, `named`, `nfs-server` all active. Standard BCM provisioning must already be working for at least one existing category. |
| **Network** | The provisioning network where compute nodes live. BCM must be able to reach the Palette endpoint (whether on-prem or public SaaS). |
| **Compute node(s)** | Bare-metal server(s) registered in cmsh with the correct MAC and assigned to a category (any existing category is fine — we move the target device into the `kairos` category automatically). Each node must be configured to PXE boot. |
| **Palette credentials** | API endpoint, project name and UID, admin API key (with `edgeToken.create` + `edgehost.delete` permissions), and the CA certificate PEM if your Palette instance uses a self-signed cert. A pre-minted edge-host registration token is *optional* — if absent the node mints one on first boot using the admin key. |
| **Out-of-band power management** | IPMI / iDRAC / Redfish reachable for the target nodes. Used to force one-time PXE boot and power-cycle during the re-image. |

### What We Provide

| Component | Detail |
| --- | --- |
| **Kairos raw disk image** | 80 GB sparse raw image (~5.4 GB after lz4 compression), pre-built with Kairos OS + K3s + Palette `stylus-agent` |
| **install-kairos.sh** | Runs inside BCM's node-installer environment: streams the compressed image via `curl | lz4 -d | dd` onto the target disk, fixes the GPT backup header with `sgdisk -e`, registers a UEFI boot entry with `efibootmgr --create`, and powers off |
| **palette-cleanup-stale.sh** | Runs on the node as a stylus-agent ExecStartPre hook. Handles re-deploy edge cases: detects registration mode, deletes any stale Palette edge-host record for this SMBIOS UID via admin API, and auto-generates a fresh `edgeHostToken` if one isn't baked into the image |
| **Ansible automation** | `make discover` / `make kairos-build` / `make deploy-dd` / `make validate` targets |
| **Validation suite** | 41-point automated validation covering BCM services, networking, Kairos OS, and Palette registration |

---

## Architecture

### Network Topology (remote BCM, single provisioning subnet)

```
  ┌──────────────┐      ┌─────────────┐
  │  Build host  │ SSH  │  Jumphost   │ SSH  ┌─────────────┐
  │  (our env)   │─────▶│             │─────▶│ BCM head    │
  │              │   via│             │   via│  .98.2      │
  │              │ proxy│             │proxy │             │
  └──────────────┘      └─────────────┘      └──────┬──────┘
                                                    │
                                          provisioning network
                                          (e.g. 192.168.98.0/24)
                                                    │
                            ┌───────────────────────┼───────────────────┐
                            ▼                       ▼                   ▼
                    ┌──────────────┐       ┌──────────────┐      ┌──────────────┐
                    │ Compute node │       │ Compute node │      │     ...      │
                    │   (Kairos)   │       │   (Kairos)   │      │              │
                    └──────────────┘       └──────────────┘      └──────────────┘

  ┌──────────────┐
  │   Palette    │◀── TLS over the site's existing internet path
  │  (on-prem or │
  │  SaaS)       │
  └──────────────┘
```

### What Changes in BCM

We SSH to the BCM head node (directly or via configured jumphost) and make the following changes via `cmsh` and the filesystem:

1. **Software image `kairos-installer`** — cloned from `bcm_source_category`'s image (on a fresh BCM this is `default-image`; on an existing site we clone from the current operating category's image). Our `install-kairos.sh`, `kairos-install.service`, and `lz4` binary are injected; `eth0`/`ens3` DHCP is added to `/etc/network/interfaces`; the PXE ramdisk is regenerated.
2. **Category `kairos`** — cloned from your existing category (e.g., `"S-AI Partner Lab"`). Set to `installmode=FULL` with `softwareimage=kairos-installer` and kernel parameters `console=ttyS0,115200n8 net.ifnames=0 biosdevname=0`. The `fsmounts` entries for `/cm/shared` and `/home` are removed (Kairos uses `COS_PERSISTENT` bind-mounts, not NFS). Three `nodeexecutionfilters` are installed to **exclude** the kairos category from BCM's `mounts`, `interfaces`, and `ntp` health checks — Kairos' immutable-OS architecture doesn't match what those checks expect, and without the filters the category would permanently show "health check failed" despite being functionally healthy.
3. **Target device reconfiguration** — the compute node is assumed to already be registered in cmsh. `bcm_target_node` in the inventory names the existing device. We set `category=kairos`, `softwareimage=kairos-installer`, and `installmode=FULL` on it. No new device records are created. (On a fresh local-KVM BCM the pipeline can alternatively register a `node001` from scratch.)
4. **IP forwarding + NAT** — `net.ipv4.ip_forward=1` and an iptables MASQUERADE rule on BCM's default-route interface (auto-detected — handles `eth1`, `ens*`, `enp*` alike). Only takes effect when compute nodes actually route through BCM for internet access; on sites where compute nodes have their own upstream gateway this is a harmless no-op.
5. **HTTP server** — systemd unit `kairos-http.service` runs a Python HTTP server on port `8888` from `/cm/shared/kairos/`. This is how compute nodes pull the compressed Kairos image during install.
6. **Kairos image upload** — the compressed `disk.raw.lz4` (~5.4 GB) is `scp`'d to `/cm/shared/kairos/` on BCM. Subsequent runs check size and skip re-upload when unchanged.

*Not* changed on a remote BCM (gated off by default):

- **DNS forwarders** — `bcm_manage_dns: false` by default; your site's existing DNS config is untouched. Only a fresh local-KVM BCM has its cluster-wide `nameservers` rewritten.
- **Cluster defaults** — `bcm_manage_cluster_defaults: false` by default; `defaultcategory` and `nodebasename` on the `base` partition are not touched.

---

## Per-Node Provisioning Flow

The node PXE boots exactly as it would for any BCM-managed node. The only difference is the software image BCM serves it.

| Phase | Time | What Happens |
| --- | --- | --- |
| **POST + PXE** | ~3 min | UEFI POST, NIC sends DHCP DISCOVER, BCM responds with the registered IP + TFTP next-server, node fetches kernel + ramdisk from `/cm/images/kairos-installer/boot/` |
| **BCM provisioning** | ~1 min | BCM's node-installer rsyncs `/cm/images/kairos-installer/` onto the target disk, installs GRUB-EFI into the ESP, `switchroot`s into the newly-synced filesystem (no reboot) |
| **Kairos `dd` install** | ~2 min | `kairos-install.service` fires: stages binaries to `/dev/shm`, wipes signatures on non-boot disks (`wipefs -a`), streams `curl → lz4 → dd` onto the pinned target disk with `oflag=direct`, runs `sgdisk -e` to relocate the GPT backup header, runs `partprobe` to re-read partitions |
| **UEFI boot entry** | ~5 s | `efibootmgr --create --disk <target> --part 1 --label Kairos --loader '\EFI\BOOT\bootx64.efi'` writes a new UEFI boot entry at the front of BootOrder — ensures the freshly-dd'd disk is picked on next power-up |
| **Poweroff** | ~2 s | SysRq-triggered poweroff from RAM (the disk has been fully rewritten; `reboot` would fail) |
| **Power on (manual or automated)** | ~3 min | Operator (or our iDRAC/Redfish hook) powers the server back on. UEFI picks the `Kairos` boot entry, loads GRUB-EFI from the new ESP, boots the active Kairos image |
| **Cloud-config + registration** | ~2 min | Stylus-agent's ExecStartPre hooks run: `palette-cleanup-stale.sh` clears any stale edge-host record and mints a token if needed; `bcm-sync-userdata.sh` syncs hostname to Palette. Stylus registers the edge host with Palette, caches the hubble JWT on `COS_PERSISTENT` |
| **Total** | **~13 min** | From first power-on to `[ UP ]` in BCM + `healthy` in Palette |

---

## Implementation Steps

### Step 0 (optional): Discover existing BCM state — `make discover`

**What:** Interactive playbook that SSHes to the BCM head node (through your jumphost), reads the internal network definition from cmsh, enumerates categories, software images, and registered devices, and writes a site-specific inventory starter file at `bcm-discovery-<bcm-hostname>.yml`.

**When to use:** Run first on any BCM you haven't deployed to before, to harvest the right values for `bcm_internal_ip`, `bcm_internal_cidr`, `bcm_external_dns`, `kairos_kernel_version`, and to see which category/image names already exist on the BCM so you can pick the right `bcm_source_category`.

**Non-interactive invocation** (so you can script it):

```bash
ansible-playbook playbooks/discover-bcm.yml \
    -e bcm_host=192.168.98.2 -e bcm_port=22 -e bcm_user=root \
    -e bcm_pass='<root-password>' \
    -e bcm_proxy_jump='user@jumphost.example.com' \
    -e bcm_proxy_key='~/.ssh/sai'
```

### Step 1: Build the Kairos image — `make kairos-build`

**What:** Builds a bootable 80 GB raw disk image containing Kairos OS, K3s, the Palette stylus-agent, and our BCM integration scripts.

**Where:** On the build host (our CI/workstation). Does not touch BCM.

**Process:**

1. **CanvOS ISO build** (~10 min, Earthly + Docker) — clones Spectro Cloud's CanvOS submodule, renders the `.arg` file with the target registry/arch/kernel, copies our overlay files (BCM compatibility scripts, systemd drop-ins, the `palette-cleanup-stale.sh` hook), patches the Earthfile to include `ifupdown` + `nfs-common`, and runs `earthly +iso` to produce the Palette Edge Installer ISO.
2. **Raw disk build under OVMF/UEFI** (~8 min, headless QEMU) — generates a BCM-↔-Kairos ed25519 SSH keypair, renders the cloud-config with the Palette + BCM parameters, creates a 4 MB FAT32 user-data image, boots a headless QEMU VM *under OVMF UEFI firmware* (not SeaBIOS) so `kairos-agent install` produces a real EFI System Partition with `\EFI\BOOT\bootx64.efi` — required for physical UEFI servers to boot the resulting raw.
3. **Post-processing** — `e2fsck` + `tune2fs -O ^metadata_csum` on each ext4 partition for GRUB compatibility, patches `bootargs.cfg` with `net.ifnames=0 biosdevname=0` for stable NIC naming, sets GRUB timeout to 5 s for unattended boot, sparse-trims the raw file with `fallocate --dig-holes` (80 GB virtual → ~8.7 GB on disk), writes a SHA-256 checksum.

**Output:** `build/kairos-disk.raw` (80 GB sparse, ~8.7 GB actual), `build/palette-edge-installer.iso` (~1.5 GB), `build/cloud-config.yaml` (~8 KB rendered), `build/bcm-kairos-key` + `.pub` (ed25519 keypair).

**Time:** ~25 min total (once; the same image deploys to all nodes).

### Step 2: Deploy to BCM — `make deploy-dd`

**What:** Uploads the Kairos image to BCM, creates the installer software image, configures the `kairos` category, targets the specified compute device, and regenerates the PXE ramdisk.

**Where:** Runs on the build host, SSHes to BCM through the jumphost to make all changes.

**What it does (7 steps):**

1. **Compress + upload** — `lz4 -f build/kairos-disk.raw build/kairos-disk.raw.lz4` (80 GB → ~5.4 GB), `scp` to `root@<bcm>:/cm/shared/kairos/disk.raw.lz4` via the configured SSH config. Skip-if-size-matches check avoids re-uploads on subsequent runs.
2. **HTTP server** — creates `/etc/systemd/system/kairos-http.service` serving `/cm/shared/kairos/` on port `8888`. Enables + starts.
3. **Create installer image** — `cmsh softwareimage; clone <bcm_source_category's image> kairos-installer; commit`. Reuses existing if already present. Waits for BCM to populate `/cm/images/kairos-installer/usr/`.
4. **Install dd service + lz4 into the image** — installs `lz4` on BCM via apt (does NOT touch BCM's `/etc/resolv.conf`), copies it + our `install-kairos.sh` into `/cm/images/kairos-installer/usr/local/{bin,sbin}/`, drops `kairos-install.service` into the image's systemd multi-user target. Also appends `eth0`/`ens3` DHCP stanzas to the image's `/etc/network/interfaces`.
5. **Configure kairos category** — clones from `bcm_source_category`, sets installmode/newnodeinstallmode/installbootrecord/kernelparameters, strips `/cm/shared` and `/home` fsmounts, and installs three `nodeexecutionfilters` (Exclude, category=kairos) against the `mounts`, `interfaces`, and `ntp` monitoring setups.
6. **Target device** — when `bcm_target_node` is set: `cmsh device; use <target>; set category kairos; set softwareimage kairos-installer; set installmode FULL; commit`. On a fresh BCM without `bcm_target_node`, falls back to registering `node001` with an explicit IP + MAC.
7. **Regenerate ramdisk** — `cmsh softwareimage; use kairos-installer; createramdisk -w` rebuilds the PXE initrd for the kairos-installer image so TFTP can serve it. Takes 5–10 min.

**Time:** ~10 min on a fresh/local BCM, or ~30 min on a remote BCM (the SCP upload of the ~5.4 GB image through a jumphost is the bottleneck). Skip-if-exists on subsequent runs drops that to ~3 min.

**Key inventory variables (see `inventory/group_vars/all.example.yml`):**

| Variable | Purpose |
| --- | --- |
| `bcm_password` | BCM root SSH password |
| `bcm_ssh_host` / `bcm_ssh_port` | BCM address (e.g., `192.168.98.2:22` on a remote, `localhost:10022` on local-KVM) |
| `bcm_ssh_proxy_jump` / `bcm_ssh_proxy_key` | Jumphost in `user@host` form + key path (empty when BCM is directly reachable) |
| `bcm_internal_ip` / `_netmask` / `_cidr` | BCM's provisioning-network identity (bake into `install-kairos.sh`'s HTTP URL) |
| `bcm_source_category` | Existing category to clone for `kairos` (e.g., `"S-AI Partner Lab"`) |
| `bcm_target_node` | Name of the existing cmsh device to re-image |
| `bcm_manage_dns` | Default `false` on remote — leaves site DNS alone |
| `bcm_manage_cluster_defaults` | Default `false` on remote — no cluster-wide changes |
| `kairos_target_disk` | Disk device to dd onto (e.g., `/dev/nvme0n1`) |
| `kairos_wipe_disks` | Sibling disks to `wipefs -a` before dd (clears stale LVM/DRBD signatures) |
| `palette_endpoint` / `palette_project_name` / `palette_project_uid` | Palette coordinates |
| `palette_api_key` | Admin key (baked to node for cleanup + token auto-gen) |
| `palette_ca_cert` | Self-signed CA PEM for non-public Palette |
| `palette_token` | *Optional* pre-minted edge-host token; auto-generated when absent |

### Step 3: PXE boot the compute node

**What:** Force a one-time PXE boot via iDRAC/Redfish, then cycle power once more after the `dd` completes.

**Automatable via racadm (Dell):**

```bash
# Before cycle — set one-time PXE boot
racadm set iDRAC.ServerBoot.BootOnce Enabled
racadm set iDRAC.ServerBoot.FirstBootDevice PXE
racadm serveraction powerdown
# ...wait until powerstatus=OFF...
racadm serveraction powerup

# Watch: BCM DHCP + TFTP → node-installer → install-kairos.sh → dd → UEFI boot entry → SysRq poweroff
# ...wait until powerstatus=OFF again (dd done)...

# After dd — power back on
racadm serveraction powerup
# UEFI now has the `Kairos` entry at the front of BootOrder and boots Kairos from disk
```

The **first** PXE boot exists because the current BootOrder doesn't contain a Kairos entry yet — UEFI has to fall through to PXE. The **second** power-on boots Kairos from the disk directly (no PXE) because `install-kairos.sh` registered the Kairos boot entry. Subsequent reboots stay on disk.

### Step 4: Validate — `make validate`

**What:** A bash script rendered from an Ansible template. Uses the same SSH chain as `deploy-dd` (through the jumphost) to run 41 checks across BCM and the compute node.

**BCM checks (18):** SSH reachability, service status (`cmd`, `dhcpd`, `named`, `nfs-server`, `rsyncd`, HTTP:8888), internal IP present on any interface, external interface detection, IP forwarding, external DNS resolution, internet reachability, cluster state (head node UP, target node registered with correct IP + `kairos` category), `kairos-installer` image present, raw disk on `/cm/shared/`.

**Kairos node checks (23):** SSH reachability (via BCM jump host), ping, OS version (Ubuntu 22.04 base), Kairos release + version, kairos-agent version, kernel version, IP address, gateway, DNS resolver, external DNS resolution, internet access, stylus-agent active, Palette registration logged, boot cmdline has `net.ifnames=0` + Kairos boot chain markers, COS partitions present (OEM/RECOVERY/STATE/PERSISTENT), root immutable, disk free, `/oem/*.yaml` present.

**Sample output:**

```
============================================
 E2E Deployment Validation
============================================
== BCM Head Node (port 22) ==
  [PASS] BCM SSH — port 22
  [PASS] cmd service
  [PASS] dhcpd
  [PASS] named (DNS)
  [PASS] nfs-server
  [PASS] rsyncd (873)
  [PASS] HTTP server (8888) — Kairos image server
  [PASS] BCM internal IP — 192.168.98.2 on enp6s0
  [PASS] BCM external iface — enp6s0
  [PASS] IP forwarding
  [PASS] External DNS
  [PASS] Internet access — HTTP 301
  [PASS] Head node (cmsh)
  [PASS] <target-node> registered
  [PASS] <target-node> IP — <ip>
  [PASS] <target-node> category — kairos
  [PASS] kairos-installer image
  [PASS] Kairos raw image — /cm/shared/kairos/disk.raw.lz4

== Kairos Compute Node ==
  [PASS] Kairos SSH
  [PASS] Kairos ping
  [PASS] OS — Ubuntu 22.04.5 LTS
  [PASS] Kairos release — v4.0.3
  [PASS] kairos-agent — v2.27.0
  [PASS] Kernel — 6.8.0-106-generic
  [PASS] IP address
  [PASS] Gateway
  [PASS] DNS resolver
  [PASS] External DNS resolution
  [PASS] Internet access — HTTP 301
  [PASS] stylus-agent
  [PASS] Palette registration
  [PASS] net.ifnames=0
  [PASS] Kairos boot chain
  [PASS] COS_OEM
  [PASS] COS_RECOVERY
  [PASS] COS_STATE
  [PASS] COS_PERSISTENT
  [PASS] Root immutable
  [PASS] Disk free
  [PASS] OEM config

 PASS: 41/41   WARN: 0/41   FAIL: 0/41
```

**Time:** ~2 min.

---

## Scaling to Multiple Nodes

Once the initial setup on BCM is done (Steps 1–2 complete, image uploaded, category + filters + installer configured), adding more nodes is straightforward:

1. Your BCM admin adds each new node to cmsh (any standard BCM onboarding process — existing site tooling applies).
2. Update `bcm_target_node` in `inventory/group_vars/all.yml` to the new device's cmsh name.
3. Re-run `make deploy-dd` — skip-if-exists means the image isn't re-uploaded; only the cmsh reconfiguration runs (~1 min).
4. PXE-boot-once the new node.

Or, for fleet provisioning: loop over target-node names, automating the per-node iDRAC cycle with a small shell script using the same racadm pattern.

One Kairos raw image + one admin API key provisions any number of nodes. No per-node Palette UI interaction is required.

---

## Re-deploying a Node (Idempotent Re-image)

A previously-provisioned Kairos node can be re-imaged safely:

- Its SMBIOS UUID is deterministic, so Palette would normally reject a re-registration with *"Edge host already registered"*. Our on-node `palette-cleanup-stale.sh` handles this: before stylus-agent starts, it checks for a stale record for this UID and deletes it via the admin API.
- Similarly, any orphan DRBD/Linstor/LVM signatures on sibling data disks from a prior cluster get wiped by `install-kairos.sh`'s `wipefs` pass, preventing Kairos (or a later cluster profile) from auto-activating stale volumes.
- The UEFI boot entry is rewritten: `install-kairos.sh` removes any existing `Kairos` entries before creating the fresh one, so re-imaging doesn't stack duplicate entries in `BootOrder`.

The re-deploy procedure is identical to the first-time procedure: `make deploy-dd` (if the image or config changed; otherwise skip), then PXE-boot-once via iDRAC.

---

## Rollback

To return a node to standard BCM management:

```bash
# 1. In cmsh, revert the device's category and clear the Kairos softwareimage override
cmsh -c "device; use <node>; set category <original-category>; clear softwareimage; set installmode AUTO; commit"

# 2. Delete the edge host record in Palette (UI → Edge Hosts → Delete, or DELETE /v1/edgehosts/<uid> via admin API)
#    to release the UID before the next re-registration

# 3. Power cycle the node. BCM now provisions the original HPC image (via PXE) instead of kairos-installer.

# 4. (Optional) Remove the kairos category's nodeexecutionfilters if you want the mounts/interfaces/ntp
#    healthchecks re-enabled for any remaining Kairos nodes
```

Total time: a few cmsh commands plus one PXE boot.

---

## Risk Mitigation

| Risk | Mitigation |
| --- | --- |
| `dd` overwrites the wrong disk | `kairos_target_disk` is pinned in inventory (e.g., `/dev/nvme0n1`). The script never auto-detects on remote deploys. Sibling disks are handled by an explicit `kairos_wipe_disks` list. |
| BCM provisioning fails | Node stays on the BCM node-installer / NFS root — no data loss. Power-cycle to retry. |
| Kairos image corrupt | `make validate` catches it — OS, partition, service, and registration checks all flag mismatches. Rebuild the image and re-run `deploy-dd`. |
| Palette registration fails with "UID already registered" | `palette-cleanup-stale.sh` deletes the stale record before stylus-agent attempts registration. Requires a valid `palette_api_key` in inventory. |
| `edgeHostToken` is empty or stale | If no token is baked in, `palette-cleanup-stale.sh` mints a fresh one via the admin API (30-day expiry) and injects it into `/oem/90_custom.yaml` before stylus-agent starts. |
| Node doesn't PXE boot | Verify BIOS boot order, check BCM DHCP logs (`journalctl -u dhcpd`), confirm MAC matches cmsh. The one-time PXE override via racadm bypasses persistent BootOrder changes. |
| BCM healthchecks flag the node | Expected for Kairos' architecture (different mount/interface semantics). Our deploy automatically installs `nodeexecutionfilters` to exclude the `kairos` category from those specific checks, keeping `cmsh device list` clean. |
| Disk space on BCM | `/cm/shared/kairos/disk.raw.lz4` is ~5.4 GB. The kairos-installer software image in `/cm/images/` is ~2 GB. Allow ~10 GB free on BCM. |

---

## Deliverables

1. **Ansible automation** — `make discover`, `make kairos-build`, `make deploy-dd`, `make validate` targets, all driven from a single inventory file (`inventory/group_vars/all.yml`; example template at `inventory/group_vars/all.example.yml`).
2. **Kairos raw disk image** — pre-built, tested, UEFI-bootable with Palette stylus-agent and our BCM integration cloud-config baked in.
3. **BCM configuration artifacts** — `kairos-installer` software image, `kairos` category, category-scoped healthcheck exclusion filters, target device reconfiguration, HTTP image server systemd unit.
4. **`palette-cleanup-stale.sh`** — on-node pre-registration hook covering all re-deploy edge cases (stale Palette records, missing tokens, re-registration).
5. **UEFI support** — image built with OVMF firmware, `install-kairos.sh` writes a UEFI boot entry via `efibootmgr --create` so physical UEFI servers boot the freshly-dd'd disk without any one-time-boot override.
6. **Discovery tool** — `make discover` / `playbooks/discover-bcm.yml` captures an existing BCM's network, category, image, and device state into a site-specific starter inventory file.
7. **Validation suite** — 41-point automated check covering BCM services, networking, Kairos OS, partitions, services, and Palette registration. Works locally (against a KVM BCM) and remotely (through an SSH jumphost).
8. **Documentation** — this POC document, an `all.example.yml` inventory template, the `docs/pipeline-deep-dive.md` architecture reference.

---

*Confidential — Kairos Edge Deployment POC*
