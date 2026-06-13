#!/usr/bin/env bash
set -euo pipefail

# Phase 3K-FIX.15
# Guarded apply script for syncing repo-owned native profile templates to real Hermes profiles.
# Default mode is dry-run. Real writes require:
#   --apply --confirm REAL_APPLY_NATIVE_PROFILE_TEMPLATES
# This script MUST NOT write real .env, real config.yaml, auth files, memories, sessions, logs, or runtime state.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE_FILE="$ROOT/config/profile-roles.txt"
SOURCE_ROOT="$ROOT/profiles"
REAL_ROOT="${HERMES_PROFILE_ROOT:-$HOME/.hermes/profiles}"
BACKUP_ROOT="${HERMES_PROFILE_BACKUP_ROOT:-$HOME/.hermes/backups/opc-native-templates}"
CONFIRM_TOKEN="REAL_APPLY_NATIVE_PROFILE_TEMPLATES"
MODE="dry-run"
CONFIRM=""
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$STAMP"

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

usage() {
  cat <<'EOF'
Usage:
  bash scripts/apply-native-profile-templates.sh [--dry-run]
  bash scripts/apply-native-profile-templates.sh --apply --confirm REAL_APPLY_NATIVE_PROFILE_TEMPLATES

Behavior:
  - Dry-run by default.
  - Applies only repo-owned native template files:
      SOUL.md
      profile.yaml
      config.yaml.template
      .env.template
  - Never writes or creates real .env.
  - Never writes or creates real config.yaml.
  - Never touches memories, sessions, logs, state DB, gateway state, auth files, skills, cron, workspace, or home.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --confirm)
      CONFIRM="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'ERROR: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

missing_source=0
missing_destination=0
candidate_count=0
applied_count=0
already_sync_count=0
protected_present_count=0
protected_missing_count=0
blocked_count=0
role_count=0

real_write=false
if [[ "$MODE" == "apply" ]]; then
  if [[ "$CONFIRM" != "$CONFIRM_TOKEN" ]]; then
    printf 'ERROR: apply mode requires --confirm %s\n' "$CONFIRM_TOKEN" >&2
    exit 2
  fi
  real_write=true
fi

printf '== OPC Hermes Native Profile Template Guarded Apply ==\n'
printf 'Status: PHASE 3K-FIX.15 NATIVE PROFILE TEMPLATE GUARDED APPLY\n'
printf 'Mode: %s\n' "$MODE"
if [[ "$real_write" == true ]]; then
  printf 'Real template apply: GUARDED_APPLY_REQUESTED\n'
else
  printf 'Real template apply: DISABLED\n'
fi
printf 'Repo root: %s\n' "$ROOT"
printf 'Role config: %s\n' "$ROLE_FILE"
printf 'Source root: %s\n' "$SOURCE_ROOT"
printf 'Real profile root: %s\n' "$REAL_ROOT"
printf 'Backup root: %s\n' "$BACKUP_ROOT"
printf 'Planned backup dir: %s\n' "$BACKUP_DIR"
printf 'Confirmation token required for apply: %s\n' "$CONFIRM_TOKEN"
printf 'REAL_PROFILE_WRITE=%s\n' "$real_write"
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n'
printf 'CONFIG_WRITE=false\n'
printf '\n'

if [[ ! -f "$ROLE_FILE" ]]; then
  printf 'ERROR: role file missing: %s\n' "$ROLE_FILE"
  exit 1
fi

if [[ "$real_write" == true ]]; then
  mkdir -p "$BACKUP_DIR"
  printf 'BACKUP_PATH=%s\n' "$BACKUP_DIR"
  printf 'BACKUP_STATUS=created\n'
  printf '\n'
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

  printf 'ROLE_STATUS=READY_FOR_TEMPLATE_APPLY\n'

  for rel in "${TEMPLATE_FILES[@]}"; do
    src="$src_dir/$rel"
    dst="$dst_dir/$rel"
    safe_rel="$(printf '%s' "$rel" | tr '/' '_' | tr '.' '_')"

    if [[ ! -f "$src" ]]; then
      printf 'TEMPLATE_MISSING role=%s path=%s\n' "$role" "$rel"
      missing_source=$((missing_source + 1))
      blocked_count=$((blocked_count + 1))
      continue
    fi

    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
      printf 'APPLY_STATUS role=%s path=%s status=already_in_sync\n' "$role" "$rel"
      already_sync_count=$((already_sync_count + 1))
      continue
    fi

    if [[ -f "$dst" ]]; then
      printf 'APPLY_CANDIDATE role=%s path=%s action=replace_repo_owned_template\n' "$role" "$rel"
    else
      printf 'APPLY_CANDIDATE role=%s path=%s action=create_repo_owned_template\n' "$role" "$rel"
    fi
    candidate_count=$((candidate_count + 1))

    if [[ "$real_write" == true ]]; then
      mkdir -p "$BACKUP_DIR/$role"
      if [[ -f "$dst" ]]; then
        cp -a "$dst" "$BACKUP_DIR/$role/${safe_rel}.bak"
        printf 'BACKED_UP_TEMPLATE role=%s path=%s backup=%s\n' "$role" "$rel" "$BACKUP_DIR/$role/${safe_rel}.bak"
      else
        printf 'NO_PREVIOUS_TEMPLATE role=%s path=%s\n' "$role" "$rel"
      fi
      install -m 0644 "$src" "$dst"
      printf 'APPLIED_TEMPLATE role=%s path=%s\n' "$role" "$rel"
      applied_count=$((applied_count + 1))
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
printf 'APPLIED_TEMPLATE_COUNT=%s\n' "$applied_count"
printf 'ALREADY_IN_SYNC_COUNT=%s\n' "$already_sync_count"
printf 'MISSING_SOURCE_COUNT=%s\n' "$missing_source"
printf 'MISSING_DESTINATION_COUNT=%s\n' "$missing_destination"
printf 'LOCAL_ONLY_PROTECTED_PRESENT_COUNT=%s\n' "$protected_present_count"
printf 'LOCAL_ONLY_PROTECTED_ABSENT_COUNT=%s\n' "$protected_missing_count"
printf 'BLOCKED_COUNT=%s\n' "$blocked_count"
printf 'REAL_PROFILE_WRITE=%s\n' "$real_write"
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n'
printf 'CONFIG_WRITE=false\n'

if [[ "$role_count" -ne 6 ]]; then
  printf 'FAIL: expected 6 canonical roles\n'
  exit 1
fi

if [[ "$blocked_count" -ne 0 ]]; then
  printf 'FAIL: native template guarded apply blocked\n'
  exit 1
fi

if [[ "$real_write" == true ]]; then
  printf 'PASS: native profile template guarded apply completed\n'
else
  printf 'PASS: native profile template guarded apply dry-run completed\n'
fi
