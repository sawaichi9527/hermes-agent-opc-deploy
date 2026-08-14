#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES_ROOT="${HERMES_PROFILES_ROOT:-$HOME/.hermes/profiles}"
PROFILE_LIST_ENV="${PROFILE_LIST:-}"
MODEL_NAME="${MODEL_NAME:-}"
APPLY=0
FORCE=0
VERIFY=0
AEON_BASE_URL="${AEON_BASE_URL:-http://192.168.23.215:1234/v1}"
AEON_AUTH="${AEON_AUTH:-}"

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

load_profiles_from_roles "${REPO_ROOT}/editions/opc-personal/roles.txt"

if [ "${#profiles[@]}" -eq 0 ]; then
  profiles=(secretary coordinator researcher writer builder runes-holder)
fi

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/set-local-model-name.sh --model <model-id> [--apply] [--force]
  MODEL_NAME=<model-id> ./scripts/set-local-model-name.sh [--apply] [--force]

Default behavior:
  - Dry-run only.
  - Reads and patches real local profile config files under ~/.hermes/profiles.
  - Does not touch repository profile templates.
  - Does not touch .env files.

Options:
  --model <model-id>
      Model id to write as model.name.

  --apply
      Write changes to ~/.hermes/profiles/<profile>/config.yaml.
      Without --apply, the script only reports what would change.

  --force
      Replace an existing model.name value.
      Without --force, existing model.name values are left unchanged.

  --verify
      After apply (or as a standalone dry-run check for aeon-builder), verify the
      remote endpoint identity by querying /v1/models and comparing the reported
      model id to the config model.name (D13). Only meaningful for aeon-builder.

Environment:
  HERMES_PROFILES_ROOT   Default: $HOME/.hermes/profiles
  PROFILE_LIST           Optional comma/space-separated profile list.
                         Example: PROFILE_LIST=secretary
  MODEL_NAME             Alternative to --model.
  AEON_BASE_URL          Default: http://192.168.23.215:1234/v1 (Spark vLLM, D13)
  AEON_AUTH              Optional "Bearer <token>" for identity check.

Examples:
  PROFILE_LIST=secretary \
  MODEL_NAME=qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m \
  ./scripts/set-local-model-name.sh

  PROFILE_LIST=secretary \
  MODEL_NAME=qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m \
  ./scripts/set-local-model-name.sh --apply

  # aeon-builder model switch (D13): set model.name then verify remote identity
  PROFILE_LIST=aeon-builder MODEL_NAME=qwen3.6-27b \
    ./scripts/set-local-model-name.sh --apply --verify

Boundary:
  This is local profile configuration cleanup only. It does not introduce model
  routing, queues, concurrency, load testing, external fallback, or daemon work.
  The --verify identity check is read-only against the remote /v1/models endpoint.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --model)
      if [ "$#" -lt 2 ]; then
        echo "FAIL --model requires a model id" >&2
        exit 2
      fi
      MODEL_NAME="$2"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --verify)
      VERIFY=1
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

if [ -n "$PROFILE_LIST_ENV" ]; then
  # Accept comma-separated or whitespace-separated values.
  # shellcheck disable=SC2206
  profiles=(${PROFILE_LIST_ENV//,/ })
fi

if [ "${#profiles[@]}" -eq 0 ]; then
  echo "FAIL no profiles loaded from editions/opc-personal/roles.txt" >&2
  exit 2
fi

if [ -z "$MODEL_NAME" ]; then
  echo "FAIL model id is required. Pass --model <model-id> or MODEL_NAME=<model-id>." >&2
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

printf 'v0.20.0 model.name setup (profiles from editions/opc-personal/roles.txt)\n'
printf 'Profiles root: %s\n' "$PROFILES_ROOT"
printf 'Selected profiles: %s\n' "${profiles[*]}"
printf 'Model name: %s\n' "$MODEL_NAME"
printf 'Apply: %s\n' "$APPLY"
printf 'Force replace existing model.name: %s\n\n' "$FORCE"

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

  if python3 - "$config_file" "$MODEL_NAME" "$FORCE" >"$tmp_file" 2>"$report_file" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
model_name = sys.argv[2]
force = sys.argv[3] == "1"

lines = path.read_text(encoding="utf-8").splitlines()

model_line = None
model_indent = 0
model_end = len(lines)
name_line = None
provider_line = None

for i, raw in enumerate(lines):
    stripped = raw.strip()
    if not stripped or stripped.startswith("#"):
        continue
    if re.match(r"^model\s*:\s*$", stripped):
        model_line = i
        model_indent = len(raw) - len(raw.lstrip(" "))
        break

if model_line is not None:
    for j in range(model_line + 1, len(lines)):
        raw = lines[j]
        stripped = raw.strip()
        indent = len(raw) - len(raw.lstrip(" "))
        if stripped and not stripped.startswith("#") and indent <= model_indent:
            model_end = j
            break
        if stripped.startswith("name:"):
            name_line = j
        if stripped.startswith("provider:"):
            provider_line = j

changed = False
if model_line is None:
    if lines and lines[-1].strip():
        lines.append("")
    lines.extend([
        "model:",
        "  provider: openai",
        f"  name: {model_name}",
    ])
    changed = True
    print("ACTION append model block", file=sys.stderr)
elif name_line is None:
    insert_at = provider_line + 1 if provider_line is not None else model_line + 1
    child_indent = " " * (model_indent + 2)
    lines.insert(insert_at, f"{child_indent}name: {model_name}")
    changed = True
    print("ACTION insert model.name", file=sys.stderr)
else:
    raw = lines[name_line]
    prefix = raw.split(":", 1)[0]
    current = raw.split(":", 1)[1].strip()
    if (current.startswith('"') and current.endswith('"')) or (current.startswith("'") and current.endswith("'")):
        current_unquoted = current[1:-1]
    else:
        current_unquoted = current
    if current_unquoted == model_name:
        print("ACTION already set", file=sys.stderr)
    elif force:
        lines[name_line] = f"{prefix}: {model_name}"
        changed = True
        print(f"ACTION replace model.name old={current_unquoted}", file=sys.stderr)
    else:
        print(f"ACTION skip existing model.name old={current_unquoted}", file=sys.stderr)

sys.stdout.write("\n".join(lines) + "\n")
sys.exit(10 if changed else 0)
PY
  then
    py_status=0
  else
    py_status=$?
  fi

  action="$(cat "$report_file" | tail -n 1 || true)"
  case "$action" in
    ACTION\ already\ set*)
      pass "$profile model.name already set"
      skip_count=$((skip_count + 1))
      ;;
    ACTION\ skip\ existing*)
      warn "$profile has existing model.name; use --force to replace"
      skip_count=$((skip_count + 1))
      ;;
    ACTION\ insert*|ACTION\ append*|ACTION\ replace*)
      if [ "$APPLY" -eq 1 ]; then
        backup="$config_file.bak.$(date +%Y%m%d%H%M%S)"
        cp "$config_file" "$backup"
        cat "$tmp_file" >"$config_file"
        pass "$profile updated config.yaml; backup=$backup; $action"
      else
        info "$profile dry-run would update config.yaml; $action"
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

# --- aeon-builder remote identity verification (D13) ---
if [ "$VERIFY" -eq 1 ] && [[ " ${profiles[*]} " == *" aeon-builder "* ]]; then
  printf '== aeon-builder remote identity check (D13) ==\n'
  need_cmd curl
  actual_model="$(curl -s -m 8 -H "Authorization: ${AEON_AUTH}" "${AEON_BASE_URL}/models" 2>/dev/null | grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"id"[[:space:]]*:[[:space:]]*"([^"]+)"/\1/' || true)"
  if [ -z "$actual_model" ]; then
    fail "aeon-builder identity check: unable to fetch /v1/models from ${AEON_BASE_URL}"
  else
    config_file="$PROFILES_ROOT/aeon-builder/config.yaml"
    configured="$(grep -E '^[[:space:]]*name:[[:space:]]*' "$config_file" 2>/dev/null | tail -1 | sed -E 's/^[^:]*:[[:space:]]*//' | tr -d '[:space:]' | tr -d "\"'" || true)"
    if [ -n "$configured" ] && [[ "$actual_model" == *"$configured"* || "$configured" == *"$actual_model"* ]]; then
      pass "aeon-builder identity verified: remote model=${actual_model} matches config model.name=${configured}"
    else
      warn "aeon-builder identity mismatch: remote=${actual_model} vs config=${configured}. Do not dispatch aeon-builder until models match (D13)."
    fi
  fi
  printf '\n'
fi

printf '== Summary ==\n'
if [ "$fail_count" -ne 0 ]; then
  printf 'FAIL local model.name cleanup found %s issue(s).\n' "$fail_count"
  exit 1
fi

if [ "$APPLY" -eq 1 ]; then
  printf 'PASS local model.name cleanup apply completed; changes=%s skipped=%s.\n' "$change_count" "$skip_count"
else
  printf 'PASS local model.name cleanup dry-run completed; planned_changes=%s skipped=%s.\n' "$change_count" "$skip_count"
fi
