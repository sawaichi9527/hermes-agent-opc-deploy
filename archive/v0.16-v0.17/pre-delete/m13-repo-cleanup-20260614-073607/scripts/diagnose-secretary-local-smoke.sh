#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-/home/eye/.hermes}"
RUN_DIAG_PROMPTS="${RUN_DIAG_PROMPTS:-0}"
RUN_DOCTOR="${RUN_DOCTOR:-0}"
SHOW_TAIL="${SHOW_TAIL:-1}"
TAIL_LINES="${TAIL_LINES:-20}"
PROMPT="${PROMPT:-請只回覆 OK}"

print_header() {
  printf '\n== %s ==\n' "$1"
}

pass() {
  printf 'PASS %s\n' "$1"
}

warn() {
  printf 'WARN %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail "missing command: $cmd"
  fi
}

run_capture() {
  local label="$1"
  shift
  local stdout_file="$1"
  shift
  local stderr_file="$1"
  shift

  printf '\n-- %s --\n' "$label"
  printf 'CMD:'
  printf ' %q' "$@"
  printf '\n'

  set +e
  "$@" >"$stdout_file" 2>"$stderr_file"
  local rc=$?
  set -e

  printf 'RC=%s\n' "$rc"

  if [ -s "$stdout_file" ]; then
    printf 'STDOUT_NONEMPTY=yes\n'
    printf 'STDOUT_BYTES=%s\n' "$(wc -c <"$stdout_file")"
  else
    printf 'STDOUT_NONEMPTY=no\n'
    printf 'STDOUT_BYTES=0\n'
  fi

  if [ -s "$stderr_file" ]; then
    printf 'STDERR_NONEMPTY=yes\n'
    printf 'STDERR_BYTES=%s\n' "$(wc -c <"$stderr_file")"
    if [ "$SHOW_TAIL" = "1" ]; then
      printf 'STDERR_TAIL_START\n'
      tail -n "$TAIL_LINES" "$stderr_file"
      printf 'STDERR_TAIL_END\n'
    fi
  else
    printf 'STDERR_NONEMPTY=no\n'
    printf 'STDERR_BYTES=0\n'
  fi

  if [ "$SHOW_TAIL" = "1" ] && [ -s "$stdout_file" ]; then
    printf 'STDOUT_TAIL_START\n'
    tail -n "$TAIL_LINES" "$stdout_file"
    printf 'STDOUT_TAIL_END\n'
  fi

  return 0
}

print_header "M9.6 secretary local smoke failure diagnosis"
printf 'Repository root=%s\n' "$ROOT"
printf 'HERMES_HOME=%s\n' "$HERMES_HOME"
printf 'RUN_DIAG_PROMPTS=%s\n' "$RUN_DIAG_PROMPTS"
printf 'RUN_DOCTOR=%s\n' "$RUN_DOCTOR"
printf 'SHOW_TAIL=%s\n' "$SHOW_TAIL"
printf 'TAIL_LINES=%s\n' "$TAIL_LINES"
printf 'Boundary=diagnostic only; no gateway start/restart, no Lark cutover, no cleanup, no profile apply.\n'

need_cmd hermes
need_cmd bash
need_cmd tail
need_cmd wc

profile_stdout="$(mktemp)"
profile_stderr="$(mktemp)"
align_stdout="$(mktemp)"
align_stderr="$(mktemp)"
z_stdout="$(mktemp)"
z_stderr="$(mktemp)"
dev_stdout="$(mktemp)"
dev_stderr="$(mktemp)"
doctor_stdout="$(mktemp)"
doctor_stderr="$(mktemp)"
trap 'rm -f "$profile_stdout" "$profile_stderr" "$align_stdout" "$align_stderr" "$z_stdout" "$z_stderr" "$dev_stdout" "$dev_stderr" "$doctor_stdout" "$doctor_stderr"' EXIT

print_header "Required preflight"
run_capture "hermes profile show secretary" "$profile_stdout" "$profile_stderr" hermes profile show secretary

if grep -q '^Profile:[[:space:]]*secretary' "$profile_stdout"; then
  pass "profile name secretary"
else
  warn "profile show did not include expected profile marker"
fi

if grep -q '^Gateway:[[:space:]]*stopped' "$profile_stdout"; then
  pass "gateway reported stopped"
else
  warn "gateway not reported as stopped"
fi

run_capture "secretary SOUL alignment dry-run" "$align_stdout" "$align_stderr" env PROFILE=secretary bash "$ROOT/scripts/dry-run-profile-deployment.sh"

if grep -q 'Comparison: MATCH' "$align_stdout"; then
  pass "secretary runtime SOUL matches repository template"
else
  warn "secretary runtime SOUL did not report MATCH"
fi

if [ "$RUN_DIAG_PROMPTS" != "1" ]; then
  print_header "Prompt diagnostics skipped"
  printf 'No local secretary prompt was sent. Re-run with RUN_DIAG_PROMPTS=1 to diagnose -z behavior.\n'
else
  print_header "Prompt diagnostics"
  printf 'Sending local diagnostic prompts. Output is captured only in temp files and not persisted to repo.\n'
  run_capture "hermes -p secretary -z prompt" "$z_stdout" "$z_stderr" hermes -p secretary -z "$PROMPT"
  run_capture "hermes -p secretary -z prompt --dev" "$dev_stdout" "$dev_stderr" hermes -p secretary -z "$PROMPT" --dev
fi

if [ "$RUN_DOCTOR" = "1" ]; then
  print_header "Hermes doctor diagnostic"
  run_capture "hermes doctor" "$doctor_stdout" "$doctor_stderr" hermes doctor
else
  print_header "Doctor skipped"
  printf 'No hermes doctor run was executed. Re-run with RUN_DOCTOR=1 to include doctor summary.\n'
fi

print_header "Post-diagnosis gateway check"
run_capture "post-diagnosis hermes profile show secretary" "$profile_stdout" "$profile_stderr" hermes profile show secretary

if grep -q '^Gateway:[[:space:]]*stopped' "$profile_stdout"; then
  pass "gateway remained stopped after diagnosis"
else
  warn "gateway not reported as stopped after diagnosis"
fi

print_header "Final note"
printf 'This diagnostic script does not start/restart gateway, cut over Lark, apply profiles, or clean runtime state.\n'
printf 'Use docs/verification-m9-secretary-smoke-partial.md to record the PARTIAL lock.\n'
