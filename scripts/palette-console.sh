#!/usr/bin/env bash
# palette-console.sh — open an SSH tunnel through BCM so the Palette appliance
# is reachable from a browser on the build host.
#
# Invoked by `make palette-console`; playbooks/palette-console.yml resolves the
# arguments (it asks BCM for the node's current IP rather than trusting a var)
# and renders a 0600 password file when the BCM uses password auth.
#
# Why this exists: the provisioning network is a QEMU socket network on a
# local-KVM rig, or a private customer subnet on a real one. The build host has
# no interface on it either way, so https://<vip>/ from a desktop browser
# reaches nothing even when the appliance is perfectly healthy — which is
# indistinguishable from a failed deploy. BCM is on that network and is already
# reachable, so it is the jump host.
#
# Read-only: it opens a tunnel and changes nothing on BCM or the appliance.

set -euo pipefail

usage() {
    cat >&2 << 'USAGE'
usage: palette-console.sh --bcm-host H --bcm-port P --bcm-user U
                          --node-ip IP --vip VIP
                          [--vip-port N] [--localui-port N]
                          [--password-file F] [--identity-file F]
                          [--proxy-jump SPEC] [--proxy-key F]
USAGE
    exit 2
}

bcm_host="" bcm_port="22" bcm_user="root"
node_ip="" vip=""
vip_port="15443" localui_port="15080"
password_file="" identity_file="" proxy_jump="" proxy_key=""

while [ $# -gt 0 ]; do
    case "$1" in
        --bcm-host)
            bcm_host="$2"
            shift 2
            ;;
        --bcm-port)
            bcm_port="$2"
            shift 2
            ;;
        --bcm-user)
            bcm_user="$2"
            shift 2
            ;;
        --node-ip)
            node_ip="$2"
            shift 2
            ;;
        --vip)
            vip="$2"
            shift 2
            ;;
        --vip-port)
            vip_port="$2"
            shift 2
            ;;
        --localui-port)
            localui_port="$2"
            shift 2
            ;;
        --password-file)
            password_file="$2"
            shift 2
            ;;
        --identity-file)
            identity_file="$2"
            shift 2
            ;;
        --proxy-jump)
            proxy_jump="$2"
            shift 2
            ;;
        --proxy-key)
            proxy_key="$2"
            shift 2
            ;;
        *) usage ;;
    esac
done

[ -n "$bcm_host" ] && [ -n "$node_ip" ] && [ -n "$vip" ] || usage

# The password file is the only place the credential lives; it never reaches
# argv, which is world-readable through /proc. Remove it however we exit.
cleanup() {
    [ -n "$password_file" ] && rm -f "$password_file"
    return 0
}
trap cleanup EXIT INT TERM

ssh_args=(
    -N
    -p "$bcm_port"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o LogLevel=ERROR
    -o ConnectTimeout=60
    -o ExitOnForwardFailure=yes
    -o ServerAliveInterval=15
    -o ServerAliveCountMax=10
    # The VIP serves the tenant + system consoles; the node itself serves the
    # Local UI on 5080. Both are wanted, and they are different addresses.
    -L "${vip_port}:${vip}:443"
    -L "${localui_port}:${node_ip}:5080"
)

[ -n "$identity_file" ] && ssh_args+=(-i "$identity_file")
if [ -n "$proxy_jump" ]; then
    proxy="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    [ -n "$proxy_key" ] && proxy="$proxy -i $proxy_key"
    ssh_args+=(-o "ProxyCommand=$proxy -W %h:%p $proxy_jump")
fi

ssh_args+=("${bcm_user}@${bcm_host}")

cat << EOF

  Palette appliance console, tunnelled through ${bcm_user}@${bcm_host}:${bcm_port}

    Tenant console   https://localhost:${vip_port}/
    System console   https://localhost:${vip_port}/system
    Local UI         https://localhost:${localui_port}/

  Both serve a self-signed certificate; the browser warning is expected.
  Ctrl-C closes the tunnel.

EOF

if [ -n "$password_file" ]; then
    exec sshpass -f "$password_file" ssh "${ssh_args[@]}"
else
    exec ssh "${ssh_args[@]}"
fi
