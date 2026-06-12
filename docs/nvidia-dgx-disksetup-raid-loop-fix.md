# NVIDIA DGX SuperPod — Kairos provisioning loop: BCM RAID vs. single-disk `dd`

**Prepared for:** NVIDIA — BCM + Kairos edge reference architecture (DGX SuperPod target node).
**Scope:** Root-cause + one-shot fix for the DGX re-provisioning loop on `dgx03`. Companion to `nvidia-dgx-superpod-install-fix.md` (the post-`dd` EBUSY quiesce, PR #15) — this doc covers the *underlying* disk-layout conflict that also produces that EBUSY.

> **Update (2026-06-12):** read **`nvidia-dgx-fixes-and-asks.md`** for the current consolidated status. Two things changed since this was written: (1) the `COS_PERSISTENT` grow failure — the real "crashes minutes after boot" symptom — is fixed in **PR #17**; (2) the RAID1 installer-env root on `nvme2/3` recommended below is itself what forces the node back to FULL and boots Ubuntu instead of Kairos (it fails disk validation mid-resync). Prefer a **diskless** or **minimal single-disk** installer-env over the RAID1 root shown here, and see the boot-hand-off asks in that doc.

---

## TL;DR

BCM's category disksetup puts the Kairos target disk (`/dev/nvme0n1`) into an 8-disk RAID0 (`md2`). Kairos's installer then `dd`s a whole-disk image onto that same `nvme0n1`. The two are mutually destructive, so the node **re-provisions in a loop** and never boots Kairos. Fix: **remove `nvme0n1` (and the data disks) from the BCM disksetup** so Kairos owns `nvme0n1` end-to-end. Replacement disksetup + apply steps below; re-PXE once.

---

## Evidence — the node is in a re-provision loop

From `dgx03`'s `/var/log/node-installer`, three installer runs ~30 min apart, each re-partitioning the disks:

| Boot | installmode | What BCM found | What BCM did |
|------|-------------|----------------|--------------|
| 12:23 | **FULL** | — | wiped all 10 NVMe, built `md0`/`md1`/`md2`, FULL-provisioned the BCM Ubuntu image to `md1`, GRUB on `nvme2n1` (kernel 6.8.0-51) |
| 12:53 | NOSYNC | "**Number of partitions on nvme0n1 is incorrect**" → recreate | wiped & rebuilt the whole mdraid layout again |
| 13:23 | NOSYNC | "nvme0n1 is **ok**, **nvme1n1 is incorrect**" → recreate | wiped & rebuilt again |

The DGX disk layout BCM builds each cycle (`lsblk` from the log):

```
nvme2n1 / nvme3n1 :  EFI + md0 (RAID1 /boot, 4G ext2) + md1 (RAID1 /, ext4)
nvme0n1,1,4,5,6,7,8,9 : md2 (RAID0 /localdisk/raid, ~24-26 TB ext4)   <-- nvme0n1 is a member
```

## Root cause — a tug-of-war over `/dev/nvme0n1`

Every boot, two systems fight over the same disk:

1. **BCM** puts `nvme0n1` into the `md2` RAID0 and FULL-provisions an Ubuntu HPC image (to `md1`, GRUB on `nvme2n1`).
2. The node boots; because the assigned software image is `default-kairos-installer`, **`install-kairos.sh` runs and `dd`s the Kairos image onto `/dev/nvme0n1`**, replacing its RAID member with a 5-partition Kairos GPT (`COS_GRUB/OEM/RECOVERY/STATE/PERSISTENT`).
3. On the **next** PXE boot, BCM validates the disks against the disksetup, sees `nvme0n1` no longer matches → **"partitions incorrect" → wipes `nvme0n1` and rebuilds the entire mdraid**, destroying the Kairos install.
4. …which re-runs `install-kairos.sh`, which `dd`s `nvme0n1` again → **loop.**

(The "incorrect" disk alternates between `nvme0n1`/`nvme1n1` because the `dd` breaks the 8-member `md2`, so each reassembly finds a different member inconsistent.)

This is also the source of the `Device or resource busy` / "in use" errors in the install recording: while `md2` is assembled, `install-kairos.sh`'s `dd`/`partprobe`/`resize2fs` on `nvme0n1` hit EBUSY because the disk is an active RAID member.

**A single-disk `dd` install and a RAID layout that includes that disk cannot coexist.** The disksetup must stop claiming `nvme0n1`.

---

## The fix (one-shot)

### 1) Replacement disksetup for the `default-kairos` category

Keeps a small BCM installer-environment root on `nvme2n1`+`nvme3n1` (BCM needs *somewhere* to provision and boot the `…-installer` image that runs `install-kairos.sh`), and **omits `nvme0n1` and all data disks** so Kairos owns `nvme0n1` and BCM never re-checks/re-partitions it.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<diskSetup>
  <!-- BCM installer-env root only (nvme2n1+nvme3n1, RAID1).
       /dev/nvme0n1 (kairos_target_disk) and all data disks are intentionally
       NOT listed: BCM must never touch nvme0n1, or it fights install-kairos.sh's
       dd and re-provisions every boot. Kairos/Palette manage the data disks. -->
  <device>
    <blockdev>/dev/nvme2n1</blockdev>
    <partition id="efi" partitiontype="esp">
      <size>100M</size>
      <type>linux</type>
      <filesystem>fat</filesystem>
      <mountPoint>/boot/efi</mountPoint>
      <mountOptions>defaults,noatime,nodiratime</mountOptions>
    </partition>
    <partition id="boot1">
      <size>4G</size>
      <type>linux raid</type>
    </partition>
    <partition id="slash1">
      <size>max</size>
      <type>linux raid</type>
    </partition>
  </device>
  <device>
    <blockdev>/dev/nvme3n1</blockdev>
    <partition id="efi2" partitiontype="esp">
      <size>100M</size>
      <type>linux</type>
      <filesystem>fat</filesystem>
    </partition>
    <partition id="boot2">
      <size>4G</size>
      <type>linux raid</type>
    </partition>
    <partition id="slash2">
      <size>max</size>
      <type>linux raid</type>
    </partition>
  </device>
  <raid id="boot">
    <member>boot1</member>
    <member>boot2</member>
    <level>1</level>
    <filesystem>ext2</filesystem>
    <mountPoint>/boot</mountPoint>
    <mountOptions>defaults,noatime,nodiratime</mountOptions>
  </raid>
  <raid id="slash">
    <member>slash1</member>
    <member>slash2</member>
    <level>1</level>
    <filesystem>ext4</filesystem>
    <mountPoint>/</mountPoint>
    <mountOptions>defaults,noatime,nodiratime</mountOptions>
  </raid>
</diskSetup>
```

Difference from the current disksetup: deleted the `nvme0n1` and `nvme1/4/5/6/7/8/9` device blocks and the 8-disk `<raid id="raid">` (`md2`). The `nvme2/3` root is unchanged.

### 2) Apply on the head node

```bash
cmsh
[bcm]% category use default-kairos
[bcm->category[default-kairos]]% set disksetup      # paste the XML above, save & close the editor
[bcm->category*[default-kairos*]]% commit
[bcm->category[default-kairos]]% device use dgx03
[bcm->device[dgx03]]% set installmode FULL          # one clean install; the node self-sets NOSYNC after Kairos boots
[bcm->device*[dgx03*]]% commit
[bcm->device[dgx03]]% quit
```

### 3) Refresh installer + image, then re-PXE

On the build host:

```bash
git pull            # PR #15 post-dd quiesce — now a backstop since nvme0n1 is RAID-free
make deploy-dd ANSIBLE_ARGS="-e kairos_profile=default-kairos -e bcm_target_node=dgx03"
```

Set `kairos_wipe_disks` to the sibling data disks so `install-kairos.sh` clears their stale `md2` superblocks (prevents leftover RAID metadata re-assembling):

```yaml
kairos_wipe_disks: "nvme1n1 nvme4n1 nvme5n1 nvme6n1 nvme7n1 nvme8n1 nvme9n1"
```

Then power-cycle `dgx03` to PXE once.

---

## Expected result + verification

1. BCM provisions its installer-env to `md0`/`md1` on `nvme2n1`/`nvme3n1` only — **no `md2`, `nvme0n1` untouched**.
2. The node boots; `install-kairos.sh` `dd`s Kairos onto a now-free `nvme0n1` — **no EBUSY**, `COS_PERSISTENT` grow succeeds, `efibootmgr` writes a valid `Kairos` entry first in BootOrder.
3. Reboot → UEFI boots **Kairos from `nvme0n1`** → registers with Palette → cloud-config flips `dgx03` to `NOSYNC`.
4. **No re-provision loop:** `nvme0n1` isn't in the disksetup, so BCM never flags it "incorrect."

After it settles:

```bash
cat /proc/mdstat        # md0 + md1 on nvme2/3 only; NO md2; nvme0n1 not a member
lsblk /dev/nvme0n1      # COS_GRUB/OEM/RECOVERY/STATE/PERSISTENT
efibootmgr              # "Kairos" entry first in BootOrder
```

## Caveats

- This still lays down a **dormant** BCM Ubuntu root on `nvme2/3` purely as the vehicle to run the Kairos installer — that's how the BCM→Kairos handoff works. Once Kairos is on `nvme0n1` and first in BootOrder, that root is never booted again.
- **BootOrder:** `install-kairos.sh` puts the `Kairos` entry first, but BCM's GRUB install also writes NVRAM, so after the first successful boot confirm `efibootmgr` lists `Kairos` (`nvme0n1`) ahead of the BCM entry (`nvme2n1`).
- To eliminate the dormant BCM root entirely, a larger change (diskless / "datanode" provisioning mode, no local OS) is possible — out of scope for this one-shot, available on request.
