# BCM + Kairos KVM Deployment

Automated end-to-end pipeline that deploys a BCM 11.0 head node and Kairos edge compute nodes in local KVM virtual machines, culminating in Palette registration.

## Architecture

```
Host Machine (QEMU/KVM)
  |
  |-- BCM Head Node VM
  |     eth0: internal provisioning (socket :31337) -- 10.141.255.254/16
  |     eth1: external NAT (QEMU user-mode)         -- 10.0.2.15 (auto)
  |     SSH:  localhost:10022 -> VM:22
  |
  |-- Kairos Compute Node VM
        eth0: internal provisioning (socket :31337) -- DHCP from BCM
        PXE boot from BCM -> installer -> dd -> Kairos
```

Two separate QEMU networks eliminate ARP conflicts and policy routing hacks:
- **Internal**: Socket-based L2 bridge (`:31337`) for BCM provisioning and PXE boot
- **External**: QEMU user-mode NAT with port forwarding for internet access

## Prerequisites

- QEMU/KVM (`qemu-system-x86_64`, `/dev/kvm`)
- Docker (for CanvOS/Earthly ISO build)
- Ansible
- `sshpass`, `xorriso`, `p7zip`, `lz4`, `jq`, `mtools`, `dosfstools`

```bash
make install-deps   # auto-install all dependencies (Debian/Fedora)
```

## Quick Start

```bash
# 1. Configure
cp inventory/group_vars/all.example inventory/group_vars/all
# Edit: set jfrog_token, palette_token, palette_project_uid

# 2. Verify prerequisites
make setup

# 3. Run full pipeline
make all
```

## Pipeline Stages

| Stage | Target | Duration | Description |
|-------|--------|----------|-------------|
| 1 | `make bcm-prepare` | ~2 min | Download BCM ISO from JFrog, patch rootfs, remaster for auto-install |
| 2 | `make bcm-vm` | ~60-90 min | Launch BCM in KVM, auto-install, boot from disk, wait for services |
| 3 | `make kairos-build` | ~10 min | Clone CanvOS, build Kairos ISO via Earthly, generate raw disk image |
| 4 | `make deploy-dd` | ~3 min | Upload lz4-compressed image to BCM, configure PXE + installer |
| 5 | `make kairos-vm` | ~10 min | PXE boot compute VM, dd Kairos to disk, boot into Kairos |
| 6 | `make validate` | ~15 sec | 39-point validation across BCM and Kairos |

```
bcm-prepare ──> bcm-vm ──> deploy-dd ──> kairos-vm ──> validate
                              ^
kairos-build ─────────────────┘
```

Stages 2 and 3 can run in parallel (BCM install + Kairos build).

## Make Targets

```bash
# Pipeline
make bcm-prepare        # Stage 1: Download + patch + remaster BCM ISO
make bcm-vm             # Stage 2: Launch BCM in local KVM
make kairos-build       # Stage 3: Build Kairos ISO + raw disk image
make deploy-dd          # Stage 4: Upload image to BCM, configure PXE
make kairos-vm          # Stage 5: PXE boot Kairos compute VM
make validate           # Stage 6: Validation
make all                # Run full pipeline (stages 1-6)

# Discovery
make discover           # Discover existing BCM head node config (interactive)

# VM Management
make bcm-stop           # Stop BCM VM
make kairos-stop        # Stop Kairos compute VM
make stop               # Stop all VMs
make bcm-serial         # Tail BCM serial log
make kairos-serial      # Tail Kairos serial log

# Cleanup
make clean              # Remove build/, logs/ (keeps dist/ and CanvOS/)
make clean-dist         # Remove downloaded ISOs (dist/)
make clean-canvos       # Remove cloned CanvOS repo
make clean-all          # Stop VMs + remove everything
make teardown           # Stop VMs + remove build artifacts (keeps dist/ and CanvOS/)

# Dependencies
make setup              # Verify prerequisites
make install-deps       # Install all build dependencies
```

## Configuration

Copy `inventory/group_vars/all.example` to `inventory/group_vars/all` and set:

| Variable | Description |
|----------|-------------|
| `bcm_password` | BCM root password |
| `jfrog_token` | JFrog bearer token for BCM ISO download |
| `palette_token` | Palette registration token (base64) |
| `palette_project_uid` | Palette project UID |
| `bcm_internal_ip` | BCM internal IP (default: `10.141.255.254`) |
| `bcm_vm_ram` / `bcm_vm_cpus` | BCM VM resources (default: 8192 MB / 4 CPUs) |
| `kairos_vm_ram` / `kairos_vm_cpus` | Compute VM resources (default: 4096 MB / 2 CPUs) |

## Deploying to an Existing BCM Head Node

If you already have a BCM head node running (not a local KVM VM), you can skip stages 1-2 and deploy Kairos directly. Use `make discover` to auto-detect the configuration:

```bash
make discover
```

This prompts for the BCM IP, SSH port, user, and password, then SSHs in and discovers:

- Network configuration (internal/external IPs, CIDR, gateway, DNS)
- Service status (cmd, dhcpd, named, nfs-server)
- Cluster state (categories, registered nodes)
- Default image kernel version
- Available disk space on `/cm/shared`

It outputs recommended `group_vars/all` values and saves them to `bcm-discovery-<ip>.yml`. Review the output, copy the values into `inventory/group_vars/all`, then run:

```bash
make kairos-build    # Build the Kairos raw disk image (runs locally)
make deploy-dd       # Upload image + configure PXE on your BCM head node
```

The `deploy-dd` stage SSHes to the BCM head node using `bcm_connect_ip` and `bcm_connect_port` from your group_vars, uploads the lz4-compressed image, and configures the installer. After that, any node that PXE boots from BCM with the `kairos` category will receive Kairos.

## How It Works

### BCM Install (Stage 2)

Two-phase QEMU install:
1. **Phase 1**: Direct kernel boot from extracted ISO rootfs with auto-install service injected. Runs `cm-master-install` unattended, patches GRUB for `net.ifnames=0`, powers off.
2. **Phase 2**: Boots from installed disk. Waits for `cmfirstboot`, `cmd` service, and `cmsh` to become responsive.

### Kairos Build (Stage 3)

1. Clones [CanvOS](https://github.com/spectrocloud/CanvOS), patches Earthfile (adds `wget`, `ifupdown`, `nfs-common`, skips dracut nfit)
2. Builds ISO via Earthly
3. Generates 80GB raw disk image in headless QEMU (SeaBIOS for BIOS+EFI boot)
4. Post-processing: fixes ext4 `metadata_csum` for GRUB, patches `net.ifnames=0` in all squashfs images, sets GRUB timeout, trims sparse zeros

### Deploy (Stage 4)

1. Compresses raw image with lz4, uploads to BCM via SCP
2. Starts HTTP server on BCM (port 8888)
3. Clones `default-image` to `kairos-installer` software image
4. Installs dd service: `curl | lz4 -d | dd of=/dev/vda bs=4M oflag=direct`
5. Configures PXE, kairos category (FULL install), node registration
6. Generates ramdisk

### PXE Boot (Stage 5)

1. Compute VM PXE boots from BCM on internal network
2. BCM rsyncs `kairos-installer` image to node
3. `kairos-install.service` fires: downloads lz4 image via HTTP, stages binaries to RAM, dd's to disk with `oflag=direct`, fixes GPT backup header with `sgdisk -e`, drops page cache, powers off via sysrq
4. Playbook restarts VM from disk — Kairos boots with COS partitions

## Display

VMs auto-detect display availability:
- If X11/Wayland is available: GTK window with VM console
- If headless (SSH session): no display, serial log only

## Key Technical Details

- **lz4** compression (not gzip) for faster decompression during dd
- **`oflag=direct`** prevents page cache / thin pool overflow
- **SeaBIOS** for raw image build makes it bootable on both BIOS and EFI
- **sysrq poweroff from RAM** — binaries staged to `/dev/shm` before dd overwrites boot disk
- **`sgdisk -e`** fixes GPT backup header after dd to smaller/larger disk
- **Persistent NFS exports**, rsyncd, DHCP fixes applied to BCM
- **IP forwarding + NAT** enabled so compute nodes route through BCM to internet
- **Squashfs patching** — `net.ifnames=0 biosdevname=0` + `ifcfg-eth0` in all images (active, passive, recovery)
- **BCM compat scripts** baked into Kairos image: hostname sync, resolv.conf fix, stylus-agent registration mode

## Logs

Each stage logs to `logs/`:
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

## File Layout

```
kvm/
├── ansible.cfg
├── Makefile
├── inventory/
│   ├── hosts.yml
│   └── group_vars/all.example
├── playbooks/              # Numbered stages + utilities
├── roles/
│   ├── bcm_prepare/        # ISO download, patch, remaster
│   ├── bcm_vm/             # Two-phase KVM install + disk boot
│   ├── kairos_build/       # CanvOS ISO + raw disk via QEMU
│   ├── deploy_dd/          # Upload + configure BCM for PXE deploy
│   ├── kairos_vm/          # PXE boot compute node
│   ├── validate/           # 39-point health checks
│   └── dependencies/       # Package installer
├── files/canvos/           # CanvOS overlay (BCM compat scripts)
├── build/                  # Generated artifacts (gitignored)
├── dist/                   # Downloaded ISOs (gitignored)
└── logs/                   # Execution logs (gitignored)
```

## Re-running Stages

Stages are idempotent:
- **bcm-prepare**: Skips ISO download and remaster if artifacts exist
- **bcm-vm**: Skips Phase 1 if disk exists, restarts VM for Phase 2
- **kairos-build**: Skips ISO build and raw image generation if artifacts exist
- **deploy-dd**: Always re-runs (configures BCM fresh)
- **kairos-vm**: Kills existing VM, resets node to FULL install mode, creates fresh disk
- **validate**: Always re-runs

To force a full rebuild: `make clean && make all`
