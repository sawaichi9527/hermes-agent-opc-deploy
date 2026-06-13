#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/.hermes}"

printf 'Hermes root: %s\n' "$ROOT"

check_path() {
  local path="$1"
  if [ -e "$path" ]; then
    printf 'PASS %s\n' "$path"
  else
    printf 'MISS %s\n' "$path"
  fi
}

check_path "$ROOT"
check_path "$ROOT/SOUL.md"
check_path "$ROOT/profiles"

for profile in coordinator researcher writer builder runes-holder; do
  check_path "$ROOT/profiles/$profile"
  check_path "$ROOT/profiles/$profile/SOUL.md"
done
