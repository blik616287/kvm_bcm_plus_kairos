# Runbook — reprovision a DGX node with a RAID profile (example: dgx03)

**Short answer to "can the kairos-dgx4 profile reprovision dgx03?"** Yes — the profile
is generic; only two things are node/target-specific: `bcm_target_node` and the
Palette/OS baked into the image. So you either (a) repoint an existing profile, or
(b) keep a per-node profile. Pick based on where dgx03 should register:

| If dgx03 should use... | Then use... |
|---|---|
| dgx03's original target (dev-cloud Palette, 22.04) | `profiles/dgx-raid.yml` (already exists, RAID-capable image already built + staged) |
| the same as dgx04 (Jon's local Palette `10.184.70.156`, 24.04) | `profiles/kairos-dgx4.yml` with `bcm_target_node: dgx03` (its image already registers to the local Palette) |

Everything else (OS RAID1 mirror + `/raid` RAID0, `/dev/md0`, finalize, installbootrecord)
is identical across nodes — it comes from the profile + the pipeline.

---

## Decide first: does dgx03 need a *reinstall*, or just a *boot-order fix*?

dgx03's disks already hold a Kairos RAID install from the earlier run — the only thing
that was broken was the **boot order** (it kept falling back to PXE/legacy because the
OPERATOR IPMI account couldn't set a persistent order). Now that we have the BMC creds,
that's fixable via Redfish **without wiping anything**.

### Path A — just fix the boot (fastest; no reinstall)
Only if you're keeping dgx03's existing install.
```bash
B=https://10.184.69.163; A='<bmc-user>:<bmc-pass>'
# 1. read BootOrder + ETag, put the disk/UEFI-OS entry first (persistent, UEFI)
ETAG=$(curl -sk -u "$A" "$B/redfish/v1/Systems/Self" | jq -r '."@odata.etag"')
#    (identify the "UEFI OS"/"Kairos" Boot#### entries first, then:)
curl -sk -u "$A" -X PATCH "$B/redfish/v1/Systems/Self" \
  -H 'Content-Type: application/json' -H "If-Match: $ETAG" \
  -d '{"Boot":{"BootOrder":["<diskEntry>","<...rest, PXE last...>"]}}'
# 2. one-time UEFI disk boot + reset
ipmitool -I lanplus -H 10.184.69.163 -U <bmc-user> -E -L OPERATOR chassis bootdev disk options=efiboot
ipmitool ... chassis power reset
# 3. verify: it UEFI-boots GRUB -> Kairos -> registers with Palette; then `make validate`
```

### Path B — full reprovision (wipe + reinstall RAID)
Use this to lay down a fresh image (new OS/Palette, or a clean rebuild).

**0. Make sure a RAID-capable image exists for the chosen profile.**
```bash
# already built for both dgx-raid and kairos-dgx4; rebuild only if you changed OS/Palette:
make kairos-build ANSIBLE_ARGS="-e @profiles/<profile>.yml"
# verify: mdadm in the image + rd.auto=1 on the cmdline (kairos_build_mdraid did its job)
```

**1. Point the profile at dgx03** — in the profile (or -e): `bcm_target_node: "dgx03"`.
Confirm `all.yml` still has the BCM connection (`bcm_ssh_*`, `bcm_internal_ip/cidr`) and
`bcm_manage_dns/cluster_defaults=false`.

**2. Fix the device's provisioning identity (only if wrong — Jon's dgx04 lesson):**
```bash
# provisioninginterface must be the PHYSICAL boot NIC (BOOTIF), and the node `mac`
# must be that NIC's burned-in MAC (read it from the node BMC EthernetInterfaces,
# the LinkUp onboard port). dgx03 is already correct (BOOTIF 0C:42:A1:74:F3:1F).
sudo cmsh -c "device; use dgx03; get provisioninginterface; get mac"
```

**3. Deploy** — uploads the image, renders the RAID finalize (`/dev/md0`), sets
`installbootrecord=no`, moves dgx03 into the category at `installmode FULL`, builds
the ramdisk:
```bash
make deploy-dd ANSIBLE_ARGS="-e @profiles/<profile>.yml"   # (bcm_target_node=dgx03)
```

**4. Set the BMC to UEFI, disk-first, one-time PXE for the install (dgx03's lessons):**
```bash
B=https://10.184.69.163; A='<bmc-user>:<bmc-pass>'
# persistent UEFI disk-first BootOrder (Redfish, If-Match) — disk entry first, PXE last
ETAG=$(curl -sk -u "$A" "$B/redfish/v1/Systems/Self" | jq -r '."@odata.etag"')
curl -sk -u "$A" -X PATCH "$B/redfish/v1/Systems/Self" -H "If-Match: $ETAG" \
  -H 'Content-Type: application/json' -d '{"Boot":{"BootOrder":[<disk-first...>]}}'
# one-time UEFI PXE for THIS boot (efiboot, NOT legacy) + power on/reset
ipmitool -I lanplus -H 10.184.69.163 -U <bmc-user> -E -L OPERATOR chassis bootdev pxe options=efiboot
ipmitool ... chassis power reset
```

**5. Watch the install on the BCM:**
```bash
sudo cmsh -c "device; use dgx03; get status"          # -> INSTALLING (provisioning) -> ...
sudo tail -f /var/log/node-installer                  # "Finalize script:" building md0, writing image, reboot
```
Finalize sequence: erase members → `mdadm --create /dev/md0 (metadata 1.0)` → dd image →
grow → per-member efibootmgr → build `/raid` RAID0 + inject the systemd mount → reboot.

**6. Verify:** dgx03 UEFI-boots the mirror → Kairos GRUB → registers as
`edge-<smbios-uuid>` in Palette; then `make validate -e @profiles/<profile>.yml`
(confirms md0 `[UU]`, `/raid` mounted, live `/dev/nvme*` names).

---

## Gotchas carried over from dgx03/dgx04 (don't relearn these)
- **`efiboot` on every manual `chassis bootdev`** — the default is legacy, which won't
  boot the UEFI Kairos ESP and makes finalize skip efibootmgr.
- **Node-installer BMC step**: `setupBmc=false` is set globally in
  `/cm/node-installer/scripts/node-installer.conf` (the DGX AMI BMC rejects BCM's
  `bright` user provisioning). Leave it, or the install fails at "set up BMC interface".
- **FULL-install confirm dialog** cycles if the node has an existing OS + the boot
  interface isn't a known DB interface — make sure `BOOTIF`/`mac` match the real
  physical port.
- **RAID needs a RAID-capable image** (`kairos_build_mdraid`) — can't be added at deploy.
