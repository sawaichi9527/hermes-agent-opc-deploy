#!/usr/bin/env bash
set -euo pipefail

# Phase 3K-FIX.4 guarded cleanup for OPC-managed drift profiles.
# Default mode is dry-run. Real delete requires:
#   --apply --confirm REAL_CLEANUP_DRIFT_PROFILES

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_PROFILE_ROOT="${HERMES_PROFILE_ROOT:-$HOME/.hermes/profiles}"
EXPECTED_SOURCE_ROOT="$REPO_ROOT/profiles"
CONFIRM_TOKEN="REAL_CLEANUP_DRIFT_PROFILES"

DRIFT_ROLES=(default developer reviewer operator trial)

APPLY=false
CONFIRM=""

candidate_count=0
blocked_count=0
missing_count=0
deleted_count=0

usage() {
  cat <<EOF
Usage: $0 [--apply --confirm REAL_CLEANUP_DRIFT_PROFILES]

Default mode is dry-run and does not delete real Hermes profile files.
Real cleanup requires both --apply and --confirm REAL_CLEANUP_DRIFT_PROFILES.

Environment:
  HERMES_PROFILE_ROOT   Override real profile root. Default: \$HOME/.hermes/profiles
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=true
      shift
      ;;
    --confirm)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --confirm requires a token" >&2
        echo "REAL_PROFILE_WRITE=false"
        echo "REAL_PROFILE_DELETE=false"
        exit 2
      fi
      CONFIRM="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      echo "REAL_PROFILE_WRITE=false"
      echo "REAL_PROFILE_DELETE=false"
      exit 2
      ;;
  esac
done

if [[ "$APPLY" == "true" && "$CONFIRM" != "$CONFIRM_TOKEN" ]]; then
  echo "ERROR: guarded cleanup requires: --confirm $CONFIRM_TOKEN" >&2
  echo "REAL_PROFILE_WRITE=false"
  echo "REAL_PROFILE_DELETE=false"
  exit 2
fi

if [[ "$APPLY" != "true" && -n "$CONFIRM" ]]; then
  echo "ERROR: --confirm is only valid with --apply" >&2
  echo "REAL_PROFILE_WRITE=false"
  echo "REAL_PROFILE_DELETE=false"
  exit 2
fi

has_marker_field() {
  local marker="$1"
  local expected="$2"
  grep -Fxq "$expected" "$marker"
}

print_header() {
  local mode="dry-run"
  local cleanup="DISABLED"
  if [[ "$APPLY" == "true" ]]; then
    mode="apply"
    cleanup="GUARDED_CLEANUP_REQUESTED"
  fi

  cat <<EOF
== OPC Hermes Drift Profile Cleanup ==

Status: PHASE 3K-FIX.4 GUARDED DRIFT CLEANUP
Mode: $mode
Real cleanup: $cleanup
Repo root: $REPO_ROOT
Real profile root: $REAL_PROFILE_ROOT
Expected source root: $EXPECTED_SOURCE_ROOT
Confirmation token required for apply: $CONFIRM_TOKEN
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=$([[ "$APPLY" == "true" ]] && echo pending || echo false)

== Safety Boundary ==
- Default mode is dry-run and does not delete real Hermes profile files.
- Guarded cleanup requires --apply --confirm REAL_CLEANUP_DRIFT_PROFILES.
- Cleanup only considers known drift roles: default, developer, reviewer, operator, trial.
- A role directory is deleted only when .opc-managed-profile ownership fields match.
- Canonical Hermes roles from config/profile-roles.txt are never targeted by this cleanup.
- Hermes Agent does not depend on this script at runtime.
EOF
}

classify_role() {
  local role="$1"
  local dir="$REAL_PROFILE_ROOT/$role"
  local marker="$dir/.opc-managed-profile"

  if [[ ! -e "$dir" ]]; then
    echo "MISSING"
    return 0
  fi

  if [[ ! -d "$dir" ]]; then
    echo "BLOCKED_NOT_DIRECTORY"
    return 0
  fi

  if [[ ! -f "$marker" ]]; then
    echo "BLOCKED_NO_MARKER"
    return 0
  fi

  if ! has_marker_field "$marker" "managed_by=hermes-agent-opc-deploy"; then
    echo "BLOCKED_MARKER_OWNER_MISMATCH"
    return 0
  fi

  if ! has_marker_field "$marker" "source_root=$EXPECTED_SOURCE_ROOT"; then
    echo "BLOCKED_SOURCE_ROOT_MISMATCH"
    return 0
  fi

  if ! has_marker_field "$marker" "role=$role"; then
    echo "BLOCKED_ROLE_MISMATCH"
    return 0
  fi

  echo "CLEANUP_CANDIDATE"
}

process_role() {
  local role="$1"
  local dir="$REAL_PROFILE_ROOT/$role"
  local marker="$dir/.opc-managed-profile"
  local status

  status="$(classify_role "$role")"

  echo
  echo "[$role]"
  echo "  path: $dir"
  echo "  status: $status"

  case "$status" in
    CLEANUP_CANDIDATE)
      echo "  marker: $marker"
      candidate_count=$((candidate_count + 1))
      if [[ "$APPLY" == "true" ]]; then
        rm -rf -- "$dir"
        deleted_count=$((deleted_count + 1))
        echo "  cleanup_action: deleted"
        echo "DELETED_ROLE=$role"
      else
        echo "  cleanup_action: would delete"
      fi
      ;;
    MISSING)
      missing_count=$((missing_count + 1))
      echo "  cleanup_action: none"
      ;;
    *)
      blocked_count=$((blocked_count + 1))
      echo "  cleanup_action: none"
      ;;
  esac
}

print_header

echo
echo "== Drift Role Set =="
for role in "${DRIFT_ROLES[@]}"; do
  echo "DRIFT_ROLE=$role"
done

echo
echo "== Guarded Drift Profile Cleanup Plan =="
for role in "${DRIFT_ROLES[@]}"; do
  process_role "$role"
done

echo
echo "== Phase 3K-FIX.4 Result =="
echo "CLEANUP_CANDIDATE_COUNT=$candidate_count"
echo "BLOCKED_COUNT=$blocked_count"
echo "MISSING_COUNT=$missing_count"
echo "DELETED_COUNT=$deleted_count"
echo "REAL_PROFILE_WRITE=false"
if [[ "$APPLY" == "true" ]]; then
  echo "REAL_PROFILE_DELETE=true"
  echo "PASS: guarded drift cleanup completed"
else
  echo "REAL_PROFILE_DELETE=false"
  echo "PASS: guarded drift cleanup dry-run completed"
fi
