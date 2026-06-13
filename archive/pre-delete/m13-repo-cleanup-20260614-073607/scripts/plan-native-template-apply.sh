#!/usr/bin/env bash
set -euo pipefail

# Phase 3K-FIX.14
# Read-only planner for applying repo-owned native profile templates to real Hermes profiles.
# This script MUST NOT write to ~/.hermes/profiles or secrets.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE_FILE="$ROOT/config/profile-roles.txt"
SOURCE_ROOT="$ROOT/profiles"
REAL_ROOT="${HERMES_PROFILE_ROOT:-$HOME/.hermes/profiles}"

TEMPLATE_FILES=(
  "SOUL.md"
  "profile.yaml"
  "config.yaml.template"
  ".env.template"
)

LOCAL_ONLY_FILES=(
  ".env"
  "config.yaml"
  "auth.json"
  "state.db"
  "state.db-wal"
  "state.db-shm"
  "gateway.pid"
  "gateway_state.json"
)

LOCAL_ONLY_DIRS=(
  "memories"
  "sessions"
  "logs"
  "skills"
  "cron"
  "workspace"
  "home"
  "plans"
  "backups"
  "cache"
)

missing_source=0
missing_destination=0
candidate_count=0
protected_present_count=0
protected_missing_count=0
blocked_count=0
role_count=0

printf '== OPC Hermes Native Profile Template Apply Plan ==\n'
printf 'Status: PHASE 3K-FIX.14 NATIVE PROFILE TEMPLATE GUARDED APPLY PLANNING ONLY\n'
printf 'Mode: read-only\n'
printf 'Repo template apply: DISABLED\n'
printf 'Repo root: %s\n' "$ROOT"
printf 'Role config: %s\n' "$ROLE_FILE"
printf 'Source root: %s\n' "$SOURCE_ROOT"
printf 'Real profile root: %s\n' "$REAL_ROOT"
printf 'Confirmation token required for future apply: REAL_APPLY_NATIVE_PROFILE_TEMPLATES\n'
printf 'REAL_PROFILE_WRITE=false\n'
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n'
printf 'CONFIG_WRITE=false\n'
printf '\n'

if [[ ! -f "$ROLE_FILE" ]]; then
  printf 'ERROR: role file missing: %s\n' "$ROLE_FILE"
  exit 1
fi

while IFS= read -r raw_role || [[ -n "$raw_role" ]]; do
  role="${raw_role%%#*}"
  role="$(printf '%s' "$role" | xargs)"
  [[ -z "$role" ]] && continue
  role_count=$((role_count + 1))

  src_dir="$SOURCE_ROOT/$role"
  dst_dir="$REAL_ROOT/$role"

  printf 'ROLE=%s\n' "$role"
  printf 'SOURCE_DIR=%s\n' "$src_dir"
  printf 'DESTINATION_DIR=%s\n' "$dst_dir"

  if [[ ! -d "$src_dir" ]]; then
    printf 'ROLE_STATUS=SOURCE_MISSING\n'
    missing_source=$((missing_source + 1))
    blocked_count=$((blocked_count + 1))
    printf '\n'
    continue
  fi

  if [[ ! -d "$dst_dir" ]]; then
    printf 'ROLE_STATUS=DESTINATION_MISSING\n'
    missing_destination=$((missing_destination + 1))
    blocked_count=$((blocked_count + 1))
    printf '\n'
    continue
  fi

  printf 'ROLE_STATUS=READY_FOR_PLANNED_TEMPLATE_COMPARE\n'

  for rel in "${TEMPLATE_FILES[@]}"; do
    src="$src_dir/$rel"
    dst="$dst_dir/$rel"
    if [[ ! -f "$src" ]]; then
      printf 'TEMPLATE_MISSING role=%s path=%s\n' "$role" "$rel"
      missing_source=$((missing_source + 1))
      blocked_count=$((blocked_count + 1))
      continue
    fi
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
      printf 'APPLY_STATUS role=%s path=%s status=already_in_sync\n' "$role" "$rel"
    elif [[ -f "$dst" ]]; then
      printf 'APPLY_CANDIDATE role=%s path=%s action=replace_repo_owned_template\n' "$role" "$rel"
      candidate_count=$((candidate_count + 1))
    else
      printf 'APPLY_CANDIDATE role=%s path=%s action=create_repo_owned_template\n' "$role" "$rel"
      candidate_count=$((candidate_count + 1))
    fi
  done

  for rel in "${LOCAL_ONLY_FILES[@]}"; do
    if [[ -e "$dst_dir/$rel" ]]; then
      printf 'LOCAL_ONLY_PROTECTED role=%s path=%s status=present_no_touch\n' "$role" "$rel"
      protected_present_count=$((protected_present_count + 1))
    else
      printf 'LOCAL_ONLY_PROTECTED role=%s path=%s status=absent_no_create\n' "$role" "$rel"
      protected_missing_count=$((protected_missing_count + 1))
    fi
  done

  for rel in "${LOCAL_ONLY_DIRS[@]}"; do
    if [[ -d "$dst_dir/$rel" ]]; then
      printf 'LOCAL_ONLY_PROTECTED role=%s path=%s/ status=present_no_touch\n' "$role" "$rel"
      protected_present_count=$((protected_present_count + 1))
    else
      printf 'LOCAL_ONLY_PROTECTED role=%s path=%s/ status=absent_no_create\n' "$role" "$rel"
      protected_missing_count=$((protected_missing_count + 1))
    fi
  done

  printf '\n'
done < "$ROLE_FILE"

printf '== Summary ==\n'
printf 'ROLE_COUNT=%s\n' "$role_count"
printf 'APPLY_CANDIDATE_COUNT=%s\n' "$candidate_count"
printf 'MISSING_SOURCE_COUNT=%s\n' "$missing_source"
printf 'MISSING_DESTINATION_COUNT=%s\n' "$missing_destination"
printf 'LOCAL_ONLY_PROTECTED_PRESENT_COUNT=%s\n' "$protected_present_count"
printf 'LOCAL_ONLY_PROTECTED_ABSENT_COUNT=%s\n' "$protected_missing_count"
printf 'BLOCKED_COUNT=%s\n' "$blocked_count"
printf 'REAL_PROFILE_WRITE=false\n'
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n'
printf 'CONFIG_WRITE=false\n'

if [[ "$role_count" -ne 6 ]]; then
  printf 'FAIL: expected 6 canonical roles\n'
  exit 1
fi

if [[ "$blocked_count" -ne 0 ]]; then
  printf 'FAIL: native template apply planning blocked\n'
  exit 1
fi

printf 'PASS: native profile template guarded apply planning completed in read-only mode\n'
