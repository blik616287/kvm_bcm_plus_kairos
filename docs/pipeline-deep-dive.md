# KVM BCM + Kairos Pipeline — Step-by-Step Technical Deep Dive

This document explains every stage of the end-to-end pipeline in enough detail for an engineer to understand exactly what happens, why, and how the pieces connect.

---

## Table of Contents

1. [Prerequisites & Dependencies](#1-prerequisites--dependencies)
2. [Stage 1 — BCM Prepare (`make bcm-prepare`)](#2-stage-1--bcm-prepare)
3. [Stage 2 — BCM VM (`make bcm-vm`)](#3-stage-2--bcm-vm)
4. [Stage 3 — Kairos Build (`make kairos-build`)](#4-stage-3--kairos-build)
5. [Stage 4 — Deploy DD (`make deploy-dd`)](#5-stage-4--deploy-dd)
6. [Stage 5 — Kairos VM (`make kairos-vm`)](#6-stage-5--kairos-vm)
7. [Stage 6 — Validate (`make validate`)](#7-stage-6--validate)
8. [Network Topology](#8-network-topology)

---

## 1. Prerequisites & Dependencies

**Role:** `roles/dependencies/tasks/main.yml`

Before anything runs, the host machine needs a set of system packages. The `make install-deps` target invokes an Ansible playbook that detects the OS family (Debian/Ubuntu vs Fedora/RHEL) and installs the appropriate packages via `apt` or `dnf`:

| Package | Purpose |
|---------|---------|
| `qemu-system-x86`, `qemu-utils`, `ovmf` | KVM virtualization — runs both the BCM and Kairos VMs |
| `docker.io` / `docker` | Required by Earthly to build the CanvOS container and Kairos ISO |
| `sshpass` | Non-interactive SSH authentication to the BCM VM using a password |
| `xorriso` | ISO remastering — rebuilds the BCM ISO with injected auto-install scripts |
| `p7zip-full` / `p7zip` | Extracts the original BCM ISO contents for modification |
| `lz4` | Fast compression of the 80GB Kairos raw disk image before upload |
| `jq` | JSON processing during build steps |
| `mtools`, `dosfstools` | Creates FAT32 images (config drives, cloud-init user-data) |
| `cpio`, `gzip` | Unpacks and repacks the BCM installer rootfs (initramfs) |
| `curl` | Downloads the BCM ISO from JFrog |
| `nfs-common` / `nfs-utils` | NFS client support for Kairos nodes mounting BCM exports |
| `gdisk` | Fixes GPT backup headers after raw disk imaging (`sgdisk -e`) |
| `e2fsprogs` | Fixes ext4 metadata_csum feature flags for GRUB compatibility |
| `socat` | Network utility for serial console and socket connections |

The `make setup` target verifies these are all present without installing anything.

---

## 2. Stage 1 — BCM Prepare

**Role:** `roles/bcm_prepare/tasks/main.yml`  
**Produces:** `build/bcm-autoinstall.iso`, `build/.bcm-kernel`, `build/.bcm-rootfs-auto.cgz`, `build/.bcm-init.img`  
**Duration:** ~2 minutes  

### What this stage does

This stage takes the stock BCM 11.0 ISO (a standard interactive installer) and transforms it into a fully unattended auto-install ISO. The BCM installer normally requires a human to click through a GUI or text-mode wizard. We eliminate that by injecting a custom systemd service and shell script into the installer's initramfs (rootfs.cgz), so when the ISO boots, it configures networking, renders the cluster configuration, and runs `cm-master-install` without any interaction.

### Step-by-step

#### 2.1 Download the BCM ISO

The ISO is fetched from a JFrog Artifactory instance using a bearer token. The download is skipped if the file already exists in `dist/`. The ISO filename and JFrog coordinates are defined in `inventory/group_vars/all.yml`.

```
curl --fail --location --progress-bar \
  -H "Authorization: Bearer <jfrog_token>" \
  -o dist/bcm-11.0-ubuntu2404.iso \
  "https://<jfrog_instance>/artifactory/<jfrog_repo>/<iso_filename>"
```

#### 2.2 Mount and extract the rootfs

The ISO is loop-mounted read-only. Two files are extracted:
- `boot/kernel` — the Linux kernel used by the installer (saved as `build/.bcm-kernel`)
- `boot/rootfs.cgz` — the compressed cpio initramfs containing the entire installer environment

The rootfs is extracted into a temporary directory using `gunzip | cpio -iumd`. This gives us a full filesystem tree that we can modify.

#### 2.3 Inject the build-config.xml template

The file `roles/bcm_prepare/files/build-config.xml.tpl` is a ~4500-line Jinja2 template that defines the entire BCM cluster configuration: network definitions, DHCP ranges, interface assignments, package lists, hostname, timezone, and more. This template is copied into the rootfs at `/cm/build-config.xml.tpl`.

Python's `jinja2` and `pyyaml` packages are installed into the rootfs (via chroot pip3 install) so the auto-install script can render this template at boot time.

The default `build-config.xml` (already present in the rootfs) is also patched with the configured hostname and timezone as a fallback.

#### 2.4 Inject the auto-install script

The Ansible template `roles/bcm_prepare/templates/bcm-autoinstall.sh.j2` is rendered with variables from inventory and placed into the rootfs at `/usr/local/bin/bcm-autoinstall.sh`. This script is the core of the unattended install. At boot time, it:

1. **Configures networking** — Sets eth0 to the static internal IP (e.g. `10.141.255.254/16`) and runs `dhclient eth1` for external NAT connectivity. Sets `/etc/resolv.conf` to the QEMU DNS forwarder.

2. **Renders build-config.xml** — Uses an embedded Python script to render the Jinja2 template with two network definitions:
   - `internalnet`: 10.141.0.0/16 for provisioning (DHCP range .16–.254)
   - `externalnet`: 10.0.2.0/24 for internet access via QEMU NAT

3. **Waits for the installer environment** — Polls for `/var/www/htdocs/content/masterdisklayouts/master-one-big-partition.xml` to confirm the BCM installer's HTTP server is ready (up to 120 seconds).

4. **Mounts the installation media** — Tries `/dev/sr0`, `/dev/sr1`, `/dev/cdrom`, `/dev/dvd` in order, falling back to `findfs LABEL=BCMINSTALLERHEAD` for the FAT config drive.

5. **Runs cm-master-install** — Executes `perl ./cm-master-install --config /cm/build-config.xml --mountpath /mnt/cdrom --password <bcm_password>` piped through `yes` to auto-accept prompts. This is the actual BCM installation process — it partitions the disk, installs the OS, configures cluster management services, etc.

6. **Post-install GRUB patching** — After installation completes, the script activates LVM volumes, finds the installed root partition, and injects `net.ifnames=0 biosdevname=0` into both `/etc/default/grub` and `grub.cfg`. This ensures the installed system uses predictable NIC names (eth0, eth1) instead of names like ens3 or enp0s3, which is critical because all subsequent scripts and configurations reference eth0/eth1.

7. **Powers off** — The VM shuts down, signaling to the Ansible controller that Phase 1 is complete.

#### 2.5 Inject the systemd service

The file `roles/bcm_prepare/files/bcm-autoinstall.service` is a systemd unit that:
- Depends on `bright-installer-configure.service` (the BCM installer's own initialization)
- Conflicts with `bright-installer-text.service` and `bright-installer-graphical.service` (the interactive installers) and all getty services
- Runs `bcm-autoinstall.sh` with `Type=oneshot` and infinite timeout

This service is symlinked into `multi-user.target.wants`. The interactive installers and getty services are disabled/masked to prevent them from competing for the console.

#### 2.6 Repack the rootfs

The modified rootfs directory is repacked:
```
find . | cpio -o -H newc | gzip --fast > build/.bcm-rootfs-auto.cgz
```
The `--fast` flag trades compression ratio for speed, since this is a temporary artifact.

#### 2.7 Remaster the ISO

The original ISO is extracted with `7z` into a working directory. The stock rootfs is replaced with the patched version. Both GRUB and isolinux configs are modified:
- Timeout set to 0 (GRUB) or 1 (isolinux) for instant boot
- Default entry set to the text installer
- Kernel command line gets `net.ifnames=0 biosdevname=0 console=ttyS0,115200 console=tty0` appended (serial console output + stable NIC names)
- The "Boot from hard drive" option is removed from isolinux

The MBR is extracted from the original ISO (first 432 bytes) and used as the hybrid MBR for the new ISO. `xorriso` rebuilds the ISO with both BIOS (isolinux) and EFI (efi.img) boot support:

```
xorriso -as mkisofs \
  -o build/bcm-autoinstall.iso \
  -V "BCMINSTALLERHEAD" \
  -isohybrid-mbr mbr.bin \
  -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e efi.img -no-emul-boot -isohybrid-gpt-basdat \
  iso-work
```

#### 2.8 Create the config drive

A 4MB FAT32 image labeled `BCMCONFIG` is created using `dd` + `mkfs.vfat`. The BCM password is written to it as `password.txt` using `mcopy`. This drive is attached to the VM as a secondary virtio disk so the auto-install script can read the password without it being baked into the ISO.

---

## 3. Stage 2 — BCM VM

**Role:** `roles/bcm_vm/tasks/main.yml`  
**Produces:** `build/bcm-headnode.qcow2` (persistent disk), running BCM VM  
**Duration:** 60–90 minutes  

### What this stage does

This stage boots the remastered ISO in a QEMU/KVM virtual machine, waits for the unattended install to complete, then reboots the VM from the installed disk and waits for all BCM services to come online. It is a two-phase process because BCM's `cm-master-install` writes to disk and then the system must be rebooted to run from the installed OS.

### Phase 1 — Install from ISO

#### 3.1 Display detection

The playbook checks whether a graphical display is available by testing for `$DISPLAY` or `$WAYLAND_DISPLAY` environment variables, then verifying via `xdpyinfo` or `xset`. If a display server is reachable, QEMU uses `-display gtk` (shows a window); otherwise `-display none` (headless). This allows the pipeline to run in both desktop and SSH-only environments.

#### 3.2 Create the disk and launch QEMU

A qcow2 disk is created (default 100GB). QEMU is launched with direct kernel boot — instead of booting from the ISO's bootloader, we pass the extracted kernel and initramfs directly:

```
qemu-system-x86_64 \
  -enable-kvm -m 8192 -smp 4 -cpu host \
  -drive file=build/bcm-headnode.qcow2,format=qcow2,if=virtio \
  -drive format=raw,media=cdrom,readonly=on,file=build/bcm-autoinstall.iso \
  -drive file=build/.bcm-init.img,format=raw,if=virtio \
  -kernel build/.bcm-kernel \
  -initrd build/.bcm-rootfs-auto.cgz \
  -append "dvdinstall nokeymap root=/dev/ram0 rw ramdisk_size=1000000 ... net.ifnames=0 biosdevname=0 console=ttyS0,115200" \
  -netdev socket,id=intnet,listen=:31337 \
  -device virtio-net-pci,netdev=intnet,mac=BC:24:11:7F:33:7C \
  -netdev user,id=extnet,hostfwd=tcp::10022-:22,hostfwd=tcp::10443-:443 \
  -device virtio-net-pci,netdev=extnet,mac=BC:24:11:ED:21:50 \
  -serial file:logs/bcm-serial.log \
  -pidfile build/.bcm-qemu.pid \
  -daemonize -boot d
```

Key points:
- **Direct kernel boot** (`-kernel` + `-initrd` + `-append`): Bypasses the ISO bootloader entirely, which is more reliable and faster. The `dvdinstall` parameter tells the BCM installer to look for packages on the CD-ROM.
- **Two NICs**: eth0 on the socket network (`:31337` — BCM listens, compute nodes connect), eth1 on user-mode NAT with port forwards.
- **Config drive**: Attached as the third virtio disk so the auto-install script can read the password.
- **Serial logging**: All console output goes to `logs/bcm-serial.log` for debugging.
- **Daemonize**: QEMU runs in the background; Ansible polls the PID.

#### 3.3 Wait for install completion

Ansible polls the QEMU PID every 15 seconds for up to 90 minutes. When the auto-install script calls `poweroff`, the QEMU process exits, and Ansible detects this by checking `kill -0 $PID`. If the PID disappears, the install is complete.

### Phase 2 — Boot from installed disk

#### 3.4 Launch from disk

Any lingering QEMU process is killed. A fresh QEMU instance is launched with almost the same parameters, but:
- No `-kernel`, `-initrd`, or `-append` — the VM boots from the qcow2 disk's installed bootloader
- `-boot c` instead of `-boot d` — boot from disk, not CD-ROM
- No ISO or config drive attached

#### 3.5 Wait for SSH

Ansible polls `sshpass -p <password> ssh -p 10022 root@localhost "echo ok"` every 5 seconds for up to 5 minutes. The port forward (host 10022 → guest 22) was set up in the QEMU command line.

#### 3.6 Wait for cmfirstboot

On first boot after installation, BCM runs `cmfirstboot` — a lengthy systemd service that finalizes cluster configuration, generates certificates, starts services, and provisions the default software image. Ansible polls `systemctl is-active cmfirstboot` via SSH. While it returns `active` or `activating`, we keep waiting (up to 10 minutes with 10-second intervals).

After cmfirstboot settles, Ansible also waits for a "clean shell" — the BCM MOTD can be noisy during initialization, so we send `echo CLEAN` and verify the output is exactly `CLEAN` to confirm the SSH session is stable.

#### 3.7 Wait for BCM services (cmd + cmsh)

The two critical BCM services are:
- **cmd** — the Bright Cluster Manager daemon (the core management service)
- **cmsh** — the cluster management shell (the CLI tool that talks to cmd)

Ansible polls both every 5 seconds for up to 5 minutes:
- `systemctl is-active cmd` must return `active`
- `cmsh -c 'device; list'` must succeed (exit code 0)

Only when both are ready does the stage complete. At this point, BCM is fully operational: DHCP, DNS, NFS, PXE, and cluster management are all running.

---

## 4. Stage 3 — Kairos Build

**Role:** `roles/kairos_build/tasks/main.yml`  
**Produces:** `build/palette-edge-installer.iso`, `build/kairos-disk.raw`, `build/kairos-disk.raw.sha256`  
**Duration:** ~10 minutes  
**Note:** This stage can run in parallel with Stage 2 (bcm-vm) since it has no dependency on BCM being online.

### What this stage does

This stage builds a Kairos edge OS image using Spectro Cloud's CanvOS build system, then converts the ISO into a raw disk image that can be written directly to a compute node's disk via `dd`. The raw disk approach is used instead of PXE-booting the ISO because it produces a fully installed system in one step, with all partitions, bootloader, and configuration pre-baked.

### Step-by-step

#### 4.1 Clone CanvOS

If the `CanvOS/` directory doesn't exist, the Spectro Cloud CanvOS repository is cloned from GitHub. This repository contains the Earthly-based build system for creating Kairos-based edge OS images.

#### 4.2 Generate the .arg file

The file `files/canvos/.arg.template` is a Jinja2 template that produces the `.arg` file CanvOS needs. It sets:
- `CUSTOM_TAG`: `bcm-test`
- `IMAGE_REGISTRY`: `ttl.sh` (a temporary container registry)
- `OS_DISTRIBUTION`: `ubuntu`, `OS_VERSION`: `22.04`
- `K8S_DISTRIBUTION`: `k3s`
- `ISO_NAME`: `palette-edge-installer`
- `ARCH`: `amd64`

#### 4.3 Copy overlay files

The `files/canvos/overlay/` directory is copied into `CanvOS/overlay/`. These are files that get baked into the Kairos image:
- `etc/network/interfaces.d/ifcfg-eth0` — DHCP configuration for eth0
- `etc/systemd/system/bcm-compat-fixes.service` — Runs BCM compatibility fixes on every boot
- `usr/bin/bcm-compat-fixes.sh` — Ensures hostname matches `/etc/hostname`, fixes `systemd-resolved` hook (changes `return` to `exit 0`), fixes dead `resolv.conf` symlinks
- `etc/systemd/system/stylus-agent.service.d/bcm-sync.conf` — Drop-in that runs `bcm-sync-userdata.sh` before stylus-agent starts
- `usr/bin/bcm-sync-userdata.sh` — Detects Palette registration mode, seeds userdata from `/oem/99_userdata.yaml`, syncs hostname to Palette edge site name

#### 4.4 Patch the Earthfile and Dockerfile

Two patches are applied to the CanvOS build configuration:

1. **Earthfile**: The `apt-get install` line is modified to add `wget`, `ifupdown`, and `nfs-common` — packages needed for BCM integration (ifupdown for `/etc/network/interfaces` support, nfs-common for mounting BCM NFS exports). A dracut config is also added to skip the `nfit` module (avoids build failures on systems without NVDIMM support).

2. **Dockerfile**: Lines are added to copy `bcm-compat-fixes.sh` and `bcm-sync-userdata.sh` into the image and make them executable.

#### 4.5 Run the CanvOS build

```
cd CanvOS && ./earthly.sh +iso --ARCH=amd64
```

This runs Earthly (a CI/CD tool similar to Dockerfile + Makefile) which:
- Builds a container image based on Ubuntu 22.04 with Kairos framework, k3s, and the Palette stylus agent
- Pushes the container image to `ttl.sh` (temporary registry)
- Generates a bootable ISO from the container image

The resulting ISO is copied to `build/palette-edge-installer.iso`. This step can take 5–10 minutes depending on network speed and Docker cache state.

#### 4.6 Generate an SSH key pair

An ed25519 SSH key pair is generated (`build/bcm-kairos-key` + `.pub`). This key is used for authenticated communication between the Kairos compute node and the BCM head node — the private key is baked into the Kairos cloud-config, and the public key is added to BCM's `authorized_keys` during deployment.

#### 4.7 Render the cloud-config

The template `roles/kairos_build/templates/cloud-config.yaml.j2` is rendered to `build/cloud-config.yaml`. This is a Kairos cloud-config that controls the node's behavior at install time and on every subsequent boot. Key sections:

- **Install directives**: `auto: true` and `poweroff: true` — the Kairos agent will install automatically and power off when done.
- **Stylus (Palette agent) configuration**: Palette endpoint URL, edge host token, and project UID for cluster registration.
- **User setup**: Creates a `kairos` user with sudo access and password authentication enabled.
- **Boot stages** (run on every boot):
  1. Sets the kairos user password
  2. Enables SSH password auth and disables fail2ban
  3. Installs the BCM SSH private key to `/var/lib/bcm/bcm-key`
  4. Runs BCM integration logic:
     - Waits for network connectivity to the BCM head node (up to 5 minutes, pinging `10.141.255.254`)
     - Queries BCM's cmsh for the node's registered name based on its MAC address
     - Sets the hostname to match BCM's node name
     - Writes a Palette site name config (`/oem/91_palette_name.yaml`) so the Palette dashboard shows the BCM node name
     - Retrieves BCM's root SSH public key and adds it to `authorized_keys` (enables BCM to SSH into the compute node)
     - Sets the node's install mode to `NOSYNC` in BCM (prevents BCM from trying to re-image the node)
     - Mounts the BCM default-image via NFS
     - Copies the cmd daemon config and node certificates
     - Launches the BCM `cmd` daemon in a chroot of the mounted NFS image (this makes the Kairos node report back to BCM as a managed compute node)

#### 4.8 Create the user-data image

A 4MB FAT32 image labeled `CIDATA` is created and the cloud-config is copied into it as `user-data`. This image is attached as a secondary drive when QEMU runs the Kairos installer.

#### 4.9 Run kairos-agent install in QEMU

A blank 80GB raw disk is created with `truncate -s 81920M`. QEMU is launched headless with SeaBIOS (the default QEMU BIOS, not UEFI):

```
qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 2 -cpu host -display none \
  -drive if=virtio,format=raw,media=disk,file=build/kairos-disk.raw \
  -drive if=virtio,format=raw,readonly=on,file=build/userdata.img \
  -drive format=raw,media=cdrom,readonly=on,file=build/palette-edge-installer.iso \
  -boot d -daemonize
```

**Why SeaBIOS?** Kairos-agent detects the firmware type and installs the appropriate bootloader. With SeaBIOS, it installs GRUB-pc (BIOS MBR bootloader), which makes the raw image bootable on both BIOS and EFI systems. Using OVMF (UEFI) would produce an EFI-only image.

After QEMU boots, commands are sent via the serial console socket using `nc`:
1. Mount the user-data drive and copy the cloud-config to `/oem/90_custom.yaml` and `/tmp/99_bcm.yaml`
2. Run `kairos-agent --debug install` which partitions the raw disk, installs the OS, and configures the bootloader
3. Copy the BCM cloud-config to the OEM partition (`/oem/99_bcm.yaml`)
4. Power off

The host waits for the QEMU PID to disappear (up to 60 minutes).

#### 4.10 Fix ext4 metadata_csum

After the QEMU install completes, the raw disk's ext4 partitions are loop-mounted and the `metadata_csum` feature is removed using `tune2fs -O ^metadata_csum`. This is a GRUB compatibility fix — older GRUB versions cannot read ext4 filesystems with this feature enabled, which would cause boot failures.

#### 4.11 Patch bootargs and network config

The raw disk contains multiple squashfs-like images inside partitions (active, passive, recovery). Each one is loop-mounted and patched:
- `etc/cos/bootargs.cfg`: `net.ifnames=1` is changed to `net.ifnames=0 biosdevname=0` for stable NIC naming
- `etc/network/interfaces.d/ifcfg-eth0` is created if missing (DHCP on eth0)

This ensures every boot mode (active, passive, recovery) uses `eth0` instead of unpredictable interface names.

#### 4.12 Set GRUB timeout

The GRUB config on the raw disk is patched to set `timeout=5` (5 seconds). This prevents the GRUB menu from waiting indefinitely for user input during unattended boots.

#### 4.13 Trim and checksum

`fallocate --dig-holes` converts zero-filled regions of the raw file into sparse holes, dramatically reducing actual disk usage (the 80GB file may only use 3–5GB of real space). A SHA256 checksum is generated for integrity verification.

---

## 5. Stage 4 — Deploy DD

**Role:** `roles/deploy_dd/tasks/main.yml`  
**Templates:** `deploy-dd.sh.j2`, `install-kairos.sh.j2`  
**Duration:** ~3 minutes  

### What this stage does

This stage uploads the Kairos raw disk image to the BCM head node, configures BCM to provision compute nodes with a custom installer image that writes Kairos to disk via `dd`, and sets up all the supporting infrastructure (HTTP server, PXE boot, node registration, NFS exports, DHCP, rsyncd).

### Step-by-step

All operations are performed by `deploy-dd.sh`, which runs on the host and executes commands on BCM via SSH (`sshpass -p <password> ssh -p 10022 root@localhost`).

#### 5.1 Wait for BCM readiness

The script verifies SSH connectivity, then waits for:
- `cmfirstboot` to finish (polls `systemctl is-active cmfirstboot`)
- A clean shell (sends `echo CLEAN`, verifies output)
- cmd service active and cmsh responsive (polls every 5s, 5-minute timeout)

#### 5.2 Configure DNS forwarders

Sets the BCM cluster's nameserver to the QEMU DNS forwarder (`10.0.2.3`) via cmsh, then restarts the `named` service. This allows compute nodes to resolve external DNS names through the BCM head node.

```
echo -e 'partition\nuse base\nset nameservers 10.0.2.3\ncommit' | cmsh
systemctl restart named
```

#### 5.3 Enable IP forwarding and NAT

Compute nodes are on the internal network (10.141.0.0/16) with no direct internet access. BCM acts as their gateway:

```
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
```

This persists the sysctl setting and adds an iptables MASQUERADE rule so traffic from the internal network is NAT'd through eth1 to the QEMU user-mode NAT, which provides internet access.

#### 5.4 SSH key exchange

The ed25519 key pair generated during Stage 3 is distributed:
- The public key is added to BCM's `/root/.ssh/authorized_keys`
- The private key was already baked into the Kairos cloud-config

This enables passwordless SSH from Kairos nodes to BCM for cmd integration.

#### 5.5 Configure NFS exports

Four NFS exports are added to BCM's `/etc/exports`:
- `/cm/images/default-image` — BCM's default software image (Kairos nodes mount this to run the cmd daemon in a chroot)
- `/cm/shared` — shared storage
- `/cm/images/kairos-installer` — the installer image (used during PXE boot)

All exports use `no_subtree_check`, `no_root_squash`, and `async` for performance.

#### 5.6 Fix DHCP configuration

Two DHCP adjustments:
1. Change `not authoritative` to `authoritative` in `/etc/dhcpd.conf` — this makes BCM the definitive DHCP server on the network, preventing delays when compute nodes request addresses.
2. Adjust the DHCP pool range to exclude BCM's own IP. If BCM is at `10.141.255.254`, the pool end becomes `10.141.255.253`.

DHCP is restarted after these changes.

#### 5.7 Configure rsyncd

An rsyncd configuration is written with two modules:
- `[kairos-installer]` → `/cm/images/kairos-installer`
- `[default-image]` → `/cm/images/default-image`

The rsync service is enabled and restarted. This allows compute nodes to sync the installer image during PXE boot.

#### 5.8 Compress and upload the raw image

The 80GB raw disk image is compressed with lz4 (fast compression, suitable for streaming decompression):
```
lz4 -f build/kairos-disk.raw build/kairos-disk.raw.lz4
```

The compressed file is uploaded to BCM via SCP:
```
scp -P 10022 build/kairos-disk.raw.lz4 root@localhost:/cm/shared/kairos/disk.raw.lz4
```

#### 5.9 Start the HTTP server

A systemd service (`kairos-http.service`) is created on BCM that runs a Python HTTP server on port 8888 serving `/cm/shared/kairos/`. This is how the compute node's installer will download the compressed raw image during the dd process. The script verifies the server is running by sending a HEAD request.

#### 5.10 Create the kairos-installer software image

BCM manages compute nodes using "software images" — filesystem trees that are synced to nodes. The script clones BCM's `default-image` to create `kairos-installer`:

```
cmsh -c "softwareimage; clone default-image kairos-installer; commit"
```

It then waits (up to 120 seconds) for the image filesystem to appear at `/cm/images/kairos-installer/usr`.

#### 5.11 Install the dd service into the installer image

This is the critical piece. The `install-kairos.sh` script (rendered from `install-kairos.sh.j2`) is placed into the kairos-installer image at `/usr/local/sbin/install-kairos.sh`. A systemd service (`kairos-install.service`) is created to run it on boot, after network is available, with a 10-second delay and 30-minute timeout.

The `lz4` binary is also copied into the image at `/usr/local/bin/lz4`.

DHCP configuration for both `eth0` and `ens3` is added to the image's `/etc/network/interfaces` to handle both naming schemes.

**What install-kairos.sh does** (this runs inside the compute node during PXE boot):

1. **Stage binaries to RAM** — Copies `bash`, `curl`, `lz4`, `dd`, `sync`, `sleep`, `sgdisk` and all their library dependencies to `/dev/shm/kinstall/`. This is critical because the dd operation will overwrite the filesystem these binaries live on — everything must be in RAM.

2. **Enable sysrq** — Writes `1` to `/proc/sys/kernel/sysrq` to enable magic SysRq commands for emergency poweroff.

3. **Create and exec a self-contained dd script** — A script at `/dev/shm/kinstall/run-dd.sh` is created with a shebang pointing to the RAM-resident bash (`#!/dev/shm/kinstall/bash`). The parent script then `exec`s this script, completely replacing the running process with the RAM-resident one. This script:
   - Streams the compressed image: `curl | lz4 -d | dd of=/dev/vda bs=4M oflag=direct`
   - `oflag=direct` bypasses the page cache, preventing the 80GB write from consuming all available memory
   - Runs `sgdisk -e` to fix the GPT backup header (it's at the wrong offset because the raw image was created on a different-sized disk)
   - Drops the page cache (`echo 3 > /proc/sys/vm/drop_caches`) to prevent stale writeback
   - Triggers an immediate poweroff via `echo o > /proc/sysrq-trigger` (SysRq because the filesystem is destroyed — normal `poweroff` would fail)

#### 5.12 Configure PXE boot

The PXE template is patched to use `IPAPPEND 2` instead of `IPAPPEND 3` (prevents duplicate IP assignment issues). Required syslinux modules (`menu.c32`, `libutil.c32`, `ldlinux.c32`, `libcom32.c32`) are copied to `/tftpboot/` if missing.

#### 5.13 Configure the kairos category and register node001

A BCM "category" named `kairos` is created by cloning the `default` category. It is configured with:
- `softwareimage`: `kairos-installer` (the image with the dd script)
- `installmode`: `FULL` (complete re-image on next boot)
- `newnodeinstallmode`: `FULL`
- `installbootrecord`: `yes` (write bootloader to disk)
- `kernelparameters`: `console=ttyS0,115200n8 net.ifnames=0 biosdevname=0`
- Default category for the `base` partition

The kernel version in the kairos-installer software image is detected and set in cmsh so BCM generates the correct ramdisk.

A compute node `node001` is registered in cmsh with:
- Explicit IP address: `10.141.255.10` (avoids BCM auto-assigning the gateway IP)
- MAC address: `52:54:00:00:02:01` (matches the QEMU compute VM's NIC)
- Category: `kairos`

#### 5.14 Regenerate the ramdisk

```
cmsh -c "softwareimage; use kairos-installer; createramdisk -w"
```

This generates the PXE boot ramdisk (initramfs) for the kairos-installer image. The `-w` flag means "wait until complete." After regeneration, the script re-verifies that the category's softwareimage is still set to `kairos-installer` (ramdisk generation can sometimes reset it).

---

## 6. Stage 5 — Kairos VM

**Role:** `roles/kairos_vm/tasks/main.yml`  
**Produces:** `build/kairos-compute.qcow2` (persistent disk), running Kairos VM  
**Duration:** ~10 minutes  

### What this stage does

This stage launches a compute node VM that PXE boots from the BCM head node, receives the kairos-installer image, runs the dd script to write Kairos to disk, powers off, and then reboots from the installed disk into a fully operational Kairos node with Palette agent registration.

### Step-by-step

#### 6.1 Preparation

- Any existing Kairos VM is killed (by PID file and by process name)
- `node001`'s install mode is reset to `FULL` in cmsh (in case it was changed to `NOSYNC` by a previous boot)
- A fresh qcow2 disk is created (default 80GB), deleting any existing one

#### 6.2 PXE boot

QEMU is launched with boot order `cn` (network first, then disk):

```
qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 2 -cpu host \
  -drive file=build/kairos-compute.qcow2,format=qcow2,if=virtio \
  -netdev socket,id=intnet,connect=:31337 \
  -device virtio-net-pci,netdev=intnet,mac=52:54:00:00:02:01 \
  -chardev socket,id=ser0,host=localhost,port=4321,server=on,wait=off,telnet=on,logfile=logs/kairos-serial.log \
  -serial chardev:ser0 \
  -boot order=cn -daemonize
```

Key differences from the BCM VM:
- **Single NIC**: Only the internal network (`connect=:31337` — connects to BCM's socket listener). No direct internet access; routes through BCM's NAT.
- **PXE boot**: `-boot order=cn` tries network boot first. The NIC's PXE ROM requests an IP from BCM's DHCP, gets a TFTP boot path, downloads the PXE config, kernel, and ramdisk, and boots into the kairos-installer image.
- **MAC address**: `52:54:00:00:02:01` matches the registered `node001` in BCM, so BCM assigns the correct IP (`10.141.255.10`) and uses the `kairos` category configuration.
- **Telnet serial console**: The serial port is exposed as a telnet socket on port 4321 for live debugging.

#### 6.3 The PXE boot and dd process (what happens inside the VM)

This is orchestrated entirely by BCM and the kairos-installer image — no Ansible involvement:

1. **PXE DHCP**: The VM gets IP `10.141.255.10` from BCM's DHCP server
2. **TFTP download**: PXE downloads the kernel and ramdisk from BCM's TFTP server
3. **Boot into kairos-installer**: The node boots the BCM-provided Linux kernel and kairos-installer ramdisk
4. **Network init**: The installer image configures eth0 via DHCP
5. **kairos-install.service starts**: After a 10-second delay, the systemd service runs `install-kairos.sh`
6. **Binaries staged to RAM**: bash, curl, lz4, dd, sgdisk, and their libraries are copied to `/dev/shm/kinstall/`
7. **exec to RAM-resident script**: The process replaces itself with the RAM-based script
8. **dd pipeline**: `curl http://10.141.255.254:8888/disk.raw.lz4 | lz4 -d | dd of=/dev/vda bs=4M oflag=direct`
9. **GPT fix**: `sgdisk -e /dev/vda` relocates the backup GPT header to the correct position
10. **Cache drop**: `echo 3 > /proc/sys/vm/drop_caches`
11. **SysRq poweroff**: `echo o > /proc/sysrq-trigger` — the VM powers off immediately

#### 6.4 Wait for poweroff

Ansible polls the QEMU PID every 10 seconds for up to 30 minutes. When the dd script triggers SysRq poweroff, the QEMU process exits.

#### 6.5 Reboot from disk

A new QEMU instance is launched with `-boot c` (disk only, no PXE):

```
qemu-system-x86_64 \
  ... (same params as above) ...
  -boot c
```

The qcow2 disk now contains the Kairos raw image that was written by dd. The VM boots into GRUB, loads the Kairos kernel, and starts the OS.

#### 6.6 Wait for Kairos boot

The script `wait-kairos-boot.sh.j2` runs on the host and checks for the compute node's availability by SSHing through BCM as a jump host:

1. Checks BCM's ARP table for the compute node's MAC address to find its IP
2. Attempts SSH to the compute node (via BCM) and checks for `/etc/kairos-release`
3. Retries every 10 seconds for up to 10 minutes

During this time, the Kairos cloud-config boot stages are executing:
- Setting user passwords
- Enabling SSH
- Querying BCM for the node name
- Setting hostname
- Configuring Palette site name
- Exchanging SSH keys with BCM
- Setting NOSYNC install mode
- Mounting BCM's NFS image
- Starting the cmd daemon in a chroot

---

## 7. Stage 6 — Validate

**Role:** `roles/validate/tasks/main.yml`  
**Template:** `roles/validate/templates/validate.sh.j2`  
**Duration:** ~15 seconds  

### What this stage does

Runs a comprehensive health check across both the BCM head node and the Kairos compute node, producing a PASS/WARN/FAIL report. The validation script connects to BCM via SSH and reaches the Kairos node through BCM as a jump host.

### Checks performed

#### BCM Head Node (18 checks)

**Connectivity:**
- SSH access to BCM on the forwarded port

**Services:**
- `cmd` systemd service is active
- `dhcpd` is active (DHCP server for compute nodes)
- `named` is active (DNS server)
- `nfs-server` is active
- rsyncd listening on port 873
- HTTP server listening on port 8888 (Kairos image server)

**Network:**
- Ping localhost
- eth0 has the correct internal IP (10.141.255.254)
- eth1 has an external IP (any — assigned by QEMU DHCP)
- IP forwarding is enabled (`/proc/sys/net/ipv4/ip_forward` = 1)

**DNS & Internet:**
- External DNS resolution (`host google.com`)
- Internet access (HTTPS to google.com returns 200 or 301)

**Cluster state:**
- cmsh `device; list` shows head node as UP
- `node001` is registered
- `node001` has correct IP
- `node001` category is `kairos`
- kairos-installer image directory exists
- Kairos raw image (`disk.raw.lz4`) exists

#### Kairos Compute Node (21 checks)

The script first discovers the Kairos node's IP from BCM's ARP table (falling back to cmsh), then tries SSH both as root (key-based, via the BCM SSH key exchange) and as kairos user (password-based).

**OS:**
- OS version (PRETTY_NAME from `/etc/os-release`)
- Kairos version (from `/etc/kairos-release`)
- kairos-agent version
- Kernel version

**Network:**
- IP address assigned
- Default gateway present
- DNS resolver configured
- External DNS resolution (ping google.com)
- Internet access (HTTPS to google.com)

**Services:**
- stylus-agent (Palette edge agent) is active
- Palette registration attempt logged in journalctl

**Boot:**
- `net.ifnames=0` present in `/proc/cmdline`
- Kairos boot chain markers (`rd.immucore` or `rd.cos`) in cmdline

**Disk / Partitions:**
- COS_OEM partition exists (OEM configuration)
- COS_RECOVERY partition exists (recovery image)
- COS_STATE partition exists (active/passive OS images)
- COS_PERSISTENT partition exists (persistent user data)
- Root filesystem is mounted read-only (immutable)
- Disk free space reported

**Cloud Config:**
- OEM yaml files exist in `/oem/`

### Output format

Each check prints `[PASS]`, `[WARN]`, or `[FAIL]` with a description and optional detail. The final line summarizes:
```
PASS: 35/39  WARN: 3/39  FAIL: 1/39
```

The script exits with code 1 if any checks FAIL, which causes the Ansible playbook to fail.

---

## 8. Network Topology

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Host Machine                                  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │              Internal Network (QEMU socket :31337)            │    │
│  │                                                               │    │
│  │  ┌─────────────────────┐      ┌──────────────────────────┐   │    │
│  │  │  BCM Head Node       │      │  Kairos Compute Node      │   │    │
│  │  │  eth0: 10.141.255.254│◄────►│  eth0: 10.141.255.10      │   │    │
│  │  │                      │      │  (DHCP from BCM)           │   │    │
│  │  │  Services:           │      │                            │   │    │
│  │  │  - DHCP (dhcpd)      │      │  Services:                 │   │    │
│  │  │  - DNS (named)       │      │  - stylus-agent (Palette)  │   │    │
│  │  │  - PXE/TFTP          │      │  - cmd (BCM chroot)        │   │    │
│  │  │  - NFS               │      │  - k3s                     │   │    │
│  │  │  - rsyncd            │      │                            │   │    │
│  │  │  - HTTP :8888        │      └──────────────────────────┘   │    │
│  │  │  - cmd               │                                     │    │
│  │  └──────────┬───────────┘                                     │    │
│  │             │                                                  │    │
│  └─────────────┼──────────────────────────────────────────────────┘    │
│                │                                                      │
│  ┌─────────────┼──────────────────────────────────────────────────┐    │
│  │  External   │  Network (QEMU user-mode NAT)                    │    │
│  │             │                                                  │    │
│  │  BCM eth1: 10.0.2.15 (DHCP from QEMU)                        │    │
│  │  Gateway: 10.0.2.2 (QEMU)                                     │    │
│  │  DNS: 10.0.2.3 (QEMU)                                         │    │
│  │                                                                │    │
│  │  IP forwarding + iptables MASQUERADE:                          │    │
│  │    Compute nodes → BCM eth0 → NAT → eth1 → Internet           │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  Port Forwards (host → BCM):                                         │
│    localhost:10022 → BCM:22   (SSH)                                  │
│    localhost:10443 → BCM:443  (HTTPS / BCM Web UI)                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Why two separate networks?

BCM's DHCP server on the internal network must be the only DHCP server visible to compute nodes. If both BCM and QEMU's user-mode NAT responded to DHCP requests, compute nodes could get the wrong IP and gateway. The socket-based L2 network provides a clean, isolated broadcast domain for provisioning, while the user-mode NAT provides internet access exclusively through BCM's IP forwarding.
