#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE_CONFIG="$ROOT/config/profile-roles.txt"
SOURCE_ROOT="${1:-$ROOT/profiles}"

REQUIRED_FILES=(
  "README.md"
  "SOUL.md"
  "profile.yaml"
  "config.yaml.template"
  ".env.template"
)

missing=0
role_count=0

printf '== OPC Hermes Native Profile Source Template Check ==\n\n'
printf 'Status: PHASE 3K-FIX.13 NATIVE PROFILE TEMPLATE SOURCE ALIGNMENT CHECK\n'
printf 'Mode: read-only\n'
printf 'Repo root: %s\n' "$ROOT"
printf 'Role config: %s\n' "$ROLE_CONFIG"
printf 'Source root: %s\n' "$SOURCE_ROOT"
printf 'REAL_PROFILE_WRITE=false\n'
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n\n'

if [[ ! -f "$ROLE_CONFIG" ]]; then
  printf 'ERROR: role config missing: %s\n' "$ROLE_CONFIG"
  exit 1
fi

mapfile -t ROLES < <(grep -Ev '^\s*(#|$)' "$ROLE_CONFIG")
role_count="${#ROLES[@]}"
printf 'ROLE_COUNT=%s\n\n' "$role_count"

for role in "${ROLES[@]}"; do
  role_dir="$SOURCE_ROOT/$role"
  printf '[%s]\n' "$role"
  if [[ ! -d "$role_dir" ]]; then
    printf '  status: SOURCE_ROLE_DIR_MISSING\n'
    missing=$((missing + ${#REQUIRED_FILES[@]}))
    continue
  fi
  role_missing=0
  for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$role_dir/$file" ]]; then
      printf '  %s: found\n' "$file"
    else
      printf '  %s: missing\n' "$file"
      missing=$((missing + 1))
      role_missing=$((role_missing + 1))
    fi
  done
  if [[ "$role_missing" -eq 0 ]]; then
    printf '  status: SOURCE_TEMPLATE_COMPLETE\n'
  else
    printf '  status: SOURCE_TEMPLATE_PARTIAL missing=%s\n' "$role_missing"
  fi
  printf '\n'
done

printf 'MISSING_SOURCE_TEMPLATE_COUNT=%s\n' "$missing"
printf 'REAL_PROFILE_WRITE=false\n'
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n'

if [[ "$missing" -eq 0 ]]; then
  printf 'PASS: native profile source templates complete\n'
else
  printf 'PARTIAL: native profile source templates missing files\n'
  exit 2
fi
