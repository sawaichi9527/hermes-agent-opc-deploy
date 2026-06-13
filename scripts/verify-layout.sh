#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/.hermes}"
PROFILES=(coordinator researcher writer builder runes-holder)
missing_optional=0

printf 'Hermes root: %s\n' "$ROOT"
printf '\n'

check_required() {
  local path="$1"
  if [ -e "$path" ]; then
    printf 'PASS required %s\n' "$path"
  else
    printf 'FAIL required %s\n' "$path"
    return 1
  fi
}

check_optional() {
  local path="$1"
  if [ -e "$path" ]; then
    printf 'PASS optional %s\n' "$path"
  else
    printf 'MISS optional %s\n' "$path"
    missing_optional=1
  fi
}

check_required "$ROOT"
check_required "$ROOT/SOUL.md"

printf '\n== Official profile layout, optional before OPC deployment ==\n'
check_optional "$ROOT/profiles"

for profile in "${PROFILES[@]}"; do
  check_optional "$ROOT/profiles/$profile"
  check_optional "$ROOT/profiles/$profile/SOUL.md"
done

printf '\n'
if [ "$missing_optional" -eq 0 ]; then
  printf 'Summary: PASS - base Hermes root exists and OPC profile layout is present.\n'
else
  printf 'Summary: BASE PASS - Hermes native root exists; OPC profiles are not fully deployed yet.\n'
  printf 'This is expected before coordinator/researcher/writer/builder/runes-holder profiles are created.\n'
fi
