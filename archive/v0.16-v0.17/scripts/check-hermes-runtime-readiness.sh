#!/usr/bin/env bash
set -euo pipefail

HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
PROFILE_ROOT="${PROFILE_ROOT:-$HERMES_ROOT/profiles}"
PROFILE_LIST_RAW="${PROFILE_LIST:-secretary coordinator researcher writer builder runes-holder}"
REQUIRE_HERMES_COMMAND=0
STRICT=0

usage() {
  cat <<'EOF'
Usage: scripts/check-hermes-runtime-readiness.sh [--strict] [--require-hermes-command]

Read-only Phase 3M Hermes runtime readiness preflight.

Environment:
  HERMES_ROOT       Real Hermes root. Default: $HOME/.hermes
  PROFILE_ROOT      Real profile root. Default: $HERMES_ROOT/profiles
  PROFILE_LIST      Space- or comma-separated profile list.

Options:
  --strict                  Treat warnings as failures.
  --require-hermes-command  Require a detectable Hermes CLI command.
  -h, --help                Show this help.

Boundary:
  - read-only
  - no profile mutation
  - no secrets printed
  - no chat request
  - no parallel probing
  - no daemon/process startup
  - no load test
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict)
      STRICT=1
      ;;
    --require-hermes-command)
      REQUIRE_HERMES_COMMAND=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'FAIL unknown argument: %s\n' "$1"
      usage
      exit 2
      ;;
  esac
  shift
done

fail_count=0
warn_count=0

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1"
  fail_count=$((fail_count + 1))
}

warn() {
  printf 'WARN %s\n' "$1"
  warn_count=$((warn_count + 1))
}

info() {
  printf 'INFO %s\n' "$1"
}

normalize_profiles() {
  printf '%s\n' "$1" | tr ',' ' ' | xargs
}

file_mode_octal() {
  local path="$1"
  if stat -c '%a' "$path" >/dev/null 2>&1; then
    stat -c '%a' "$path"
  else
    stat -f '%Lp' "$path"
  fi
}

read_env_value() {
  local env_file="$1"
  local key="$2"
  awk -F= -v key="$key" '
    $0 ~ "^[[:space:]]*#" { next }
    $1 == key {
      sub(/^[^=]*=/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      gsub(/^\"|\"$/, "")
      gsub(/^'\''|'\''$/, "")
      print
      exit
    }
  ' "$env_file"
}

has_yaml_key_under_model() {
  local config_file="$1"
  local key="$2"
  python3 - "$config_file" "$key" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
try:
    lines = path.read_text(encoding="utf-8").splitlines()
except Exception:
    sys.exit(2)

in_model = False
model_indent = None
for line in lines:
    if not line.strip() or line.lstrip().startswith("#"):
        continue
    indent = len(line) - len(line.lstrip(" "))
    stripped = line.strip()
    if re.match(r"^model\s*:\s*$", stripped):
        in_model = True
        model_indent = indent
        continue
    if in_model and indent <= model_indent:
        in_model = False
    if in_model and re.match(rf"^{re.escape(key)}\s*:\s*\S+", stripped):
        sys.exit(0)

sys.exit(1)
PY
}

command_exists_any() {
  local found=1
  local candidate
  for candidate in "$@"; do
    if command -v "$candidate" >/dev/null 2>&1; then
      printf '%s' "$candidate"
      found=0
      break
    fi
  done
  return "$found"
}

profiles="$(normalize_profiles "$PROFILE_LIST_RAW")"

printf 'Phase 3M Hermes runtime readiness preflight\n'
printf 'Hermes root: %s\n' "$HERMES_ROOT"
printf 'Profiles root: %s\n' "$PROFILE_ROOT"
printf 'Selected profiles: %s\n' "$profiles"
printf 'Strict: %s\n' "$STRICT"
printf 'Require Hermes command: %s\n\n' "$REQUIRE_HERMES_COMMAND"

printf '== Hermes root ==\n'
if [ -d "$HERMES_ROOT" ]; then
  pass "Hermes root exists"
else
  fail "Hermes root missing: $HERMES_ROOT"
fi

if [ -f "$HERMES_ROOT/SOUL.md" ]; then
  pass "Hermes root SOUL.md exists"
else
  warn "Hermes root SOUL.md missing: $HERMES_ROOT/SOUL.md"
fi

if [ -d "$PROFILE_ROOT" ]; then
  pass "profile root exists"
else
  fail "profile root missing: $PROFILE_ROOT"
fi

printf '\n== Hermes command discovery ==\n'
hermes_cmd=""
if hermes_cmd="$(command_exists_any hermes hermes-agent hermes-agent-cli)"; then
  pass "Hermes command found: $hermes_cmd"
else
  if [ "$REQUIRE_HERMES_COMMAND" -eq 1 ]; then
    fail "Hermes command not found in PATH"
  else
    warn "Hermes command not found in PATH; preflight continues without command invocation"
  fi
fi

printf '\n== Profile readiness ==\n'
for profile in $profiles; do
  printf '\n-- Profile: %s --\n' "$profile"
  profile_dir="$PROFILE_ROOT/$profile"
  env_file="$profile_dir/.env"
  config_file="$profile_dir/config.yaml"
  soul_file="$profile_dir/SOUL.md"

  if [ -d "$profile_dir" ]; then
    pass "$profile directory exists"
  else
    fail "$profile directory missing"
    continue
  fi

  if [ -f "$soul_file" ]; then
    pass "$profile SOUL.md exists"
  else
    warn "$profile SOUL.md missing"
  fi

  if [ -f "$config_file" ]; then
    pass "$profile config.yaml exists"
  else
    fail "$profile config.yaml missing"
  fi

  if [ -f "$env_file" ]; then
    pass "$profile .env exists"
    mode="$(file_mode_octal "$env_file")"
    if [ "$mode" = "600" ]; then
      pass "$profile .env permission 600"
    else
      warn "$profile .env permission is $mode, expected 600"
    fi
  else
    fail "$profile .env missing"
  fi

  if [ -f "$env_file" ]; then
    base="$(read_env_value "$env_file" OPENAI_API_BASE || true)"
    key="$(read_env_value "$env_file" OPENAI_API_KEY || true)"
    if [ -n "$base" ]; then
      pass "$profile OPENAI_API_BASE present"
      case "$base" in
        */v1)
          pass "$profile OPENAI_API_BASE ends with /v1"
          ;;
        *)
          warn "$profile OPENAI_API_BASE does not end with /v1"
          ;;
      esac
    else
      fail "$profile OPENAI_API_BASE missing"
    fi
    if [ -n "$key" ]; then
      pass "$profile OPENAI_API_KEY present"
    else
      fail "$profile OPENAI_API_KEY missing"
    fi
  fi

  if [ -f "$config_file" ]; then
    if has_yaml_key_under_model "$config_file" provider; then
      pass "$profile model.provider present"
    else
      warn "$profile model.provider missing under model"
    fi
    if has_yaml_key_under_model "$config_file" name; then
      pass "$profile model.name present"
    else
      fail "$profile model.name missing under model"
    fi
  fi
done

if [ "$STRICT" -eq 1 ] && [ "$warn_count" -gt 0 ]; then
  fail "strict mode treats warnings as failures; warnings=$warn_count"
fi

printf '\n== Summary ==\n'
if [ "$fail_count" -eq 0 ]; then
  printf 'PASS Hermes runtime readiness preflight completed; warnings=%s.\n' "$warn_count"
  exit 0
fi

printf 'FAIL Hermes runtime readiness preflight found %s issue(s); warnings=%s.\n' "$fail_count" "$warn_count"
exit 1
