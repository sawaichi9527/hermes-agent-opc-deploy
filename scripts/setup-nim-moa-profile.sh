#!/usr/bin/env bash
set -euo pipefail

# setup-nim-moa-profile.sh — nim-researcher MoA preset（D5 / M6b 實測）
#
# 設計：在 K6 上，把 nim-researcher profile 的 config.yaml 設定 MoA preset：
#   reference = NVIDIA NIM meta/llama-3.3-70b-instruct（provider nvidia，非 nim）
#   aggregator = 本機 custom agents-a1
#   reference_max_tokens: 600 / fanout: user_turn
#
# dry-run 預設 + backup-before-write；不含真實 secret。
#
# 執行方式：
#   bash scripts/setup-nim-moa-profile.sh              # dry-run
#   bash scripts/setup-nim-moa-profile.sh --apply      # 寫入 config
#   HERMES_PROFILES_ROOT=... bash scripts/setup-nim-moa-profile.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES_ROOT="${HERMES_PROFILES_ROOT:-$HOME/.hermes/profiles}"
PROFILE="nim-researcher"
CONFIG_FILE="$PROFILES_ROOT/$PROFILE/config.yaml"
APPLY=0

AGGREGATOR_BASE_URL="${AGGREGATOR_BASE_URL:-http://192.168.23.217:1234/v1}"
AGGREGATOR_MODEL="${AGGREGATOR_MODEL:-agents-a1}"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/setup-nim-moa-profile.sh [--apply]

Default behavior:
  - Dry-run only: reports the MoA preset that would be written to nim-researcher config.
  - Uses provider nvidia (reads NVIDIA_API_KEY) — NOT nim (NIM_API_KEY does not exist).

Options:
  --apply
      Write the moa.presets.nim-researcher block (backup-before-write).

Environment:
  HERMES_PROFILES_ROOT   Default: $HOME/.hermes/profiles
  AGGREGATOR_BASE_URL    Default: http://192.168.23.217:1234/v1
  AGGREGATOR_MODEL       Default: agents-a1

Boundary:
  This configures the MoA preset only. The per-task trigger cap (<=3, D5b) is
  enforced via jobs.json moa_trigger_count + nim-researcher SOUL, not here.
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

if [ ! -f "$CONFIG_FILE" ]; then
  echo "FAIL nim-researcher config missing: $CONFIG_FILE" >&2
  exit 1
fi

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "FAIL missing command: $cmd" >&2
    exit 1
  fi
}
need_cmd python3

printf 'setup-nim-moa-profile.sh (v0.20.0) — MoA preset for nim-researcher\n'
printf 'Config: %s\n' "$CONFIG_FILE"
printf 'Aggregator: %s @ %s\n' "$AGGREGATOR_MODEL" "$AGGREGATOR_BASE_URL"
printf 'Apply: %s\n\n' "$APPLY"

tmp_file="$(mktemp)"
report_file="$(mktemp)"

if python3 - "$CONFIG_FILE" "$AGGREGATOR_BASE_URL" "$AGGREGATOR_MODEL" >"$tmp_file" 2>"$report_file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
base_url = sys.argv[2]
model = sys.argv[3]

text = path.read_text(encoding="utf-8")
block = (
    "\nmoa:\n"
    "  presets:\n"
    "    nim-researcher:\n"
    "      reference_models:\n"
    "        - provider: nvidia\n"
    f"          model: meta/llama-3.3-70b-instruct\n"
    "      aggregator:\n"
    "        provider: custom\n"
    f"        model: {model}\n"
    f"        base_url: {base_url}\n"
    "      reference_max_tokens: 600\n"
    "      fanout: user_turn\n"
)

if "nim-researcher:" in text and "meta/llama-3.3-70b-instruct" in text:
    print("ACTION already present", file=sys.stderr)
    sys.stdout.write(text)
    sys.exit(0)

# append block at end
if not text.endswith("\n"):
    text += "\n"
text += block
print("ACTION append moa.presets.nim-researcher", file=sys.stderr)
sys.stdout.write(text)
sys.exit(10)
PY
then
  py_status=0
else
  py_status=$?
fi

action="$(cat "$report_file" | tail -n 1 || true)"
case "$action" in
  ACTION\ already\ present*)
    printf 'PASS nim-researcher MoA preset already present\n'
    ;;
  ACTION\ append\ moa.presets.nim-researcher*)
    if [ "$APPLY" -eq 1 ]; then
      backup="$CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
      cp "$CONFIG_FILE" "$backup"
      cat "$tmp_file" >"$CONFIG_FILE"
      printf 'PASS MoA preset written; backup=%s\n' "$backup"
    else
      printf 'INFO dry-run would append MoA preset to nim-researcher config\n'
    fi
    ;;
  *)
    if [ "$py_status" -eq 10 ]; then
      if [ "$APPLY" -eq 1 ]; then
        backup="$CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
        cp "$CONFIG_FILE" "$backup"
        cat "$tmp_file" >"$CONFIG_FILE"
        printf 'PASS MoA preset written\n'
      else
        printf 'INFO dry-run would update config\n'
      fi
    elif [ "$py_status" -eq 0 ]; then
      printf 'PASS no change needed\n'
    else
      printf 'FAIL config patcher failed\n'
      exit 1
    fi
    ;;
esac

rm -f "$tmp_file" "$report_file"

printf '\nVerify with:\n'
printf '  hermes -p nim-researcher chat -Q -q "<prompt>" -m moa:nim-researcher\n'
printf '  # or moa-trace to confirm reference fan-out + aggregator convergence (M6b)\n'
