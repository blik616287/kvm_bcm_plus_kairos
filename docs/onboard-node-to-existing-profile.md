# Onboarding an additional DGX to an existing Kairos profile

The expensive work — building the image and configuring the BCM category — is paid
**once per profile**. Every *additional* identical node just **joins that category** and
gets triggered: **no `kairos-build`, no `deploy-dd`.** Worked example: onboarding
**dgx03** onto the already-built **`kairos-dgx4`** category (24.04, OS RAID1 mirror +
8-drive `/raid` RAID0, local Palette).

## The fleet model
| Cost | How often |
|---|---|
| `make kairos-build` | **once per image variant** (OS + Palette + RAID layout) |
| `make deploy-dd` | **once per category** — uploads the image, renders the finalize, builds the ramdisk |
| **each additional box** | just step 1 (associate) + step 2 (BMC trigger) below |

## Preconditions
- The target category already exists and is fully configured — image staged at
  `/cm/shared/kairos/<profile>/disk.raw.lz4`, `finalizescript` set, `installbootrecord=no`,
  installer ramdisk built. (This is what `deploy-dd` did the first time.)
- The new node is **identical hardware** to what the image targets (same DGX model → the
  OS/data-RAID disk layout in the finalize matches; mdadm assembles by **superblock**, so
  exact `/dev/nvme*` naming may differ between install and boot — that's fine).
- The node is registered in BCM with a **correct physical boot interface**: `BOOTIF` =
  the physical PXE NIC and its **burned-in** MAC — never a bond (see `dgx-onboarding-retro.md`).

## Step 1 — associate the node with the category (the one BCM command)
```bash
sudo cmsh -c "device; use dgx03; set category kairos-dgx4; set installmode FULL; commit"
# verify:
sudo cmsh -c "device; use dgx03; get category; get installmode"     # -> kairos-dgx4 / FULL
```
That's the entire BCM side. The category already carries the image URL, the RAID
finalize (`/dev/md0`, OS mirror + `/raid`), `installbootrecord=no`, and the ramdisk.

## Step 2 — point the node's BMC at UEFI + disk-first + one-time PXE (per-node, not in BCM)
```bash
B=https://<node-bmc-ip>; A="<bmc-user>:<bmc-pass>"
# (a) persistent UEFI disk-first BootOrder so it lands in Kairos after the finalize reboot.
#     Identify the disk boot entries first (DisplayName "UEFI OS" / "Kairos"), then:
ETAG=$(curl -sk -u "$A" "$B/redfish/v1/Systems/Self" | jq -r '."@odata.etag"')
curl -sk -u "$A" -X PATCH "$B/redfish/v1/Systems/Self" \
  -H 'Content-Type: application/json' -H "If-Match: $ETAG" \
  -d '{"Boot":{"BootOrder":["<UEFI-OS>","<Kairos>","<...rest, PXE last...>"]}}'
# (b) one-time UEFI PXE for THIS boot (efiboot — the default is legacy, which won't boot the ESP)
export IPMI_PASSWORD='<bmc-pass>'
ipmitool -I lanplus -H <node-bmc-ip> -U <bmc-user> -E -L OPERATOR chassis bootdev pxe options=efiboot
ipmitool -I lanplus -H <node-bmc-ip> -U <bmc-user> -E -L OPERATOR chassis power reset   # or power on
```

## Step 3 — watch the install (on the BCM)
```bash
sudo cmsh -c "device; use dgx03; get status"        # DOWN/maintenance -> INSTALLING (provisioning) -> ...
sudo tail -f /var/log/node-installer                # "Finalize script:" lines
```
Finalize sequence: erase members → `mdadm --create /dev/md0 --metadata=1.0` → dd image →
grow last partition → build `/raid` RAID0 + inject the systemd mount → force reboot.
(The `~/var/log/node-installer` may show `EFI variables are not supported` — the BCM PXE
loader is legacy, so efibootmgr is skipped; the persistent UEFI BootOrder from Step 2 +
the `\EFI\BOOT\bootx64.efi` fallback boot the mirror anyway.)

## Step 4 — verify
```bash
make validate ANSIBLE_ARGS="-e @profiles/<profile>.yml"        # 30-point health check
# or directly on the node:
ssh kairos@<node-ip> 'cat /proc/mdstat; findmnt /raid'         # md* [UU] mirror + /raid rw
```
The node UEFI-boots the mirror → Kairos → self-registers as a **unique**
`edge-<smbios-uuid>` in the profile's Palette. Last step is a click: assign that edge-host
to a cluster in the Palette UI.

## Be deliberate about
- **This RE-IMAGES the node** — it wipes its disks and installs whatever OS/Palette the
  category's image baked in. dgx03 joining `kairos-dgx4` makes it **24.04 on the local
  Palette**, discarding its prior install. Needing a *different* OS/Palette is the **only**
  reason to build a second image/category.
- **UEFI + `efiboot` every time** — legacy is the default for IPMI boot overrides and
  won't boot the UEFI Kairos ESP.
- **Palette identity is per-node** — each box registers as its own `edge-<uuid>`; no clash.
- Global `setupBmc=false` in `/cm/node-installer/scripts/node-installer.conf` must stay set
  (the DGX AMI BMC rejects BCM's `bright` user provisioning; otherwise the install fails at
  "set up BMC interface").

## See also
- `reprovision-dgx.md` — full reprovision runbook (build/deploy paths, boot-order-only fix).
- `dgx-onboarding-retro.md` — the failure modes these steps avoid (bond-MAC PXE blocker,
  RAID-is-build-time, confirm-node cycling).
