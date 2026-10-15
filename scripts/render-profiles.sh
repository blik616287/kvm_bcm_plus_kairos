#!/usr/bin/env bash
# Golden render check: what every profile actually puts on a node.
#
# Renders, for each profiles/*.yml and tests/render/variants/*.yml, the stage-4
# dd installer and finalize script and the stage-3 cloud-config the profile
# selects, with variables merged in Ansible's precedence order and fixed
# placeholders for run-time facts (tests/fixtures/render-vars.yml). Every
# render must be valid (bash -n + shellcheck errors for scripts, the role's own
# cloud-config validator for YAML) and must match the committed copy under
# tests/golden/<profile>/.
#
# A change to a template, role default or profile therefore shows up in the
# PR as a diff of what each profile renders. That is the review surface for
# "does this change behaviour for a profile it should not touch?".
#
# Usage: scripts/render-profiles.sh check    # CI gate: render + validate + diff
#        scripts/render-profiles.sh update   # rewrite tests/golden/ after an intended change
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
MODE="${1:-check}"
GOLDEN="$ROOT/tests/golden"

case "$MODE" in
    check | update) ;;
    *)
        echo "usage: $0 check|update" >&2
        exit 2
        ;;
esac

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
OUT="$WORK/render"
mkdir -p "$OUT"

fail=0
for src in profiles/*.yml tests/render/variants/*.yml; do
    name=$(basename "$src" .yml)
    python3 -I tests/render/merge_vars.py "$ROOT" "$src" "$WORK/$name.vars.yml"
    if ! ANSIBLE_LOG_PATH=/dev/null ANSIBLE_STDOUT_CALLBACK=default \
        ansible-playbook -i localhost, -c local tests/render/render.yml \
        -e repo="$ROOT" -e out="$OUT/$name" -e "@$WORK/$name.vars.yml" \
        > "$WORK/$name.log" 2>&1; then
        echo "RENDER FAILED  $name" >&2
        grep -m3 -E 'fatal|ERROR|msg' "$WORK/$name.log" >&2 || true
        fail=1
        continue
    fi
    for sh in "$OUT/$name"/*.sh; do
        bash -n "$sh" || {
            echo "BASH SYNTAX    $name/$(basename "$sh")" >&2
            fail=1
        }
        shellcheck -s bash --severity=error "$sh" || {
            echo "SHELLCHECK     $name/$(basename "$sh")" >&2
            fail=1
        }
    done
    python3 -I roles/kairos_build/files/check-cloud-config.py "$OUT/$name/cloud-config.yaml" > /dev/null || {
        echo "CLOUD-CONFIG   $name/cloud-config.yaml" >&2
        fail=1
    }
    echo "rendered       $name"
done

[ "$fail" = 0 ] || {
    echo "render check FAILED: fix the renders above before comparing goldens" >&2
    exit 1
}

if [ "$MODE" = update ]; then
    rm -rf "$GOLDEN"
    cp -r "$OUT" "$GOLDEN"
    echo "tests/golden/ updated; review 'git diff tests/golden' and commit it with the change"
    exit 0
fi

if ! diff -ru "$GOLDEN" "$OUT"; then
    cat >&2 << 'EOF'

render check FAILED: a profile now renders differently from tests/golden/.
If the change is intended, run `make render-update`, review the per-profile
diff, and commit tests/golden/ with an explanation in the PR of why each
profile that changed should change.
EOF
    exit 1
fi
echo "render check OK: every profile matches tests/golden/"
