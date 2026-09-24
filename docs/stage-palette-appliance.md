# Optional — self-hosted Palette appliance (`make palette-appliance`)

Builds a **Palette management appliance** image and has **BCM provision it** onto a managed
node, exactly the way BCM provisions Kairos edge nodes. The rig then has its own Palette, so
edge nodes can register against it instead of SaaS.

> The appliance is **not a special case**: it is a build profile
> (`profiles/palette-appliance.yml`) flowing through the ordinary stages. What makes it an
> appliance rather than an edge node is one variable — `kairos_cloud_config_template`, which
> swaps the image's cloud-config wholesale.

| | |
|---|---|
| **Profile** | `profiles/palette-appliance.yml` |
| **Playbook** | `playbooks/palette-appliance.yml` (imports 03 → 04 → 05, then the cluster roles) |
| **Targets** | `make palette-appliance`, or `palette-build` / `palette-deploy` / `palette-node` / `palette-cluster` / `palette-tenant` |
| **Modes** | local-KVM (BCM must already be up — it is what provisions the node) |
| **Provenance** | ported from [palette-appliance-automation](https://github.com/blik616287/palette-appliance-automation) @ `8f29a40` |

## Flow

```
03 kairos-build   build/palette-appliance-disk.raw   (appliance cloud-config, self-install)
04 deploy-dd      BCM: software image + category + PXE + node registration
05 kairos-vm      PXE boot; BCM dd's the image; finalize grows + sets the UEFI entry
   palette_cluster  content bundle -> Local UI; create the management cluster
   palette_tenant   create + activate the first tenant
```

Stages 1–2 (`bcm-prepare`, `bcm-vm`) must already have produced a running BCM.

## The five things that make an appliance build different

Each of these was found the hard way; none is optional.

### 1. `kairos_cloud_config_template` — a different image, same pipeline

`kairos_build` renders the Kairos **edge** cloud-config by default (BCM integration, Palette
*registration*, the `kairos` user). The appliance needs its own
(`appliance-cloud-config.yaml.j2`: `stylus.applianceType: palette`, seeded Local UI admin,
storage bind-mounts). `kairos_user_data` cannot express this — it only *layers on top* of the
base config.

### 2. `kairos_build_self_install` — let the image install itself

An appliance/stylus image **boots its own installer**, and its config mounts `COS_PERSISTENT`
the moment those labels appear. The edge path (inject `kairos-agent install` over the serial
console) therefore loses a race against the very labels it writes, failing with
`device or resource busy` on every retry while writing nothing.

Self-install bakes the cloud-config into the ISO (`CanvOS/user-data` → `files-iso/config.yaml`)
and simply waits for the VM to power off. No injection, no teardown, no race.

### 3. `deploy_dd_finalize_install` — dd from the node-installer, not from the disk

Without it the stage-2 `dd` overwrites its own running rootfs and every post-`dd` step
silently fails:

```
Problem opening /dev/vda for reading! Error is 2.
run-dd.sh: /dev/shm/kinstall/timeout: No such file or directory
WARN: couldn't detect last partition, skipping grow
efivars or efibootmgr unavailable; skipping EFI entry creation
```

The `dd` succeeds and the disk is still unbootable. The finalize stage runs from the
node-installer NFS root, so the GPT fix, the `COS_PERSISTENT` grow and the `efibootmgr` entry
all work. Same reason `profiles/dgx-raid.yml` sets it.

### 4. `kairos_edge_custom_config` — bake in the content-signing key

The appliance verifies the content bundle against a public key **baked into the image**.
Without it the upload fails:

```
500 content verification failed: public key to verify content not found
```

The profile reads `artifacts/*.pem` and embeds it; `EDGE_CUSTOM_CONFIG` in `kairos_canvos_args`
tells CanvOS to ship it.

### 5. `kairos_vm_probe_user` / `_password` — the post-boot probe

`kairos_vm`'s boot probe SSHes in to confirm the node came up, defaulting to the **edge**
image's `kairos`/`kairos` account. An appliance image has no such user, so the probe can never
succeed and burns its full 10-minute timeout while the appliance sits there serving.

## Addressing

BCM owns the node's address. `roles/deploy_dd/tasks/node.yml` **derives** it for local-KVM as
`bcm_internal_ip` prefix + `(9 + node number)` — so **node002 is always `192.168.98.11`** — and
ignores `kairos_target_ip` on that path (that is remote-BCM only).

The VIP must therefore avoid three things: BCM's DHCP pool (`.16`–`.250`), `bcm_internal_ip`
(`.2`), and the derived node address. `.251` clears all three. `roles/palette_cluster` asserts
the VIP is not the node's own address.

## Reaching the appliance

The build host cannot route to the provisioning network, so **everything talks to the
appliance through BCM** (`delegate_to: bcm`), including the ~10 GB bundle: it is staged under
`/cm/shared/kairos/<profile>/` and pushed from there, then removed. On a customer head node
that is a large temporary footprint — check free space on `/cm` first.

That applies to your browser too: `https://<vip>/` from the desktop reaches nothing however
healthy the appliance is, which looks exactly like a failed deploy. BCM *is* on that network,
so tunnel through it:

```bash
make palette-console          # Ctrl-C closes it
#   https://localhost:15443/         tenant console
#   https://localhost:15443/system   system console
#   https://localhost:15080/         Local UI (appliance_admin_user)
```

It asks BCM for the node's current IP rather than trusting a var, forwards the VIP and the
node's Local UI port, and changes nothing. Both endpoints serve a self-signed certificate, so
the browser warning is expected.

## Inputs

Licensed artifacts go in `artifacts/`, auto-discovered by extension — see
[`artifacts/README.md`](../artifacts/README.md).

| Var | Purpose |
|---|---|
| `appliance_pe_version` | the **stylus agent** version in the bundle — *not* the filename (a `…-4.10.17.tar.zst` bundle ships stylus `v4.10.4`) |
| `appliance_vip` | management-cluster VIP; see Addressing above |
| `appliance_storage_pool_drive` | second disk on the node, **wiped** at deploy (`/dev/vdb` on local-KVM virtio) |
| `kairos_vm_disks` | the node's extra disks — a list of `{size, bus}`; `bus: nvme` emulates an NVMe controller |
| `appliance_csi_placement_count` / `_mongo_replicas` | `1` for single node; profile defaults are `3` |
| `appliance_admin_*` | Local UI login, baked into the image as a **hash** — see below |

### Credentials are sticky on purpose

`kairos_build` bakes a *hash* of `appliance_admin_password` into the image. A regenerated
password on a later stage installs an appliance nobody can log into — the Local UI answers and
every login 401s. `playbooks/tasks/appliance_credentials.yml` resolves
**inventory > persisted in `.run-credentials.yml` > generated**, so split runs stay consistent.
Deleting `.run-credentials.yml` after the image is built strands the appliance.

## Validate

```bash
# from BCM (the build host cannot reach the provisioning net)
ansible bcm -m uri -a "url=https://<node-ip>:5080/ validate_certs=false"     # Local UI 200
ansible bcm -m uri -a "url=https://<vip>/system validate_certs=false"        # Palette 200

# the image itself, before deploy
sudo losetup -fP --show build/palette-appliance-disk.raw   # expect COS_GRUB(vfat)+COS_OEM+
                                                           # COS_RECOVERY+COS_STATE+COS_PERSISTENT
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `device or resource busy` on every install retry, empty image | injected `kairos-agent install` racing the image's own installer | `kairos_build_self_install: true` |
| dd succeeds but the node will not boot; `timeout: not found`, `couldn't detect last partition` | stage-2 dd overwrote its own rootfs | `deploy_dd_finalize_install: true` |
| `500 content verification failed: public key to verify content not found` | signing key not baked into the image | `kairos_edge_custom_config` + `EDGE_CUSTOM_CONFIG` |
| Node re-PXEs and re-provisions in a loop | a stale VM from an earlier run was killed mid-`dd`, or the UEFI entry was never written | `make kairos-stop` before re-running; check the finalize log on BCM for `dd-install COMPLETE` |
| Boot probe times out while the Local UI answers | probe using the edge `kairos` account | `kairos_vm_probe_user` / `_password` |
| `Grow persistent ... requested size <= current` in the node's boot log | **benign** — finalize already grew `COS_PERSISTENT` | none |
| Cluster VIP unreachable | VIP collides with the derived node address | see Addressing |
| `https://<vip>/` dead in a browser while `ansible bcm -m uri` gets 200 | the build host has no interface on the provisioning network | `make palette-console` |
| `kairos-agent` segfaults in `DeepMerge`, then `no EFI System Partition (vfat) found` | a cloud-config stage key rendered with nothing under it (YAML null) | fixed at render time by `check-cloud-config.py`; if you add a template branch, emit the key only when populated |

`/var/log/node-installer` **on BCM** is the source of truth for the provisioning half —
`Finalize script:` lines carry the whole dd → grow → efibootmgr sequence.

## See also
[Stage 4 — deploy-dd](stage-4-deploy-dd.md) · [Stage 5 — kairos-vm](stage-5-kairos-vm.md) ·
[`artifacts/README.md`](../artifacts/README.md) · [`profiles/README.md`](../profiles/README.md)
