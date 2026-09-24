# End-to-end: self-hosted Palette appliance + a Kairos edge node registered to it

Stands up a **self-hosted Palette management appliance** on one node, then
provisions a **Kairos edge node** on a second node that registers to *that*
appliance rather than to Palette SaaS. Both nodes are provisioned by BCM over the
ordinary stage 3 → 4 → 5 path (PXE → `dd` → UEFI boot); the appliance is not a
parallel pipeline, it is a build profile.

Everything below was run on the local-KVM rig. Timings are from that run.

---

## What you end up with

| | |
|---|---|
| `node002` | the appliance — Palette management cluster, Local UI on `:5080`, tenant + system consoles on the VIP |
| `node003` | a Kairos edge node, registered to node002, `health: healthy` / `state: ready` |
| VIP `192.168.98.251` | tenant console `/` and system console `/system` |

The edge node has **no route to the internet** — it reaches the appliance over
the provisioning network, which is the same path a real on-prem edge node uses.
That is the point of the exercise, and it is also the proof that registration
went to the local appliance: `api.spectrocloud.com` is unreachable from the node.

---

## Prerequisites

1. **BCM up** (stages 1–2). The appliance and the edge node are both BCM-provisioned
   nodes; BCM is what serves DHCP, TFTP, NFS and the node-installer. Stage 1 needs
   the **BCM ISO** at `dist/<iso_filename>`; it downloads it from `jfrog_repo` when
   absent, or you copy it in by hand. That is a *different* input from the licensed
   Spectro artifacts below, out of a different JFrog repo into a different directory —
   `make palette-artifacts-pull` does not fetch it.
2. **Licensed Spectro artifacts** in `artifacts/` — content bundle, its detached
   signature, and the content-signing public key. Either copy them in or pull them:
   ```bash
   make palette-artifacts-pull
   ```
   See [`artifacts/README.md`](../artifacts/README.md). An appliance build also
   pulls whatever is missing, so on a fresh rig you can skip this step.
3. **A multi-peer provisioning LAN.** The appliance and the edge node must be up
   **at the same time** — the edge node has to reach the appliance's VIP to
   register. `inventory/hosts.yml` ships `bcm_internal_net_mode: bridge` for this.
   The older `socket` mode is point-to-point and carries exactly one compute VM,
   so the edge stage cannot work under it. See
   [Networking](architecture-and-troubleshooting.md#networks-local-kvm).

---

## The run

### 1 — Appliance: build, deploy, boot, cluster, tenant

```bash
make palette-appliance
```

One command covers stages 3 → 4 → 5 plus the post-boot cluster and tenant work:
builds the appliance raw disk, pushes it to BCM, PXE-boots `node002` so BCM `dd`s
it, waits for the Local UI, uploads the ~11 GB content bundle, installs the
cluster definition, creates the management cluster, then creates the first tenant.

**~75 min.** Watch it with `make palette-serial` or
`tail -f logs/latest/palette-appliance.console.log`.

Finishes with:

```
Palette is up, deployed by BCM onto node002.
Tenant 'acme' created and activated.
  Tenant console: https://192.168.98.251/   (admin@example.test)
  System console: https://192.168.98.251/system
```

Credentials land in `.run-credentials.yml` (mode 0600, gitignored). They are
**sticky on purpose** — the image carries a *hash* of the Local UI password, so a
regenerated password strands the appliance. Do not delete that file between runs.

Verify independently:

```bash
# from BCM, which shares the provisioning LAN; the build host cannot route to it
ansible bcm -m uri -a "url=https://192.168.98.11:5080/ validate_certs=false"   # Local UI 200
ansible bcm -m uri -a "url=https://192.168.98.251/system validate_certs=false" # Palette 200
```

To reach it from a browser on the build host:

```bash
make palette-console     # tunnels the VIP + Local UI through BCM; Ctrl-C closes
```

### 2 — Mint the edge node's registration credentials

```bash
make palette-edge-credentials
```

An edge node registers itself: on first boot `palette-cleanup-stale.sh` (a
`stylus-agent` `ExecStartPre` hook) mints an edge-host token against Palette's
admin API, then stylus registers with it. To do that it needs a tenant-scoped
**API key** and a **project UID** from the tenant step 1 just created. Nothing in
the repo had those, so this step logs in as the tenant admin, finds the project,
creates the key, and records both in `.run-credentials.yml`:

```
Edge nodes will register to https://192.168.98.251
  project uid: 6ab469f35921b3e691ec3b3e
  api key:     recorded in .run-credentials.yml (0600)
```

**~1 min.** Re-runnable; it mints a new key each time.

### 3 — Edge node: build, deploy, boot, register

The credentials are baked into the image, so the image must be built **after**
step 2:

> **Version pinning — two numbers, and you want the second one.**
>
> | | Example | Where it comes from |
> |---|---|---|
> | package / bundle version | `4.10.17` | the `.tar.zst` filename and manifest |
> | **stylus agent version** | **`v4.10.4`** | inside the bundle — what you configure |
>
> You set it **once**, as `appliance_pe_version` in
> `inventory/group_vars/all.yml` (default in `inventory/hosts.yml`). Both images
> derive from it — `profiles/palette-appliance.yml` and
> `profiles/edge-to-appliance.yml` each pass
> `PE_VERSION: "{{ appliance_pe_version }}"` to CanvOS — so the edge node cannot
> end up on a different stylus than the appliance, and
> `playbooks/tasks/appliance_credentials.yml` checks the value against the bundle
> before anything is built. Get it from the bundle, never the filename:
>
> ```bash
> python3 playbooks/files/bundle_stylus_version.py artifacts/*.tar.zst
> ```
>
> This replaced three separate literals, and the failure mode is worth knowing
> because you would not find it by looking: with the edge profile's copy unset,
> CanvOS supplies its own default (`v4.10.0-rc.2` was observed), the node still
> registers and still reports `health: healthy` / `state: ready`, and it simply
> retries a self-upgrade forever (`failed to upgrade stylus: 2 errors occurred`).

```bash
make kairos-build ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml"   # ~25 min
make deploy-dd    ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml"   # ~8 min
make kairos-vm    ANSIBLE_ARGS="-e @profiles/edge-to-appliance.yml"   # ~15 min
```

The profile must be passed to **every** stage, or the stages disagree about which
artifact and BCM category they are operating on.

`node002` stays up throughout — that is required, and it is what the bridge-mode
provisioning LAN makes possible.

Confirm the image really points at your appliance before deploying (this reads the
installed disk, not the ISO — edge profiles put their cloud-config in `/oem`, not
into the ISO):

```bash
sudo sh -c 'LOOP=$(losetup -fP --show build/edge-appliance-disk.raw)
  partprobe "$LOOP"; udevadm settle
  MP=$(mktemp -d)
  for p in ${LOOP}p*; do
    [ "$(blkid -o value -s LABEL $p)" = COS_OEM ] && { mount -o ro $p $MP
      grep -oE "ENDPOINT=.*|PROJECTUID=.*" $MP/90_custom.yaml; umount $MP; break; }
  done; rmdir $MP; losetup -d "$LOOP"'
```

Expect `ENDPOINT=192.168.98.251` and the same `PROJECTUID` step 2 printed.

### 4 — Verify registration

```bash
make palette-edge-verify
```

Polls the tenant until the host appears (registration is asynchronous and happens
on the node, so nothing on the controller is told when it finishes):

```
1 edge host(s) registered with the appliance: edge-3190aa7c0fd041e1b1761e21c87139d1
```

**Registration lands ~7 min after the node starts booting** — the node needs
roughly two minutes just to bring up networking, then mints its token and
registers.

---

## Proving it registered to the *local* appliance

Four independent checks; the first and third together are conclusive.

```bash
AK=$(grep '^edge_palette_api_key:' .run-credentials.yml | awk '{print $2}')
PU=$(grep '^edge_palette_project_uid:' .run-credentials.yml | awk '{print $2}')

# 1. the record lives in YOUR appliance's own database
ssh bcm "curl -sk -X POST -H 'ApiKey: $AK' -H 'ProjectUid: $PU' \
  -H 'Content-Type: application/json' -d '{}' \
  https://192.168.98.251/v1/dashboard/edgehosts/search"

# 2. what the node is configured to talk to
#    /oem/palette-admin.env -> ENDPOINT=192.168.98.251
#    /run/stylus/userdata   -> paletteEndpoint: 192.168.98.251

# 3. the node cannot reach SaaS at all
#    curl https://api.spectrocloud.com/... -> 000 UNREACHABLE
#    curl https://192.168.98.251/system    -> 200

# 4. the minted token is listed in your tenant
ssh bcm "curl -sk -H 'ApiKey: $AK' https://192.168.98.251/v1/edgehosts/tokens"
```

Healthy end state:

```
name:    edge-3190aa7c0fd041e1b1761e21c87139d1
health:  healthy
state:   ready
in use:  (none)
```

`in use: (none)` is correct and expected: the host is **registered and available
for assignment**, not a worker in a running cluster. Making it a worker needs an
Edge Native cluster profile and a machine pool that references it — this repo
does not automate that today.

---

## Node layout

Node numbers are load-bearing: `roles/deploy_dd` derives the local-KVM address as
`bcm_internal_ip` prefix + `(9 + node number)`, and `roles/kairos_vm` derives the
slug, serial port, disk paths and VM name from the node name.

| Profile | Node | MAC | IP | Serial | Role |
|---|---|---|---|---|---|
| `palette-appliance` | node002 | `52:54:00:00:03:01` | `.11` | 4322 | the appliance |
| `edge-to-appliance` | node003 | `52:54:00:00:05:01` | `.12` | 4323 | edge node registered to it |
| `dgx-raid-kvm` | node004 | `52:54:00:00:06:01` | `.13` | 4324 | RAID emulation (unrelated) |

The VIP (`192.168.98.251`) must avoid BCM's DHCP pool (`.16`–`.250`),
`bcm_internal_ip` (`.2`), and every derived node address.

---

## Re-running

| Situation | Do this |
|---|---|
| Appliance image unchanged, redo the deploy | `make palette-deploy && make palette-node` |
| Cluster step failed after a good boot | `make palette-cluster` |
| Tenant step failed (usually Palette's API not up yet) | `make palette-tenant` |
| **Changed a profile or a cloud-config template** | delete `build/<ISO_NAME>.iso` and `build/<profile>-disk.raw*` first — stage 3 skips the *entire* input-generation block when the ISO already exists, so otherwise nothing rebuilds and the old image deploys looking successful |
| New tenant (appliance rebuilt) | re-run `make palette-edge-credentials`, then rebuild the edge image — the old key and project UID are gone with the old cluster |

---

## Failure signatures

| Symptom | Cause | Fix |
|---|---|---|
| `PXE-E18: Server response timeout`, BCM's dhcpd logs nothing | on a Docker/Kubernetes host, `br_netfilter` hands bridged IP frames to an `iptables FORWARD` chain whose policy is DROP. ARP still works (arptables, ACCEPT) and host pings still work (OUTPUT, not FORWARD), so everything *looks* fine | `scripts/provisioning-net.sh` installs the required `-i <bridge> -o <bridge> -j ACCEPT`. Per-bridge `nf_call_iptables=0` is **not** sufficient |
| Second compute VM gets no carrier, PXE times out | `bcm_internal_net_mode: socket` is point-to-point — one compute VM at a time | use `bridge` mode (the default) |
| Cluster sits at `Provisioning`, Local UI dies, nothing in any log | `stylus-agent` crash-looping `203/EXEC` on an `ExecStartPre` script its rootfs does not carry | `kairos_build_bcm_integration: false` for appliance profiles (already set in `profiles/palette-appliance.yml`) |
| Tenant step times out with a censored `no_log` failure | it started before Palette's API existed; the API comes up ~30 min after the cluster reports Running | `palette_cluster` now waits for the API itself; re-run `make palette-tenant` |
| `no EFI System Partition (vfat) found` right after a successful-looking install | either a cloud-config stage key rendered with nothing under it (YAML null → kairos-agent segfault), or the verify step raced udev | `check-cloud-config.py` catches the first at render time; the udev race is fixed in the verify task |
| Node registers but `failed to upgrade stylus` | the edge image's stylus version differs from the appliance's | both profiles now derive `PE_VERSION` from `appliance_pe_version`, so check that one value against the bundle (`bundle_stylus_version.py`) — and that no profile copy re-pins `PE_VERSION` |
| `https://<vip>/` dead in a browser, but `ansible bcm -m uri` gets 200 | the build host has no interface on the provisioning network | `make palette-console` |

`/var/log/node-installer` **on BCM** is the source of truth for the provisioning
half; `Finalize script:` lines carry the whole `dd` → grow → `efibootmgr` sequence.

---

## See also

[Palette appliance stage](stage-palette-appliance.md) ·
[`profiles/README.md`](../profiles/README.md) ·
[`artifacts/README.md`](../artifacts/README.md) ·
[Architecture + troubleshooting](architecture-and-troubleshooting.md)
