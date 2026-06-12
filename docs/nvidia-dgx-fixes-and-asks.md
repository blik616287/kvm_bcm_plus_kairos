# NVIDIA DGX SuperPod — Kairos provisioning: fixes shipped + open item + asks

**Prepared for:** NVIDIA — BCM 11.0 + Spectro Cloud Kairos edge reference architecture (DGX SuperPod target, `dgx03`).
**Date:** 2026-06-12.

## TL;DR

From the `dgx03` logs (`node-installer.log` + `/dev/shm/kairos-install.log`) we found **three** issues:

1. **COS_PERSISTENT never grows → "crashes minutes after boot."** Fixed — **PR #17**. *(This is the one that explains the reported crash.)*
2. **Post-`dd` partition ops hit "device busy."** Fixed — **PR #15** (backstop).
3. **Node boots the BCM Ubuntu image instead of Kairos, and reverts to FULL.** **Not yet fixed** — it's a BCM/BMC boot-order behavior. We have a recommended step + need a little data from you to finalize it.

Items 1 and 2 ship with `make deploy-dd` + re-PXE — **no image rebuild**.

---

## Fix 1 — COS_PERSISTENT never grows (PR #17) — *the important one*

**What your `kairos-install.log` showed:**

```
Growing last partition + ext4 to fill disk...
The operation has completed successfully.            # sgdisk recreated p5 (table only)
Timed out for waiting the udev queue being empty.
e2fsck:   No such device or address while trying to open /dev/nvme1n1p5
resize2fs: open: No such device or address while opening /dev/nvme1n1p5
```

`sgdisk` recreated partition 5 in the table, but **`/dev/nvme1n1p5` never appeared as a device node**, so `e2fsck`/`resize2fs` couldn't open it and the grow silently failed. `COS_PERSISTENT` stays at the ~30 GB image size on the 1.7 TB partition → it fills under real workload → the node becomes unstable and **crashes a few minutes after boot**. This matches the originally reported symptom.

**Cause:** a `udevadm control --stop-exec-queue` we had added in PR #15 paused udev around the table surgery. With the queue paused, udev never processed the uevent that creates the new partition node — so `resize2fs` had nothing to open. The same pause is also why you saw `Timed out for waiting the udev queue being empty` (×4) and ~4 minutes of stall per run.

**Fix (PR #17):** removed the exec-queue pause. The unmount / `swapoff` / `vgchange` / `mdadm --stop` / `dmsetup remove_all` releases already free the disk; the pause was unnecessary and actively broke the grow.

---

## Fix 2 — post-`dd` "device or resource busy" (PR #15) — backstop

After `dd`, systemd/udev on the node auto-activate the freshly-written cOS partitions (auto-mount by `COS_*` label, LVM/mdraid auto-assembly, `blkid` scans), holding the disk open so the kernel can't re-read the table (`EBUSY`). PR #15 added a post-`dd` quiesce (unmount, `swapoff`, `vgchange -an`, `mdadm --stop`, `dmsetup remove_all`) before the GPT-fix/grow/boot-entry steps. With Fix 1 on top, your latest log already shows **no EBUSY** on `wipefs`/`dd`/GPT.

---

## Fix 3 (config, not a commit) — take the Kairos target disk out of the RAID

The Kairos installer `dd`s a whole-disk image onto `nvme1n1`. If `nvme1n1` is also a member of a BCM disksetup RAID, the two fight: BCM re-validates `nvme1n1` every boot, finds it no longer matches → wipes and rebuilds → destroys Kairos → loop. **Remove `nvme1n1` (and the data disks) from the category disksetup** so BCM never claims it. Your latest run already targets `nvme1n1` cleanly with no EBUSY, so this is in place.

---

## How to apply (no image rebuild)

```bash
git pull                        # PR #15 + PR #17 on main
make deploy-dd ANSIBLE_ARGS="-e kairos_profile=default-kairos -e bcm_target_node=dgx03"
# then re-PXE dgx03 once
```

`install-kairos.sh` is rendered + uploaded by `deploy-dd` — it is **not** baked into the image, so this is installer-only.

**Verify Fix 1 after re-PXE:**

```bash
lsblk /dev/nvme1n1     # COS_PERSISTENT (p5) should fill the disk (~1.7T), not stick at ~30G
```

---

## Open item — the node boots Ubuntu instead of Kairos (and reverts to FULL)

**What you observed:** after a clean Kairos install, the node boots the BCM-provisioned Ubuntu (on `nvme2n1`) and the node flips back to FULL — Kairos on `nvme1n1` never boots.

**What we can prove from the logs:**

- The Kairos installer **does** set Kairos first in the UEFI boot order — `BootOrder: 0005,0004,0009,…` with `Boot0005* Kairos …\EFI\BOOT\bootx64.efi` ahead of `Boot0004* Ubuntu …\EFI\ubuntu\shimx64.efi`. So the UEFI side is correct.
- Yet the node boots Ubuntu and re-runs the node-installer (the only way it reverts to FULL). That means **something is overriding the UEFI BootOrder** and re-entering the installer. On BCM-managed servers that is almost always the **BMC boot device being forced to PXE** by CMDaemon.
- The node-installer log also shows that even in NOSYNC it escalated to FULL because a disksetup disk failed validation (`Error: /dev/nvme3n1: unrecognised disk label` → `Creating new disk layout` → `install mode: FULL`), and then `grub installed on /dev/nvme2n1` — i.e., BCM re-owns the boot via the Ubuntu root it keeps on `nvme2n1`/`nvme3n1`. (That root is a 3.5 TB RAID1 whose resync hadn't finished — `finish=1542min` — which is a likely reason `nvme3n1` looked invalid on the next boot.)

**We have NOT directly captured a second PXE boot** — "the BMC re-PXEs every cycle" is our best explanation for "Kairos was first yet Ubuntu booted," not something we've logged. The asks below confirm it.

### Recommended immediate step (and the cleanest diagnostic) — yes, set boot-to-disk

After the Kairos installer powers off:

```bash
# 1) stop BCM from re-provisioning the node
cmsh -c "device use dgx03; set installmode NOSYNC; commit"

# 2) point the node at its LOCAL DISK instead of PXE (BMC-level, make it persistent)
ipmitool -H <bmc> -U <user> -P <pw> chassis bootdev disk options=persistent
#   (or set the boot device to "disk/HDD" in the DGX BMC UI)

# 3) power on
ipmitool -H <bmc> -U <user> -P <pw> chassis power on
```

Expected if the theory holds: the firmware honors `Boot0005 "Kairos"` (first in BootOrder) → **Kairos boots from `nvme1n1`** → its cloud-config keeps the node NOSYNC, so it stops re-provisioning.

- If it boots Kairos and **stays**: confirms the root cause is the boot hand-off, and the durable fix is "make BCM boot the node from local disk after the Kairos install."
- If it **still** boots Ubuntu or re-PXEs: BCM is re-asserting the boot device each cycle, and the durable fix is a BCM-side change — either **diskless installer-env** (provision the `…-installer` root in RAM/NFS so no competing Ubuntu root is ever written), or disabling PXE for the node once it's provisioned.

> Note: `install-kairos.sh` now also sets **BootNext** to the Kairos entry, which forces the *next* boot to Kairos even over a network-first BootOrder — but BootNext is a UEFI-level override and will **not** help if the BMC forces the boot device in hardware. That's why the BMC/disk step above matters.

### Asks — the data that tells us which durable fix to build

On the **next power-on after a Kairos install**, please capture any of:

1. **Serial console at power-on** — does it print `>>Start PXE over IPv4`, or `BdsDxe: … starting Boot0005 "Kairos"`? (This alone settles the PXE-vs-disk question.)
2. **`efibootmgr -v`** taken right after the installer powers off — is `Boot0005 Kairos` still first in `BootOrder`?
3. **`ipmitool chassis bootparam get 5`** — is the boot device forced to PXE, and is it persistent?
4. **`lsblk /dev/nvme1n1`** after a boot with PR #17 applied — did `COS_PERSISTENT` grow to ~1.7 TB? (Confirms Fix 1.)

With (1)–(3) we can tell you definitively whether to go "set boot-local after install" or "diskless installer-env," and ship it.

---

## Reference — commits

| Item | Where | State |
|------|-------|-------|
| COS_PERSISTENT grow / udev-queue stall | PR #17 (`install-kairos.sh`) | merged to `main` |
| Post-`dd` EBUSY quiesce | PR #15 (`install-kairos.sh`) | merged to `main` |
| Kairos target out of disksetup RAID | category `disksetup` (cmsh) | applied on `dgx03` |
| Boot hand-off (Ubuntu vs Kairos) | BCM/BMC boot policy | **open — see asks** |
