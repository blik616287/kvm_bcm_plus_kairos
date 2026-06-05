# Troubleshooting

Field-tested failure modes and how to diagnose them.

---

## Node won't boot from disk after a successful install (efibootmgr GUID is all zeros / entry greyed out)

### Symptoms
- `make kairos-vm` / `install-kairos.sh` reports **no error** — the install
  "completes successfully" — but the node never boots into Kairos.
- In UEFI firmware setup, the **`Kairos` boot entry is greyed out / inactive**.
- `efibootmgr -v` shows the Kairos entry with an **all-zeros GPT partition GUID**:
  `HD(1,GPT,00000000-0000-0000-0000-000000000000,...)`.
- Removing the entry and re-running doesn't help.
- **Reproduces on real hardware but NOT on local KVM.**

### Root cause
`install-kairos.sh` creates the boot entry with:

```bash
efibootmgr --create --disk $DISK --part 1 --label Kairos --loader '\EFI\BOOT\bootx64.efi'
```

`--part 1` makes efibootmgr read partition 1's GPT GUID **from the kernel's
in-memory view of the disk**. On a **re-provisioned** machine, the previous
install's LVM / DRBD / device-mapper / multipath can still **hold the target
disk**. After `dd` overwrites it, `partprobe $DISK` fails with `EBUSY`, so the
kernel keeps a **stale or empty partition table**. efibootmgr then encodes an
**all-zeros** partition GUID, and the firmware greys out the unresolvable entry.

Because historically every step was wrapped in `|| true`, none of this surfaced
as an error — hence "completes successfully."

### Why local KVM doesn't reproduce it
On local KVM the target (`/dev/vda`) is clean — nothing holds it, `partprobe`
succeeds, GUIDs are valid. **More importantly, OVMF (the KVM UEFI firmware)
falls back to the ESP removable-media loader** `\EFI\BOOT\BOOTX64.EFI` when it
finds no usable NVRAM entry, so the node boots **even with no working efibootmgr
entry at all**. Verified on a local node: it had *zero* `Kairos` NVRAM entries
yet booted fine, and the on-disk GPT was valid (`sgdisk -i 1 /dev/vda` →
non-zero GUID). Real server firmware (Dell/HPE/SuperMicro) typically does **not**
auto-fall-back to the removable path, so it depends on the (broken) NVRAM entry.

### Diagnose
Boot the node into the BCM rescue/installer shell or any live USB. With
`$DISK` = your `kairos_target_disk`:

```bash
# 1. Is the ON-DISK GPT valid? (rules the image in/out)
sgdisk -v $DISK ; sgdisk -i 1 $DISK          # 'Partition unique GUID' should be NON-zero
lsblk -o NAME,PARTUUID,PARTLABEL $DISK

# 2. What did efibootmgr actually write?
efibootmgr -v | grep -A1 Kairos              # is the HD(1,GPT,<GUID>) all zeros?

# 3. Was the table re-read, or is the disk held?
dmesg | grep -iE 'GPT|alternate|EBUSY|in use|partition'
dmsetup ls ; pvs ; vgs ; lsblk               # is $DISK claimed by dm/LVM from a prior install?

# 4. Does the ESP carry the fallback loader?
mount ${DISK}1 /mnt && find /mnt -iname '*.efi'; umount /mnt   # expect /EFI/BOOT/BOOTX64.EFI
```

Interpretation:

| Observation | Meaning |
|-------------|---------|
| on-disk GUID **non-zero**, efibootmgr GUID **zero** | kernel table not re-read / disk held — the common case |
| `$DISK` appears in `dmsetup ls` / `pvs` | prior LVM/dm is holding the target → must release before dd |
| on-disk GUID **also zero** | the built image's GPT differs from a known-good build — compare the raw image |
| no `*.efi` on the ESP | image/build problem (the loader should be there) |

### Fix
Implemented in `roles/deploy_dd/templates/install-kairos.sh.j2` (branch
`fix/local-kvm-edge-registration`):

1. **Quiesce the target before `dd`** — `vgchange -an`, `dmsetup remove_all`,
   `wipefs -a -f $DISK`, `udevadm settle`. (Previously only *sibling* disks in
   `kairos_wipe_disks` were wiped; the target itself was never released.)
2. **Verify before efibootmgr** — `partprobe` + `udevadm settle`, then confirm
   partition 1 has a readable `PARTUUID` (retry up to 5×) before creating the
   entry; warn loudly if it stays empty.
3. **Stop masking efibootmgr** — capture its output/exit, warn on non-zero exit
   and on an all-zeros `HD(...,GPT,0000...)` GUID in the output.
4. **Partition-suffix fix** — derive `PSEP` (`p` for nvme/mmcblk/loop, empty for
   sd/vd/hd) instead of hardcoding `${DISK}p<N>` (which silently skipped the
   COS_PERSISTENT grow on SATA/virtio disks).

### Workarounds (no code change)
- **Scrub the target first.** From a live env: `vgchange -an; dmsetup remove_all;
  wipefs -a $DISK; sgdisk --zap-all $DISK`, then re-run `make deploy-dd` + reimage.
  Highest-probability fix on a dirty disk.
- Confirm `kairos_target_disk` is the right device; add every stale sibling/holder
  to `kairos_wipe_disks`.
- In firmware setup, add a manual UEFI boot option pointing at the disk's
  `\EFI\BOOT\BOOTX64.EFI`, or enable "boot from removable / UEFI default" — that
  uses the same fallback path KVM relies on.
- Rule out **Secure Boot** (if enabled and the Kairos shim isn't enrolled, that's
  a *different* failure — a security violation, not a zero-GUID entry).

### Capturing the install log
`install-kairos.sh` tees to `/dev/shm/kairos-install.log`, but the node powers
off immediately after (sysrq), so it's lost. To inspect it, watch the compute
node's **serial console** during install (`make kairos-serial` locally; on metal,
the BMC/SOL console), or temporarily comment out the final
`echo o > /proc/sysrq-trigger` to keep the node up for post-mortem.

---

## Edge host never registers with Palette ("EdgeHostToken is mandatory" loop)

### Symptoms
- Node boots Kairos fine, but never appears in Palette (API returns
  `ResourceNotFound` for `edge-<uuid>`).
- `journalctl -u stylus-agent` loops on
  `error ... EdgeHostToken is mandatory`.

### Root cause
The auto-mint hook (`palette-cleanup-stale.sh`) minted a token but failed to put
it where stylus reads it:
- It injected into `/oem/90_custom.yaml`, but **stylus reads
  `/run/stylus/userdata`** (regenerated from `/oem` at boot, *before* the hook
  runs as an `ExecStartPre`).
- The injection sed assumed a fixed 2-space indent; the live files are
  serialized at 2- *and* 4-space, so the insert matched nothing.

### Fix
Branch `fix/local-kvm-edge-registration`:
- `cloud-config.yaml.j2` always emits an `edgeHostToken` line (empty placeholder
  when no pre-minted token), so stylus bakes it into `/run/stylus/userdata` at
  its own indentation.
- `palette-cleanup-stale.sh` injects via an indent-agnostic helper into **both**
  `/run/stylus/userdata` (what stylus reads this boot) and `/oem/90_custom.yaml`
  (persists across reboots).

### Manual recovery on a live (unfixed) node
```bash
# fetch/mint a token string, then inject into the file stylus reads:
sshpass -p <kairos-pass> ssh -o PreferredAuthentications=password \
  -o PubkeyAuthentication=no kairos@<node-ip> \
  'sudo sed -i "/^  site:[[:space:]]*$/a\    edgeHostToken: <TOKEN>" /run/stylus/userdata; \
   sudo systemctl restart stylus-agent'
```
Confirm: `curl -sk -H "ApiKey: <key>" -H "ProjectUid: <uid>" \
https://<endpoint>/v1/edgehosts/edge-<uuid>` returns HTTP 200, `state: ready`.

> The `make validate` "Palette registration" check is a log-grep and can WARN
> even when the node *is* registered — confirm via the API above, which is
> authoritative.

---

## node001 PXE-boots but never re-images (boots its old OS instead)

### Symptom
After `make deploy-dd`, the node PXE-boots but skips the dd install.

### Cause / fix
`installmode` on the device must be **FULL** for BCM to run the installer. The
local auto-add path now sets it in `deploy-dd` directly (branch
`fix/local-kvm-edge-registration`); on older revisions it was only set by the
`kairos-vm` stage. Verify:

```bash
sshpass -p <bcm-pass> ssh -p 2222 root@localhost \
  "cmsh -c 'device use node001; get installmode'"   # must be FULL
```
