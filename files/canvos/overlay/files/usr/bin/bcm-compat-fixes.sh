#!/bin/bash
# bcm-compat-fixes.sh — patch system files for BCM-provisioned Kairos.
#
# BCM provisions Kairos differently from the native installer, so a few system
# files need patching for BCM's environment. Every-boot fixes run each boot;
# one-time fixes run once (guarded by a marker file).
#
# Fail-OPEN (no `set -e`): a boot hook must never break the boot if a best-effort
# fix doesn't apply. `set -u` only.
set -u

MARKER="/var/lib/bcm-compat-fixes.done"

log() { echo "bcm-compat: $*"; }

# ---- Every-boot: hostname from /etc/hostname ----
if [ -f /etc/hostname ]; then
    expected="$(tr -d '[:space:]' < /etc/hostname)"
    if [ -n "$expected" ] && [ "$(hostname)" != "$expected" ]; then
        hostnamectl set-hostname "$expected" 2> /dev/null || hostname "$expected"
        log "set hostname to $expected"
    fi
fi

# ---- One-time fixes (marker-guarded) ----
[ -f "$MARKER" ] && exit 0

# Fix resolved hook: a bare `return` outside a function crashes networking.service.
RESOLVED="/etc/network/if-up.d/resolved"
if [ -f "$RESOLVED" ] && grep -q '^        return$' "$RESOLVED"; then
    sed -i 's/^        return$/        exit 0/' "$RESOLVED"
    log "fixed resolved hook (return -> exit 0)"
fi

# Fix resolv.conf: Kairos ships a symlink to systemd-resolved's stub resolver;
# BCM masks systemd-resolved, leaving a dead symlink and no DNS. Replace with a
# plain file that DHCP (dhclient) manages directly.
if [ -L /etc/resolv.conf ] && [ ! -e /etc/resolv.conf ]; then
    rm -f /etc/resolv.conf
    # Head-node fallback; dhclient overwrites this on lease renewal.
    echo "nameserver 10.141.255.254" > /etc/resolv.conf
    log "fixed resolv.conf (replaced dead symlink)"
fi

touch "$MARKER"
log "one-time fixes applied"
