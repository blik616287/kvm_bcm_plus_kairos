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

1. **`inventory/group_vars/all.yml`** — copy from `all.local-minimal.example.yml`
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
make kairos-stop                                                  # free the socket net

# validate 26.04 on node002
make kairos-vm    ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
make validate     ANSIBLE_ARGS="-e @profiles/ubuntu-26.04.yml"
```

For a **remote BCM** (no local KVM), run only `kairos-build`, `deploy-dd`, `validate`
with the same `-e @profiles/<file>.yml`, and trigger PXE on the real node via
iDRAC/IPMI/Redfish.

---

## Notes

- **ISO_NAME must differ per profile** — the build's "ISO already exists" short-circuit
  keys on `build/<ISO_NAME>.iso`. Same name across profiles would reuse the wrong ISO.
- **Base tag pattern**: `kairos-ubuntu:<ver>-core-amd64-generic-<KAIROS_VERSION>`.
  `KAIROS_VERSION` (default `v4.0.3`) and `KAIROS_INIT_VERSION` come from the `Makefile`;
  bump them there and in the tag together.
- The JFrog **read-only token** (BCM ISO download + 26.04 base pull) lives only in
  gitignored `all.yml` — share it through a secrets channel, never commit it.
