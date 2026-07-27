# Retro — DGX-04 Kairos/BCM onboarding didn't provision

_ursa-bcm11-headnode · node `dgx04` (BMC 10.184.69.164) · category `kairos-dgx4`_

## TL;DR
Jon hand-built the BCM category + device for dgx04 and registered the node's
**provisioning MAC as a network-bond's virtual MAC**. PXE happens over a single
**physical** NIC using its **burned-in** MAC — bonding doesn't exist in firmware —
so BCM's DHCP never matched dgx04's PXE requests. The node never got a boot offer,
never provisioned, and dropped to "maintenance." Four more errors rode along from
copy-pasting dgx03's setup by hand. None of them were hit because it never got past
step one.

## What Jon did (reconstructed)
1. Built a Kairos **Ubuntu 24.04** image for dgx04 and staged it on the head node
   (`/cm/shared/kairos/kairos-dgx4/disk.raw.lz4`, 5.6 GB). ✅ this part was fine.
2. Created the `kairos-dgx4` category + `kairos-dgx4-installer` software image by
   hand, **copying dgx03's (`dgx-raid`) category** as the starting point.
3. Registered `dgx04` as a BCM device with:
   - `provisioninginterface = bond0` (a bond over `enp225s0f1` + `enp97s0f1`)
   - `mac = DE:1B:09:B9:49:3E`  ← the **bond's** locally-administered MAC
   - IP `10.184.70.7` on dgxnet
4. Wrote group_vars for a **single-disk** install (`kairos_target_disk=/dev/nvme1n1`)
   to a **local Palette** (`10.184.70.156`, its own project/token/CA cert).
5. Powered it on → it sat in `[ DOWN ] entered maintenance`, and he was stuck.

## Why it didn't work — ranked

### 1. ROOT CAUSE — provisioning over a bond, with the bond MAC
- BCM matches a PXE request by the node's `mac`. Jon set it to `DE:1B:09:B9:49:3E`,
  the **bond0** virtual MAC.
- The DGX firmware PXE-boots from **one physical NIC** with its **burned-in** MAC.
  dgx04's live provisioning port is `EthernetInterface1 = 0C:42:A1:74:F2:C7`
  (LinkUp; same onboard-NIC family as dgx03's `BOOTIF 0C:42:A1:74:F3:1F`).
- So on the wire dgx04 says `0C:42:A1:74:F2:C7`; BCM is waiting for `DE:1B…`; **no
  match → no DHCP/PXE offer → no provisioning → maintenance.** Nothing else ever ran.

### 2. IP conflict on 10.184.70.7
A stale `debianDGX` LiteNode holds the same IP as dgx04 → duplicate-address
ambiguity on dgxnet even once the MAC is fixed.

### 3. The finalize script is dgx03's, verbatim
The `kairos-dgx4` category's `finalizescript` is a copy of dgx-raid's — it:
- fetches `http://…/dgx-raid/disk.raw.lz4` (**the wrong image**; his own
  `kairos-dgx4` image is staged but never used), and
- hardcodes **dgx03's RAID layout** (`DISK=/dev/md0`, OS `nvme2n1/nvme3n1`, data
  `nvme0,1,4-9`) — which **contradicts his group_vars** (single disk `/dev/nvme1n1`).

So even if it had provisioned, it would `dd` the wrong OS onto the wrong disks.

### 4. installbootrecord = yes
Must be **no** for the finalize/dd flow — otherwise the node-installer runs
grub-install over the freshly-dd'd Kairos disk (fails "cannot find EFI directory"
on UEFI, or clobbers the bootloader). He left the default.

### 5. He hand-built the category instead of using the pipeline
`make deploy-dd -e @profiles/<node>.yml` renders the finalize with the **correct
image URL and target disk**, sets `installbootrecord=no`, clones the category, and
configures PXE — all of it. Doing it by hand is exactly how #3 and #4 slipped in.

### 6. RAID confusion — the image wasn't built for RAID
His config was internally **contradictory**: the group_vars asked for a **single
disk** (`kairos_target_disk: /dev/nvme1n1`, no `kairos_os_raid`), but the category
he copied carried dgx03's **RAID** finalize (`/dev/md0`). The deeper problem: to run
on a RAID mirror the **image itself must be built RAID-capable** —
`kairos_build_mdraid: true` puts `mdadm` + the dracut `mdraid` module + `rd.auto=1`
into the initramfs so it can assemble `/dev/md0` at boot. **Jon's `kairos-dgx4`
image was a plain single-disk build**, so even pointed at `/dev/md0` it could never
assemble or boot the array — it would silently drop to the dracut emergency shell.
You can't bolt RAID onto a non-RAID image at deploy time; it's a **build-time**
property. (Fix: rebuild with `kairos_build_mdraid: true` + `kairos_os_raid` /
`kairos_data_raid`, target `/dev/md0`.)

## What fixes it
| # | Fix |
|---|-----|
| 1 | Set the node's `mac` (and provisioning interface) to the **physical** PXE NIC `0C:42:A1:74:F2:C7` — not the bond. Confirm on first PXE that the DHCPDISCOVER MAC matches. |
| 2 | Remove/re-IP the stale `debianDGX` so `10.184.70.7` is unique. |
| 3 | Regenerate the category via `make deploy-dd -e @profiles/kairos-dgx4.yml` so the finalize points at `…/kairos-dgx4/…` and the right disk (`/dev/nvme1n1` per his intent — or wire `kairos_os_raid` if dgx04 is meant to mirror like dgx03). |
| 4 | `installbootrecord=no` (deploy-dd's `finalize.yml` sets this automatically). |
| 5 | Set the DGX BIOS boot order **UEFI disk-first / PXE-fallback** so it stays on Kairos after the finalize reboot (this was the last hurdle on dgx03 too — one-time IPMI overrides don't persist; use Redfish `BootOrder` or BIOS setup). Also force `efiboot` on any manual `chassis bootdev` — legacy is the default and won't boot the UEFI Kairos ESP. |

## The complete, correct process (DGX → Kairos via BCM)
Read this before onboarding the next node.

1. **Build** the image for the node's OS: `make kairos-build -e @profiles/<node>.yml`
   (the profile pins OS version, ISO_NAME, Palette target, and — if wanted —
   `kairos_build_mdraid: true` + `kairos_os_raid`/`kairos_data_raid`).
2. **Register the device in BCM correctly:**
   - `provisioninginterface` = the **physical** NIC cabled to dgxnet that the
     firmware PXE-boots from; `mac` = that NIC's **burned-in** MAC (read it from
     the node's BMC `EthernetInterfaces`, the LinkUp onboard port). **Never a bond.**
   - A **unique** dgxnet IP (no LiteNode/leftover collisions).
3. **Deploy:** `make deploy-dd -e @profiles/<node>.yml` — renders the finalize
   (right image URL + target disk), sets `installmode FULL` + `installbootrecord=no`,
   clones the category, configures PXE + the installer ramdisk. Keep
   `bcm_manage_dns=false` / `bcm_manage_cluster_defaults=false` on the shared BCM.
4. **BIOS/boot:** set the node **UEFI, disk-first, PXE-fallback** (persistent).
   Trigger the install with a one-time **UEFI** PXE (`chassis bootdev pxe
   options=efiboot`), power on.
5. **Watch** the finalize on the BCM: `cmsh -c "device; use <node>; get status"`
   and `/var/log/node-installer` (`Finalize script:` lines: mkfs/mdadm → `writing
   image` → grow → efibootmgr → reboot). The dd is the long pole.
6. **Verify:** node UEFI-boots the disk → Kairos GRUB → registers with Palette
   (`edge-<smbios-uuid>` appears in the project). Then `make validate`.

## Prevention
- Use the **pipeline**, not hand-copied categories — it's the whole reason the
  finalize/installbootrecord/image-URL are correct by construction.
- The BCM `mac` is a **PXE-match** field: it must be the physical boot NIC's real
  MAC. Bonds are OS-level and invisible to PXE.
- **RAID is a build-time decision, not a deploy-time one.** A node can only boot off
  `/dev/md0` if the *image* was built with `kairos_build_mdraid: true` (mdadm +
  mdraid initramfs). Decide single-disk vs RAID **before** `kairos-build`, keep
  `kairos_target_disk` / `kairos_os_raid` / `kairos_data_raid` consistent across the
  profile, and don't copy another node's finalize — let `deploy-dd` render it.
- Docs to read: `docs/stage-4-deploy-dd.md`, `profiles/README.md` (incl. the RAID
  schema), and the `deploy_dd/defaults/main.yml` header (finalize +
  `installbootrecord` rationale).
