#!/bin/bash
# bcm-sync-userdata.sh — sync BCM hostname to Palette edge name
#
# Called as ExecStartPre for stylus-agent.service.
# BCM sets the hostname during provisioning/sync. This script updates
# the Palette user-data so stylus-agent registers with the BCM node name.
#
# Also handles registration mode: BCM always PXE boots, so the
# stylus.registration kernel param never reaches the running kernel.
# We detect unregistered nodes and bind-mount a modified /proc/cmdline.

USERDATA="/oem/99_userdata.yaml"

# ---- Registration mode ----
if ! grep -q "stylus.registration" /proc/cmdline 2>/dev/null; then
    NEEDS_REGISTRATION=false
    if [ ! -f /oem/.stylus-state ]; then
        NEEDS_REGISTRATION=true
    elif ! grep -q "authToken" /oem/.stylus-state 2>/dev/null; then
        NEEDS_REGISTRATION=true
    fi

    if [ "$NEEDS_REGISTRATION" = "true" ]; then
        echo "$(cat /proc/cmdline) stylus.registration" > /tmp/cmdline-registration
        mount --bind /tmp/cmdline-registration /proc/cmdline
        echo "bcm-sync: enabled registration mode (no auth token found)"

        if [ -f /oem/80_stylus.yaml ]; then
            rm -f /oem/80_stylus.yaml
            echo "bcm-sync: removed /oem/80_stylus.yaml (prevents upgrade-path crash)"
        fi
    fi
fi

# ---- Ensure /run/stylus/userdata exists ----
if [ ! -f /run/stylus/userdata ] && [ -f "$USERDATA" ]; then
    mkdir -p /run/stylus
    cp "$USERDATA" /run/stylus/userdata
    echo "bcm-sync: seeded /run/stylus/userdata from $USERDATA"
fi

# ---- Hostname sync ----
NODE_NAME=$(hostname)

if [ -z "$NODE_NAME" ] || [ "$NODE_NAME" = "localhost" ]; then
    echo "bcm-sync-userdata: hostname not set yet, skipping"
    exit 0
fi

if [ ! -f "$USERDATA" ]; then
    echo "bcm-sync-userdata: $USERDATA not found, skipping"
    exit 0
fi

# Check if name already matches
if grep -q "name: ${NODE_NAME}$" "$USERDATA" 2>/dev/null; then
    echo "bcm-sync-userdata: name already set to ${NODE_NAME}"
    exit 0
fi

# Update the name field in user-data
sed -i "s/^    name: .*/    name: ${NODE_NAME}/" "$USERDATA"

# Update /run/stylus/userdata if it exists
if [ -f /run/stylus/userdata ]; then
    sed -i "s/^    name: .*/    name: ${NODE_NAME}/" /run/stylus/userdata
fi

# Update cached edge name
if [ -f /oem/.stylus-state ]; then
    sed -i "s/^siteName: .*/siteName: ${NODE_NAME}/" /oem/.stylus-state
fi

echo "bcm-sync-userdata: edge name set to ${NODE_NAME}"
