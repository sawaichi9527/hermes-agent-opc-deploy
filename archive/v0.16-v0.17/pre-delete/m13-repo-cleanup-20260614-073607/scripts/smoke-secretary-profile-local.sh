#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-/home/eye/.hermes}"
RUN_SECRETARY_SMOKE="${RUN_SECRETARY_SMOKE:-0}"
SHOW_OUTPUT="${SHOW_OUTPUT:-0}"
EXPECT_MARKER="${EXPECT_MARKER:-0}"
MARKER="${MARKER:-M9-secretary-smoke-ok}"
PROMPT="${PROMPT:-請用繁體中文只回覆一行：M9-secretary-smoke-ok。不要修改檔案，不要啟動 gateway，不要建立記憶。}"

print_header() {
  printf '\n== %s ==\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS %s\n' "$1"
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail "missing command: $cmd"
  fi
}

print_header "M9 secretary-only local behavior smoke"
printf 'Repository root=%s\n' "$ROOT"
printf 'HERMES_HOME=%s\n' "$HERMES_HOME"
printf 'RUN_SECRETARY_SMOKE=%s\n' "$RUN_SECRETARY_SMOKE"
printf 'EXPECT_MARKER=%s\n' "$EXPECT_MARKER"
printf 'SHOW_OUTPUT=%s\n' "$SHOW_OUTPUT"
printf 'Boundary=no gateway start/restart, no Lark cutover, no other profile apply, no cleanup.\n'

need_cmd hermes
need_cmd bash
need_cmd python3

print_header "Profile preflight"
profile_tmp="$(mktemp)"
align_tmp="$(mktemp)"
output_tmp="$(mktemp)"
trap 'rm -f "$profile_tmp" "$align_tmp" "$output_tmp"' EXIT

if hermes profile show secretary >"$profile_tmp"; then
  pass "hermes profile show secretary"
else
  cat "$profile_tmp" >&2 || true
  fail "hermes profile show secretary failed"
fi

if grep -q '^Profile:[[:space:]]*secretary' "$profile_tmp"; then
  pass "profile name secretary"
else
  cat "$profile_tmp"
  fail "profile show did not identify secretary"
fi

if grep -q '^SOUL.md:[[:space:]]*exists' "$profile_tmp"; then
  pass "secretary SOUL.md exists"
else
  cat "$profile_tmp"
  fail "secretary SOUL.md missing"
fi

if grep -q '^\.env:[[:space:]]*exists' "$profile_tmp"; then
  pass "secretary .env exists"
else
  cat "$profile_tmp"
  fail "secretary .env missing"
fi

if grep -q '^Gateway:[[:space:]]*stopped' "$profile_tmp"; then
  pass "secretary gateway remained stopped before smoke"
else
  printf 'WARN secretary gateway is not reported as stopped:\n'
  grep '^Gateway:' "$profile_tmp" || true
fi

print_header "SOUL alignment preflight"
if PROFILE=secretary bash "$ROOT/scripts/dry-run-profile-deployment.sh" >"$align_tmp"; then
  pass "secretary SOUL alignment dry-run command"
else
  cat "$align_tmp" >&2 || true
  fail "secretary SOUL alignment dry-run failed"
fi

if grep -q 'Comparison: MATCH' "$align_tmp"; then
  pass "secretary runtime SOUL matches repository template"
else
  cat "$align_tmp"
  fail "secretary runtime SOUL is not aligned with repository template"
fi

if [ "$RUN_SECRETARY_SMOKE" != "1" ]; then
  print_header "Dry-run only"
  printf 'No local secretary prompt was sent.\n'
  printf 'To run the real secretary-only prompt smoke:\n'
  printf 'RUN_SECRETARY_SMOKE=1 bash scripts/smoke-secretary-profile-local.sh\n'
  exit 0
fi

print_header "Local secretary prompt smoke"
printf 'Sending exactly one local secretary prompt. Output is validated in a temp file and not persisted to repo.\n'

if hermes -p secretary -z "$PROMPT" >"$output_tmp"; then
  pass "hermes -p secretary -z prompt returned successfully"
else
  cat "$output_tmp" >&2 || true
  fail "hermes -p secretary -z prompt failed"
fi

trimmed="$(python3 - "$output_tmp" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").strip()
print(text)
PY
)"

if [ -z "$trimmed" ]; then
  fail "secretary prompt returned empty output"
fi
pass "secretary prompt returned non-empty output"

if [ "$EXPECT_MARKER" = "1" ]; then
  if printf '%s\n' "$trimmed" | grep -q "$MARKER"; then
    pass "secretary output contains marker $MARKER"
  else
    printf 'Output did not contain expected marker: %s\n' "$MARKER" >&2
    if [ "$SHOW_OUTPUT" = "1" ]; then
      printf '\n== Secretary output ==\n%s\n' "$trimmed"
    fi
    fail "marker validation failed"
  fi
fi

if [ "$SHOW_OUTPUT" = "1" ]; then
  printf '\n== Secretary output ==\n%s\n' "$trimmed"
fi

print_header "Post-smoke gateway check"
if hermes profile show secretary >"$profile_tmp"; then
  pass "post-smoke hermes profile show secretary"
else
  cat "$profile_tmp" >&2 || true
  fail "post-smoke profile show failed"
fi

if grep -q '^Gateway:[[:space:]]*stopped' "$profile_tmp"; then
  pass "secretary gateway remained stopped after smoke"
else
  printf 'WARN secretary gateway is not reported as stopped after smoke:\n'
  grep '^Gateway:' "$profile_tmp" || true
fi

print_header "Final result"
printf 'PASS secretary-only local behavior smoke completed.\n'
printf 'No gateway start/restart or Lark cutover was performed by this script.\n'
