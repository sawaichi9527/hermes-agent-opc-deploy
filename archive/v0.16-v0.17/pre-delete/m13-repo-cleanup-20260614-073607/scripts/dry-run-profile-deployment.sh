#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-/home/eye/.hermes}"
PROFILES_DIR="$HERMES_HOME/profiles"
SHOW_DIFF="${SHOW_DIFF:-0}"
PROFILE_FILTER="${PROFILE:-}"

profiles=(
  "secretary"
  "coordinator"
  "researcher"
  "writer"
  "builder"
  "runes-holder"
)

print_header() {
  printf '\n== %s ==\n' "$1"
}

file_meta() {
  local path="$1"
  if [ -f "$path" ]; then
    if stat --version >/dev/null 2>&1; then
      stat -c 'META size=%s mtime=%y path=%n' "$path"
    else
      ls -l "$path"
    fi
  else
    printf 'MISSING %s\n' "$path"
  fi
}

should_include_profile() {
  local profile="$1"
  if [ -z "$PROFILE_FILTER" ]; then
    return 0
  fi
  [ "$PROFILE_FILTER" = "$profile" ]
}

print_header "M7 read-only profile deployment dry-run"
printf 'Repository root=%s\n' "$ROOT"
printf 'HERMES_HOME=%s\n' "$HERMES_HOME"
printf 'SHOW_DIFF=%s\n' "$SHOW_DIFF"
if [ -n "$PROFILE_FILTER" ]; then
  printf 'PROFILE=%s\n' "$PROFILE_FILTER"
fi
printf 'Mode=read-only comparison; no files are copied, overwritten, deleted, or modified.\n'

for profile in "${profiles[@]}"; do
  if ! should_include_profile "$profile"; then
    continue
  fi

  template="$ROOT/profiles/$profile/SOUL.md.template"
  runtime="$PROFILES_DIR/$profile/SOUL.md"

  print_header "Profile: $profile"
  printf 'Repository template: %s\n' "$template"
  file_meta "$template"
  printf 'Runtime SOUL.md: %s\n' "$runtime"
  file_meta "$runtime"

  if [ ! -f "$template" ] || [ ! -f "$runtime" ]; then
    printf 'Decision hint: defer / missing file\n'
    continue
  fi

  if cmp -s "$template" "$runtime"; then
    printf 'Comparison: MATCH\n'
    printf 'Decision hint: skip / already aligned\n'
  else
    printf 'Comparison: DIFFERENT\n'
    printf 'Decision hint: review diff, backup runtime profile, then choose apply-now / partial-manual-merge / defer / skip\n'
    if [ "$SHOW_DIFF" = "1" ]; then
      printf '\n-- Unified diff: repo template vs runtime SOUL.md --\n'
      diff -u --label "repo:$template" --label "runtime:$runtime" "$template" "$runtime" || true
    else
      printf 'Diff hidden by default. Re-run with SHOW_DIFF=1 to display unified diff.\n'
    fi
  fi

done

print_header "Final note"
printf 'This script is dry-run only. It does not create backups and does not apply profile changes.\n'
printf 'Before any future apply: create backup outside git, review diff, approve exact profile target, and keep rollback path.\n'
printf 'Recommended docs: docs/pre-production-profile-deployment.md and docs/profile-deployment-dry-run.md\n'
