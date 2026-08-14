#!/usr/bin/env bash
set -euo pipefail

# Phase 3K-FIX.3 read-only planner for drift profile cleanup.
# This script does not remove or modify real Hermes profile files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_PROFILE_ROOT="${HERMES_PROFILE_ROOT:-$HOME/.hermes/profiles}"
EXPECTED_SOURCE_ROOT="$REPO_ROOT/profiles"

DRIFT_ROLES=(default developer reviewer operator trial)

candidate_count=0
blocked_count=0
missing_count=0

has_marker_field() {
  local marker="$1"
  local expected="$2"
  grep -Fxq "$expected" "$marker"
}

print_header() {
  cat <<EOF
== OPC Hermes Drift Profile Cleanup Planner ==

Status: PHASE 3K-FIX.3 DRIFT CLEANUP PLANNING ONLY
Mode: read-only
Real cleanup: DISABLED
Repo root: $REPO_ROOT
Real profile root: $REAL_PROFILE_ROOT
Expected source root: $EXPECTED_SOURCE_ROOT
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false

== Safety Boundary ==
- This script only inspects known drift profile directories.
- It never deletes files.
- It only marks a directory as cleanup-candidate when ownership markers match.
- Real cleanup must require a separate guarded command and confirmation token.
- Hermes Agent does not depend on this script at runtime.
EOF
}

inspect_role() {
  local role="$1"
  local dir="$REAL_PROFILE_ROOT/$role"
  local marker="$dir/.opc-managed-profile"
  local status=""

  echo
  echo "[$role]"
  echo "  path: $dir"

  if [[ ! -e "$dir" ]]; then
    echo "  status: MISSING"
    echo "  cleanup_action: none"
    missing_count=$((missing_count + 1))
    return 0
  fi

  if [[ ! -d "$dir" ]]; then
    echo "  status: BLOCKED_NOT_DIRECTORY"
    echo "  cleanup_action: none"
    blocked_count=$((blocked_count + 1))
    return 0
  fi

  if [[ ! -f "$marker" ]]; then
    echo "  status: BLOCKED_NO_MARKER"
    echo "  marker: missing"
    echo "  cleanup_action: none"
    blocked_count=$((blocked_count + 1))
    return 0
  fi

  echo "  marker: $marker"

  if ! has_marker_field "$marker" "managed_by=hermes-agent-opc-deploy"; then
    echo "  status: BLOCKED_MARKER_OWNER_MISMATCH"
    echo "  cleanup_action: none"
    blocked_count=$((blocked_count + 1))
    return 0
  fi

  if ! has_marker_field "$marker" "source_root=$EXPECTED_SOURCE_ROOT"; then
    echo "  status: BLOCKED_SOURCE_ROOT_MISMATCH"
    echo "  cleanup_action: none"
    blocked_count=$((blocked_count + 1))
    return 0
  fi

  if ! has_marker_field "$marker" "role=$role"; then
    echo "  status: BLOCKED_ROLE_MISMATCH"
    echo "  cleanup_action: none"
    blocked_count=$((blocked_count + 1))
    return 0
  fi

  echo "  status: CLEANUP_CANDIDATE"
  echo "  cleanup_action: would remove $dir in a future guarded cleanup phase"
  candidate_count=$((candidate_count + 1))
}

print_header

echo
 echo "== Drift Role Set =="
for role in "${DRIFT_ROLES[@]}"; do
  echo "DRIFT_ROLE=$role"
done

echo
 echo "== Real Drift Profile Inspection =="
for role in "${DRIFT_ROLES[@]}"; do
  inspect_role "$role"
done

echo
 echo "== Phase 3K-FIX.3 Result =="
echo "CLEANUP_CANDIDATE_COUNT=$candidate_count"
echo "BLOCKED_COUNT=$blocked_count"
echo "MISSING_COUNT=$missing_count"
echo "REAL_PROFILE_WRITE=false"
echo "REAL_PROFILE_DELETE=false"
echo "PASS: drift cleanup planning completed in read-only mode"
