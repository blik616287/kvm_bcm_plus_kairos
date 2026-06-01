# Local KVM Deployment — Step-by-Step

End-to-end guide for standing up a **BCM 11.0 head node + a Kairos compute node**
entirely in local QEMU/KVM VMs, then registering that node with Palette. This is
the dev/demo path (`make all`, stages 1–6). For the remote-BCM path see
`README.md`.

What you end up with:
- A BCM head node VM (`BCM-HeadNode`) running DHCP/PXE/TFTP/NFS/HTTP on an
  internal socket network.
- A Kairos compute VM (`Kairos-ComputeNode`) that PXE-booted from BCM, had a
  prebuilt Kairos raw disk `dd`'d onto it, rebooted into Kairos under UEFI, and
  registered itself as an **edge host** in your Palette project.

Wall-clock: **~100–120 min**, dominated by stage 2 (BCM install) and stage 3
(CanvOS image build).

---

## 0. Prerequisites

```bash
make install-deps     # auto-installs on Debian/Fedora/Ubuntu
make setup            # verifies ansible, qemu, docker, sshpass, xorriso, lz4, jq, all.yml
test -e /dev/kvm && echo "KVM ok"
```

You need: Ansible, `qemu-system-x86_64` + `/dev/kvm`, Docker, `sshpass`, `jq`,
`xorriso`, `p7zip`, `lz4`, `mtools`, `dosfstools`, and OVMF (UEFI) firmware.
`make setup` must print `All prerequisites OK` before you continue.

> Docker must be usable by your user (the CanvOS/Earthly build in stage 3 shells
> out to `docker`). If `docker ps` needs sudo, add yourself to the `docker`
> group and re-login first.

---

## 1. Configure `inventory/group_vars/all.yml`

This file is the single source of truth and is gitignored. It is already
populated for this environment. The values that matter for a local run:

| Var | Value | Why |
|-----|-------|-----|
| `bcm_ssh_host` | `localhost` | BCM runs as a local VM reached via port-forward |
| `bcm_ssh_port` / `bcm_https_port` | `2222` / `10443` | Host ports forwarded to BCM `:22` / `:443` |
| `bcm_ssh_proxy_jump` | `""` | **must be empty** locally |
| `bcm_target_node` | *(unset)* | when empty, deploy-dd auto-registers `node001` bound to `kairos_vm_mac` |
| `bcm_source_category` | `default` | the category a fresh BCM ships with |
| `kairos_target_disk` | `/dev/vda` | the compute VM's virtio disk |
| `kairos_vm_mac` | `52:54:00:00:02:01` | binds the registered device to the PXE-booting VM |
| `palette_endpoint` | `palette.isc-spectro-dev.click` | **baked in at build time — see warning below** |
| `palette_project_uid` | `69d6c1308390e83a5e40405c` | project the edge host lands in; needed to mint the token |
| `palette_api_key` | *(set)* | tenant-admin key; mints token + cleans stale records |

> ⚠️ **Palette endpoint is baked into the image at build time (stage 3).** It is
> not a runtime knob. To target a different Palette tenant you must rebuild:
> `make clean-canvos && make kairos-build`. Set it correctly before you build.

> ⚠️ **`kairos_target_disk` is `dd`'d — destructive.** Locally this is the VM's
> own `/dev/vda`, so it's safe. Never point it at a real disk you care about.

### Verify the JFrog ISO path before a long run

Stage 1 downloads the licensed BCM ISO from JFrog and fails immediately if the
repo/filename is wrong. Confirm it exists first:

```bash
curl -sI -H "Authorization: Bearer <jfrog_token>" \
  "https://insightsoftmax.jfrog.io/artifactory/iso-releases/bcm-11.0-ubuntu2404.iso" \
  | head -1     # expect: HTTP/.. 200
```

If the filename differs, update `iso_filename` / `jfrog_repo` in `all.yml`.

### Check host ports are free

```bash
ss -tlnp | grep -E ':(2222|10443) ' || echo "ports free"
```

If either is in use, change `bcm_ssh_port` / `bcm_https_port` in `all.yml`.

---

## 2. Run the pipeline

### Option A — one shot (recommended)

```bash
make all
```

Runs stages 1→6 in order (`playbooks/site.yml`), tee'd to `logs/<stage>.log`.

### Option B — stage by stage (better for first run / debugging)

Run each, confirm it's green, then proceed:

```bash
make bcm-prepare    # 1  ~2 min   — download + patch + remaster BCM ISO
make bcm-vm         # 2  ~60-90m  — install BCM in KVM, boot from disk, wait for services
make kairos-build   # 3  ~30 min  — CanvOS ISO + OVMF raw disk (build/default-kairos-disk.raw)
make deploy-dd      # 4  ~3-5 min — upload image to BCM, configure PXE + kairos category
make kairos-vm      # 5  ~10 min  — PXE boot compute VM, dd Kairos, reboot
make validate       # 6  ~15 sec  — ~40-point health check
```

Stages 2 and 3 are independent — you can run `make bcm-vm` and `make
kairos-build` in two terminals at the same time to save wall-clock.

---

## 3. Watch progress

Each stage logs to `logs/`. The two VMs also expose serial consoles:

```bash
make bcm-serial      # tail logs/bcm-serial.log  — BCM auto-install console (stage 2)
make kairos-serial   # tail logs/kairos-serial.log — Kairos PXE + dd + boot (stage 5)
tail -f logs/03-kairos-build.log   # CanvOS/Earthly build output (stage 3)
```

Reaching BCM directly once stage 2 is up:

```bash
ssh -p 2222 root@localhost        # password: HelloRubyTuesday
# https://localhost:10443         # BCM Base View / web UI
```

---

## 4. What each stage actually does

1. **bcm-prepare** — pulls `bcm-11.0-ubuntu2404.iso` from JFrog into `dist/`,
   patches the rootfs, and remasters it for unattended auto-install.
2. **bcm-vm** — boots the remastered ISO in QEMU (UEFI), auto-installs BCM to a
   100G qcow2 disk, reboots from disk, and waits for `cmd`/DHCP/named/NFS to come
   up. Two-phase: install, then boot-from-disk.
3. **kairos-build** — clones CanvOS, renders `.arg` from `kairos_canvos_*`,
   `./earthly.sh +iso` builds the Palette-edge ISO, then an **OVMF QEMU install**
   produces `build/default-kairos-disk.raw`. Your Palette endpoint/project are
   baked into `/oem/*.yaml` here.
4. **deploy-dd** — SSHes to BCM, uploads the lz4-compressed image to
   `/cm/shared/kairos/default-kairos/disk.raw.lz4`, registers the
   `default-kairos-installer` software image + `install-kairos.sh`, clones the
   `default` category into a `default-kairos` category, **auto-adds `node001`**
   (MAC `52:54:00:00:02:01`) in FULL install mode, and adds the
   health-check exclude filter + NFS export ACLs.
5. **kairos-vm** — launches the compute VM on the internal socket network. It
   PXE-boots from BCM, the installer `curl`s the image over HTTP and
   `dd | lz4 -d`'s it onto `/dev/vda`, fixes the GPT + grows the last partition,
   writes a UEFI boot entry, and reboots into Kairos.
6. **validate** — ~40 checks across BCM and the Kairos node.

---

## 5. Verify success

```bash
make validate
```

Then confirm the node registered in Palette:

- UI: `https://palette.isc-spectro-dev.click` → project **Default** → Edge Hosts.
  A host named `edge-<smbios-uuid>` should appear (Ready / waiting to be assigned
  to a cluster).
- The Kairos serial console (`make kairos-serial`) should show stylus-agent
  registering, then a login prompt.

> The node registers as an **edge host** only. It is not running Kubernetes yet —
> that happens when you build a Palette cluster profile whose BYOOS
> (`edge-native-byoi`) OS layer sets `system.uri` to a provider image. On this
> local day-1 path the provider image is only in the local Docker daemon, so for
> a real cluster you'd `make kairos-image` to push it to a persistent registry
> first, then use that ref as `system.uri`.

---

## 6. Stop / clean up / re-run

```bash
make stop           # stop both VMs (bcm-stop / kairos-stop individually)
make teardown       # stop VMs + remove build/ + logs/ (keeps dist/ ISO + CanvOS/ clone)
make clean          # remove build/ + logs/
make clean-canvos   # remove the CanvOS clone + per-profile raw artifacts (needed to rebake the image)
make clean-all      # stop VMs + remove everything (build, logs, dist, CanvOS)
```

Idempotency / re-running:
- `bcm-prepare`, `bcm-vm`, `kairos-build` skip work if their artifacts already exist.
- `deploy-dd` and `validate` always re-run.
- `kairos-vm` kills any existing compute VM, resets the node to FULL install, and
  creates a fresh disk.

Force a full rebuild:

```bash
make clean && make all
```

If you changed anything that's **baked into the image** (Palette endpoint/project,
`kairos_canvos_args`, `kairos_extra_apt_packages`, `kairos_user_data`), you must
rebake — `clean-canvos` first:

```bash
make clean-canvos && make kairos-build deploy-dd kairos-vm
```

---

## 7. Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| `make setup` fails on `all.yml` | `inventory/group_vars/all.yml` missing — it must exist. |
| Stage 1 fails downloading ISO | Wrong `jfrog_token` / `jfrog_repo` / `iso_filename`; verify the curl in §1. |
| Stage 2 aborts "port 2222 in use" | Another service on the host port; change `bcm_ssh_port`. |
| Stage 3 docker permission denied | Add user to `docker` group, re-login. |
| Stage 5 node never PXE boots | `kairos_vm_mac` must match the MAC deploy-dd registered (auto path uses `kairos_vm_mac`); the two VMs must share socket net `:31337`. |
| Node not in Palette after boot | Check `make kairos-serial` for stylus errors; confirm `palette_api_key` + `palette_project_uid` are valid (token-mint needs them). Endpoint must be reachable from the node. |
| Need to repoint to a different Palette | Endpoint is build-time baked → `make clean-canvos && make kairos-build deploy-dd kairos-vm`. |

Logs to attach when asking for help:
`logs/0{1..6}-*.log`, `logs/bcm-serial.log`, `logs/kairos-serial.log`,
`logs/qemu-install.log`.
