#!/usr/bin/env bash
set -euo pipefail

PROVIDER="${HERMES_RUNTIME_PROVIDER:-lmstudio}"
MODEL="${HERMES_RUNTIME_MODEL:-qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m}"
PROMPT="Reply with exactly: hermes-runtime-ok"
EXPECTED="hermes-runtime-ok"
NON_EMPTY=0
SHOW_OUTPUT=0

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/smoke-hermes-runtime-oneshot.sh [options]

Default behavior:
  - Runs exactly one `hermes -z` request.
  - Uses explicit --provider and --model overrides.
  - Validates exact marker output: hermes-runtime-ok.
  - Does not mutate profile state.
  - Does not create alias wrappers.
  - Does not start daemon/process management.
  - Does not run concurrent or load-test requests.

Options:
  --provider <name>    Default: lmstudio or HERMES_RUNTIME_PROVIDER
  --model <name>       Default: qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m or HERMES_RUNTIME_MODEL
  --prompt <text>      Prompt for the single request.
  --expected <text>    Expected exact output marker. Default: hermes-runtime-ok
  --non-empty          Pass when trimmed output is non-empty instead of exact-match.
  --show-output        Print the trimmed model output after validation.
  -h, --help           Show this help.

Examples:
  bash scripts/smoke-hermes-runtime-oneshot.sh

  bash scripts/smoke-hermes-runtime-oneshot.sh \
    --prompt "Summarize Phase 3L, 3M, and 3N in three short bullet lines. Do not edit files." \
    --non-empty
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --provider)
      if [ "$#" -lt 2 ]; then
        echo "FAIL --provider requires a value" >&2
        exit 2
      fi
      PROVIDER="$2"
      shift 2
      ;;
    --model)
      if [ "$#" -lt 2 ]; then
        echo "FAIL --model requires a value" >&2
        exit 2
      fi
      MODEL="$2"
      shift 2
      ;;
    --prompt)
      if [ "$#" -lt 2 ]; then
        echo "FAIL --prompt requires a value" >&2
        exit 2
      fi
      PROMPT="$2"
      shift 2
      ;;
    --expected)
      if [ "$#" -lt 2 ]; then
        echo "FAIL --expected requires a value" >&2
        exit 2
      fi
      EXPECTED="$2"
      shift 2
      ;;
    --non-empty)
      NON_EMPTY=1
      shift
      ;;
    --show-output)
      SHOW_OUTPUT=1
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

if ! command -v hermes >/dev/null 2>&1; then
  echo "FAIL missing command: hermes" >&2
  exit 1
fi

printf 'Hermes runtime oneshot smoke\n'
printf 'Provider: %s\n' "$PROVIDER"
printf 'Model: %s\n' "$MODEL"
printf 'Validation: %s\n' "$([ "$NON_EMPTY" -eq 1 ] && echo non-empty || echo exact-marker)"
printf 'Boundary: one request / no profile mutation / no alias wrapper / no daemon / no concurrency / no load test\n\n'

output_tmp="$(mktemp)"
trap 'rm -f "$output_tmp"' EXIT

if ! hermes -z "$PROMPT" \
    --provider "$PROVIDER" \
    --model "$MODEL" >"$output_tmp"; then
  echo "FAIL hermes oneshot request failed" >&2
  exit 1
fi

trimmed="$(python3 - "$output_tmp" <<'PY'
import sys
from pathlib import Path
print(Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").strip())
PY
)"

if [ "$NON_EMPTY" -eq 1 ]; then
  if [ -z "$trimmed" ]; then
    echo "FAIL hermes oneshot returned empty output" >&2
    exit 1
  fi
  echo "PASS non-empty output returned"
else
  if [ "$trimmed" != "$EXPECTED" ]; then
    echo "FAIL exact marker mismatch" >&2
    echo "Expected: $EXPECTED" >&2
    echo "Actual:   $trimmed" >&2
    exit 1
  fi
  echo "PASS exact marker returned"
fi

if [ "$SHOW_OUTPUT" -eq 1 ]; then
  printf '\n== Output ==\n%s\n' "$trimmed"
fi

printf '\nPASS Hermes runtime oneshot smoke completed\n'
