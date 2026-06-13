#!/usr/bin/env bash
set -euo pipefail

PROFILES_ROOT="${HERMES_PROFILES_ROOT:-$HOME/.hermes/profiles}"
SMOKE_DELAY_SEC="${SMOKE_DELAY_SEC:-2}"
RUN_CHAT=0
CHAT_MAX_TOKENS="${CHAT_MAX_TOKENS:-32}"
SINGLE_PROFILE=""

profiles=(
  secretary
  coordinator
  researcher
  writer
  builder
  runes-holder
)

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/smoke-local-provider-sequential.sh [--chat] [--profile <name>]

Default behavior:
  - Sequential only.
  - Checks ~/.hermes/profiles/<profile>/.env and config.yaml.
  - Calls /v1/models once per profile.
  - Does not trigger text generation.

Options:
  --chat
      Also send one minimal chat completion per profile, sequentially.

  --profile <name>
      Check only one profile.

Environment:
  HERMES_PROFILES_ROOT   Default: $HOME/.hermes/profiles
  SMOKE_DELAY_SEC        Default: 2
  CHAT_MAX_TOKENS        Default: 32

Concurrency rule:
  This script intentionally does not use background jobs, xargs -P, GNU parallel,
  or async fanout. LM Studio / llama.cpp server is treated as a personal local
  backend, not a vLLM-style concurrent serving backend.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --chat)
      RUN_CHAT=1
      shift
      ;;
    --profile)
      if [ "$#" -lt 2 ]; then
        echo "FAIL --profile requires a profile name" >&2
        exit 2
      fi
      SINGLE_PROFILE="$2"
      shift 2
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

if [ -n "$SINGLE_PROFILE" ]; then
  profiles=("$SINGLE_PROFILE")
fi

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "FAIL missing command: $cmd" >&2
    exit 1
  fi
}

need_cmd curl
need_cmd python3

extract_env_value() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
needle = key + "="

for raw in path.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if line.startswith("export "):
        line = line[len("export "):].strip()
    if not line.startswith(needle):
        continue
    value = line[len(needle):].strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        value = value[1:-1]
    print(value)
    sys.exit(0)
sys.exit(0)
PY
}

extract_model_name() {
  local file="$1"
  python3 - "$file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8").splitlines()
inside_model = False
model_indent = None
for raw in text:
    stripped = raw.strip()
    if not stripped or stripped.startswith("#"):
        continue
    indent = len(raw) - len(raw.lstrip(" "))
    if stripped == "model:" or stripped.startswith("model:"):
        inside_model = True
        model_indent = indent
        continue
    if inside_model:
        if indent <= (model_indent or 0) and not raw.startswith(" "):
            inside_model = False
        if stripped.startswith("name:"):
            value = stripped.split(":", 1)[1].strip()
            if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
                value = value[1:-1]
            print(value)
            sys.exit(0)
print("")
PY
}

json_get_model_count() {
  local file="$1"
  python3 - "$file" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    print("parse-error")
    sys.exit(1)

items = None
if isinstance(data, dict):
    items = data.get("data")
elif isinstance(data, list):
    items = data

if isinstance(items, list):
    print(len(items))
elif isinstance(items, dict):
    print(len(items))
else:
    print("unknown-shape")
PY
}

json_get_chat_text() {
  local file="$1"
  python3 - "$file" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
    choices = data.get("choices") or []
    if not choices:
        print("")
        sys.exit(0)
    msg = choices[0].get("message") or {}
    print((msg.get("content") or "").strip())
except Exception:
    print("")
    sys.exit(1)
PY
}

fail_count=0

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1"
  fail_count=$((fail_count + 1))
}

warn() {
  printf 'WARN %s\n' "$1"
}

printf 'Local provider sequential smoke\n'
printf 'Profiles root: %s\n' "$PROFILES_ROOT"
printf 'Chat smoke: %s\n' "$RUN_CHAT"
printf 'Delay: %ss\n\n' "$SMOKE_DELAY_SEC"

for profile in "${profiles[@]}"; do
  printf '== Profile: %s ==\n' "$profile"

  profile_dir="$PROFILES_ROOT/$profile"
  env_file="$profile_dir/.env"
  config_file="$profile_dir/config.yaml"

  if [ ! -d "$profile_dir" ]; then
    fail "$profile directory missing: $profile_dir"
    printf '\n'
    continue
  fi
  pass "$profile directory exists"

  if [ ! -f "$env_file" ]; then
    fail "$profile .env missing"
    printf '\n'
    continue
  fi
  pass "$profile .env exists"

  if [ ! -f "$config_file" ]; then
    fail "$profile config.yaml missing"
    printf '\n'
    continue
  fi
  pass "$profile config.yaml exists"

  if [ "$(stat -c '%a' "$env_file" 2>/dev/null || stat -f '%Lp' "$env_file" 2>/dev/null || echo unknown)" != "600" ]; then
    warn "$profile .env permission is not 600"
  else
    pass "$profile .env permission 600"
  fi

  base_url="$(extract_env_value "$env_file" OPENAI_API_BASE)"
  api_key="$(extract_env_value "$env_file" OPENAI_API_KEY)"
  model_name="$(extract_model_name "$config_file")"

  if [ -z "$base_url" ]; then
    fail "$profile OPENAI_API_BASE missing"
    printf '\n'
    continue
  fi
  pass "$profile OPENAI_API_BASE present"

  if [ -z "$api_key" ]; then
    fail "$profile OPENAI_API_KEY missing"
    printf '\n'
    continue
  fi
  pass "$profile OPENAI_API_KEY present"

  case "$base_url" in
    */v1)
      pass "$profile OPENAI_API_BASE ends with /v1"
      ;;
    *)
      fail "$profile OPENAI_API_BASE must end with /v1: $base_url"
      printf '\n'
      continue
      ;;
  esac

  if grep -Eq '^[[:space:]]*(LM_API_KEY|LM_BASE_URL)=' "$env_file"; then
    warn "$profile contains LM_API_KEY or LM_BASE_URL; baseline prefers OPENAI_API_BASE/OPENAI_API_KEY"
  fi

  models_url="${base_url%/}/models"
  models_tmp="$(mktemp)"
  if curl -fsS --max-time 30 \
      -H "Authorization: Bearer $api_key" \
      "$models_url" >"$models_tmp"; then
    count="$(json_get_model_count "$models_tmp" || true)"
    pass "$profile /models reachable; model_count=$count"
  else
    fail "$profile /models request failed: $models_url"
    rm -f "$models_tmp"
    printf '\n'
    sleep "$SMOKE_DELAY_SEC"
    continue
  fi
  rm -f "$models_tmp"

  if [ "$RUN_CHAT" -eq 1 ]; then
    if [ -z "$model_name" ]; then
      fail "$profile model.name missing in config.yaml; cannot run chat smoke"
      printf '\n'
      sleep "$SMOKE_DELAY_SEC"
      continue
    fi
    pass "$profile model.name present"

    chat_tmp="$(mktemp)"
    payload_tmp="$(mktemp)"
    python3 - "$model_name" "$CHAT_MAX_TOKENS" >"$payload_tmp" <<'PY'
import json, sys
model = sys.argv[1]
max_tokens = int(sys.argv[2])
payload = {
    "model": model,
    "messages": [
        {"role": "user", "content": "Reply with exactly: local-openai-compatible-ok"}
    ],
    "temperature": 0,
    "max_tokens": max_tokens,
}
print(json.dumps(payload, ensure_ascii=False))
PY

    if curl -fsS --max-time 120 \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        -d "@$payload_tmp" \
        "${base_url%/}/chat/completions" >"$chat_tmp"; then
      text="$(json_get_chat_text "$chat_tmp" || true)"
      if [ "$text" = "local-openai-compatible-ok" ]; then
        pass "$profile chat completion exact marker"
      else
        warn "$profile chat completion returned unexpected text: ${text:0:120}"
      fi
    else
      fail "$profile chat completion request failed"
    fi
    rm -f "$chat_tmp" "$payload_tmp"
  fi

  printf '\n'
  sleep "$SMOKE_DELAY_SEC"
done

printf '== Summary ==\n'
if [ "$fail_count" -eq 0 ]; then
  printf 'PASS local provider sequential smoke completed.\n'
  exit 0
fi

printf 'FAIL local provider sequential smoke found %s issue(s).\n' "$fail_count"
exit 1
