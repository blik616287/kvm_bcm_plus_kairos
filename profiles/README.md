# Build profiles

Reproducible, per-OS-version variable files for the Kairos pipeline. Each file is
a complete set of extra-vars for one profile; pass it to **every** make stage with
`ANSIBLE_ARGS="-e @profiles/<file>.yml"`. They replace the ad-hoc `-e @/tmp/*.json`
files used during bring-up so a clean checkout reproduces the same builds.

| Profile | File | Base image | Compute node |
|---------|------|-----------|--------------|
| Ubuntu 24.04 | `ubuntu-24.04.yml` | Spectro curated (auto) | node001 |
| Ubuntu 26.04 | `ubuntu-26.04.yml` | **self-built** (see §26.04) | node002 |

`all.yml` carries the **shared** config (BCM connection/network, VM sizing, JFrog
token, Palette); the profile file carries the **per-OS** bits (`kairos_profile`,
node identity, `OS_VERSION`, `ISO_NAME`, and for 26.04 `BASE_IMAGE`). Ansible loads
`all.yml` automatically; the profile is layered on top via `-e`.

---

## 0. Shared setup (once, for both profiles)

1. **`inventory/group_vars/all.yml`** — copy from `all.local-kvm.example.yml`
   (local-KVM) and fill in real values. Local-KVM essentials:
   ```yaml
   bcm_ssh_host: "127.0.0.1"        # BCM runs as a local QEMU VM
   bcm_ssh_port: 10022              # qemu hostfwd → BCM:22
   bcm_internal_ip:   "10.141.255.254"
   bcm_internal_cidr: "10.141.0.0/16"
   bcm_manage_dns: true             # TRUE only because we own this BCM
   bcm_manage_cluster_defaults: true
   bcm_target_node: ""              # empty → deploy-dd auto-registers the node
   kairos_target_disk: "/dev/vda"   # virtio in QEMU
   jfrog_token: "<read-only token>" # bcm-prepare ISO download
   jfrog_instance: "insightsoftmax.jfrog.io"
   jfrog_repo: "iso-releases"
   iso_filename: "bcm-11.0-ubuntu2404.iso"
   palette_api_key: "<...>"
   palette_token:   "<...>"
   ```
   > On a customer/remote BCM, `bcm_manage_dns` and `bcm_manage_cluster_defaults`
   > **must be `false`**, and `bcm_ssh_host`/`bcm_target_node` point at the real box.

2. **Bring up the BCM head node** (local-KVM only — stages 1–2):
   ```bash
   make install-deps
   make bcm-prepare        # downloads + remasters the BCM ISO (uses jfrog_* from all.yml)
   make bcm-vm             # installs BCM in KVM, boots from disk
   ```

---

## Ubuntu 24.04 — `profiles/ubuntu-24.04.yml`

24.04 uses Spectro's published curated base, so **no base image to build** —
CanvOS derives and pulls `kairos-ubuntu:24.04-core-...` automatically.

```bash
make kairos-build ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make deploy-dd    ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make kairos-vm    ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make validate     ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
```
Installs/boots **node001**; expects `make validate` → `41/41 PASS`.

---

## Ubuntu 26.04 — `profiles/ubuntu-26.04.yml`

Spectro publishes **no** curated 26.04 base, so build and push a Kairos core base
once, then point `BASE_IMAGE` at it.

**One-time base build + auth:**
```bash
# 1. Build + push a Kairos core base from ubuntu:26.04 (registry of your choice)
make kairos-base-push \
  BASE_OS_IMAGE=ubuntu:26.04 \
  KAIROS_BASE_VER=26.04 \
  KAIROS_BASE_REGISTRY=<your-registry-host>/<repo>
#   e.g. → ttl.sh/kairos-ubuntu:26.04-core-amd64-generic-v4.0.3

# 2. Log the build host in so earthly/buildkit can pull it during kairos-build
docker login <your-registry-host>          # for JFrog: -u kairos-ci-ro -p <read-only token>

# 3. Set BASE_IMAGE in profiles/ubuntu-26.04.yml to the exact pushed tag
```

**Then build / deploy / boot / validate:**
```bash
make kairos-build ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
make deploy-dd    ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
make kairos-vm    ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
make validate     ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
```
Installs/boots **node002** (distinct MAC `52:54:00:00:02:02`); expects `41/41 PASS`.

---

## Running BOTH on one BCM

`deploy-dd` is additive and profile-namespaced, so both images coexist on the same
BCM (separate software image + category + node). **Caveat:** the local QEMU socket
network serves **one compute node at a time**, so boot/validate them **sequentially**
— stop node001's VM (`make kairos-stop`) before booting node002.

```bash
# build + deploy both
make kairos-build ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make kairos-build ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
make deploy-dd    ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make deploy-dd    ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"

# validate 24.04 on node001
make kairos-vm    ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make validate     ANSIBLE_ARGS="-e @profiles/ubuntu-24.04.yml"
make kairos-stop                                                  # stop compute VMs

# validate 26.04 on node002
make kairos-vm    ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
make validate     ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
```

For a **remote BCM** (no local KVM), run only `kairos-build`, `deploy-dd`, `validate`
with the same `-e @profiles/<file>.yml`, and trigger PXE on the real node via
iDRAC/IPMI/Redfish.

---

## RAID layouts (OS mirror + data arrays)

A profile can declare a software-RAID disk layout — the roles are a generic engine,
so a new layout is just a new profile file, no code changes. Requires a RAID-capable
image (`kairos_build_mdraid: true`, stage 3) **and** the finalize-stage install
(`deploy_dd_finalize_install: true`, stage 4). Arrays are created by the finalize
script on the node (not the BCM disksetup), so we control mdadm metadata.

```yaml
# capability (stage 3): build an image whose initramfs can assemble mdadm at boot
kairos_build_mdraid: true
deploy_dd_finalize_install: true

# OS mirror → the dd target. MUST be level 1 (only a mirror gives each member a
# UEFI-readable ESP under metadata 1.0); >=2 members. Set target to the array.
kairos_os_raid: {level: 1, metadata: "1.0", devices: [nvme2n1, nvme3n1]}
kairos_target_disk: /dev/md0

# data arrays (off the boot path → any level 0/1/5/6/10). Each is created + mkfs'd
# with a stable LABEL and mounted FAIL-OPEN (a dead RAID0 member never blocks boot).
kairos_data_raid:
  - {name: raid, level: 0, devices: [nvme0n1, nvme1n1, nvme4n1], filesystem: ext4, mount: /raid}
```

Guardrails (asserted in `deploy_dd/tasks/finalize.yml`): the **OS array must be
RAID1** — RAID0/5/6/10 for the root can't boot (no single member holds a complete
ESP), so use `kairos_data_raid` for striped/parity storage. `profiles/dgx-raid.yml`
is a worked example (2-drive OS mirror + 8-drive data RAID0). ⚠️ Confirm the
`/dev/nvme*` enumeration on the live box before deploying — BMC `Device#` ≠ Linux
device name.

### Testing a RAID layout without the hardware

`profiles/dgx-raid-kvm.yml` runs the same RAID path on a local-KVM node, so the
array creation, the `dd`-to-`/dev/md0` and the UEFI boot off a mirror member can
be exercised on the rig instead of on a DGX. Two things make it a faithful stand-in:

- **Every disk is NVMe** (`bus: nvme` in `kairos_vm_disks` attaches an emulated
  NVMe controller, not virtio). `kairos_raid_select: size` globs `/sys/block/nvme*n1`
  — virtio disks would be `vd*` and the selector would find nothing.
- **There is no separate boot disk** (`kairos_vm_disk_size: ""`). A DGX has none,
  and here it would actively break selection: the smallest N drives become the OS
  mirror, so a small boot disk would be chosen as a member.

It runs on **node004** (`52:54:00:00:06:01` → `.13`), not node003 — node003
belongs to `profiles/edge-to-appliance.yml`, and on a bridge-mode provisioning LAN
both can be up at once, so sharing a node slot would have them overwrite each
other's BCM registration and qcow2 disks.

```yaml
kairos_vm_disk_size: ""          # no boot disk; the mirror IS the boot target
kairos_vm_disks:
  - {size: "96G",  bus: nvme}    # \
  - {size: "96G",  bus: nvme}    #  > smallest two -> OS mirror
  - {size: "128G", bus: nvme}    # \
  - {size: "128G", bus: nvme}    #  > the rest -> /raid stripe
```

The members are 96G rather than something token-sized because of the three floors
in the table below — in particular the array has to hold the whole raw image, and
a mirror is only one member wide.

Two sizing floors apply, to different things — get either wrong and the error names neither:

| Floor | Applies to | Symptom if too small |
|---|---|---|
| BCM installer env (disksetup: 100M ESP + 16G swap + ~9.4G image) | each **OS mirror member** | `An error occurred while provisioning. Ran out of disk space!` — before finalize ever runs |
| `kairos_raw_disk_size` | the assembled **array** | `dd` stops at `No space left on device` (now caught before the write, naming both numbers) |
| the image's own layout (OEM + recovery + state, ~51 GiB on the edge image) | `kairos_raw_disk_size` itself | `the requested partitions size (50960MiB) does not fit in the target disk` during the stage-3 install |

What it does **not** cover: real NVMe enumeration instability (the reason
`kairos_raid_select` exists at all — QEMU enumerates deterministically), drive
count, and anything vendor-firmware shaped. Treat it as a regression test for the
role logic, not as sign-off for a DGX deploy.

## Notes

- **`PE_VERSION` is the stylus *agent* version, not the bundle filename.** A
  `palette-enterprise-appliance-4.10.17.tar.zst` bundle ships stylus `v4.10.4`;
  `4.10.17` is the package/manifest version. Any profile that talks to a
  self-hosted appliance — the appliance profile itself and every edge profile
  registering to it — must pin the *stylus* version, and they must all match.
  `python3 playbooks/files/bundle_stylus_version.py artifacts/<bundle>.tar.zst`
  prints the real one. Unset on an edge profile, CanvOS picks its own default and
  the node registers healthy but retries a self-upgrade forever.

- **ISO_NAME must differ per profile** — the build's "ISO already exists" short-circuit
  keys on `build/<ISO_NAME>.iso`. Same name across profiles would reuse the wrong ISO.
- **Base tag pattern**: `kairos-ubuntu:<ver>-core-amd64-generic-<KAIROS_VERSION>`.
  `KAIROS_VERSION` (default `v4.0.3`) and `KAIROS_INIT_VERSION` come from the `Makefile`;
  bump them there and in the tag together.
- The JFrog **read-only token** (BCM ISO download + 26.04 base pull) lives only in
  gitignored `all.yml` — share it through a secrets channel, never commit it.
