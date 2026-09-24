# Reproducing the experiment: BCM → Palette appliance → registered edge node

A step-by-step reproduction of the validated end-to-end run: a Bright Cluster
Manager head node provisions a **self-hosted Palette management appliance**, and
then provisions a **Kairos edge node that registers to that appliance** rather
than to Palette SaaS. Everything runs in local KVM on one machine.

This document is self-contained — it assumes nothing beyond a bare Linux host and
the licensed inputs listed below. Every command, variable and expected output
here was taken from the run recorded in
[`e2e-appliance-and-edge.md`](e2e-appliance-and-edge.md).

**Total wall time ≈ 65 min** of pipeline, plus a one-time ~60–90 min BCM install.

---

## 1. What you must obtain first

Two things cannot be downloaded without entitlement:

| Input | Where | Notes |
|---|---|---|
| **BCM 11 ISO** for Ubuntu 24.04 | NVIDIA/Bright entitlement | the run used `bcm-11.0-ubuntu2404.iso` |
| **Palette Enterprise content bundle** + its detached signature + the content-signing public key | [Artifact Studio](https://artifact-studio.spectrocloud.com) (customer login) | the run used `palette-enterprise-appliance-4.10.17.tar.zst` (~10 GB) |

Both were mirrored to a private JFrog in the validated run, so the pipeline pulls
them itself. If you have your own mirror, read access to exactly two repo paths
is enough — nothing else is fetched from JFrog by this experiment:

```
<repo-for-isos>/bcm-11.0-ubuntu2404.iso
<repo-for-content>/palette-enterprise-appliance-<ver>.tar.zst
<repo-for-content>/palette-enterprise-appliance-<ver>.tar.sig.bin
<repo-for-content>/spectro_public_key.pem
```

Without a mirror, drop the three Palette files into `artifacts/` by hand and put
the BCM ISO in `dist/`.

> **The edge node needs no licensed artifacts of its own.** It is built from
> upstream `ubuntu` via CanvOS plus credentials minted from your own appliance.

---

## 2. Host requirements

The validated host:

| | |
|---|---|
| Kernel | 7.0.0-28-generic (x86_64) |
| CPUs | 32 |
| RAM | 125 GiB |
| Free disk | ≥ 400 GB (three 80 GiB raw images + lz4 copies + qcow2 growth) |
| Virtualisation | `/dev/kvm` present |
| ansible-core | 2.20.2 |
| QEMU | 8.2.2 |
| Docker | 29.8.1 |

Smaller will work, but the three VMs run concurrently and request **30 GiB** of
guest RAM in total (BCM 8 + appliance 16 + edge 6), and the images are large.

Required binaries — `make setup` checks all of them:

```
ansible-playbook  qemu-system-x86_64  docker  sshpass
xorriso  lz4  jq  zstd  bsdtar
```

```bash
make install-deps    # installs them on Debian/Ubuntu
make setup           # verify; must print no MISSING lines
```

> `make setup` checks **root's** PATH, because the playbooks run under
> `become: true`. A tool visible only in your user's PATH (a conda shim, say)
> will pass a naive check and fail mid-run.

### Also required on a Docker or Kubernetes host

The provisioning LAN is a host bridge, and `br_netfilter` hands bridged **IP**
frames to the `iptables FORWARD` chain, whose policy under Docker or kube-router
is `DROP`. `scripts/provisioning-net.sh` installs the necessary
`-i <bridge> -o <bridge> -j ACCEPT` automatically from each VM launcher, so
nothing is needed from you — but be aware it edits `FORWARD`, and that without it
DHCP dies silently while ARP and host pings still work.

---

## 3. Configuration

### 3.1 The one file you must create

`inventory/group_vars/all.yml` is gitignored and holds everything site-specific.
**This is the complete file used by the validated run** — seven keys, nothing else:

```yaml
---
# --- JFrog mirror for the licensed inputs -----------------------------------
# Read-only token. Needs GET on the ISO repo and the Palette content repo.
# Also used as the default for appliance_jfrog_token.
jfrog_token: "<read-only JFrog token>"
jfrog_instance: "insightsoftmax.jfrog.io"
jfrog_repo: "iso-releases"
iso_filename: "bcm-11.0-ubuntu2404.iso"

# --- The disk BCM will dd the image onto on the compute node ----------------
# Never auto-guessed: a wrong value destroys the wrong disk.
# /dev/vda is correct for the local-KVM virtio compute VMs.
kairos_target_disk: "/dev/vda"

# --- Local-KVM owns its BCM, so cluster-wide writes are safe ----------------
# Default is false to protect a customer's head node. Leaving it false makes
# stage 4 skip the DHCP-pool and site-DNS work the local rig depends on.
bcm_manage_cluster_defaults: true

# --- Stylus AGENT version in the content bundle (NOT the filename) ----------
# A palette-enterprise-appliance-4.10.17.tar.zst bundle ships stylus v4.10.4.
# Read it from the bundle, never off the name:
#   python3 playbooks/files/bundle_stylus_version.py artifacts/<bundle>.tar.zst
appliance_pe_version: "v4.10.4"
```

Everything else comes from committed defaults: `inventory/hosts.yml` for the rig
(addresses, VM sizing, bridge, VIP) and `profiles/*.yml` per build. Full variable
reference: `inventory/group_vars/all.example.yml`.

### 3.2 Values you may need to change

| Variable | Default (`inventory/hosts.yml`) | Change if |
|---|---|---|
| `appliance_jfrog_repo` | `palette-content` | your Palette mirror repo is named differently |
| `bcm_internal_cidr` | `192.168.98.0/24` | it collides with a network on your host |
| `appliance_vip` | `192.168.98.251` | you change the CIDR. Must avoid BCM's DHCP pool (`.16`–`.250`), `bcm_internal_ip` (`.2`) and every derived node address |
| `bcm_internal_net_mode` | `bridge` | **leave it.** `socket` is point-to-point and cannot run the appliance and edge node together, so the experiment is impossible under it |

### 3.3 Pin the Palette version in three places

All three must equal the **stylus agent** version inside the bundle — not the
package version in the filename:

| Setting | File |
|---|---|
| `appliance_pe_version` | `inventory/group_vars/all.yml` |
| `PE_VERSION` | `profiles/palette-appliance.yml` |
| `PE_VERSION` | `profiles/edge-to-appliance.yml` |

Only the first is validated against the bundle automatically. A mismatch in the
edge profile does not fail anything — the node registers and reports healthy,
then retries a self-upgrade forever.

Also update the three filenames in `profiles/palette-appliance.yml`
(`appliance_bundle_filename`, `appliance_bundle_signature_filename`,
`appliance_signing_key_filename`) if your bundle version differs.

---

## 4. The reproduction, in order

### Step 0 — clone and configure

```bash
git clone https://github.com/blik616287/kvm_bcm_plus_kairos
cd kvm_bcm_plus_kairos
cp inventory/group_vars/all.local-kvm.example.yml inventory/group_vars/all.yml
chmod 600 inventory/group_vars/all.yml
$EDITOR inventory/group_vars/all.yml        # section 3.1
make install-deps && make setup             # no MISSING lines
```

### Step 1 — stage the licensed inputs

```bash
make palette-artifacts-pull      # JFrog -> artifacts/   (~10 GB)
ls -la artifacts/                # bundle + .sig.bin + .pem
```

Or copy the three files in by hand. Verify the bundle before trusting it:

```bash
openssl dgst -sha256 -verify artifacts/spectro_public_key.pem \
  -signature artifacts/*.tar.sig.bin artifacts/*.tar.zst    # -> Verified OK
```

### Step 2 — build BCM (one time, ~60–90 min)

```bash
make bcm-prepare     # download + patch + remaster the BCM ISO
make bcm-vm          # unattended install, then boot from disk
```

Ends when `cmsh` answers. Confirm:

```bash
sshpass -p bcm-test-pw ssh -p 10022 root@localhost "cmsh -c 'device; list'"
```

BCM is reusable — later steps never reinstall it.

### Step 3 — appliance: image → BCM → PXE → cluster → tenant (~43 min)

```bash
make palette-appliance
```

Expected tail:

```
Palette is up, deployed by BCM onto node002.
Tenant 'acme' created and activated.
  Tenant console: https://192.168.98.251/   (admin@example.test)
  System console: https://192.168.98.251/system
```

Generated credentials land in `.run-credentials.yml` (mode 0600, gitignored).
They are **sticky by design** — the image carries a *hash* of the Local UI
password, so deleting this file between runs strands the appliance.

Verify (from BCM — the host has no route to the provisioning network):

```bash
ansible bcm -m uri -a "url=https://192.168.98.11:5080/ validate_certs=false"
ansible bcm -m uri -a "url=https://192.168.98.251/system validate_certs=false"
```

For a browser on the host: `make palette-console` (Ctrl-C closes).

### Step 4 — mint the edge node's registration credentials (~5 s)

```bash
make palette-edge-credentials
```

```
Edge nodes will register to https://192.168.98.251
  project uid: 6ab5797e35f3515b26970eda
  api key:     recorded in .run-credentials.yml (0600)
```

Must run **after** step 3 — it reads the tenant step 3 created. Re-run it any
time the appliance is rebuilt; a new cluster means a new tenant and the old key
is gone.

### Step 5 — edge node: image → BCM → PXE → register (~21 min)

The credentials are baked into the image, so build **after** step 4. Pass the
profile to **every** stage or they disagree about which artifact and BCM category
they operate on:

```bash
make kairos-build ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml"   # ~8 min
make deploy-dd    ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml"   # ~4 min
make kairos-vm    ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml"   # ~9 min
```

The appliance **stays running** throughout. That is required — the edge node has
to reach the appliance's VIP to register — and it is what bridge-mode networking
makes possible.

### Step 6 — verify (~2 min)

```bash
make palette-edge-verify
```

```
1 edge host(s) registered with the appliance: edge-bd59f72d1f204a31a91b6da9cc9e7288
```

---

## 5. Confirming the result

### The host is registered, healthy and ready

```bash
AK=$(grep '^edge_palette_api_key:'     .run-credentials.yml | awk '{print $2}')
PU=$(grep '^edge_palette_project_uid:' .run-credentials.yml | awk '{print $2}')

ansible bcm -m shell -a "curl -sk -X POST \
  -H 'ApiKey: $AK' -H 'ProjectUid: $PU' -H 'Content-Type: application/json' \
  -d '{}' https://192.168.98.251/v1/dashboard/edgehosts/search"
```

Expected: one item, `status.health.state = healthy`, `status.state = ready`.

`inUseClusterUid` is absent — the host is registered and **available for
assignment**, not a worker in a running cluster. Making it one requires an Edge
Native cluster profile and a machine pool; this repo does not automate that.

### It registered to *your* appliance, not SaaS

The decisive evidence is that the record lives in **your** appliance's database —
the query above goes to your VIP — and that the node's own config points there:

```bash
# on the edge node (via BCM):
#   /oem/palette-admin.env  -> ENDPOINT=192.168.98.251
#   /run/stylus/userdata    -> paletteEndpoint: 192.168.98.251
# and the token it minted is listed in your tenant:
ansible bcm -m shell -a "curl -sk -H 'ApiKey: $AK' \
  https://192.168.98.251/v1/edgehosts/tokens"
```

### The version pin took effect

```bash
# on the edge node:
sudo journalctl -u stylus-agent -b | grep -oE 'version=v[0-9a-zA-Z.-]+' | sort -u
sudo journalctl -u stylus-agent -b | grep -c 'failed to upgrade stylus'
```

Expected: `version=v4.10.4` matching the appliance, and `0` upgrade failures.
Unpinned, the node runs CanvOS's default (`v4.10.0-rc.2` observed) and loops on
a failed self-upgrade while still reporting healthy.

---

## 6. Expected topology

```
            host bridge br-kairos  (192.168.98.0/24, "internalnet")
   ┌──────────────┬──────────────────────────┬──────────────────────────┐
   │              │                          │                          │
 BCM head      node002                    node003                   (VIP .251)
  .2           .11  appliance             .12  edge node            tenant + system
               Local UI :5080             registered to .11          consoles
```

| Profile | Node | MAC | IP | Serial | Guest RAM |
|---|---|---|---|---|---|
| — | BCM | `BC:24:11:7F:33:7C` | `.2` | `logs/bcm-serial.log` (file) | 8 GiB |
| `palette-appliance` | node002 | `52:54:00:00:03:01` | `.11` | telnet `localhost:4322` | 16 GiB |
| `edge-to-appliance` | node003 | `52:54:00:00:05:01` | `.12` | telnet `localhost:4323` | 6 GiB |

Compute-node serial is `4320 + <node number>`, reachable over telnet and also
tee'd to `logs/<node>-serial.log`. BCM writes straight to a file.

Node numbers are load-bearing: the address is derived as
`bcm_internal_ip` prefix + `(9 + node number)`, and the VM slug, serial port and
disk paths derive from the node name.

---

## 7. Timings from the validated run

| Step | Wall time |
|---|---|
| 2 — BCM install (one time) | 60–90 min |
| 3 — appliance (build → cluster → tenant) | 43 min |
| 4 — edge credentials | 5 s |
| 5 — edge image + deploy + PXE + boot | 21 min |
| 6 — verify registration | 2 min |
| **Steps 3–6** | **≈ 65 min** |

Step 3's build is much faster on a rebuild because Docker layers are cached; a
cold CanvOS build adds ~15 min.

---

## 8. Re-running and resetting

| Goal | Command |
|---|---|
| Redo the appliance deploy only | `make palette-deploy && make palette-node` |
| Redo the cluster step after a good boot | `make palette-cluster` |
| Redo the tenant step | `make palette-tenant` |
| Stop one VM | `make kairos-stop NODE=node003` |
| Stop everything | `make stop` |
| **After editing any profile or cloud-config template** | delete `build/<ISO_NAME>.iso` and `build/<profile>-disk.raw*` first |

That last row matters and is easy to miss: stage 3 skips the **entire**
input-generation block when the ISO already exists, so otherwise nothing rebuilds
and the previous image deploys looking like a success.

A full clean reproduction, gated so a failure stops rather than cascading:

```bash
make kairos-stop
sudo rm -f build/palette-appliance-installer.iso build/palette-appliance-disk.raw* \
           build/palette-edge-appliance.iso      build/edge-appliance-disk.raw*
# drop the stale edge block from .run-credentials.yml (the tenant is about to change)

make palette-appliance        && \
make palette-edge-credentials && \
make kairos-build ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml" && \
make deploy-dd    ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml" && \
make kairos-vm    ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml" && \
make palette-edge-verify
```

Keep `.run-credentials.yml` itself — only the `# BEGIN/END edge registration`
block should go.

---

## 9. If it fails

Failure signatures, causes and fixes are tabulated in
[`e2e-appliance-and-edge.md` § Failure signatures](e2e-appliance-and-edge.md#failure-signatures).
The short version:

- `/var/log/node-installer` **on BCM** is the source of truth for the provisioning
  half; `Finalize script:` lines carry the whole `dd` → grow → `efibootmgr` sequence.
- `logs/latest/<stage>.ansible.log` is what actually ran on BCM.
- `make palette-serial` / `make kairos-serial` tail the guest consoles.
- A node is silent on serial after `evm: overlay not supported` because the kernel
  cmdline ends with `console=tty1`; that is not a hang.
- A freshly booted node takes ~2 minutes to answer on the network. `No route to
  host` before then is normal.

---

## See also

[e2e runbook](e2e-appliance-and-edge.md) ·
[Palette appliance stage](stage-palette-appliance.md) ·
[`profiles/README.md`](../profiles/README.md) ·
[`artifacts/README.md`](../artifacts/README.md) ·
[Architecture + troubleshooting](architecture-and-troubleshooting.md)
