#!/bin/bash
# bcm-sync-userdata.sh — sync the BCM hostname into the Palette edge name.
#
# Called as ExecStartPre for stylus-agent.service. BCM sets the hostname during
# provisioning/sync; this propagates it into the stylus user-data so the node
# registers in Palette under its BCM node name.
#
# Also forces registration mode: BCM always PXE boots, so the
# `stylus.registration` kernel param never reaches the running kernel — we
# detect an unregistered node and bind-mount a patched /proc/cmdline.
#
# Fail-OPEN (no `set -e`): a boot-time ExecStartPre must never block stylus from
# starting. `set -u` only, to catch genuine unset-variable bugs.
set -u

USERDATA="/oem/99_userdata.yaml"
STYLUS_RUNTIME="/run/stylus/userdata"
STYLUS_STATE="/oem/.stylus-state"

log() { echo "bcm-sync: $*"; }

# Replace `<indent><key>: <value>` in a file, idempotently. The value is taken
# verbatim; callers must pass a sed-safe value (see the NODE_NAME guard below).
# Args: FILE  KEY  VALUE  [INDENT(default 4 spaces)]
update_field() {
    local file="$1" key="$2" value="$3" indent="${4:-    }"
    [ -f "$file" ] || return 0
    sed -i "s|^${indent}${key}: .*|${indent}${key}: ${value}|" "$file"
}

# ---- Registration mode (no cached auth token => force stylus.registration) ----
if ! grep -q "stylus.registration" /proc/cmdline 2> /dev/null; then
    needs_registration=false
    if [ ! -f "$STYLUS_STATE" ] || ! grep -q "authToken" "$STYLUS_STATE" 2> /dev/null; then
        needs_registration=true
    fi

    if [ "$needs_registration" = true ]; then
        echo "$(cat /proc/cmdline) stylus.registration" > /tmp/cmdline-registration
        mount --bind /tmp/cmdline-registration /proc/cmdline
        log "enabled registration mode (no auth token found)"

        if [ -f /oem/80_stylus.yaml ]; then
            rm -f /oem/80_stylus.yaml
            log "removed /oem/80_stylus.yaml (prevents upgrade-path crash)"
        fi
    fi
fi

# ---- Seed the runtime userdata copy stylus actually reads ----
if [ ! -f "$STYLUS_RUNTIME" ] && [ -f "$USERDATA" ]; then
    mkdir -p /run/stylus
    cp "$USERDATA" "$STYLUS_RUNTIME"
    log "seeded $STYLUS_RUNTIME from $USERDATA"
fi

# ---- Hostname -> edge name ----
NODE_NAME="$(hostname)"
if [ -z "$NODE_NAME" ] || [ "$NODE_NAME" = "localhost" ]; then
    log "hostname not set yet, skipping"
    exit 0
fi

# Only proceed with a valid hostname. This is also what makes NODE_NAME safe to
# splice into the sed replacements below — a valid hostname can't contain the
# sed specials (/, &, \), so no escaping/injection is possible.
if ! [[ "$NODE_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
    log "hostname '$NODE_NAME' has unexpected characters, skipping name sync"
    exit 0
fi

if [ ! -f "$USERDATA" ]; then
    log "$USERDATA not found, skipping"
    exit 0
fi

if grep -qF "name: ${NODE_NAME}" "$USERDATA" 2> /dev/null; then
    log "name already set to ${NODE_NAME}"
    exit 0
fi

# One helper, three files (was three near-identical sed lines).
update_field "$USERDATA" name "$NODE_NAME"
update_field "$STYLUS_RUNTIME" name "$NODE_NAME"
update_field "$STYLUS_STATE" siteName "$NODE_NAME" ""

log "edge name set to ${NODE_NAME}"
