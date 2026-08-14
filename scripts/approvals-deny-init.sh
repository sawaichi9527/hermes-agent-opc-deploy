#!/usr/bin/env bash
set -euo pipefail

# approvals-deny-init.sh — 寫入 D18 L3 清單至 approvals.deny（M3/M6a 實測）
#
# 設計：在 K6 上，把三級破壞性白名單的 L3 毀滅清單寫入 builder/aeon-builder
#   profile 的 approvals.deny（user glob 硬熔斷，連 --yolo 都擋，caveat 1 收斂）。
#
#   L3 = HARDLINE_PATTERNS（hermes 原生，rm -rf /、mkfs、dd of=/dev/ 等）
#      + user approvals.deny glob 補強（fdisk、shred 等）。
#   L2 = DANGEROUS_PATTERNS（原生 ask-approval）+ Feishu 卡片（send_exec_approval）。
#
# dry-run 預設 + backup-before-write；不含真實 secret。
#
# 執行方式：
#   bash scripts/approvals-deny-init.sh              # dry-run
#   bash scripts/approvals-deny-init.sh --apply      # 寫入 config
#   HERMES_PROFILES_ROOT=... bash scripts/approvals-deny-init.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES_ROOT="${HERMES_PROFILES_ROOT:-$HOME/.hermes/profiles}"
APPLY=0

# L3 毀滅補強清單（HARDLINE_PATTERNS 已含 rm -rf /、mkfs、dd of=/dev/；
# 此處以 approvals.deny glob 補 fdisk/shred 等硬熔斷）
DENY_PATTERNS=(fdisk shred)

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/approvals-deny-init.sh [--apply]

Default behavior:
  - Dry-run only: reports the approvals.deny entries that would be added.

Options:
  --apply
      Write approvals.deny entries (backup-before-write) to builder and aeon-builder configs.

Environment:
  HERMES_PROFILES_ROOT   Default: $HOME/.hermes/profiles

Boundary:
  L3 hardline is hermes-native HARDLINE_PATTERNS + user deny glob; no shell wrapper
  (caveat 1 resolved). L2 is DANGEROUS_PATTERNS ask-approval + Feishu card (D20),
  handled by SOUL guidance, not this deny list.
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

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "FAIL missing command: $cmd" >&2
    exit 1
  fi
}
need_cmd python3

printf 'approvals-deny-init.sh (v0.20.0) — D18 L3 deny list for builder/aeon-builder\n'
printf 'Profiles root: %s\n' "$PROFILES_ROOT"
printf 'Deny patterns: %s\n' "${DENY_PATTERNS[*]}"
printf 'Apply: %s\n\n' "$APPLY"

for profile in builder aeon-builder; do
  printf '== Profile: %s ==\n' "$profile"
  config_file="$PROFILES_ROOT/$profile/config.yaml"

  if [ ! -f "$config_file" ]; then
    printf 'WARN %s config missing (skip)\n' "$config_file"
    continue
  fi

  tmp_file="$(mktemp)"
  report_file="$(mktemp)"

  if python3 - "$config_file" "${DENY_PATTERNS[@]}" >"$tmp_file" 2>"$report_file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
patterns = sys.argv[2:]

lines = path.read_text(encoding="utf-8").splitlines()

approvals_line = None
approvals_indent = 0
deny_line = None
deny_indent = 0
deny_end = len(lines)

for i, raw in enumerate(lines):
    stripped = raw.strip()
    if not stripped or stripped.startswith("#"):
        continue
    if stripped == "approvals:":
        approvals_line = i
        approvals_indent = len(raw) - len(raw.lstrip(" "))
    if stripped == "deny:" and approvals_line is not None:
        deny_line = i
        deny_indent = len(raw) - len(raw.lstrip(" "))

# determine deny list end (next key at or above deny_indent)
if deny_line is not None:
    for j in range(deny_line + 1, len(lines)):
        raw = lines[j]
        stripped = raw.strip()
        indent = len(raw) - len(raw.lstrip(" "))
        if stripped and not stripped.startswith("#") and indent <= deny_indent:
            deny_end = j
            break

existing = set()
if deny_line is not None:
    for j in range(deny_line + 1, deny_end):
        stripped = lines[j].strip()
        if stripped.startswith("- "):
            existing.add(stripped[2:].strip().strip("'\""))

new_items = [p for p in patterns if p not in existing]
if not new_items:
    print("ACTION already covered", file=sys.stderr)
    sys.stdout.write("\n".join(lines) + "\n")
    sys.exit(0)

if deny_line is None:
    if approvals_line is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append("approvals:")
        lines.append("  deny:")
    else:
        lines.append("  deny:")
    insert_at = len(lines)
else:
    insert_at = deny_end

for i, p in enumerate(new_items):
    lines.insert(insert_at + i, f"    - {p}")

print(f"ACTION add deny {', '.join(new_items)}", file=sys.stderr)
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
    ACTION\ already\ covered*)
      printf 'PASS %s approvals.deny already covers L3 list\n' "$profile"
      ;;
    ACTION\ add\ deny*)
      if [ "$APPLY" -eq 1 ]; then
        backup="$config_file.bak.$(date +%Y%m%d%H%M%S)"
        cp "$config_file" "$backup"
        cat "$tmp_file" >"$config_file"
        printf 'PASS %s approvals.deny updated; backup=%s; %s\n' "$profile" "$backup" "$action"
      else
        printf 'INFO %s dry-run would update approvals.deny; %s\n' "$profile" "$action"
      fi
      ;;
    *)
      if [ "$py_status" -eq 10 ]; then
        if [ "$APPLY" -eq 1 ]; then
          backup="$config_file.bak.$(date +%Y%m%d%H%M%S)"
          cp "$config_file" "$backup"
          cat "$tmp_file" >"$config_file"
          printf 'PASS %s updated config.yaml\n' "$profile"
        else
          printf 'INFO %s dry-run would update config\n' "$profile"
        fi
      elif [ "$py_status" -eq 0 ]; then
        printf 'PASS %s no change needed\n' "$profile"
      else
        printf 'FAIL %s config patcher failed\n' "$profile"
      fi
      ;;
  esac

  rm -f "$tmp_file" "$report_file"
  printf '\n'
done

printf 'Reminder:\n'
printf '  L3 hardline is hermes-native HARDLINE_PATTERNS (rm -rf /, mkfs, dd of=/dev/) — built-in, non-bypassable.\n'
printf '  L2 (apt upgrade, systemctl stop, reboot) is ask-approval + Feishu card — enforced via coordinator/builder SOUL (G-D18).\n'
