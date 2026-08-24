#!/usr/bin/env bash
set -euo pipefail

# align-secretary-model.sh — secretary → coordinator/builder/writer/researcher 模型對齊
# 用途：把 secretary 的 model 區塊（provider / base_url / name / api_key 等）原樣複製到 4 個 worker，
#        確保 5 角色使用「同一模型」。
# 來源：使用者需求「coordinator, builder, writer, researcher 使用的模型，與 secretary 一致」
# 機制：讀 ~/.hermes/profiles/secretary/config.yaml 的 model: 區塊，寫入目標 4 profile 的同區塊。
# 安全：dry-run 預設；--apply 才寫檔；自動 backup；不觸及 .env / secrets；不改 aeon-builder / nim-researcher / runes-holder。

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES_ROOT="${HERMES_PROFILES_ROOT:-$HOME/.hermes/profiles}"
SECRETARY_PROFILE="${SECRETARY_PROFILE:-secretary}"
TARGETS_DEFAULT="coordinator builder writer researcher"
TARGETS_ENV="${PROFILE_LIST:-}"
APPLY=0

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/align-secretary-model.sh [--apply] [--secretary <name>] [--targets <list>]
  PROFILE_LIST="coordinator writer" ./scripts/align-secretary-model.sh [--apply]

對齊 secretary 的 model 區塊到 4 worker（coordinator/builder/writer/researcher）。

Default behavior:
  - Dry-run only. 顯示將如何對齊，不寫檔。
  - 不觸及 aeon-builder / nim-researcher / runes-holder（專用模型/ MoA）。
  - 不觸及 .env / api_key 值本身（只複製 config.yaml 的 model 區塊引用）。

Options:
  --apply
      實際寫入 ~/.hermes/profiles/<target>/config.yaml。
  --secretary <name>
      Secretary 來源 profile（預設 secretary）。
  --targets <list>
      逗號或空白分隔的目標清單（預設: coordinator builder writer researcher）。

Environment:
  HERMES_PROFILES_ROOT  Default: $HOME/.hermes/profiles
  PROFILE_LIST          覆蓋預設 targets（逗號/空白分隔）。
  SECRETARY_PROFILE     覆蓋來源 secretary 名稱。

Examples:
  ./scripts/align-secretary-model.sh
  ./scripts/align-secretary-model.sh --apply
  PROFILE_LIST="coordinator builder" ./scripts/align-secretary-model.sh --apply

Verify after apply:
  for p in secretary coordinator builder writer researcher; do echo "== $p =="; grep -A5 '^model:' ~/.hermes/profiles/$p/config.yaml | head -10; done
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --secretary)
      if [ "$#" -lt 2 ]; then echo "FAIL --secretary requires a name" >&2; exit 2; fi
      SECRETARY_PROFILE="$2"; shift 2 ;;
    --targets)
      if [ "$#" -lt 2 ]; then echo "FAIL --targets requires a list" >&2; exit 2; fi
      TARGETS_ENV="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "FAIL unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Resolve targets
targets=()
if [ -n "$TARGETS_ENV" ]; then
  # shellcheck disable=SC2206
  targets=(${TARGETS_ENV//,/ })
else
  # shellcheck disable=SC2206
  targets=(${TARGETS_DEFAULT//,/ })
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then echo "FAIL missing command: $1" >&2; exit 1; fi
}
# Resolve python interpreter (K6 has python3; Windows dev may have python)
if command -v python3 >/dev/null 2>&1 && python3 -c "import sys" >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "FAIL missing python3/python" >&2; exit 1
fi

pass() { printf 'PASS %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; }
info() { printf 'INFO %s\n' "$1"; }

printf 'align-secretary-model: secretary -> 4 workers (model block mirror)\n'
printf 'Profiles root: %s\n' "$PROFILES_ROOT"
printf 'Source: %s\n' "$SECRETARY_PROFILE"
printf 'Targets: %s\n' "${targets[*]}"
printf 'Apply: %s\n\n' "$APPLY"

src_file="$PROFILES_ROOT/$SECRETARY_PROFILE/config.yaml"
if [ ! -f "$src_file" ]; then
  fail "source config missing: $src_file"
  exit 1
fi
pass "source config exists: $src_file"

# Extract model block via python (preserve raw lines for fidelity)
src_model_block="$($PYTHON - "$src_file" <<'PY'
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
lines = p.read_text(encoding="utf-8").splitlines()
m_start = None
m_indent = 0
m_end = len(lines)
for i, raw in enumerate(lines):
    s = raw.strip()
    if not s or s.startswith("#"):
        continue
    if re.match(r"^model\s*:\s*$", s):
        m_start = i
        m_indent = len(raw) - len(raw.lstrip(" "))
        break
if m_start is None:
    print("FAIL no model block in source", file=sys.stderr)
    sys.exit(1)
for j in range(m_start+1, len(lines)):
    raw = lines[j]
    s = raw.strip()
    indent = len(raw) - len(raw.lstrip(" "))
    if s and not s.startswith("#") and indent <= m_indent:
        m_end = j
        break
block = lines[m_start:m_end]
# sanity: must contain name or default:
joined = "\n".join(block)
if "name:" not in joined and "default:" not in joined:
    print("FAIL source model block has no name/default:", file=sys.stderr)
    sys.exit(1)
for l in block:
    print(l)
PY
)"
py_status=$?
if [ $py_status -ne 0 ]; then
  fail "failed to extract model block from $src_file"
  exit 1
fi

printf 'Source model block (%s):\n' "$SECRETARY_PROFILE"
printf '%s\n' "$src_model_block"
printf '\n'

fail_count=0
change_count=0
skip_count=0

for profile in "${targets[@]}"; do
  printf '== Target: %s ==\n' "$profile"
  profile_dir="$PROFILES_ROOT/$profile"
  cfg="$profile_dir/config.yaml"
  if [ ! -d "$profile_dir" ]; then
    printf 'FAIL %s directory missing: %s\n\n' "$profile" "$profile_dir"
    fail_count=$((fail_count+1)); continue
  fi
  pass "$profile directory exists"
  if [ ! -f "$cfg" ]; then
    printf 'FAIL %s config.yaml missing\n\n' "$profile"
    fail_count=$((fail_count+1)); continue
  fi
  pass "$profile config.yaml exists"

  tmp_file="$(mktemp)"
  report_file="$(mktemp)"

  # Python: replace or insert model block with source block
  if $PYTHON - "$cfg" "$src_model_block" >"$tmp_file" 2>"$report_file" <<'PY'
import re, sys
from pathlib import Path
cfg_path = Path(sys.argv[1])
src_block_text = sys.argv[2]
src_block = src_block_text.splitlines()

lines = cfg_path.read_text(encoding="utf-8").splitlines()

m_start = None
m_indent = 0
m_end = len(lines)
for i, raw in enumerate(lines):
    s = raw.strip()
    if not s or s.startswith("#"):
        continue
    if re.match(r"^model\s*:\s*$", s):
        m_start = i
        m_indent = len(raw) - len(raw.lstrip(" "))
        break

if m_start is not None:
    for j in range(m_start+1, len(lines)):
        raw = lines[j]
        s = raw.strip()
        indent = len(raw) - len(raw.lstrip(" "))
        if s and not s.startswith("#") and indent <= m_indent:
            m_end = j
            break

# Compare existing block vs source
if m_start is not None:
    existing = lines[m_start:m_end]
    if existing == src_block:
        print("ACTION already aligned", file=sys.stderr)
        sys.stdout.write("\n".join(lines) + "\n")
        sys.exit(0)
    # replace
    new_lines = lines[:m_start] + src_block + lines[m_end:]
    print(f"ACTION replace model block lines {m_start}:{m_end} -> {len(src_block)} lines", file=sys.stderr)
    sys.stdout.write("\n".join(new_lines) + "\n")
    sys.exit(10)
else:
    # append
    if lines and lines[-1].strip():
        lines.append("")
    lines.extend(src_block)
    print("ACTION append model block", file=sys.stderr)
    sys.stdout.write("\n".join(lines) + "\n")
    sys.exit(10)
PY
  then
    py_status=0
  else
    py_status=$?
  fi

  action="$(cat "$report_file" | tail -n 1 || true)"
  case "$action" in
    ACTION\ already\ aligned*)
      pass "$profile already aligned with $SECRETARY_PROFILE"
      skip_count=$((skip_count+1))
      ;;
    ACTION\ replace*|ACTION\ append*)
      if [ "$APPLY" -eq 1 ]; then
        backup="$cfg.bak.align-$(date +%Y%m%d%H%M%S)"
        cp "$cfg" "$backup"
        cat "$tmp_file" >"$cfg"
        pass "$profile updated; backup=$backup; $action"
      else
        info "$profile dry-run would $action"
        # show diff snippet
        printf '  --- dry-run preview (first 8 lines of new model block) ---\n'
        printf '%s\n' "$src_model_block" | head -8 | sed 's/^/  /'
      fi
      change_count=$((change_count+1))
      ;;
    *)
      if [ "$py_status" -eq 10 ]; then
        if [ "$APPLY" -eq 1 ]; then
          backup="$cfg.bak.align-$(date +%Y%m%d%H%M%S)"
          cp "$cfg" "$backup"
          cat "$tmp_file" >"$cfg"
          pass "$profile updated (fallback)"
        else
          info "$profile dry-run would update (fallback)"
        fi
        change_count=$((change_count+1))
      elif [ "$py_status" -eq 0 ]; then
        pass "$profile no change"
        skip_count=$((skip_count+1))
      else
        printf 'FAIL %s patch failed: %s\n' "$profile" "$action"
        fail_count=$((fail_count+1))
      fi
      ;;
  esac
  rm -f "$tmp_file" "$report_file"
  printf '\n'
done

printf '== Summary ==\n'
if [ "$fail_count" -ne 0 ]; then
  printf 'FAIL alignment completed with %s failure(s); changes=%s skipped=%s\n' "$fail_count" "$change_count" "$skip_count"
  exit 1
fi
if [ "$APPLY" -eq 1 ]; then
  printf 'PASS alignment apply completed; changes=%s skipped=%s (source=%s -> targets=%s)\n' "$change_count" "$skip_count" "$SECRETARY_PROFILE" "${targets[*]}"
  printf 'Verify: for p in secretary coordinator builder writer researcher; do echo "== $p =="; grep -A6 "^model:" ~/.hermes/profiles/$p/config.yaml | head -10; done\n'
else
  printf 'PASS alignment dry-run completed; planned_changes=%s skipped=%s\n' "$change_count" "$skip_count"
  printf 'Run with --apply to write changes.\n'
fi
