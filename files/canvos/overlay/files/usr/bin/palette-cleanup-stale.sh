#!/bin/bash
# palette-cleanup-stale.sh — pre-registration housekeeping for Palette on the node.
#
# Runs as ExecStartPre for stylus-agent. Only acts during registration mode
# (either `stylus.registration` in /proc/cmdline OR no cached authToken in
# /oem/.stylus-state). In other states it's a quick no-op.
#
# Two responsibilities:
#   (1) If /oem/90_custom.yaml has no edgeHostToken value, mint a fresh one
#       via the Palette admin API and inject it. Without this, stylus has
#       nothing to authenticate with.
#   (2) If a stale Palette edge host record already exists for our UID (from a
#       prior install), DELETE it so this node's registration isn't refused
#       with "UID already registered".
#
# Config (baked into /oem/palette-admin.env at first boot by cloud-config):
#   APIKEY=<base64 palette admin api key with edgeToken.create + edgehost.delete>
#   PROJECTUID=<palette project uid>
#   ENDPOINT=<palette hostname, e.g. s-ai.lan>
#
# Fail-open on every error path — never block stylus-agent from starting.

set +e
LOG_TAG="palette-cleanup-stale"
USERDATA_FILE="/oem/90_custom.yaml"

log()  { echo "${LOG_TAG}: $*" ; }

# ---- Gate: registration mode only ----
NEEDS_REGISTRATION=false
if grep -q "stylus.registration" /proc/cmdline 2>/dev/null; then
    NEEDS_REGISTRATION=true
fi
if [ ! -f /oem/.stylus-state ] || ! grep -q "authToken" /oem/.stylus-state 2>/dev/null; then
    NEEDS_REGISTRATION=true
fi
if [ "$NEEDS_REGISTRATION" != "true" ]; then
    log "not in registration mode (cached authToken present), skipping"
    exit 0
fi

# ---- Load admin creds ----
CONF=/oem/palette-admin.env
if [ ! -r "$CONF" ]; then
    log "admin config $CONF missing/unreadable, skipping"
    exit 0
fi
# shellcheck disable=SC1090
. "$CONF"
if [ -z "${APIKEY:-}" ] || [ -z "${PROJECTUID:-}" ] || [ -z "${ENDPOINT:-}" ]; then
    log "admin config missing one of APIKEY/PROJECTUID/ENDPOINT, skipping"
    exit 0
fi

api() {
    # api METHOD PATH [BODY]  — emit "HTTP_CODE\nBODY"
    local method="$1" path="$2" body="${3:-}"
    local extra=()
    [ -n "$body" ] && extra=(-H "Content-Type: application/json" -d "$body")
    curl -sk -o /tmp/palette-api.out -w "%{http_code}" \
        -X "$method" \
        -H "ApiKey: ${APIKEY}" \
        --connect-timeout 10 --max-time 20 \
        "${extra[@]}" \
        "https://${ENDPOINT}${path}"
    echo
    cat /tmp/palette-api.out 2>/dev/null
    rm -f /tmp/palette-api.out
}

# ---- (1) ensure edgeHostToken is present in userdata ----
CURRENT_TOKEN=""
if [ -r "$USERDATA_FILE" ]; then
    # grab the value after "edgeHostToken:" (trim quotes/whitespace). Empty if absent.
    CURRENT_TOKEN=$(awk '
        /^[[:space:]]*edgeHostToken:[[:space:]]*/ {
            sub(/^[[:space:]]*edgeHostToken:[[:space:]]*/, "");
            gsub(/["\047]/, "");
            gsub(/[[:space:]]+$/, "");
            print; exit
        }' "$USERDATA_FILE")
fi

if [ -z "$CURRENT_TOKEN" ]; then
    log "no edgeHostToken in $USERDATA_FILE — generating one via admin API"
    EXPIRY=$(date -u -d "+30 days" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null)
    if [ -z "$EXPIRY" ]; then
        # fallback for busybox date
        EXPIRY=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    fi
    NAME="auto-$(cat /sys/class/dmi/id/product_uuid 2>/dev/null | head -c 18)-$(date +%s)"
    BODY=$(printf '{"metadata":{"name":"%s"},"spec":{"defaultProject":{"uid":"%s"},"expiry":"%s"}}' \
           "$NAME" "$PROJECTUID" "$EXPIRY")
    # The create-token endpoint is TENANT-scoped — do NOT send ProjectUid header.
    RESP=$(api POST "/v1/edgehosts/tokens" "$BODY")
    HTTP=$(echo "$RESP" | head -1)
    BODYLINE=$(echo "$RESP" | tail -n +2)
    if [ "$HTTP" != "201" ] && [ "$HTTP" != "200" ]; then
        log "token create failed HTTP $HTTP: $BODYLINE — continuing without token"
    else
        TOKEN_UID=$(echo "$BODYLINE" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("uid",""))' 2>/dev/null)
        if [ -n "$TOKEN_UID" ]; then
            # Fetch the token string
            RESP2=$(api GET "/v1/edgehosts/tokens/${TOKEN_UID}" "")
            BODY2=$(echo "$RESP2" | tail -n +2)
            NEW_TOKEN=$(echo "$BODY2" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("spec",{}).get("token",""))' 2>/dev/null)
            if [ -n "$NEW_TOKEN" ]; then
                log "generated token uid=${TOKEN_UID}; injecting into $USERDATA_FILE"
                # replace existing edgeHostToken: line, or inject under stylus.site: if missing
                if grep -q '^[[:space:]]*edgeHostToken:' "$USERDATA_FILE"; then
                    sed -i "s|^\([[:space:]]*edgeHostToken:\).*|\1 ${NEW_TOKEN}|" "$USERDATA_FILE"
                else
                    # insert after "site:" line (two-space indent assumed)
                    sed -i "/^  site:/a\    edgeHostToken: ${NEW_TOKEN}" "$USERDATA_FILE"
                fi
                CURRENT_TOKEN="$NEW_TOKEN"
            else
                log "token create returned uid but token fetch returned empty; continuing"
            fi
        fi
    fi
else
    log "edgeHostToken already present in $USERDATA_FILE, skipping generation"
fi

# ---- (2) purge stale edge host record if present ----
SYS_UUID=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null | tr -d '-' | tr 'A-Z' 'a-z')
if [ -z "$SYS_UUID" ]; then
    log "no SMBIOS product_uuid available, skipping stale-record check"
    exit 0
fi
EDGE_UID="edge-${SYS_UUID}"
log "our edge host UID: ${EDGE_UID}"

# edge host lookup is project-scoped, so the GET/DELETE need ProjectUid header.
# Inline a variant of api() for project scope.
project_api() {
    local method="$1" path="$2"
    curl -sk -o /tmp/palette-api.out -w "%{http_code}" \
        -X "$method" \
        -H "ApiKey: ${APIKEY}" \
        -H "ProjectUid: ${PROJECTUID}" \
        --connect-timeout 10 --max-time 20 \
        "https://${ENDPOINT}${path}"
    echo
    rm -f /tmp/palette-api.out
}

HTTP=$(project_api GET "/v1/edgehosts/${EDGE_UID}")
case "$HTTP" in
    200)
        log "stale record found for ${EDGE_UID}, deleting"
        DEL=$(project_api DELETE "/v1/edgehosts/${EDGE_UID}")
        if [ "$DEL" = "204" ] || [ "$DEL" = "200" ]; then
            log "deleted stale record (HTTP ${DEL})"
        else
            log "delete returned HTTP ${DEL}; stylus will attempt registration anyway"
        fi
        ;;
    404)
        log "no existing record for ${EDGE_UID}, proceeding to registration"
        ;;
    401|403)
        log "auth failure (HTTP ${HTTP}); check APIKEY permissions — skipping"
        ;;
    *)
        log "unexpected response (HTTP ${HTTP}) — skipping"
        ;;
esac

exit 0
