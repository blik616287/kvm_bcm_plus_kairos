#!/usr/bin/env bash
# shellcheck-templates.sh — INTERIM bridge for linting bash that still lives
# inside Jinja2 *.sh.j2 templates (shellcheck can't parse {{ }} / {% %}).
#
# It renders each template against tests/fixtures/lint-vars.yml (+ the owning
# role's defaults/main.yml) into throwaway .sh files, then runs shellcheck on
# them. As templates are EXTRACTED into real .sh files (plan Part C, Phase 3),
# they leave this harness and join the first-class `shellcheck` gate. The cost
# of keeping the fixtures rendering is itself the argument for finishing the
# extraction.
#
# Usage: scripts/shellcheck-templates.sh [--severity=error|warning|style]
# A template that fails to RENDER is reported and skipped (non-fatal here, since
# missing role-fact vars are expected for not-yet-extracted role templates);
# shellcheck findings respect the severity and DO set the exit code.
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
SEVERITY="${1:---severity=error}"
FIXTURES="tests/fixtures/lint-vars.yml"

command -v ansible >/dev/null 2>&1 || { echo "ansible not found — cannot render templates"; exit 2; }
command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found"; exit 2; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

rc=0
render_fails=0
checked=0

# Find every shell template. (Today: roles/*/templates/*.sh.j2.)
while IFS= read -r tpl; do
  # Derive the owning role to load its defaults/main.yml, which supplies
  # role-internal vars (e.g. kairos_vm_slug) the fixtures don't carry.
  role_defaults=""
  if [[ "$tpl" == roles/*/templates/* ]]; then
    role="${tpl#roles/}"; role="${role%%/*}"
    [[ -f "roles/${role}/defaults/main.yml" ]] && role_defaults="roles/${role}/defaults/main.yml"
  fi

  out="$tmp/$(echo "$tpl" | tr '/' '_' | sed 's/\.j2$//')"

  extra_args=(-e "@${FIXTURES}")
  [[ -n "$role_defaults" ]] && extra_args+=(-e "@${role_defaults}")

  if ! ansible localhost -m ansible.builtin.template \
        -a "src=${ROOT}/${tpl} dest=${out}" \
        "${extra_args[@]}" >/dev/null 2>"$tmp/render.err"; then
    echo "RENDER-SKIP  $tpl  (missing vars — covered once extracted to a real .sh)"
    render_fails=$((render_fails + 1))
    continue
  fi

  if shellcheck -x "$SEVERITY" "$out"; then
    echo "OK           $tpl"
  else
    echo "SHELLCHECK   $tpl  (see findings above)"
    rc=1
  fi
  checked=$((checked + 1))
done < <(find roles -name '*.sh.j2' | sort)

echo "---"
echo "templates shellchecked: $checked   render-skipped: $render_fails   severity: $SEVERITY"
exit "$rc"
