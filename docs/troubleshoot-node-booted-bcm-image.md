# Troubleshooting: node booted the BCM installer image, not Kairos

**Symptom:** after a deploy, the compute node is SSH-reachable and `make validate` mostly passes, but the Kairos-specific checks fail:

```
[FAIL] Kairos release
[FAIL] kairos-agent
[WARN] net.ifnames=0
[WARN] Kairos boot chain
[WARN] COS_OEM / COS_RECOVERY / COS_STATE / COS_PERSISTENT — not found
[WARN] Root immutable
[FAIL] OEM config
[WARN] stylus-agent — inactive
OS — Ubuntu 24.04.x LTS   Kernel — 6.8.0-51-generic
```

The node also "isn't rebooting," and it never appears in the Palette UI.

## What it means

The node is running the **BCM installer image** — `<profile>-installer`, which is a **clone of `default-image`** (plain Ubuntu) — **not** Kairos. No `COS_*` partitions, no `kairos-agent`, a stock BCM kernel (`6.8.0-51-generic`), and a mutable root all confirm it.

> BCM registration ≠ Kairos ≠ Palette. The node shows up as a registered BCM device (`kairos-3`) because that happens at PXE/node-installer time. It never became Kairos, so it can't register with Palette. The "no API key" Palette WARN is a *separate* issue (empty `palette_api_key`).

## The intended flow (and where it stalled)

From `roles/deploy_dd/templates/deploy-dd.sh.j2:256–284`, `deploy-dd`:
- copies `install-kairos.sh` into the installer image at `/usr/local/sbin/install-kairos.sh`, and
- installs + enables a systemd unit **`kairos-install.service`**
  (`Type=oneshot`, `ExecStartPre=sleep 10`, `ExecStart=/usr/local/sbin/install-kairos.sh`, `TimeoutStartSec=1800`, `WantedBy=multi-user.target`).

So the design is:

> PXE → node-installer provisions `<profile>-installer` (the Ubuntu clone) → node boots that Ubuntu → **`kairos-install.service` runs `install-kairos.sh`** → `dd`s the Kairos raw onto the disk → `efibootmgr` + **reboot into Kairos**.

A *successful* `install-kairos.sh` ends in a `sysrq` reboot into Kairos. **"Node isn't rebooting" + no `COS_*` partitions = `kairos-install.service` never completed the `dd`.** It either didn't run, or failed before the reboot.

## Diagnose — run on the node

From BCM, `ssh kairos-3` (the node's IP, e.g. 10.184.70.165):

```bash
systemctl status kairos-install.service
journalctl -u kairos-install.service -b --no-pager | tail -60
cat /dev/shm/kairos-install.log 2>/dev/null      # install-kairos.sh logs here
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT       # which disk? is kairos_target_disk correct?
ls -l /usr/local/sbin/install-kairos.sh          # did the script land?
```

The log shows the exact failure. Two most likely causes (especially after stale files from a previous run):

### 1. `dd` hit the wrong / empty disk
`kairos_target_disk` must be the node's **actual boot disk**. On `ens18`/virtio VMs it's usually `/dev/vda`; if BCM provisioned Ubuntu to `/dev/sda` and `install-kairos` `dd`'d `/dev/vda` (or vice-versa), Kairos lands on a non-boot disk or the `dd` fails. `lsblk` settles it — if a *different* disk shows `COS_*`, that's the split.

### 2. Stale Kairos raw / installer image, or the service wasn't enabled
Check on BCM:

```bash
ls -l /cm/shared/kairos/<profile>/disk.raw.lz4                                   # current build?
ls -l /cm/images/<profile>-installer/usr/local/sbin/install-kairos.sh            # fresh script?
ls -l /cm/images/<profile>-installer/etc/systemd/system/multi-user.target.wants/kairos-install.service  # enabled?
```

If that symlink is missing, the unit was defined but **not enabled**, so it never ran on boot.

## Fix path

Once the log shows which it is:

| Root cause | Fix |
|---|---|
| Wrong disk | set `kairos_target_disk` to the real boot disk → `make deploy-dd` → re-PXE (FULL) |
| Service not enabled / stale script | `make deploy-dd` (re-injects + enables + rebuilds ramdisk) → re-PXE (FULL) |
| Stale raw image | `make kairos-build` → `make deploy-dd` → re-PXE (FULL) |

## Next wall (after the `dd` succeeds): the boot-handoff loop

Even once `install-kairos` `dd`s Kairos and reboots, watch that the node doesn't just **PXE again and re-provision the Ubuntu installer over it**. If it does, the node must be pointed at the **local disk** after the install (not network-first) so it boots the Kairos it just wrote. But get `kairos-install.service` to complete the `dd` first — the `journalctl` / `/dev/shm/kairos-install.log` output pinpoints the failing step.
