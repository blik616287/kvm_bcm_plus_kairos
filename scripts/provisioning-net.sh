#!/usr/bin/env bash
# provisioning-net.sh — ensure the local-KVM provisioning LAN exists and hand a
# tap interface to a VM that is about to start.
#
#   provisioning-net.sh up <bridge>    # create the bridge, make it qemu-usable
#
# Why a bridge at all: the original rig wired BCM and the compute VM together
# with a QEMU socket netdev (`listen=` on one end, `connect=` on the other).
# That is a point-to-point link and carries exactly ONE compute VM -- a second
# one gets no carrier and dies with `PXE-E18: Server response timeout`, which
# reads like broken DHCP on BCM. Anything with two nodes on the provisioning
# network at once (an appliance plus an edge node registering to it, say) is
# impossible that way. A bridge is an ordinary multi-peer LAN, so it just works.
#
# The bridge deliberately gets NO host IP: BCM owns DHCP on this subnet and a
# host address here would both collide with BCM's pool and quietly expose the
# rig's PXE traffic to host routing. Guests talk to each other and to BCM only.
#
# Needs root for `ip`; the callers already run qemu under become/sudo.

set -euo pipefail

usage() {
    echo "usage: provisioning-net.sh up <bridge> <tap> | down <tap>" >&2
    exit 2
}

action="${1:-}"
[ -n "$action" ] || usage

case "$action" in
    up)
        bridge="${2:?bridge name required}"

        if ! ip link show "$bridge" > /dev/null 2>&1; then
            ip link add name "$bridge" type bridge
            # No STP: a single-host bridge has no loops, and STP's forwarding
            # delay would black-hole the first ~15s of a PXE boot.
            ip link set "$bridge" type bridge stp_state 0 forward_delay 0
        fi
        ip link set "$bridge" up

        # On a host running Docker or Kubernetes, iptables FORWARD policy is
        # DROP and br_netfilter (bridge-nf-call-iptables=1) hands bridged IP
        # frames to it. The LAN then looks perfectly healthy -- bridge up,
        # ports forwarding, carrier present, ARP and host-originated pings all
        # working -- while silently dropping every guest-to-guest IP broadcast.
        # DHCP is exactly that, so PXE dies with `PXE-E18: Server response
        # timeout` and BCM's dhcpd logs nothing at all.
        #
        # ARP survives because it goes to arptables (policy ACCEPT), and a ping
        # from the host survives because it is OUTPUT, not FORWARD -- which is
        # what makes this look like anything other than a firewall problem.
        #
        # The per-bridge nf_call_iptables toggle is NOT sufficient: with it set
        # to 0 the FORWARD drop counter still increments once per flooded port
        # (measured 68 -> 80 for six DHCP broadcasts). An explicit ACCEPT is
        # required. Scoped to traffic both entering AND leaving this bridge, so
        # it permits only the provisioning LAN.
        for f in nf_call_iptables nf_call_arptables nf_call_ip6tables; do
            [ -e "/sys/class/net/${bridge}/bridge/${f}" ] || continue
            echo 0 > "/sys/class/net/${bridge}/bridge/${f}" 2> /dev/null || true
        done
        if command -v iptables > /dev/null 2>&1; then
            if ! iptables -C FORWARD -i "$bridge" -o "$bridge" -j ACCEPT 2> /dev/null; then
                iptables -I FORWARD 1 -i "$bridge" -o "$bridge" -j ACCEPT
            fi
        fi

        # qemu-bridge-helper creates and attaches each VM's tap itself, with
        # the virtio vnet_hdr flags qemu needs. Managing taps by hand here
        # instead produced links that carried ARP but silently dropped the
        # guests' DHCP, so PXE failed with PXE-E18 on a bridge that otherwise
        # looked correct. The helper only attaches to bridges listed here.
        mkdir -p /etc/qemu
        if ! grep -qx "allow ${bridge}" /etc/qemu/bridge.conf 2> /dev/null; then
            echo "allow ${bridge}" >> /etc/qemu/bridge.conf
            chmod 0644 /etc/qemu/bridge.conf
        fi
        ;;
    down)
        # Nothing to tear down: qemu removes its own tap when the VM exits, and
        # the bridge is shared by every VM on the provisioning LAN.
        :
        ;;
    *) usage ;;
esac
