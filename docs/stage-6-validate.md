# Stage 6 — `validate`

~40 health checks over SSH — the BCM head node **and** the booted Kairos node — printing `PASS` / `WARN` / `FAIL` and a tally. Exits non-zero if any `FAIL`. This is the closest thing to a test suite; it's also how you confirm a node actually became Kairos.

| | |
|---|---|
| **Playbook / role** | `playbooks/06-validate.yml` → `roles/validate` |
| **Target** | `make validate` |
| **Modes** | local-KVM **and** remote-BCM |
| **Key template** | `roles/validate/templates/validate.sh.j2` |

## Run it
```bash
make validate ANSIBLE_ARGS="-e kairos_profile=<profile> -e kairos_node_name=<node>"
```
(`kairos_profile` / `kairos_node_name` must match what you deployed; remote uses `bcm_target_node`.)

## What it checks

**BCM head node**
| Group | Checks |
|---|---|
| Connectivity | SSH reachable |
| Services | `cmd`, `dhcpd`, `named`, `nfs-server`, rsync :873, HTTP :8888 |
| Network | internal IP on the right iface, external iface/route, IP forwarding |
| DNS / Internet | external resolve + outbound HTTP |
| Cluster | head node UP; target node registered; node IP/category; `<profile>-installer` image; raw at `/cm/shared/kairos/<profile>/disk.raw.lz4` |

**Kairos compute node** (IP resolved via BCM ARP → cmsh fallback)
| Group | Checks |
|---|---|
| Connectivity | SSH (key, then `kairos:kairos`), ping |
| OS | `/etc/os-release`, **`/etc/kairos-release`**, **`kairos-agent`**, kernel |
| Network | IP, gateway, resolver, external DNS, Internet |
| Services | **`stylus-agent`**, **Palette registration** (API state, or stylus log) |
| Boot | `net.ifnames=0`, **Kairos boot chain** (`rd.cos`/`rd.immucore`) |
| Disk | **`COS_OEM` / `COS_RECOVERY` / `COS_STATE` / `COS_PERSISTENT`**, root immutable, free space |
| Cloud-config | `/oem/*.yaml` present |

## Reading the result

**Healthy Kairos:** the bolded node checks PASS (kairos-release, kairos-agent, all `COS_*`, immutable root, OEM config).

**"Booted the BCM image, not Kairos"** — this signature:
```
[FAIL] Kairos release   [FAIL] kairos-agent   [FAIL] OEM config
[WARN] COS_OEM/RECOVERY/STATE/PERSISTENT — not found
[WARN] Root immutable   [WARN] Kairos boot chain
OS = Ubuntu …  Kernel = 6.8.0-51-generic
```
→ go to [troubleshoot-node-booted-bcm-image](troubleshoot-node-booted-bcm-image.md).

**`[WARN] Palette registration — no API key set`** is **expected** when `palette_api_key` is empty (the minimal local-KVM config) — not a failure.

## Logging
`logs/06-validate.log` (Ansible run + the full printed report) · `build/validate.sh` (the exact rendered checks).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Kairos IP lookup fails (loopback/0.0.0.0) | node not booted / no DHCP / cmsh IP unset | `arp -an \| grep <mac>` on BCM; `cmsh … get ip` / BOOTIF iface |
| Kairos SSH unreachable | node up but sshd not ready / isolated | `ssh kairos@<ip>` (pw `kairos`) from BCM manually |
| All Kairos OS/disk checks FAIL/WARN | booted Ubuntu, not Kairos | see the signature above + the troubleshoot doc |
| `[WARN] stylus-agent inactive` | Palette integration failed / endpoint unreachable | `journalctl -u stylus-agent`; check endpoint + `palette_*` |
| `[FAIL] Palette registration` (API 404) | edge-host UID not in project / wrong creds | verify `palette_project_uid` + `palette_api_key`; check the UID in Palette |
| BCM checks FAIL | stage 2/4 not complete | re-check [Stage 2](stage-2-bcm-vm.md) / [Stage 4](stage-4-deploy-dd.md) |

## See also
[Runbook §7 "Where did it break?"](architecture-and-troubleshooting.md#where-did-it-break) · [Stage 5 — kairos-vm](stage-5-kairos-vm.md) · [docs index](README.md).
