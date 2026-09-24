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
<jfrog_repo>/bcm-11.0-ubuntu2404.iso                                -> dist/
<appliance_jfrog_repo>/palette-enterprise-appliance-<ver>.tar.zst   -> artifacts/
<appliance_jfrog_repo>/palette-enterprise-appliance-<ver>.tar.sig.bin
<appliance_jfrog_repo>/spectro_public_key.pem
```

The two halves are fetched by **different commands into different directories**,
and that is the step most easily missed: `make palette-artifacts-pull` stages the
Palette bundle only — it never touches the BCM ISO. Step 1 below does both.

| Input | JFrog repo variable | Lands in | Fetched by |
|---|---|---|---|
| BCM ISO (~13 GB) | `jfrog_repo` (default `iso-releases`) | `dist/<iso_filename>` | `make bcm-prepare`, if the file is absent |
| bundle + `.sig.bin` + `.pem` (~10 GB) | `appliance_jfrog_repo` (default `palette-content`) | `artifacts/` | `make palette-artifacts-pull`, or any appliance build with an empty `artifacts/` |

Without a mirror, copy each set into its directory by hand. **Filenames matter** —
discovery is by name, so the ISO must be called exactly what `iso_filename` says
and the Palette files exactly what the three `appliance_*_filename` settings in
`profiles/palette-appliance.yml` say.

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
| Free disk | ≥ 400 GB (the ~23 GB of licensed inputs, plus three 80 GiB raw images + lz4 copies + qcow2 growth) |
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
**This is the complete file used by the validated run** — eight keys, nothing else:

```yaml
---
# --- JFrog mirror for the licensed inputs -----------------------------------
# Read-only token. Needs GET on the ISO repo and the Palette content repo.
# Also used as the default for appliance_jfrog_token.
jfrog_token: "<PLACE JFROG TOKEN HERE>"
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

# --- Which licensed Palette artifact set to build against -------------------
# TWO version numbers, and they are not the same one:
#   appliance_bundle_version  the PACKAGE version = the .tar.zst filename
#   appliance_pe_version      the STYLUS AGENT version INSIDE that bundle
# A palette-enterprise-appliance-4.10.17.tar.zst bundle ships stylus v4.10.4.
# Read the second out of the bundle, never off the name:
#   python3 playbooks/files/bundle_stylus_version.py artifacts/<bundle>.tar.zst
# The filenames are derived from the first, and both profiles take their CanvOS
# PE_VERSION from the second, so these two keys retarget the whole artifact set.
appliance_bundle_version: "4.10.17"
appliance_pe_version: "v4.10.4"
```

Everything else comes from committed defaults: `inventory/hosts.yml` for the rig
(addresses, VM sizing, bridge, VIP, and the artifact names/locations derived from
the two keys above) and `profiles/*.yml` per build. Full variable reference:
`inventory/group_vars/all.example.yml` — the licensed artifact set has its own
section there, and none of it lives in a profile, so a different bundle version
or a differently-named mirror is a group_vars change, never a profile edit.

### 3.2 Values you may need to change

| Variable | Default (`inventory/hosts.yml`) | Change if |
|---|---|---|
| `appliance_jfrog_repo` | `palette-content` | your Palette mirror repo is named differently |
| `appliance_bundle_filename` (and `_bundle_signature_filename`, `_signing_key_filename`) | derived from `appliance_bundle_version` | your mirror does not use Spectro's `palette-enterprise-appliance-<ver>.tar.zst` naming. The JFrog path and the local filename are the same string |
| `appliance_artifacts_dir` | `<repo>/artifacts` | you keep the ~10 GB bundle elsewhere (or pin absolute paths with `appliance_content_bundle` / `appliance_signing_public_key`) |
| `bcm_internal_cidr` | `192.168.98.0/24` | it collides with a network on your host |
| `appliance_vip` | `192.168.98.251` | you change the CIDR. Must avoid BCM's DHCP pool (`.16`–`.250`), `bcm_internal_ip` (`.2`) and every derived node address |
| `bcm_internal_net_mode` | `bridge` | **leave it.** `socket` is point-to-point and cannot run the appliance and edge node together, so the experiment is impossible under it |

### 3.3 The version is pinned in one place

`appliance_pe_version` in `inventory/group_vars/all.yml` is the only place the
**stylus agent** version is written. Both images derive their CanvOS
`PE_VERSION` from it — `profiles/palette-appliance.yml` and
`profiles/edge-to-appliance.yml` each pass `PE_VERSION: "{{ appliance_pe_version }}"`
— and `playbooks/tasks/appliance_credentials.yml` checks it against the bundle
before anything is built, so a wrong value fails the run early and by name.

That matters because the failure it replaces was invisible: the appliance and the
edge node used to carry separate literals, and an edge image a version behind
registers fine and reports `health: healthy` / `state: ready`, then retries
`failed to upgrade stylus` forever.

Likewise the bundle's own name: set `appliance_bundle_version` (or the three
`appliance_*_filename` keys, for a mirror with different naming) in
`inventory/group_vars/all.yml`. Nothing version-shaped is left in a profile.
Copy `profiles/palette-appliance.yml` only to run two Palette versions side by
side on one rig, where each build needs its own BCM-side namespace — a profile is
passed with `-e`, so the copy's pins deliberately beat group_vars.

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

Two sets, two destinations (section 1). Do **both** — the BCM ISO is not part of
`palette-artifacts-pull`.

**1a — BCM ISO into `dist/`.** With a mirror configured this is optional:
`make bcm-prepare` in step 2 downloads
`https://<jfrog_instance>/artifactory/<jfrog_repo>/<iso_filename>` itself when
`dist/<iso_filename>` is missing, and skips the download when it is already
there. Stage it up front if you want the ~13 GB transfer to fail early rather
than 90 minutes into the run, or if you have no mirror and are copying the ISO
straight off your NVIDIA/Bright entitlement download:

```bash
mkdir -p dist
# no mirror — just place the entitlement download, under its exact iso_filename:
cp /path/to/bcm-11.0-ubuntu2404.iso dist/

# or pull it from your mirror. The token goes in a 0600 file, never in argv:
# (this is the same thing roles/bcm_prepare does, and why)
umask 077
printf 'header = "Authorization: Bearer %s"\n' "$JFROG_TOKEN" > "$HOME/.jfrog-curl.cfg"
curl --fail -L --progress-bar -K "$HOME/.jfrog-curl.cfg" \
  -o dist/bcm-11.0-ubuntu2404.iso \
  "https://insightsoftmax.jfrog.io/artifactory/iso-releases/bcm-11.0-ubuntu2404.iso"
rm -f "$HOME/.jfrog-curl.cfg"

ls -lh dist/     # ~13 GB, and the name must equal iso_filename
```

A 401/403 here means the token lacks read on the ISO repo. Check the size
afterwards either way: `--fail` stops an error page being saved, but nothing
catches an interrupted transfer, and a truncated ISO is the worst case:
`bcm-prepare` never re-downloads a file that already exists, so the run reports
an archive error out of `7z x` during the remaster rather than a download error,
and re-running changes nothing. Delete a short file and pull it again.

**1b — Palette bundle into `artifacts/`.**

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
