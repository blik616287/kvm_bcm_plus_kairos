#!/bin/bash
# Kairos dd-install as a BCM node-installer FINALIZE script (profile: default-kairos).
#
# Rendered by roles/deploy_dd/tasks/finalize.yml when deploy_dd_finalize_install=true.
# Runs in the node-installer (NFS) environment after provisioning, before reboot:
#   - the rootfs is NFS, so the dd never overwrites what this script runs from
#     (no "timeout: not found", no XFS console spam);
#   - /dev/vda is a clean target, so sgdisk + the COS_PERSISTENT
#     grow work;
#   - on a UEFI node-installer /sys/firmware/efi/efivars is present, so efibootmgr
#     can create a boot entry (else the image's ESP fallback loader boots).
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set +e
DISK="/dev/vda"
HEAD_IP="192.168.98.2"
RAW_URL="http://${HEAD_IP}:8888/default-kairos/disk.raw.lz4"
WIPE_DISKS=""

echo "[kairos-finalize $(date)] start -> ${DISK}"

# --- Drive inventory (name/size/model). NVMe naming is NOT stable across machines,
# so log the physical layout to verify kairos_os_raid/kairos_data_raid target the
# intended drives (e.g. the OS mirror must land on the two matched OS disks, not a
# data disk). A size-mismatched OS mirror thrashes and hangs boot. ---
echo "[kairos-finalize $(date)] === drive inventory ==="
for _dev in /sys/block/nvme*n1; do
    [ -e "${_dev}" ] || continue
    _n=$(basename "${_dev}")
    _gb=$(($(cat "${_dev}/size" 2> /dev/null || echo 0) / 2 / 1024 / 1024))
    _model=$(tr -s ' ' < "${_dev}/device/model" 2> /dev/null)
    echo "  DRIVE ${_n} ${_gb}GB ${_model}"
done
# Stable identifiers, to populate a kairos_raid_select: path (or id) profile.
echo "[kairos-finalize $(date)] by-path map (for kairos_raid_select: path):"
ls -l /dev/disk/by-path/ 2> /dev/null | awk '/nvme/{print "  "$(NF-2)" -> "$NF}' || true

# Quiet the kernel console: the dd over the target still triggers some block noise.
echo 1 > /proc/sys/kernel/printk 2> /dev/null || true

# Release the freshly-provisioned target so dd can overwrite the WHOLE disk. We
# unmount /localdisk here (needed so the post-dd partition-table re-read + grow
# work); the node-installer's own post-finalize cleanup is bypassed by the forced
# reboot at the end.
sync
swapoff -a 2> /dev/null || true
for mp in $(awk -v d="${DISK}" '$1 ~ ("^" d) {print $2}' /proc/mounts | sort -r); do
    umount -fl "$mp" 2> /dev/null || true
done
umount -Rfl /localdisk 2> /dev/null || true
vgchange -an 2> /dev/null || true
mdadm --stop "${DISK}"* 2> /dev/null || true
dmsetup remove_all 2> /dev/null || true
udevadm settle --timeout=20 2> /dev/null || true
# Release any md array that currently holds one of our target disks. A previous
# install on this node leaves md metadata that udev/mdadm auto-assembles at boot,
# under whatever md node it lands on (md127/md126, not the md0 we stop above); a
# member still held by a live array cannot be wiped or re-created, so the create
# below dies with "Device or resource busy" - and opaquely, because the wipe is
# best-effort. Stop the owning arrays first, then assert the members came free.
# Without this a RE-image of a node that already carries arrays fails where a
# first install on a bare node succeeds.
# The kernel records md membership on the MEMBER as holders/mdN (on the whole
# disk, or on a partition of it); there is no reverse "md" link on a member.
_md_holders() {
    _hb=$(basename "$(readlink -f "$1")")
    for _h in /sys/class/block/"${_hb}"/holders/md* /sys/class/block/"${_hb}"/"${_hb}"*/holders/md*; do
        [ -e "${_h}" ] && basename "${_h}"
    done | sort -u
}
_release_md_members() {
    for _m in "$@"; do
        [ -b "${_m}" ] || continue
        for _md in $(_md_holders "${_m}"); do
            echo "[kairos-finalize $(date)] $(basename "${_m}") is held by ${_md}; stopping it"
            mdadm --stop "/dev/${_md}" 2> /dev/null || true
        done
    done
    udevadm settle --timeout=20 2> /dev/null || true
}
# Loud, early failure naming the device beats an opaque mdadm --create abort later.
_assert_md_members_free() {
    for _m in "$@"; do
        [ -b "${_m}" ] || continue
        _held=$(_md_holders "${_m}" | tr '\n' ' ')
        if [ -n "${_held}" ]; then
            echo "[kairos-finalize $(date)] FATAL: $(basename "${_m}") still held by ${_held% } after stop; refusing to build a partial array"
            exit 1
        fi
    done
}

# Wipe only AFTER the holders are released: wiping signatures out from under a live
# device is what produced the EBUSY/partprobe failures. That includes arrays a
# previous install left behind, which auto-assemble under md127/md126 and so are
# not caught by the `mdadm --stop "${DISK}"*` above.
_WIPE="${WIPE_DISKS}"
_WIPE_DEVS=""
for d in ${_WIPE}; do _WIPE_DEVS="${_WIPE_DEVS} /dev/${d}"; done
_release_md_members ${_WIPE_DEVS}
for d in ${_WIPE}; do [ -b "/dev/$d" ] && wipefs -a -f "/dev/$d" 2> /dev/null || true; done
udevadm settle --timeout=20 2> /dev/null || true

# --- Drive selection. kairos_raid_select controls how the kairos_os_raid /
# kairos_data_raid device specs resolve to real block devices:
#   name (default) -> /dev/<spec>
#   path           -> /dev/disk/by-path/<spec>  (stable per PCIe slot)
#   id             -> /dev/disk/by-id/<spec>     (stable per model+serial)
#   size           -> ignore specs; OS mirror = the smallest N drives, data = the rest
# nvmeXn1 names are NOT stable across boots on these DGX systems (a name maps to a
# different physical drive per install), so a name-pinned OS mirror can span a large
# data disk -> size-mismatched -> thrashes and hangs boot. Prefer size or path. ---
_SELECT="name"
_resolve_dev() {
    case "${_SELECT}" in
        path) readlink -f "/dev/disk/by-path/$1" 2> /dev/null ;;
        id) readlink -f "/dev/disk/by-id/$1" 2> /dev/null ;;
        *) echo "/dev/$1" ;;
    esac
}


for i in $(seq 1 30); do curl --fail --silent --head "${RAW_URL}" > /dev/null 2>&1 && break; sleep 5; done

# The image is dd'd byte for byte, so the target must be at least as large as
# the raw disk. On a RAID profile the target is the ARRAY, which is easy to
# undersize: members look roomy individually while the mirror is one member
# wide. Say so here, naming both numbers -- the alternative is dd stopping at
# "No space left on device" several minutes in, with a half-written GPT.
_TARGET_BYTES=$(blockdev --getsize64 "${DISK}" 2> /dev/null || echo 0)
_IMAGE_BYTES=0
if [ "${_TARGET_BYTES}" -eq 0 ]; then
    # On a RAID profile this is how a failed `mdadm --create` shows up: the
    # array above only warns, so without this the dd would write to a path
    # that is not a block device at all.
    echo "[kairos-finalize $(date)] FATAL: ${DISK} is not a usable block device (size 0)."
    exit 1
fi
if [ "${_IMAGE_BYTES}" -gt 0 ] && [ "${_TARGET_BYTES}" -lt "${_IMAGE_BYTES}" ]; then
    echo "[kairos-finalize $(date)] FATAL: ${DISK} is ${_TARGET_BYTES} bytes but the image is ${_IMAGE_BYTES} bytes."
    echo "[kairos-finalize $(date)] Grow the target (on a RAID profile that means the members) or shrink kairos_raw_disk_size."
    exit 1
fi

echo "[kairos-finalize $(date)] writing image (${_IMAGE_BYTES} bytes -> ${DISK}, ${_TARGET_BYTES} bytes)..."
curl --fail -s "${RAW_URL}" | lz4 -d - - | dd of="${DISK}" bs=4M oflag=direct status=progress
sync
echo "[kairos-finalize $(date)] dd complete; fixing GPT + growing last partition..."
sgdisk -e "${DISK}" 2>&1 || true
partprobe "${DISK}" 2>&1 || true
udevadm settle --timeout=30 2> /dev/null || true

case "${DISK}" in *nvme* | *mmcblk* | *loop* | *md*) PSEP=p ;; *) PSEP= ;; esac
if command -v sgdisk > /dev/null 2>&1 && command -v resize2fs > /dev/null 2>&1; then
    LAST_NUM=$(sgdisk -p "${DISK}" 2> /dev/null | awk '/^[ ]+[0-9]+/{n=$1} END{print n}')
    LAST_INFO=$(sgdisk -i "${LAST_NUM}" "${DISK}" 2> /dev/null)
    LAST_START=$(echo "$LAST_INFO" | awk '/First sector:/{print $3}')
    LAST_TYPE=$(echo "$LAST_INFO" | awk '/Partition GUID code:/{print $4}')
    LAST_LABEL=$(echo "$LAST_INFO" | grep 'name:' | sed -e 's/.*name: //; s/^.\(.*\).$/\1/')
    if [ -n "$LAST_NUM" ] && [ -n "$LAST_START" ]; then
        echo "[kairos-finalize $(date)] growing partition ${LAST_NUM} (${LAST_LABEL}) from ${LAST_START}..."
        sgdisk -d "${LAST_NUM}" -n "${LAST_NUM}:${LAST_START}:0" -t "${LAST_NUM}:${LAST_TYPE}" -c "${LAST_NUM}:${LAST_LABEL}" "${DISK}" 2>&1 || true
        partprobe "${DISK}" 2>&1 || true
        partx -u --nr "${LAST_NUM}" "${DISK}" 2>&1 || true
        e2fsck -fy "${DISK}${PSEP}${LAST_NUM}" 2>&1 | tail -3 || true
        resize2fs "${DISK}${PSEP}${LAST_NUM}" 2>&1 | tail -3 || true
    else
        echo "[kairos-finalize $(date)] WARN: could not detect last partition; skipping grow"
    fi
fi

partprobe "${DISK}" 2> /dev/null || true
udevadm settle --timeout=20 2> /dev/null || true
# The BCM node-installer PXE-boots UEFI but does NOT mount efivarfs, so
# /sys/firmware/efi/efivars exists yet is empty and efibootmgr fails with "EFI
# variables are not supported" — its --create calls silently no-op and NO boot
# entry is written, so the node falls back to UEFI-PXE and reinstall-loops. Mount
# efivarfs ourselves, then gate on efibootmgr actually working (not just the dir).
if [ -d /sys/firmware/efi ]; then
    mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2> /dev/null || true
fi
if command -v efibootmgr > /dev/null 2>&1 && efibootmgr > /dev/null 2>&1; then
    echo "[kairos-finalize $(date)] creating UEFI boot entry..."
    # drop any stale Kairos entries first
    for n in $(efibootmgr 2> /dev/null | grep 'Kairos' | grep -oE '^Boot[0-9A-Fa-f]+' | sed 's/^Boot//'); do
        efibootmgr -b "$n" -B 2> /dev/null || true
    done
    # Create a labelled entry off the (assembled) target. On RAID we deliberately point
    # --disk at ${DISK} (= /dev/md0), NOT at the member disks: the members are busy mdraid
    # devices whose partition 1 is not exposed, so "--disk <member> --part 1" fails with
    # "Could not prepare Boot variable: No such file or directory". partprobe exposed
    # ${DISK}p1 (the ESP) and the cOS image's partition GUIDs are fixed, so the resulting
    # HD(GPT,<uuid>) entry matches the ESP physically mirrored on every member (metadata 1.0).
    efibootmgr --create --disk "${DISK}" --part 1 --label Kairos --loader '\EFI\BOOT\bootx64.efi' 2>&1 || true
    # Load-bearing: make an OS entry boot BEFORE PXE. Our Kairos --create may not stick,
    # but the firmware always auto-discovers the ESP fallback as a "UEFI OS" entry
    # (\EFI\BOOT\bootx64.efi, fixed image PARTUUID). This DGX firmware otherwise rebuilds
    # BootOrder PXE-first on every POST — which is exactly what makes the node re-PXE and
    # reinstall-loop after the finalize reboot. Reorder: OS entries first, PXE entries last.
    os_boot=$(efibootmgr 2> /dev/null | grep -iE 'Kairos|UEFI OS' | grep -oE '^Boot[0-9A-Fa-f]{4}' | sed 's/^Boot//' | paste -sd, -)
    pxe_boot=$(efibootmgr 2> /dev/null | grep -iE 'PXE|Network' | grep -oE '^Boot[0-9A-Fa-f]{4}' | sed 's/^Boot//' | paste -sd, -)
    if [ -n "${os_boot}" ]; then
        neworder=$(echo "${os_boot},${pxe_boot}" | sed 's/,,*/,/g; s/,$//')
        echo "[kairos-finalize $(date)] setting BootOrder OS-first: ${neworder}"
        efibootmgr -o "${neworder}" 2>&1 || true
    fi
else
    echo "[kairos-finalize $(date)] no efivars/efibootmgr; relying on ESP fallback loader \\EFI\\BOOT\\bootx64.efi"
fi


# Force a real reboot instead of returning to the node-installer. BCM would
# otherwise switch_root into /localdisk and exec its /sbin/init — but we dd'd
# Kairos over the whole disk, so /localdisk is no longer a Linux root and
# switch_root drops to an emergency shell. Kairos can only be started by firmware
# (GRUB in its own ESP). The node's boot order must be disk-first / PXE-fallback,
# so this reboot lands in the freshly-written Kairos.
echo "[kairos-finalize $(date)] dd-install COMPLETE; rebooting into Kairos (bypassing node-installer switch_root)..."
sync
sleep 2
echo 1 > /proc/sys/kernel/sysrq 2> /dev/null || true
echo b > /proc/sysrq-trigger 2> /dev/null || true
reboot -f 2> /dev/null || true
systemctl --force --force reboot 2> /dev/null || true
exit 0
