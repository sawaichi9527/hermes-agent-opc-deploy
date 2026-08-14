#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 骨架模式（階段一）：只驗證 SOUL.md.template 存在、非空、不含 secrets / 危險命令。
# 階段二填實 v4.1 內容後，再切回嚴格 pattern 檢查（見 archive/v0.16-v0.17/scripts/verify-profile-templates.sh 舊版）。

GENERIC_ROLES=(secretary coordinator researcher builder writer)
OPC_ROLES=(secretary coordinator researcher writer builder runes-holder aeon-builder nim-researcher)
issues=0

pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; issues=$((issues + 1)); }

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file $path"
  else
    fail "missing file $path"
  fi
}

require_nonempty() {
  local path="$1"
  if [[ -s "$path" ]]; then
    pass "non-empty $path"
  else
    fail "empty $path"
  fi
}

reject_pattern() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eiq -- "$pattern" "$path"; then
    fail "$path contains forbidden $label"
  else
    pass "$path avoids $label"
  fi
}

check_edition() {
  local edition="$1"
  shift
  local roles=("$@")
  local role
  local template

  echo
  echo "== Edition: $edition (skeleton mode) =="
  for role in "${roles[@]}"; do
    template="editions/$edition/profiles/$role/SOUL.md.template"
    echo
    echo "-- $role --"
    require_file "$template"
    require_nonempty "$template"
    [[ -f "$template" ]] || continue
    reject_pattern "$template" '(API[_ -]?KEY|TOKEN|PASSWORD|SECRET)[[:space:]]*[:=][[:space:]]*[^[:space:]]+|sk-[A-Za-z0-9]{8,}' 'real secret values'
    reject_pattern "$template" 'rm -rf[[:space:]]+/' 'dangerous shell command'
  done
}

check_edition generic "${GENERIC_ROLES[@]}"
check_edition opc-personal "${OPC_ROLES[@]}"

echo
echo "== Summary =="
if (( issues == 0 )); then
  echo "PASS profile templates (skeleton mode) satisfy baseline static checks."
else
  echo "FAIL profile template checks found $issues issue(s)."
  exit 1
fi
