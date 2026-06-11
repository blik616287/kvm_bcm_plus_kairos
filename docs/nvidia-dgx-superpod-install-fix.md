# NVIDIA DGX SuperPod — Kairos PXE install: partition-table EBUSY fix

**Prepared for:** NVIDIA — BCM + Kairos edge reference architecture (DGX SuperPod target node).
**Status:** fix **merged to `main`** (PR #15, 2026-06-11). Installer-script only — applying it is `make deploy-dd` + re-PXE, **no image rebuild**.

---

## TL;DR

On the DGX, the image `dd`s onto the disk fine, but **every partition-table step afterward fails with "device in use / resource busy."** The most likely consequences are that the persistent partition never grows (stays ~30 GB on the multi-TB NVMe) and/or the UEFI boot entry is written against a stale table — either of which fits *"boots, then crashes a few minutes later."* The fix releases the partition holders after `dd`, before the grow/boot-entry steps.

---

## What the recording shows

The console capture is the **PXE install phase** (`install-kairos.sh` on the BMC console), not the Kairos boot:

1. ✅ `dd` succeeds — `85899345920 bytes (86 GB, 80 GiB) copied, ~210 MB/s`.
2. ❌ Then every partition-table operation fails:

   ```
   Fixing GPT backup header...
     Warning: the kernel is still using the old partition table ... in use
     Error! Partition(s) 1,2,3,4,5 on /dev/nvme0n1 ... unable to inform the
     kernel of the change, probably because it/they are in use.
   Growing last partition + ext4 to fill disk...
     e2fsck: Cannot continue, aborting.
     resize2fs: Device or resource busy while trying to open /dev/nvme0n1p5
     Couldn't find valid filesystem superblock.
   ```

3. The install then reaches its **by-design** `sysrq` poweroff (`Write complete. Powering off…` → "No Signal" → "Powered Off"). That poweroff is expected — the node is meant to be powered back on to boot from disk — so it is easy to mistake for a crash.

The errors are non-fatal in the script (guarded with `|| true`), so the install "completes" but in a **degraded** state.

## Root cause

On the DGX, the BCM node-installer is a **full-systemd environment**. The moment `dd` lays down the cOS partition signatures, systemd/udev **auto-activate** them — auto-mount by `COS_*` filesystem label, and/or LVM/mdraid auto-assembly, and/or udev `blkid` scans. That holds `/dev/nvme0n1` open, so the kernel cannot re-read the partition table (`EBUSY`).

The installer already quiesces the disk **before** `dd`, but that cannot cover activations that happen **after** `dd` re-creates the signatures. This is also why it did not surface in local-KVM testing — the KVM compute node's minimal installer does not auto-mount the new partitions, so the same code path works there.

## Why this matches "crashes a few minutes after boot"

The EBUSY failures have two downstream effects, both consistent with the reported symptom:

- **`COS_PERSISTENT` is never grown** (`resize2fs` cannot open p5), so it stays at the build size (~30 GB) on the large NVMe. Under real k8s / GPU / container load it fills quickly → the node becomes unstable and crashes shortly after coming up. *This is the leading hypothesis.*
- The **stale partition table** can make `efibootmgr` record a zero/garbage GPT GUID for the boot entry, which UEFI greys out → unreliable boot on the next power-on.

## The fix

Adds a **post-`dd` quiesce** before the GPT/grow steps, in `roles/deploy_dd/templates/install-kairos.sh.j2`:

- `udevadm settle` + pause udev's exec-queue (so it stops re-opening the partitions during the table rewrite),
- unmount anything auto-mounted from the target, `swapoff`, `vgchange -an`, `mdadm --stop`, `dmsetup remove_all`,
- resume udev before the `efibootmgr` step.

It is fully guarded (`|| true`, `[ -x … ]`), so it is a **no-op** where there is nothing to release (the existing/working paths are unchanged). It **complements** — does not replace — the existing `timeout` guards around `e2fsck`/`resize2fs` (those guard a separate e2fsprogs *hang*; on a held-open partition `resize2fs` returns busy immediately and the timeout never fires).

## How to apply (no image rebuild)

The change lives in `install-kairos.sh`, which `deploy-dd` renders and uploads — not in the image:

```bash
git pull                 # get the merged fix on main
make deploy-dd           # re-pushes the installer to BCM
# then re-PXE the DGX node
```

## Please help confirm it was this

This was diagnosed from the recording and has not been reproduced on a DGX here, so it is a strong candidate, not a certainty. If possible, capture this on the node right after `dd` (or before re-running) to pin the exact holder:

```bash
cat /proc/mounts | grep nvme0n1
lsof /dev/nvme0n1p5
dmsetup ls ; cat /proc/mdstat ; vgs
```

The fix handles all of those regardless, but the output identifies which one it was. After re-provisioning with the fix, `lsblk` should show `COS_PERSISTENT` filling the disk rather than stuck at ~30 GB.

## Separate note — Palette registration files

The *"missing files to register with our self-hosted Palette endpoint"* is a **different** issue from the partition crash (cloud-config / stylus side, not the installer). For an on-prem Palette the usual gaps are `palette_ca_cert` (the self-signed CA PEM — required, or TLS to the endpoint fails) and the `palette_endpoint` / `palette_token` / `palette_api_key` values. If you share which specific files it flags (or the `stylus-agent` log), we can trace that one too.
