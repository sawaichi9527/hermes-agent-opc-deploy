#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

profiles=(secretary coordinator researcher writer builder runes-holder)
issues=0

pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; issues=$((issues + 1)); }
warn() { echo "WARN $*"; }

require_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass "file $path"
  else
    fail "missing file $path"
  fi
}

require_pattern() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if grep -Eiq -- "$pattern" "$path"; then
    pass "$path contains $label"
  else
    fail "$path missing $label"
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

echo "Repository root: $ROOT"
echo

echo "== SOUL template presence and syntax =="
for profile in "${profiles[@]}"; do
  template="profiles/$profile/SOUL.md.template"
  require_file "$template"
  if [[ -f "$template" ]]; then
    if [[ -s "$template" ]]; then
      pass "non-empty $template"
    else
      fail "empty $template"
    fi
  fi
done

echo

echo "== Common required sections =="
for profile in "${profiles[@]}"; do
  template="profiles/$profile/SOUL.md.template"
  [[ -f "$template" ]] || continue

  echo
  echo "-- $profile --"
  require_pattern "$template" '^# ' 'top-level title'
  require_pattern "$template" 'role|mission|purpose|職責|定位' 'role or mission definition'
  require_pattern "$template" 'boundary|must not|forbidden|do not|禁止|不得' 'role boundary / forbidden behavior'
  require_pattern "$template" 'handoff|escalat|delegate|route|report|回報|交接|轉交' 'handoff / escalation / reporting rule'
  require_pattern "$template" 'language|Traditional Chinese|English|中文|英文|語言' 'language policy'
  require_pattern "$template" 'runes|memory|記憶|沉澱|wiki' 'memory / runes awareness'

  # Allow safety text such as "do not store secrets". Reject only value-like
  # credential assignments or obvious OpenAI-style secret-looking tokens.
  reject_pattern "$template" '(API[_ -]?KEY|TOKEN|PASSWORD|SECRET)[[:space:]]*[:=][[:space:]]*[^[:space:]]+|sk-[A-Za-z0-9]{8,}' 'real secret values'
  reject_pattern "$template" 'rm -rf[[:space:]]+/' 'dangerous shell command'
  require_pattern "$template" 'do not.*real.*(~/.hermes|/home/eye/.hermes)|simulation-first|explicit.*approval|明確.*批准' 'real Hermes mutation safety boundary'
done

echo

echo "== Role-specific boundary checks =="

require_pattern "profiles/secretary/SOUL.md.template" 'Lark|intake|preference|使用者|偏好|入口' 'secretary intake / user preference role'
require_pattern "profiles/secretary/SOUL.md.template" 'coordinator|route|轉交|交辦' 'secretary routes work onward'
reject_pattern "profiles/secretary/SOUL.md.template" 'primary implementer|main coder|own final implementation' 'secretary as implementation owner'

require_pattern "profiles/coordinator/SOUL.md.template" 'plan|route|merge|boundary|assign|PM|project manager|項目經理' 'coordinator planning / routing role'
require_pattern "profiles/coordinator/SOUL.md.template" 'researcher|writer|builder|runes-holder' 'coordinator knows worker profiles'
reject_pattern "profiles/coordinator/SOUL.md.template" 'primary coder|main researcher|final prose owner' 'coordinator taking worker ownership'

require_pattern "profiles/researcher/SOUL.md.template" 'evidence|source|uncertainty|verify|citation|來源|查證' 'research evidence role'
reject_pattern "profiles/researcher/SOUL.md.template" 'final polished draft owner|production code owner|primary implementer|own implementation' 'researcher owning writer/builder work'

require_pattern "profiles/writer/SOUL.md.template" 'structure|audience|clarity|draft|narrative|讀者|結構' 'writer composition role'
require_pattern "profiles/writer/SOUL.md.template" 'do not invent|do not fabricate|evidence|citation|不得捏造|不可捏造' 'writer anti-fabrication rule'
reject_pattern "profiles/writer/SOUL.md.template" 'primary researcher|primary implementer|production code owner' 'writer owning research/build work'

require_pattern "profiles/builder/SOUL.md.template" 'implement|debug|test|verify|shell|code|實作|測試' 'builder implementation role'
require_pattern "profiles/builder/SOUL.md.template" 'dry-run|backup|approval|confirm|simulation|模擬|批准' 'builder safety rule'
reject_pattern "profiles/builder/SOUL.md.template" 'write runes directly|own long-term memory' 'builder direct memory ownership'

require_pattern "profiles/runes-holder/SOUL.md.template" 'runes|hermes-runes-md-wiki|sediment|govern|沉澱|治理' 'runes governance role'
require_pattern "profiles/runes-holder/SOUL.md.template" 'not required|optional|not a dependency|不依賴|不是必要' 'runes optionality boundary'
reject_pattern "profiles/runes-holder/SOUL.md.template" 'replace Hermes native memory|required dependency|mandatory runtime' 'runes replacing native Hermes memory'

echo

echo "== Summary =="
if (( issues == 0 )); then
  echo "PASS profile templates satisfy baseline static checks."
else
  echo "FAIL profile template checks found $issues issue(s)."
  exit 1
fi
