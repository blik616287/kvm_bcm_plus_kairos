#!/usr/bin/env python3
"""Render /cm/build-config.xml from /cm/build-config.xml.tpl for the BCM KVM
auto-install.

Runs inside the BCM installer ramdisk (bcm-autoinstall.sh execs it). Extracted
from a python heredoc embedded in bcm-autoinstall.sh so it's a real, lintable
file. All inputs arrive via the environment (exported by bcm-autoinstall.sh):

    BCM_INTERNAL_IP        BCM's IP on the internal provisioning network
    BCM_INTERNAL_NETMASK   internal network prefix bits (e.g. "24")
    BCM_INTERNAL_CIDR      internal network CIDR (e.g. "192.168.98.0/24")
    BCM_EXTERNAL_GATEWAY   external (NAT) gateway
    BCM_HOSTNAME           head-node hostname
    BCM_TIMEZONE           head-node timezone

KVM uses a fixed two-network topology: internalnet + externalnet.
"""
import os

from jinja2 import Template

TPL = "/cm/build-config.xml.tpl"
OUT = "/cm/build-config.xml"

internal_ip = os.environ["BCM_INTERNAL_IP"]
prefix = internal_ip.rsplit(".", 1)[0]  # e.g. 192.168.98

networks = [
    {
        "name": "internalnet", "type": "internal",
        "base": os.environ["BCM_INTERNAL_CIDR"].split("/")[0],
        "maskbits": os.environ["BCM_INTERNAL_NETMASK"],
        "domain": "eth.cluster",
        "dyn_start": f"{prefix}.16",
        "dyn_end": f"{prefix}.200",
    },
    {
        "name": "externalnet", "type": "external",
        "base": "10.0.2.0", "maskbits": "24",
        "domain": "brightcomputing.com",
        "gateway": os.environ["BCM_EXTERNAL_GATEWAY"],
    },
]

interfaces = [
    {"name": "eth0", "network": "internalnet", "ip": internal_ip, "provisioning": True},
    {"name": "eth1", "network": "externalnet", "ip": "10.0.2.15"},
]

with open(TPL) as f:
    template = Template(f.read())

result = template.render(
    networks=networks,
    interfaces=interfaces,
    hostname=os.environ["BCM_HOSTNAME"],
    timezone=os.environ["BCM_TIMEZONE"],
    slave_ip=f"{prefix}.1",
)

with open(OUT, "w") as f:
    f.write(result)

print(f"[OK] Rendered build-config.xml: {len(networks)} networks, {len(interfaces)} interfaces")
for n in networks:
    print(f"  {n['name']}: base={n['base']}/{n['maskbits']}")
