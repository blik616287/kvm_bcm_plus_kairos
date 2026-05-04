# BCM + Kairos Pipeline — Technical Deep Dive

Engineer-level walkthrough of every stage: what runs, what it touches, and why. The README is the user-facing introduction; this document is the complement an engineer consults before modifying a role.

The pipeline supports two deployment modes from the same roles:

- **Remote BCM** (primary, customer sites) — deploy Kairos to bare-metal compute nodes managed by an already-running BCM head node, reached over SSH (optionally via a jumphost). Only stages 3, 4, and 6 run.
- **Local KVM** (dev / demo / regression) — stand up BCM + Kairos compute node entirely in local QEMU VMs. All six stages run.

Where a stage, role, or code path is mode-specific it is called out explicitly.

## Table of Contents

1. [Prerequisites & shared machinery](#1-prerequisites--shared-machinery)
2. [`make discover` — remote BCM discovery](#2-make-discover--remote-bcm-discovery)
3. [Stage 1 — BCM Prepare *(local-KVM only)*](#3-stage-1--bcm-prepare-local-kvm-only)
4. [Stage 2 — BCM VM *(local-KVM only)*](#4-stage-2--bcm-vm-local-kvm-only)
5. [Stage 3 — Kairos Build](#5-stage-3--kairos-build)
6. [Stage 4 — Deploy DD](#6-stage-4--deploy-dd)
7. [Stage 5 — Kairos VM *(local-KVM only)*](#7-stage-5--kairos-vm-local-kvm-only)
8. [Stage 6 — Validate](#8-stage-6--validate)
9. [Cross-cutting design points](#9-cross-cutting-design-points)
10. [Network topology](#10-network-topology)

---

## 1. Prerequisites & shared machinery

### 1.1 System packages

`make install-deps` invokes `playbooks/install-dependencies.yml` (role: `roles/dependencies`) which detects the OS family (Debian/Ubuntu vs Fedora/RHEL) and installs via `apt` or `dnf`:

| Package | Purpose |
|---------|---------|
| `qemu-system-x86`, `qemu-utils`, `ovmf` | KVM virtualization + **OVMF UEFI firmware** required for Kairos build |
| `docker.io` / `docker` | Earthly uses Docker to build the CanvOS container and Kairos ISO |
| `sshpass` | Non-interactive password auth to BCM (used by every role that SSHes to BCM) |
| `xorriso` | ISO remastering (local-KVM bcm_prepare) |
| `p7zip-full` / `p7zip` | Extract the original BCM ISO (local-KVM bcm_prepare) |
| `lz4` | Fast compression of the 80 GB Kairos raw image before SCP to BCM |
| `jq` | JSON parsing in build/validation scripts |
| `mtools`, `dosfstools` | Create FAT32 images (CIDATA cloud-init, BCM config drive) |
| `cpio`, `gzip` | Repack BCM initramfs (local-KVM bcm_prepare) |
| `curl` | Download BCM ISO from JFrog (local-KVM bcm_prepare) |
| `nfs-common` / `nfs-utils` | NFS mount support (kairos_build bakes this into image too) |
| `gdisk` | `sgdisk -e` to fix GPT backup header after dd (install-kairos.sh) |
| `e2fsprogs` | `tune2fs -O ^metadata_csum` for GRUB compatibility in kairos_build |
| `socat` | Serial console / socket helper |

`make setup` verifies these are present without installing. The `make setup` check also requires `inventory/group_vars/all.yml` to exist.

### 1.2 Single source of truth for configuration

`inventory/group_vars/all.yml` (gitignored) holds every site- and run-specific value; `inventory/group_vars/all.example.yml` is the committed template and documents each variable. All playbooks run against `hosts: localhost` (`inventory/hosts.yml`). Ansible does not connect to BCM directly — every BCM-side operation is a local shell task that opens its own `sshpass | ssh` connection.

### 1.3 Per-run SSH config + jumphost ProxyCommand

Three places build their own per-run SSH config file in `build/` or the repo root and route all traffic through it:

- `roles/deploy_dd/templates/deploy-dd.sh.j2` → `build/.bcm-ssh-config` (stage 4)
- `roles/validate/templates/validate.sh.j2` → `build/.bcm-ssh-config` (stage 6)
- `playbooks/discover-bcm.yml` → `.discover-ssh-config` (top-level, cleaned up at end)

The template is:

```
Host bcm-target
    HostName {{ bcm_ssh_host }}
    Port {{ bcm_ssh_port }}
    User root
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
{% if bcm_ssh_proxy_jump %}
    ProxyCommand ssh -i <expanded bcm_ssh_proxy_key> ... -W %h:%p <bcm_ssh_proxy_jump>
{% endif %}
```

Every SSH/SCP call then takes the form `sshpass -p $BCM_PASSWORD ssh -F $SSH_CONFIG bcm-target …` (or `scp -O -F $SSH_CONFIG …`). The `-F` flag confines OpenSSH to *only* the per-run config — it does not read `~/.ssh/config`. Jumphost auth uses the key at `bcm_ssh_proxy_key` (which may start with `~` — the template pre-expands `~` via `lookup('env','HOME')` because OpenSSH doesn't always expand `~` inside `ProxyCommand`). BCM auth is still by password via `sshpass -p`.

Any new code that needs to talk to BCM must reuse this pattern (`-F <config> bcm-target`) rather than shelling out with ad-hoc `-J` flags — otherwise it silently ignores the jumphost and breaks customer deploys.

---

## 2. `make discover` — remote BCM discovery

**Playbook:** `playbooks/discover-bcm.yml`
**Produces:** `bcm-discovery-<bcm-hostname>.yml` (gitignored) + inline TTY report
**Duration:** ~10 seconds

Not a pipeline stage — a precursor for remote-BCM deploys. Prompts interactively for BCM host/port/user/password and optional jumphost, writes a per-run SSH config (as above), then `ssh bcm-target bash -s <<REMOTE` to run a single remote script that collects:

- `dpkg -l cm-config` → BCM version
- `hostname` → BCM hostname (used for the output filename)
- `cmsh -c 'network; list'` → finds the "Internal" network, reads its base address and netmask bits to get the provisioning CIDR
- Discovers which BCM interface holds an IP inside that CIDR by matching IP against interface, not by NIC name (customer BCMs use `ens*`/`enp*`, not `eth*`)
- Default route → external interface + gateway, `/etc/resolv.conf` DNS, `cmsh partition base nameservers`
- `systemctl is-active` for `cmd`, `dhcpd`, `named`, `nfs-server`
- `cmsh category; list -f name` → existing categories (with whitespace trimmed; names can contain spaces like `"Partner Lab"`, so per-field `get` calls are used rather than parsing column-aligned `list` output)
- `cmsh softwareimage; list -f name` → existing software images
- `cmsh device; list` filtered to `PhysicalNode|HeadNode` rows → node name, MAC, IP, category, software image (one per-field `get` call per field to survive whitespace-containing category names)
- Installed kernel version (`/cm/images/default-image/boot/vmlinuz-*`)
- Free space on `/cm/shared`, `ip_forward` status

The output file is a commented-out YAML block that can be pasted directly into `all.yml`, with the safe defaults `bcm_manage_dns: false` and `bcm_manage_cluster_defaults: false` pre-set and the SSH transport (host/port/proxy_jump/proxy_key) preserved verbatim from the prompts.

---

## 3. Stage 1 — BCM Prepare *(local-KVM only)*

**Role:** `roles/bcm_prepare/tasks/main.yml`
**Produces:** `build/bcm-autoinstall.iso`, `build/.bcm-kernel`, `build/.bcm-rootfs-auto.cgz`, `build/.bcm-init.img`
**Duration:** ~2 minutes
**Mode:** local-KVM only. Skip entirely if you have a real BCM.

Takes the stock BCM 11.0 installer ISO and turns it into an unattended auto-install ISO by injecting a systemd service into the installer's initramfs.

### 3.1 Download the BCM ISO from JFrog

Fetched with a bearer token to `dist/bcm-*.iso`; skipped if the file already exists:

```
curl --fail -L -H "Authorization: Bearer $jfrog_token" \
  -o dist/<iso_filename> \
  "https://<jfrog_instance>/artifactory/<jfrog_repo>/<iso_filename>"
```

### 3.2 Extract kernel + rootfs

ISO is loop-mounted read-only. `boot/kernel` is saved as `build/.bcm-kernel`; `boot/rootfs.cgz` is extracted (`gunzip | cpio -iumd`) into a working directory.

### 3.3 Inject the cluster-config Jinja template

`roles/bcm_prepare/files/build-config.xml.tpl` is a ~4500-line template describing the whole BCM cluster config (networks, DHCP ranges, interface assignments, package lists, hostname, timezone). Copied into the rootfs at `/cm/build-config.xml.tpl`. Python `jinja2` + `pyyaml` are installed into the rootfs via chroot pip3 so the auto-install script can render the template at boot time against the runtime inventory values.

### 3.4 Inject `bcm-autoinstall.sh`

`roles/bcm_prepare/templates/bcm-autoinstall.sh.j2` is rendered with inventory values and placed at `/usr/local/bin/bcm-autoinstall.sh`. On BCM's first boot, this script:

1. Configures eth0 static IP (`$bcm_internal_ip/$bcm_internal_netmask`) and DHCPs eth1 for NAT egress.
2. Renders `build-config.xml` from the template with `internalnet` = `$bcm_internal_cidr` and `externalnet` = 10.0.2.0/24 (QEMU user-mode).
3. Waits for the BCM installer's HTTP server (polls `/var/www/htdocs/content/masterdisklayouts/master-one-big-partition.xml`, up to 120 s).
4. Finds install media (`/dev/sr0`, `/dev/sr1`, or `findfs LABEL=BCMINSTALLERHEAD` as fallback).
5. Runs `yes | perl ./cm-master-install --config /cm/build-config.xml --mountpath /mnt/cdrom --password <bcm_password>` — the real BCM installer.
6. Post-install GRUB patching: activates LVM, locates the installed root partition, injects `net.ifnames=0 biosdevname=0` into `/etc/default/grub` and `grub.cfg` so the installed system uses stable NIC names (every subsequent role assumes eth0/eth1).
7. `poweroff` — signals Ansible that Phase 1 is done.

### 3.5 Systemd unit + service hookup

`roles/bcm_prepare/files/bcm-autoinstall.service` is copied into the rootfs. It `Conflicts=` the interactive (text + graphical) installers and getty services, runs as `Type=oneshot` with no timeout, and is symlinked into `multi-user.target.wants`. The interactive installers and getty units are disabled/masked so nothing else grabs the console.

### 3.6 Repack + remaster

```
find . | cpio -o -H newc | gzip --fast > build/.bcm-rootfs-auto.cgz
```

Original ISO is extracted with `7z`. Patched rootfs replaces the original. Both GRUB and isolinux configs are modified: timeout set to 0/1, default entry switched to text installer, kernel command line gets `net.ifnames=0 biosdevname=0 console=ttyS0,115200 console=tty0`. MBR first 432 bytes are kept as the hybrid MBR. `xorriso -as mkisofs` rebuilds with both BIOS (isolinux) and EFI (efi.img) boot support.

### 3.7 Config drive

A 4 MB FAT32 image labeled `BCMCONFIG` with `password.txt` is created via `dd` + `mkfs.vfat` + `mcopy`. Attached to the VM as a secondary virtio disk so the password isn't baked into the ISO.

---

## 4. Stage 2 — BCM VM *(local-KVM only)*

**Role:** `roles/bcm_vm/tasks/main.yml`
**Produces:** `build/bcm-headnode.qcow2` + a running BCM VM
**Duration:** 60–90 minutes
**Mode:** local-KVM only.

Two-phase QEMU install: boot from the remastered ISO, wait for auto-install + poweroff, then relaunch booting from the installed disk and wait for BCM services to come up.

### 4.1 Display detection

Tests for `$DISPLAY`/`$WAYLAND_DISPLAY` + `xdpyinfo`/`xset`. Chooses `-display gtk` if a display server is reachable, otherwise `-display none`. Lets the pipeline run both on a desktop and over SSH.

### 4.2 Phase 1 — ISO install

qcow2 disk is created (default 100 GB). QEMU is launched with **direct kernel boot** (not the ISO bootloader):

```
qemu-system-x86_64 \
  -enable-kvm -m $bcm_vm_ram -smp $bcm_vm_cpus -cpu host \
  -drive file=build/bcm-headnode.qcow2,format=qcow2,if=virtio \
  -drive format=raw,media=cdrom,readonly=on,file=build/bcm-autoinstall.iso \
  -drive file=build/.bcm-init.img,format=raw,if=virtio \
  -kernel build/.bcm-kernel \
  -initrd build/.bcm-rootfs-auto.cgz \
  -append "dvdinstall nokeymap root=/dev/ram0 rw ramdisk_size=1000000 … net.ifnames=0 biosdevname=0 console=ttyS0,115200" \
  -netdev socket,id=intnet,listen=:31337 \
  -device virtio-net-pci,netdev=intnet,mac=BC:24:11:7F:33:7C \
  -netdev user,id=extnet,hostfwd=tcp::${bcm_ssh_port}-:22,hostfwd=tcp::${bcm_https_port}-:443 \
  -device virtio-net-pci,netdev=extnet,mac=BC:24:11:ED:21:50 \
  -serial file:logs/bcm-serial.log -pidfile build/.bcm-qemu.pid -daemonize -boot d
```

Key points:
- Direct `-kernel`/`-initrd`/`-append` — bypasses the ISO bootloader; `dvdinstall` tells the installer to look on CD-ROM.
- eth0 on a QEMU **socket network** listening on `:31337` (compute VM will `connect=:31337`); eth1 on user-mode NAT with host port-forwards for SSH + HTTPS.
- Config drive is the third virtio disk.
- Serial to `logs/bcm-serial.log` for tailing (`make bcm-serial`).

Ansible polls the PID every 15 s for up to 90 minutes; when `bcm-autoinstall.sh` calls `poweroff`, the process exits and install is complete.

### 4.3 Phase 2 — Boot from disk

Lingering QEMU killed (`kill` by PID file + pgrep by VM name). New QEMU launched with almost the same args but no `-kernel`/`-initrd`/`-append`, no ISO, no config drive, `-boot c`.

Ansible then sequentially waits for:

1. SSH on host:$bcm_ssh_port (polled every 5 s for up to 5 min).
2. `cmfirstboot` service finishes (polls `systemctl is-active cmfirstboot`, up to 10 min; BCM's first-boot service generates certificates, starts services, provisions the default software image).
3. A "clean shell" — send `echo CLEAN`, verify output is exactly `CLEAN`. BCM's MOTD prints `cmfirstboot is still in progress` during init; we filter it out but also need stable stdout.
4. `cmd` active + `cmsh -c 'device; list'` exits 0 (5 s poll, 5 min timeout).

At the end, BCM is fully operational: DHCP, DNS, NFS, PXE, cluster management all up.

---

## 5. Stage 3 — Kairos Build

**Role:** `roles/kairos_build/tasks/main.yml`
**Produces:** `build/palette-edge-installer.iso`, `build/{{ kairos_profile }}-disk.raw`, `build/{{ kairos_profile }}-disk.raw.sha256`, `build/bcm-kairos-key{,.pub}` (artifact name namespaced by `kairos_profile`, default `default-kairos`)
**Duration:** ~30 minutes (10–15 min CanvOS build + ~15 min OVMF kairos-agent install)
**Mode:** both (runs in parallel with stage 2 in local-KVM mode — no dependency on BCM being up)

Builds a Kairos edge OS image with CanvOS (Spectro Cloud's Earthly-based builder), then uses a local QEMU VM under **OVMF (UEFI)** to run `kairos-agent install` onto a blank raw disk. The resulting raw disk is a fully-installed Kairos system with GRUB-EFI in its ESP, ready to be `dd`'d onto a target node's OS disk.

### 5.1 Clone CanvOS

If `CanvOS/` doesn't exist, clone `https://github.com/spectrocloud/CanvOS.git`. The directory is gitignored — `make clean-canvos` removes it to force a fresh clone.

### 5.2 Generate the `.arg` file

`files/canvos/.arg.template` is a one-line Jinja2 loop that emits one `KEY=VALUE` per entry of `kairos_canvos_args_effective` — a dict computed at task time as `kairos_canvos_defaults | combine(kairos_canvos_args | default({}))`.

`roles/kairos_build/defaults/main.yml` carries the upstream-CanvOS-aligned defaults:

| Key | Default | Notes |
|-----|---------|-------|
| `CUSTOM_TAG` | `bcm-test` | image tag |
| `IMAGE_REGISTRY` | `ttl.sh` | temporary registry; override via `kairos_canvos_args.IMAGE_REGISTRY` |
| `OS_DISTRIBUTION` / `IMAGE_REPO` | `ubuntu` / `ubuntu` | set both when switching to `ubuntu-pro` |
| `OS_VERSION` | `"22.04"` | also `"20.04"`, `"24.04"` per upstream CanvOS |
| `K8S_DISTRIBUTION` | `k3s` | |
| `ISO_NAME` | `palette-edge-installer` | pipeline-load-bearing — used to find the built ISO |
| `ARCH` | `amd64` | pipeline-load-bearing — passed to `earthly.sh +iso --ARCH=` |
| `HTTPS_PROXY` / `HTTP_PROXY` | `""` | populated for proxied build environments |
| `UPDATE_KERNEL` | `"false"` | when `"true"`, CanvOS unholds kernel packages so apt upgrades pull HWE |
| `CIS_HARDENING` | `"false"` | when `"true"`, CanvOS runs `/cis-harden/harden.sh` during build |
| `CLUSTERCONFIG` | `spc.tgz` | upstream default |
| `EDGE_CUSTOM_CONFIG` | `.edge-custom-config.yaml` | upstream default |
| `FORCE_INTERACTIVE_INSTALL` | `"false"` | upstream default |
| `UBUNTU_PRO_KEY` | `""` | when set, CanvOS `pro attach`es during build then `pro detach`es post-build |

User overrides via `inventory/group_vars/all.yml`:

```yaml
kairos_canvos_args:
  OS_VERSION: "22.04"
  UPDATE_KERNEL: "true"
  CIS_HARDENING: "false"
  UBUNTU_PRO_KEY: ""
  # arbitrary new keys are forward-compatible — they're appended to .arg verbatim
```

Anything in the merged dict surfaces in `CanvOS/.arg` as `KEY=VALUE`. The role pulls `iso_name` and `arch` back out of the merged dict so the rest of the pipeline (CanvOS build, ISO copy) sees the same values rendered into `.arg`.

### 5.3 Copy the overlay

`files/canvos/overlay/` is copied onto `CanvOS/overlay/`. Three BCM-integration scripts are baked into the image at build time:

| Script | What it does |
|--------|--------------|
| `usr/bin/bcm-compat-fixes.sh` | On every boot — ensures hostname matches `/etc/hostname`, patches systemd-resolved's Kairos init hook (`return` → `exit 0`) so the hook doesn't abort, repairs dead `resolv.conf` symlinks. |
| `usr/bin/bcm-sync-userdata.sh` | Before stylus-agent — detects Palette registration mode, seeds userdata from `/oem/99_userdata.yaml`, syncs hostname into Palette edge-site name. |
| `usr/bin/palette-cleanup-stale.sh` | Before stylus-agent — the **Palette pre-registration hook**. See §9.3 for full behavior. Gates on registration mode, deletes any stale edge-host record whose UID collides with our SMBIOS-UUID-derived `edge-<uuid>`, and auto-mints a fresh `edgeHostToken` via the admin API if `palette_token` wasn't baked in. Fail-open on every error path — never blocks stylus-agent startup. |

All three are marked executable; failure to chmod is ignored (the Dockerfile patch below does it again inside the image layer).

### 5.4 Patch Earthfile and Dockerfile

- **Earthfile** — `apt-get install --no-install-recommends kbd` is replaced with `… wget ifupdown nfs-common kbd` so the image has the BCM-integration tools (NFS mount of `/cm/images`, `ifupdown` for the eth0 ifcfg patch). A dracut conf is added that sets `omit_dracutmodules+=" nfit "` to avoid dracut build failures on hosts without NVDIMM support. These are pipeline-load-bearing — they're not user-extensible.
- **Dockerfile (BCM scripts)** — inserted `COPY` + `RUN chmod +x` for the three overlay scripts so they end up at `/usr/bin/` in the image with executable bits.
- **Dockerfile (user extras, gated by `kairos_extra_apt_packages`)** — when the inventory list is non-empty, a separate `RUN apt-get update && apt-get install -y --no-install-recommends <packages>` block is appended via `blockinfile` after the BCM-scripts block. Empty list ⇒ task is skipped, Dockerfile unchanged. Going through the Dockerfile (instead of the Earthfile) keeps user packages cleanly bisected as their own layer for debugging, and avoids cache invalidation of the OS-base layer when the user list churns.

### 5.5 Run the CanvOS build

```
cd CanvOS && ./earthly.sh +iso --ARCH=amd64
```

Earthly builds a container image based on Ubuntu 22.04 with the Kairos framework, k3s, and Palette stylus agent; pushes it to `ttl.sh`; then generates a bootable ISO. Result is copied to `build/palette-edge-installer.iso`. 10–15 minutes depending on Docker cache state + network.

### 5.6 SSH key pair for BCM integration

`ssh-keygen -t ed25519 -f build/bcm-kairos-key -N "" -C "kairos-node@bcm"`. The private key is baked into the Kairos cloud-config (for the on-node BCM integration scripts); the public key is pushed to BCM's `authorized_keys` during stage 4 deploy-dd.

### 5.7 Render cloud-config.yaml

`roles/kairos_build/templates/cloud-config.yaml.j2` → `build/cloud-config.yaml`. Key sections:

- **`install:`** — `auto: true`, `poweroff: true`. The in-VM kairos-agent installs and powers off without user interaction.
- **`stylus.site:`** — `paletteEndpoint`, optional `edgeHostToken` (if `palette_token` is set), one of `projectName`/`projectUid`, optional `caCerts:` block (PEM from `palette_ca_cert`), tags marking this as a Palette control-plane node.
- **`stylus.installationMode` + `.managementMode`** — from `palette_installation_mode` + `palette_management_mode`.
- **`users:`** — creates a `kairos` user with `sudo ALL NOPASSWD` and `lock_passwd: false`.
- **`stages.initramfs:`** — if `palette_api_key` + `palette_project_uid` are set, writes `/oem/palette-admin.env` (mode 0600) with `APIKEY=`, `PROJECTUID=`, `ENDPOINT=`. This is what `palette-cleanup-stale.sh` reads.
- **`stages.boot:`** — every boot:
  1. Set the `kairos` user password to `kairos` (POC convenience; swap for a real secret in production).
  2. Write `/etc/ssh/sshd_config.d/99-kairos-test.conf` with `PasswordAuthentication yes` + `PermitRootLogin yes`; restart sshd; disable fail2ban.
  3. Install the BCM SSH key to `/var/lib/bcm/bcm-key` (0600).
  4. **BCM integration** (conditional on `bcm_ssh_key_content` being set):
     - Wait up to 5 min for network + ping to `$bcm_internal_ip`.
     - Query BCM via `cmsh device list | grep $MAC` to find this node's registered name; set hostname to match; write `/oem/91_palette_name.yaml` so the Palette dashboard matches.
     - Fetch BCM's root public key and append to `/root/.ssh/authorized_keys` (enables BCM → Kairos SSH).
     - Set the node's `installmode` to `NOSYNC` in cmsh so BCM doesn't try to re-image the freshly-installed Kairos node on next PXE.
     - NFS-mount `/cm/images/default-image` read-only at `/var/lib/cm/rootfs`. Copy `/cm/local/apps/cmd/etc` out into `/var/lib/cm/cmd-etc`, rewrite `Master = master` → `Master = $bcm_internal_ip`, SCP the per-node cert + key from BCM.
     - `unshare --mount --fork` a child that bind-mounts cmd-etc + proc + sys + tmpfs, and `chroot` into the NFS image to run `/cm/local/apps/cmd/sbin/cmd -s -n` — BCM's cluster daemon, in a chroot of the BCM default image, so the Kairos node reports back into cmsh as a managed compute node.

### 5.8 CIDATA user-data image

4 MB FAT32 labeled `CIDATA` containing one or two files. The base `user-data` is always present; an `extra-userdata` file is added when `kairos_user_data` is set in inventory.

```
dd if=/dev/zero of=build/userdata.img bs=1M count=4
mkfs.vfat -n CIDATA build/userdata.img
mcopy -i build/userdata.img build/cloud-config.yaml ::user-data
[ -f build/extra-userdata.yaml ] && mcopy -i build/userdata.img build/extra-userdata.yaml ::extra-userdata
```

The role first writes `build/extra-userdata.yaml` from the inventory variable (or removes it if the variable is empty), so the FAT32 image always reflects the current inventory.

### 5.9 Run `kairos-agent install` under **OVMF (UEFI)**

A blank 80 GB raw disk is created with `truncate -s 81920M`. QEMU is launched headless with **OVMF firmware loaded as a pflash pair** (read-only `OVMF_CODE_4M.fd`, RW copy of `OVMF_VARS_4M.fd`):

```
qemu-system-x86_64 \
  -enable-kvm -m 4096 -smp 2 -cpu host -machine q35 \
  -drive if=pflash,format=raw,readonly=on,file=$OVMF_CODE \
  -drive if=pflash,format=raw,file=build/ovmf-vars.fd \
  -display none \
  -chardev socket,id=ser0,path=build/.qemu-install.sock,server=on,wait=off \
  -serial chardev:ser0 \
  -drive if=virtio,format=raw,media=disk,file=build/kairos-disk.raw \
  -drive if=virtio,format=raw,readonly=on,file=build/userdata.img \
  -drive format=raw,media=cdrom,readonly=on,file=build/palette-edge-installer.iso \
  -boot d -pidfile build/.qemu-install.pid -daemonize
```

**Why OVMF / UEFI (not SeaBIOS).** kairos-agent autodetects the firmware type and installs the matching bootloader. Under OVMF it installs **GRUB-EFI into a real ESP** with `\EFI\BOOT\bootx64.efi`. Physical Dell / HPE / Supermicro servers that ship with UEFI firmware need this; a SeaBIOS-built image would produce a GRUB-pc MBR bootloader that won't boot on a modern UEFI-only server. BIOS-only platforms would need a separately-built image.

After QEMU boots, a background `nc -U <sock>` feeds commands into the serial console:

```
mount /dev/vdb /mnt && cp /mnt/user-data /oem/90_custom.yaml && cp /mnt/user-data /tmp/99_bcm.yaml \
    && { [ -f /mnt/extra-userdata ] && cp /mnt/extra-userdata /tmp/99_userdata.yaml; true; }
kairos-agent --debug install 2>&1
mount /dev/vda2 /oem
cp /tmp/99_bcm.yaml /oem/99_bcm.yaml
{ [ -f /tmp/99_userdata.yaml ] && cp /tmp/99_userdata.yaml /oem/99_userdata.yaml; true; }
poweroff
```

The `[ -f ]` guards mean the `99_userdata.yaml` copy is a no-op when `kairos_user_data` was empty in inventory — empty inventory still produces today's `/oem/` layout exactly. When set, the user's YAML lands at `/oem/99_userdata.yaml`, layered after `/oem/90_custom.yaml` (BCM/Palette base) and `/oem/99_bcm.yaml` (a copy of the base for fallback).

Host polls the QEMU PID every 10 s (up to 60 min) for exit.

### 5.10 Post-install raw-disk patching

kairos-agent writes the image but a few things need fixing before this disk can be `dd`'d onto different hardware:

1. **Fix ext4 metadata_csum** — loop-mount partitions 2–5, `e2fsck -fy` + `tune2fs -O ^metadata_csum`. Older GRUB versions in some BCM-installer initrds can't read ext4 with this feature on.
2. **Patch squashfs-like images for stable NIC naming** — `cOS/active.img`, `cOS/passive.img`, and `cOS/recovery.img` are loop-mounted in turn. Inside each:
   - `etc/cos/bootargs.cfg`: `net.ifnames=1` → `net.ifnames=0 biosdevname=0`.
   - `etc/network/interfaces.d/ifcfg-eth0` is created (`auto eth0 / iface eth0 inet dhcp`) if missing.
   This guarantees every Kairos boot mode (active / passive / recovery) uses `eth0`.
3. **GRUB timeout** — patch `grub2/grub.cfg` and `grub/grub.cfg` on the BIOS boot partition to `set timeout=5` so unattended boots don't stall at the menu.
4. **Sparse trim** — `fallocate --dig-holes build/kairos-disk.raw` converts zero-filled regions into holes (80 GB file shrinks to 3–5 GB of real bytes on disk).
5. **Checksum** — `sha256sum kairos-disk.raw > kairos-disk.raw.sha256`.

At the end, `build/` ownership is restored to the invoking user (ansible.cfg has `become=true` globally).

---

## 6. Stage 4 — Deploy DD

**Role:** `roles/deploy_dd/tasks/main.yml`
**Templates:** `deploy-dd.sh.j2`, `install-kairos.sh.j2`
**Produces:** on BCM: populated `<profile>-installer` software image, `<profile>` cmsh category, target device in FULL install mode, `/cm/shared/kairos/<profile>/disk.raw.lz4`, `kairos-http.service` (single, profile-agnostic, serves `/cm/shared/kairos/`), DHCP/NFS/rsyncd config, NAT rule. Locally: `build/deploy-dd.sh`, `build/install-kairos.sh`, `build/.bcm-ssh-config`
**Duration:** ~3–5 minutes
**Mode:** both. This is the stage where remote-BCM and local-KVM diverge in policy (safety flags) but share the same template.

`<profile>` everywhere below is the value of inventory's `kairos_profile` (default `default-kairos`). Multiple profiles coexist on the same BCM — running deploy-dd for `gpu-kairos` does not alter the state of `default-kairos` (or any other profile). Each profile gets its own software image, its own category, its own `/cm/shared/kairos/<profile>/` upload directory, its own `exclude-<profile>` health-check filter. Rsyncd modules and NFS exports are added additively — neither is rewritten in a way that would remove other profiles' state.

Rendered scripts do all the work. `deploy-dd.sh` runs on the build host and SSHes to BCM through the per-run config (§1.3). `install-kairos.sh` is SCP'd into the `<profile>-installer` software image and runs later on the compute node during PXE boot.

### 6.1 BCM readiness gate

Verify SSH works. Wait for `cmfirstboot` not to be `active` or `activating`. Wait for a clean shell (`echo CLEAN`). Wait for `cmd` + `cmsh` to be responsive (5 min timeout).

### 6.2 DNS forwarders *(gated by `bcm_manage_dns`)*

```
{% if bcm_manage_dns | default(true) %}
echo -e 'partition\nuse base\nset nameservers $bcm_external_dns\ncommit' | cmsh
systemctl restart named
{% else %}
info "Skipping DNS management — leaving site's existing resolver untouched"
{% endif %}
```

**Default `true` historically, but remote-BCM deploys must set `bcm_manage_dns: false`** (discover-bcm.yml writes this as the suggested default). Rewriting the cluster nameservers on a customer BCM would break every non-kairos node on the site.

### 6.3 IP forwarding + MASQUERADE NAT

Enabled unconditionally (harmless on a customer BCM that already has NAT configured):

```
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1
# persist in /etc/sysctl.conf
EXT_IF=$(ip route | awk '/^default/ {print $5; exit}')
iptables -t nat -C POSTROUTING -o $EXT_IF -j MASQUERADE \
  || iptables -t nat -A POSTROUTING -o $EXT_IF -j MASQUERADE
```

Interface name is derived from the default route — works whether BCM's external NIC is `eth1` (local-KVM) or `ens192` / `enp3s0` (customer hardware).

### 6.4 SSH key exchange

`build/bcm-kairos-key.pub` (generated in stage 3) is appended to `/root/.ssh/authorized_keys` on BCM if not already present. Private key is already baked into `/var/lib/bcm/bcm-key` inside the Kairos image. Closes the passwordless loop needed by the cloud-config's BCM-integration boot stage.

### 6.5 NFS exports

Appended to `/etc/exports` if not already present, scoped to `$bcm_internal_cidr`:

```
/cm/images/default-image          <cidr>(ro,no_subtree_check,no_root_squash,async)
/cm/shared                        <cidr>(rw,no_subtree_check,no_root_squash,async)
/cm/images/<profile>-installer    <cidr>(ro,no_subtree_check,no_root_squash,async)
exportfs -ra
```

Each profile adds its own `<profile>-installer` export; existing profiles' lines are untouched.

### 6.6 DHCP authoritative + pool range

`sed 's/not authoritative/authoritative/'` on `/etc/dhcpd.conf`; rewrite the `range` line so the pool fits inside $bcm_internal_cidr (e.g. `.16` through `.250` when CIDR is /24). `systemctl restart dhcpd`.

### 6.7 rsyncd

`/etc/rsyncd.conf` is *additive*: a base config with the global section + `[default-image]` module is written if `/etc/rsyncd.conf` is missing or doesn't already contain `[default-image]`. Then a per-profile module (`[<profile>-installer]` → `/cm/images/<profile>-installer`) is appended only if not already present. Other profiles' modules are untouched. `systemctl enable --now rsync`.

### 6.8 Compress + upload (idempotent)

```
lz4 -f build/<profile>-disk.raw build/<profile>-disk.raw.lz4
```

Only re-compresses if `.lz4` is older than `.raw`. Then compares local vs remote file size (`stat -c %s /cm/shared/kairos/<profile>/disk.raw.lz4`) — if they match and are non-zero, skips the SCP entirely. This makes re-runs of `make deploy-dd` through a slow jumphost fast. The remote profile subdirectory is created with `mkdir -p` so multiple profiles' uploads coexist as `/cm/shared/kairos/<profile>/disk.raw.lz4`.

### 6.9 HTTP server

Installs `kairos-http.service` on BCM (single shared unit, profile-agnostic) — a Python `http.server` on port 8888 with `WorkingDirectory=/cm/shared/kairos`. This serves the entire profile tree at `http://<bcm>:8888/<profile>/disk.raw.lz4` without a per-profile unit. The HEAD-request health check confirms the current profile's image is reachable.

### 6.10 `<profile>-installer` software image

Clone BCM's `default-image` to `<profile>-installer`:

```
cmsh -c "softwareimage; clone default-image <profile>-installer; commit"
```

Wait up to 120 s for `/cm/images/<profile>-installer/usr` to appear (BCM provisions this asynchronously). Ensure `lz4` is installed on BCM (`apt-get install -y lz4` if missing); copy it into the image at `/usr/local/bin/lz4`. Existing `<profile>-installer` is detected and reused — re-running deploy-dd for the same profile doesn't re-clone.

### 6.11 Install `install-kairos.sh` + systemd unit

SCP `build/install-kairos.sh` (rendered from `install-kairos.sh.j2`) to `${IMAGE_ROOT}/usr/local/sbin/install-kairos.sh`. Create a systemd unit inside the image:

```
[Unit]
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStartPre=/bin/bash -c 'sleep 10'
ExecStart=/usr/local/sbin/install-kairos.sh
TimeoutStartSec=1800
```

Enable it (`chroot $IMAGE_ROOT systemctl enable kairos-install.service` with a symlink fallback). Add DHCP stanzas for both `eth0` and `ens3` in the image's `/etc/network/interfaces` (covers both naming schemes on physical hardware).

**What install-kairos.sh does on the compute node** (rendered with `$bcm_internal_ip`, `$kairos_profile`, `$kairos_target_disk`, `$kairos_wipe_disks`):

1. **HTTP probe** — poll `HEAD http://$HEAD_IP:8888/<profile>/disk.raw.lz4` every 10 s for up to 10 minutes. Abort if unreachable.
2. **Stage binaries to RAM** (`/dev/shm/kinstall/`) — `bash curl lz4 dd sync sleep sgdisk wipefs dmsetup efibootmgr partprobe blkid` and all `ldd` dependencies. This is required because the dd will overwrite the filesystem these binaries currently live on.
3. **Enable sysrq** — `echo 1 > /proc/sys/kernel/sysrq`.
4. **Write a run-dd.sh with shebang `#!/dev/shm/kinstall/bash`**, then `exec` it — the parent process is replaced with a RAM-resident one. From here on nothing touches the target disk's filesystem.
5. **Wipe sibling disks** — for every name in `$WIPE_DISKS`, `dmsetup remove_all; wipefs -a -f /dev/<name>`. Clears LVM PV / DRBD / old filesystem signatures so Kairos's persistent-partition logic doesn't see stale metadata.
6. **Stream + dd** — `curl --fail -s $RAW_URL | lz4 -d - - | dd of=$DISK bs=4M oflag=direct`. `oflag=direct` bypasses the page cache (critical — without it an 80 GB write can drive an LVM thin pool into overflow on a tight-RAM server).
7. **Fix GPT backup header** — `sgdisk -e $DISK; partprobe $DISK`. The raw image was created on an 80 GB disk; the target disk is usually larger, so GPT's backup header ends up at the wrong offset. `sgdisk -e` moves it to the correct location.
8. **Create a UEFI boot entry** (new — guards physical UEFI deploys):
   ```
   if [ -d /sys/firmware/efi/efivars ] && [ -x efibootmgr ]; then
       # delete any existing 'Kairos' entries so re-installs don't stack
       for n in $(efibootmgr | grep 'Kairos$' | grep -oE '^Boot[0-9A-Fa-f]+' | sed 's/^Boot//'); do
           efibootmgr -b $n -B
       done
       efibootmgr --create --disk $DISK --part 1 --label Kairos --loader '\EFI\BOOT\bootx64.efi'
       # move new entry to front of BootOrder
   fi
   ```
   Without this, physical UEFI firmware keeps booting stale `BootXXXX` entries tied to the *previous* install's GPT UUIDs and never discovers the freshly-dd'd Kairos bootloader. Guarded by presence of `efivars` so it's a no-op on legacy BIOS.
9. **Drop page cache + sync** — `echo 3 > /proc/sys/vm/drop_caches; sync`.
10. **SysRq poweroff** — `echo o > /proc/sysrq-trigger`. Instant hard poweroff because the filesystem is destroyed and normal `poweroff` would fail.

### 6.12 PXE template + syslinux modules

Patch `/tftpboot/pxelinux.cfg/template` (and the x86_64/bios variant): `IPAPPEND 3` → `IPAPPEND 2` (prevents duplicate IP assignment). Ensure `menu.c32`, `libutil.c32`, `ldlinux.c32`, `libcom32.c32` exist at `/tftpboot/` (copy from `x86_64/bios/` or `/usr/lib/syslinux/modules/bios/` if missing).

### 6.13 Create the `<profile>` category (cloned from `bcm_source_category`)

```
cmsh -c "category; list" | grep -q '^<profile>\b' \
  || cmsh -c "category; clone \"{{ bcm_source_category | default('default') }}\" <profile>; commit"
```

On **local-KVM** this clones `default`. On **remote BCM** it clones whatever the site already uses — e.g. `"Partner Lab"` — so the `<profile>` category inherits disksetup, mon templates, interface layout, and FinalizeXML that match the target hardware. Creating an empty category and hand-copying config would re-invent site-specific behavior that's already correct.

Configure:

```
set softwareimage <profile>-installer
set installmode FULL
set newnodeinstallmode FULL
set installbootrecord yes
set kernelparameters "console=ttyS0,115200n8 net.ifnames=0 biosdevname=0"
```

Strip `fsmounts` for `/cm/shared` and `/home` from the `<profile>` category — Kairos is an immutable OS; it uses `COS_PERSISTENT` bind-mounts for `/home` and doesn't mount `/cm/shared`. Leaving these entries produces permanent "fsmounts" health-check failures with no functional meaning.

### 6.14 Category-scoped `nodeexecutionfilters`

```
for CHECK in mounts interfaces ntp; do
    cmsh -c "monitoring setup; use $CHECK; nodeexecutionfilters; \
             add category exclude-<profile>; \
             set filteroperation Exclude; \
             set categories <profile>; \
             commit"
done
```

One filter per check, named `exclude-<profile>` and scoped to the `<profile>` category only — these checks still apply to every other category on the BCM, including other Kairos profiles (each profile's deploy-dd installs its own `exclude-<profile>` filter). Rationale:
- `mounts` — Kairos mounts root read-only and uses COS bind-mounts, not `/etc/fstab` entries BCM understands.
- `interfaces` — Kairos NIC is `eth0` (we forced `net.ifnames=0`) not BCM's expected `BOOTIF`.
- `ntp` — Kairos uses systemd-timesyncd, not chronyd/ntpd.

After this the `<profile>` category reports clean `[ UP ]` in cmsh.

### 6.15 Cluster-wide defaults *(gated by `bcm_manage_cluster_defaults`)*

```
{% if bcm_manage_cluster_defaults | default(false) %}
cmsh -c "partition; use base; set defaultcategory <profile>; commit"
cmsh -c "partition; use base; set nodebasename node; set nodedigits 3; commit"
{% endif %}
```

**Default `false`.** Remote-BCM must keep it `false` — flipping `defaultcategory` cluster-wide would make every newly-PXE'd compute node on the site try to install whatever Kairos profile is most recently set as default. Only set `true` for a fresh/local BCM where the whole cluster is yours.

### 6.16 Target device assignment

Two modes share the same template, branched on whether `bcm_target_node` is defined:

**Remote BCM** (`bcm_target_node` set) — move the existing device:
```
cmsh -c "device; use $bcm_target_node; \
         set category <profile>; \
         set softwareimage <profile>-installer; \
         set installmode FULL; \
         [set mac $kairos_target_mac;] \
         [set ip  $kairos_target_ip;]  \
         commit"
```
Also sets `softwareimage` at the device level because device-level overrides beat category values on existing BCMs (customers' devices often have device-level overrides for site-specific software images). `set mac` and `set ip` lines are emitted only when `kairos_target_mac` / `kairos_target_ip` are defined in inventory — mirrors the local-KVM path (where `device add physicalnode <name> <ip> eth0; set mac …` takes the same two fields at registration time), so deploy-dd owns the MAC + IP mapping rather than relying on the device having been registered with the right values previously. When either variable is absent, the device keeps whatever value cmsh already has (the common case — customers have registered the hardware via BCM's normal workflow, `nodeidentityhelper`, or manual cmsh earlier). We deliberately do *not* `remove` + `add physicalnode` like the local-KVM path does — that would wipe site-specific device-level overrides (hostname, interfaces, disksetup) that aren't ours to touch.

**Local KVM** (`bcm_target_node` empty) — register node001:
```
cmsh -c "device; remove node001; commit"   # idempotent
cmsh -c "device; add physicalnode node001 <prefix>.10 eth0; \
         set category kairos; \
         set mac $kairos_vm_mac; \
         commit"
```

Verifies the category's softwareimage is still `kairos-installer` (BCM sometimes resets this when cloning from certain source categories).

### 6.17 Regenerate ramdisk

```
cmsh -c "softwareimage; use kairos-installer; createramdisk -w"
```

`-w` waits until complete. After regeneration, re-commits the category's `softwareimage` and verifies — rare races where ramdisk generation drops the value.

At this point BCM is fully configured. The target node will pick up the `kairos-installer` image on its next PXE boot and `install-kairos.sh` will run inside it.

---

## 7. Stage 5 — Kairos VM *(local-KVM only)*

**Role:** `roles/kairos_vm/tasks/main.yml`
**Produces:** `build/kairos-compute.qcow2` + a running Kairos VM
**Duration:** ~10 minutes
**Mode:** local-KVM only. On remote-BCM deploys, the equivalent is a power-cycle of the target node via iDRAC / IPMI / Redfish (manual).

### 7.1 Preparation

- Kill any existing Kairos VM (PID file + pgrep).
- Reset `node001`'s `installmode` to `FULL` in cmsh (may have been set to `NOSYNC` by a prior successful run).
- Create a fresh `build/kairos-compute.qcow2` (default 80 GB), overwriting any existing one.

### 7.2 Launch with PXE boot

```
qemu-system-x86_64 \
  -enable-kvm -m $kairos_vm_ram -smp $kairos_vm_cpus -cpu host \
  -drive file=build/kairos-compute.qcow2,format=qcow2,if=virtio \
  -netdev socket,id=intnet,connect=:31337 \
  -device virtio-net-pci,netdev=intnet,mac=$kairos_vm_mac \
  -chardev socket,id=ser0,host=localhost,port=4321,server=on,wait=off,telnet=on,logfile=logs/kairos-serial.log \
  -serial chardev:ser0 \
  -boot order=cn -daemonize
```

Key differences from BCM VM:
- **Single NIC** on socket network (`connect=:31337` connects to BCM's listen) — no direct internet, routes through BCM's NAT.
- **`-boot order=cn`** — network first, then disk. PXE ROM requests DHCP from BCM, pulls the PXE config + kernel + ramdisk over TFTP.
- **MAC matches registered node001** (`52:54:00:00:02:01` by default) so BCM assigns the expected IP and the `kairos` category.
- **Telnet serial on port 4321** — attach with `telnet localhost 4321` for live debugging.

### 7.3 What happens inside the VM (orchestrated by BCM)

No Ansible involvement in this part:

1. DHCP from BCM → IP `<prefix>.10`.
2. TFTP kernel + ramdisk from BCM (the regenerated `kairos-installer` ramdisk).
3. Systemd boots; `kairos-install.service` fires 10 s after `network-online.target`.
4. `install-kairos.sh` stages binaries, execs into RAM-resident bash, curls + lz4-decompresses + dds, fixes GPT, creates EFI entry (no-op here — SeaBIOS on the compute VM), drops cache, SysRq poweroff.

### 7.4 Wait for poweroff

Poll QEMU PID every 10 s for up to 30 min.

### 7.5 Reboot from disk

New QEMU with the same args except `-boot c`. GRUB loads Kairos kernel from the freshly-dd'd disk.

### 7.6 Wait for Kairos boot

`wait-kairos-boot.sh.j2` runs on the host and probes through BCM:

1. Check BCM's ARP table for the compute VM's MAC to get its current IP.
2. SSH via BCM (`sshpass | ssh BCM "ssh root@<kairos-ip> cat /etc/kairos-release"`), retrying every 10 s for up to 10 min.

During this window the Kairos boot stages (§5.7) run: hostname, Palette site name, BCM key exchange, NOSYNC install mode, NFS mount, cmd daemon chroot — all via the `bcm-kairos-key` SSH key.

---

## 8. Stage 6 — Validate

**Role:** `roles/validate/tasks/main.yml`
**Template:** `roles/validate/templates/validate.sh.j2`
**Duration:** ~15 seconds
**Mode:** both. The template is parameterized by `bcm_target_node` (defaulting to `node001` for local-KVM) and by the same jumphost SSH config pattern as deploy-dd.

Runs a comprehensive health check across BCM and the Kairos compute node. Reuses `build/.bcm-ssh-config` (from deploy-dd, or regenerated here), so `ProxyCommand` works transparently.

### 8.1 Connecting to the Kairos node

The template discovers the Kairos IP by reading BCM's ARP table for the compute node's MAC (obtained from `cmsh device use $TARGET_NODE get mac`), falling back to `cmsh device get ip`. Then tries SSH two ways, **from BCM** (using BCM as a jump host into the provisioning network):
1. `ssh root@$KAIROS_IP` (key-based, via the SSH key pair exchanged during the Kairos boot stages).
2. `sshpass -p kairos ssh kairos@$KAIROS_IP` (password-based fallback to the POC user).

### 8.2 BCM checks (roughly 18, all through the same `bcm-target` SSH alias)

**Connectivity:** SSH reachability.

**Services:** `cmd`, `dhcpd`, `named`, `nfs-server` all `is-active`; `ss -tlnp` shows `:873` (rsyncd) and `:8888` (HTTP image server) listening.

**Network:**
- BCM internal IP present on any interface (match by IP, not NIC name — works for `eth0` or `ens*`/`enp*`).
- Under `bcm_manage_dns=true`: `eth1` has an IP (local-KVM NAT NIC). Under `bcm_manage_dns=false`: default-route interface exists — i.e. BCM has outbound routing, whatever the NIC happens to be called.
- `/proc/sys/net/ipv4/ip_forward == 1`.

**DNS / internet:** `host google.com` resolves; `curl -s -w "%{http_code}" https://google.com` returns 200 or 301.

**Cluster state:** `cmsh device list` shows head as `UP`; `$TARGET_NODE` is registered; IP + category = `kairos`; `/cm/images/kairos-installer/` exists; `/cm/shared/kairos/disk.raw.lz4` exists.

### 8.3 Kairos checks (roughly 22, via BCM → Kairos SSH)

**Connectivity:** SSH + ping.

**OS:** `/etc/os-release`'s `PRETTY_NAME`; `/etc/kairos-release` `KAIROS_VERSION`; `kairos-agent version`; kernel.

**Network:** IP address assigned; default gateway; DNS resolver in `/etc/resolv.conf`; ping to google.com; `curl` to https://google.com returns 200/301.

**Services:** `stylus-agent is-active`; `journalctl -u stylus-agent | grep -c "registering edge host"` is > 0.

**Boot:** `/proc/cmdline` contains `net.ifnames=0`; contains `rd.immucore` or `rd.cos` (Kairos boot-chain markers).

**Disk / partitions:** `blkid -L` finds `COS_OEM`, `COS_RECOVERY`, `COS_STATE`, `COS_PERSISTENT`; root is mounted read-only; `df -h /` reports free space.

**Cloud config:** `/oem/*.yaml` files exist.

### 8.4 Output format

Each check prints `[PASS]`, `[WARN]`, or `[FAIL]` with an optional detail. Final line:

```
PASS: 35/40  WARN: 4/40  FAIL: 1/40
```

Script `exit 1` if any `FAIL`, which fails the Ansible playbook.

---

## 9. Cross-cutting design points

### 9.1 Additive, reversible changes on customer BCMs

Two safety flags in `inventory/group_vars/all.yml` gate the only operations that would be cluster-wide:

- `bcm_manage_dns` (default in discover output: `false`) — §6.2 — when false, the cmsh DNS-nameserver rewrite + `systemctl restart named` is skipped entirely. Rewriting this on a customer BCM would break every non-Kairos node on the site.
- `bcm_manage_cluster_defaults` (default: `false`) — §6.15 — when false, `partition base set defaultcategory`/`nodebasename` is skipped. Flipping defaultcategory would make every newly-added compute node on the customer's BCM try to install Kairos.

Beyond these flags, `deploy-dd` is additive: it creates a *new* `kairos` category (cloned from `bcm_source_category`, inheriting site-specific disksetup / FinalizeXML) and moves exactly one device — `bcm_target_node` — into it. Moving the device back to its original category and re-PXE'ing reverts it to standard HPC provisioning.

When modifying `deploy_dd/templates/deploy-dd.sh.j2`, preserve both properties: no cluster-wide writes outside the two gates, and the only cmsh device touched is `bcm_target_node`.

### 9.2 UEFI raw image + post-`dd` efibootmgr

Stage 3 uses **OVMF firmware** (§5.9) so the raw image has a real ESP with `\EFI\BOOT\bootx64.efi`. Stage 4 `install-kairos.sh` (§6.11 step 8) runs `efibootmgr --create --disk $DISK --part 1 --label Kairos --loader '\EFI\BOOT\bootx64.efi'` after `dd` so UEFI firmware boots the freshly-written disk on next power-up — no manual OneTimeBoot via iDRAC required.

Three invariants any change to the boot path must preserve:

1. **ESP is partition 1** — `efibootmgr --part 1` assumes this, and the CanvOS raw image layout puts the ESP there. If you change kairos-agent install flags, verify the ESP is still `/dev/$DISK`p1.
2. **Delete old `Kairos` entries before creating a new one** — re-installs shouldn't stack duplicate NVRAM entries.
3. **Guard on `/sys/firmware/efi/efivars`** — the same script runs on both UEFI hardware and the local-KVM compute VM (which boots SeaBIOS). No efivars means no-op, not a failure.

### 9.3 Palette pre-registration hook

`files/canvos/overlay/files/usr/bin/palette-cleanup-stale.sh` is baked into the image in §5.3 and runs via `systemd ExecStartPre` before `stylus-agent`. Full behavior:

1. **Gate on registration mode** — exits as no-op if `/proc/cmdline` doesn't contain `stylus.registration` AND `/oem/.stylus-state` already has an `authToken`. Post-registration re-boots skip the hook entirely.
2. **Load admin creds** from `/oem/palette-admin.env` (written by cloud-config initramfs stage §5.7 from `palette_api_key` + `palette_project_uid` + `palette_endpoint`). Missing file = skip.
3. **Auto-mint an edgeHostToken if missing** — inspect `/oem/90_custom.yaml` for `edgeHostToken:`. If empty, `POST /v1/edgehosts/tokens` (tenant-scoped — no `ProjectUid` header), fetch the created token by UID, and inject it into the userdata yaml (replace existing line, or insert after `site:`).
4. **Delete stale edge-host record** — compute `edge-<smbios-uuid>`. `GET /v1/edgehosts/<uid>` (project-scoped — `ProjectUid` header). On 200 → `DELETE /v1/edgehosts/<uid>`. On 404 → proceed. On 401/403 → log + continue. Without this, re-imaging a previously-registered node fails with "UID already registered".
5. **Fail-open on every error path** — `set +e`; the script's final `exit 0` is unconditional. A bug here must not block stylus-agent.

When modifying this script, preserve all five properties. The "reimage a node with one command" UX depends on steps 3 + 4 being automatic and step 5 being bulletproof.

### 9.4 Category-scoped health-check suppression

See §6.14. BCM's `mounts`, `interfaces`, and `ntp` measurables don't match Kairos's architecture (immutable read-only root, no `/etc/fstab` BCM would recognize, no `ntp.conf`, stable `eth0` not `BOOTIF`). The `nodeexecutionfilters` on each measurable are scoped `Exclude + categories=kairos` so every other category on the BCM is unaffected.

Idempotent: the check against `exclude-kairos` in the existing filters means re-runs don't add duplicates.

### 9.5 Jumphost-aware SSH everywhere

See §1.3. Every BCM-side operation in deploy-dd, validate, and discover-bcm uses a per-run SSH config with `ProxyCommand`. `bcm_ssh_proxy_key` is expanded via `lookup('env','HOME')` at template-render time (not at SSH time) because OpenSSH doesn't reliably expand `~` inside `ProxyCommand`. New code that needs BCM access must reuse this config — `-J` flags scattered ad-hoc will silently skip the jumphost.

### 9.6 Other install-kairos.sh details worth knowing

- **lz4 not gzip** — decompression is faster than the `dd` write speed, so the pipeline is write-bound, not CPU-bound.
- **`oflag=direct`** — bypasses the page cache. Without it, writing an 80 GB image can push an LVM thin pool into overflow before the sync completes.
- **Staging binaries to `/dev/shm/kinstall` + exec before dd** — the dd overwrites the filesystem hosting the currently-running binaries; without RAM-staging + exec, the script would SIGBUS partway through. The shebang on `run-dd.sh` points at `/dev/shm/kinstall/bash`.
- **sgdisk -e + partprobe** — the raw image was created on an 80 GB virtual disk; target disks are typically larger, so the GPT backup header is at the wrong offset after dd. `sgdisk -e` relocates it; `partprobe` re-reads the corrected partition table.

---

## 10. Network topology

### 10.1 Remote BCM (customer site)

```
┌────────────────────┐         ┌────────────────────────────────────┐
│ Build host          │  SSH    │ Customer network                   │
│ (this repo)         │──►(via)─┤                                    │
│  ansible-playbook   │  jump   │ ┌─────────────┐   provisioning VLAN│
│  sshpass | ssh -F   │  host   │ │ Jumphost    │  (BCM's "internalnet")
│                     │         │ │ ProxyCommand│                    │
└────────────────────┘         │ └──────┬──────┘                    │
                                │        │                            │
                                │        ▼                            │
                                │   ┌─────────────────────────┐       │
                                │   │ BCM head node           │       │
                                │   │  IP: $bcm_internal_ip   │       │
                                │   │  cmd, dhcpd, named, nfs │       │
                                │   │  HTTP :8888 (kairos img)│       │
                                │   └──────┬──────────────────┘       │
                                │          │ PXE + HTTP                │
                                │          ▼                            │
                                │   ┌─────────────────────────┐        │
                                │   │ Compute node (bare metal)│       │
                                │   │  $bcm_target_node        │       │
                                │   │  UEFI → Kairos           │       │
                                │   │  stylus-agent → Palette  │       │
                                │   └─────────┬────────────────┘       │
                                │             │ HTTPS                  │
                                └─────────────┼────────────────────────┘
                                              ▼
                                       Palette ($palette_endpoint)
                                       SaaS or on-prem
```

The build host never sees the provisioning VLAN directly — every BCM operation tunnels through the jumphost via `ProxyCommand`. The compute node reaches Palette once Kairos is up; egress path is site-specific (either via BCM NAT or via site routing; `bcm_manage_dns=false` ensures we don't override whatever the site has).

### 10.2 Local KVM (dev / demo)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Host Machine                                  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │   QEMU socket net :31337  (flat L2, "internalnet")            │    │
│  │                                                               │    │
│  │   ┌─────────────────────┐       ┌──────────────────────────┐  │    │
│  │   │ BCM head node VM    │       │ Kairos compute node VM   │  │    │
│  │   │  eth0 → listen      │◄──────┤  eth0 → connect          │  │    │
│  │   │  $bcm_internal_ip   │       │  DHCP from BCM            │  │    │
│  │   │  cmd + dhcpd + nfs +│       │  stylus-agent + k3s       │  │    │
│  │   │  named + HTTP :8888 │       │  cmd (BCM chroot)         │  │    │
│  │   └─────────┬───────────┘       └──────────────────────────┘  │    │
│  │             │                                                   │    │
│  └─────────────┼───────────────────────────────────────────────────┘    │
│                ▼                                                       │
│      QEMU user-mode NAT (extnet)                                       │
│        BCM eth1: 10.0.2.15 / GW 10.0.2.2 / DNS 10.0.2.3              │
│        Compute → BCM eth0 → NAT → eth1 → Internet                    │
│                                                                      │
│  Host port forwards (→ BCM VM):                                      │
│    localhost:$bcm_ssh_port  → 22   (SSH)                             │
│    localhost:$bcm_https_port → 443 (BCM Web UI)                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Why two separate networks.** BCM's DHCP must be the only DHCP visible to compute nodes — if QEMU's user-mode NAT also answered DHCP, compute VMs could get the wrong gateway. The socket-based L2 network is a clean isolated broadcast domain for provisioning; the user-mode NAT provides internet exclusively via BCM's IP-forwarding + MASQUERADE rule.
