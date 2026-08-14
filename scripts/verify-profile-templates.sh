#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 嚴格模式（階段二/M8）：驗證 editions/*/profiles/*/SOUL.md.template
# 具備 v4.1 必要 sections、無真實 secret 值、無實質危險執行指令。
#
# 對 L3 命令的描述（如 D18 安全規則中列出 rm -rf /）是允許的——
# 那是 boundary 規則，不是執行指令。僅拒絕「sk-...」等真實 secret 值
# 與「實際含參數的破壞指令」形式。

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

require_section() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eiq -- "$pattern" "$path"; then
    pass "$path contains $label"
  else
    fail "$path missing $label"
  fi
}

reject_real_secrets() {
  local path="$1"
  # 拒絕真實 secret 值：sk-[0-9A-Za-z]{20,}（OpenAI/LM Studio 格式）、
  # 或 KEY/TOKEN/PASSWORD 後接非註解的實際長字串。
  if grep -Eiq -- 'sk-[A-Za-z0-9]{20,}|(API[_ -]?KEY|TOKEN|PASSWORD|SECRET)[[:space:]]*[:=][[:space:]]*[A-Za-z0-9/+]{20,}' "$path"; then
    fail "$path contains real secret-looking value"
  else
    pass "$path avoids real secret values"
  fi
}

reject_executable_destructive() {
  local path="$1"
  # 拒絕「實際執行形式」的破壞指令：命令開頭（^、^sudo、^bash -c 等）
  # 且帶完整目標參數。允許安全規則中的描述（如 `rm -rf /` 在 D18 表格內）。
  if grep -Eiq -- '^[[:space:]]*(sudo[[:space:]]+)?(rm[[:space:]]+-rf|dd[[:space:]].*of=/dev/|mkfs|fdisk|shred)[[:space:]]' "$path"; then
    fail "$path contains executable destructive command form"
  else
    pass "$path avoids executable destructive commands"
  fi
}

check_edition() {
  local edition="$1"
  shift
  local roles=("$@")
  local role
  local template

  echo
  echo "== Edition: $edition (strict mode) =="
  for role in "${roles[@]}"; do
    template="editions/$edition/profiles/$role/SOUL.md.template"
    echo
    echo "-- $role --"
    require_file "$template"
    [[ -f "$template" ]] || continue
    require_section "$template" '^(#|##)[[:space:]]*.*(Role|角色|Mission|任務|定位)' 'role/mission section'
    require_section "$template" '(Not Your Role|不是你的角色|Do not|不得|禁止)' 'role boundary / forbidden section'
    require_section "$template" '(Safety|安全|Boundary|邊界)' 'safety section'
    require_section "$template" '(Language|語言|policy|政策)' 'language policy'
    require_section "$template" '(Memory|記憶|Runes|runes|wiki)' 'memory/runes awareness'
    reject_real_secrets "$template"
    reject_executable_destructive "$template"
  done
}

check_edition generic "${GENERIC_ROLES[@]}"
check_edition opc-personal "${OPC_ROLES[@]}"

echo
echo "== Summary =="
if (( issues == 0 )); then
  echo "PASS profile templates (strict mode) satisfy v4.1 baseline checks."
else
  echo "FAIL profile template checks found $issues issue(s)."
  exit 1
fi
