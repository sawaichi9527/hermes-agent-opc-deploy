#!/usr/bin/env bash
set -euo pipefail

# setup-plur.sh — 確認所有 profile 啟用 plur-memory（D7，M7 實測）
#
# 設計：在 K6 上執行，確認 8 個 OPC profile 的 plugins.enabled 都含 plur。
#   * plur-hermes（pip plugin）與 plur-memory（skill 形態）皆需存在（M7 修正）。
#   * 本腳本不做 pip/npm 安裝（那是 M7 的一次性動作），只確認與修補 profile config。
#   * 備份 = 一次性快照（M7 已做 m7-plur-snapshot），非定期；本腳本不改 ~/.plur。
#
# 執行方式：
#   bash scripts/setup-plur.sh              # dry-run（預設）
#   bash scripts/setup-plur.sh --apply      # 寫入 profile config
#   HERMES_PROFILES_ROOT=... bash scripts/setup-plur.sh
#
# 對應藍圖 §4（三層記憶）與 D7。

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES_ROOT="${HERMES_PROFILES_ROOT:-$HOME/.hermes/profiles}"
ROLES_FILE="${REPO_ROOT}/editions/opc-personal/roles.txt"
PLUGIN_NAME="plur"
APPLY=0

profiles=()

load_profiles_from_roles() {
  local roles_file="$1"
  local line
  profiles=()
  if [ -f "${roles_file}" ]; then
    while IFS= read -r line || [ -n "${line}" ]; do
      line="${line%%#*}"
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
      [ -n "${line}" ] || continue
      profiles+=("${line}")
    done < "${roles_file}"
  fi
}

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/setup-plur.sh [--apply]

Default behavior:
  - Dry-run only: reports each profile's plugins.enabled status and what would change.
  - Reads editions/opc-personal/roles.txt for the 8 profiles.

Options:
  --apply
      Actually write plugins.enabled changes to ~/.hermes/profiles/<role>/config.yaml
      (backup-before-write). Without --apply nothing is written.

Environment:
  HERMES_PROFILES_ROOT   Default: $HOME/.hermes/profiles

Boundary:
  This script does NOT install plur-hermes / @plur-ai/cli and does NOT touch ~/.plur.
  One-time backup is handled separately (m7-plur-snapshot).
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply)
      APPLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "FAIL unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

load_profiles_from_roles "${ROLES_FILE}"

if [ "${#profiles[@]}" -eq 0 ]; then
  echo "FAIL no profiles loaded from ${ROLES_FILE}" >&2
  exit 2
fi

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "FAIL missing command: $cmd" >&2
    exit 1
  fi
}

need_cmd python3

fail_count=0
change_count=0
skip_count=0

pass() { printf 'PASS %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }
info() { printf 'INFO %s\n' "$1"; }

printf 'setup-plur.sh (v0.20.0) — plugins.enabled: plur for OPC profiles\n'
printf 'Profiles root: %s\n' "$PROFILES_ROOT"
printf 'Profiles: %s\n' "${profiles[*]}"
printf 'Apply: %s\n\n' "$APPLY"

for profile in "${profiles[@]}"; do
  printf '== Profile: %s ==\n' "$profile"
  profile_dir="$PROFILES_ROOT/$profile"
  config_file="$profile_dir/config.yaml"

  if [ ! -d "$profile_dir" ]; then
    fail "$profile directory missing: $profile_dir"
    printf '\n'
    continue
  fi
  pass "$profile directory exists"

  if [ ! -f "$config_file" ]; then
    fail "$profile config.yaml missing"
    printf '\n'
    continue
  fi
  pass "$profile config.yaml exists"

  tmp_file="$(mktemp)"
  report_file="$(mktemp)"

  if python3 - "$config_file" >"$tmp_file" 2>"$report_file" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
plugin = "plur"
lines = path.read_text(encoding="utf-8").splitlines()

plugins_line = None
plugins_indent = 0
plugins_end = len(lines)

for i, raw in enumerate(lines):
    stripped = raw.strip()
    if not stripped or stripped.startswith("#"):
        continue
    if re.match(r"^plugins\s*:\s*$", stripped):
        plugins_line = i
        plugins_indent = len(raw) - len(raw.lstrip(" "))
        break

has_plur = False
if plugins_line is not None:
    for j in range(plugins_line + 1, len(lines)):
        raw = lines[j]
        stripped = raw.strip()
        indent = len(raw) - len(raw.lstrip(" "))
        if stripped and not stripped.startswith("#") and indent <= plugins_indent:
            plugins_end = j
            break
        if re.match(r"^-\s*[\"']?plur[\"']?\s*$", stripped) or re.match(r"^enabled:\s*.*\bplur\b", stripped):
            has_plur = True

if has_plur:
    print("ACTION already enabled", file=sys.stderr)
else:
    if plugins_line is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append("plugins:")
        lines.append("  enabled:")
        lines.append("    - plur")
    else:
        lines.insert(plugins_end, " " * (plugins_indent + 2) + "- plur")
    print("ACTION enable plur", file=sys.stderr)

sys.stdout.write("\n".join(lines) + "\n")
sys.exit(10 if not has_plur else 0)
PY
  then
    py_status=0
  else
    py_status=$?
  fi

  action="$(cat "$report_file" | tail -n 1 || true)"
  case "$action" in
    ACTION\ already\ enabled*)
      pass "$profile plugins.enabled already contains plur"
      skip_count=$((skip_count + 1))
      ;;
    ACTION\ enable\ plur*)
      if [ "$APPLY" -eq 1 ]; then
        backup="$config_file.bak.$(date +%Y%m%d%H%M%S)"
        cp "$config_file" "$backup"
        cat "$tmp_file" >"$config_file"
        pass "$profile enabled plur in config.yaml; backup=$backup"
      else
        info "$profile dry-run would enable plur"
      fi
      change_count=$((change_count + 1))
      ;;
    *)
      if [ "$py_status" -eq 10 ]; then
        if [ "$APPLY" -eq 1 ]; then
          backup="$config_file.bak.$(date +%Y%m%d%H%M%S)"
          cp "$config_file" "$backup"
          cat "$tmp_file" >"$config_file"
          pass "$profile updated config.yaml"
        else
          info "$profile dry-run would update config.yaml"
        fi
        change_count=$((change_count + 1))
      elif [ "$py_status" -eq 0 ]; then
        pass "$profile no change needed"
        skip_count=$((skip_count + 1))
      else
        fail "$profile config patcher failed"
      fi
      ;;
  esac

  rm -f "$tmp_file" "$report_file"
  printf '\n'
done

printf '== Summary ==\n'
if [ "$fail_count" -ne 0 ]; then
  printf 'FAIL setup-plur found %s issue(s).\n' "$fail_count"
  exit 1
fi

if [ "$APPLY" -eq 1 ]; then
  printf 'PASS setup-plur apply completed; changes=%s already=%s.\n' "$change_count" "$skip_count"
else
  printf 'PASS setup-plur dry-run completed; planned_changes=%s already=%s.\n' "$change_count" "$skip_count"
fi
