#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_SOURCE_ROOT="$REPO_ROOT/profiles"
ROLE_CONFIG="$REPO_ROOT/config/profile-roles.txt"

DRIFT_ROLES=(default developer reviewer operator trial)

candidate_count=0
blocked_count=0
missing_count=0
canonical_count=0

is_canonical_role() {
  local role="$1"
  if [[ ! -f "$ROLE_CONFIG" ]]; then
    return 1
  fi
  grep -Ev '^[[:space:]]*($|#)' "$ROLE_CONFIG" | grep -Fxq "$role"
}

repo_role_file_count() {
  local dir="$1"
  find "$dir" -maxdepth 1 -type f | wc -l | tr -d ' '
}

repo_role_dir_count() {
  local dir="$1"
  find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '
}

echo "== OPC Hermes Repo Drift Source Cleanup Plan =="
echo
echo "Status: PHASE 3K-FIX.6 REPO DRIFT SOURCE CLEANUP PLANNING ONLY"
echo "Mode: read-only"
echo "Repo cleanup: DISABLED"
echo "Repo root: $REPO_ROOT"
echo "Profile source root: $PROFILE_SOURCE_ROOT"
echo "Role config: $ROLE_CONFIG"
echo "REPO_PROFILE_WRITE=false"
echo "REPO_PROFILE_DELETE=false"
echo "REAL_PROFILE_WRITE=false"
echo "REAL_PROFILE_DELETE=false"
echo
echo "== Safety Boundary =="
echo "- This script does not delete repo files."
echo "- This script does not touch ~/.hermes/profiles."
echo "- It only classifies repo-local drift source directories."
echo "- Canonical roles from config/profile-roles.txt are never cleanup candidates."
echo "- Any repo deletion must be performed in a later reviewed git change."
echo
echo "== Canonical Role Set =="
if [[ -f "$ROLE_CONFIG" ]]; then
  while IFS= read -r role; do
    [[ -z "$role" || "$role" =~ ^[[:space:]]*# ]] && continue
    canonical_count=$((canonical_count + 1))
    echo "CANONICAL_ROLE=$role"
  done < "$ROLE_CONFIG"
else
  echo "CANONICAL_ROLE_CONFIG_STATUS=MISSING"
fi
echo "CANONICAL_ROLE_COUNT=$canonical_count"
echo
echo "== Repo Drift Role Set =="
for role in "${DRIFT_ROLES[@]}"; do
  echo "DRIFT_ROLE=$role"
done
echo
echo "== Repo Drift Source Cleanup Plan =="

for role in "${DRIFT_ROLES[@]}"; do
  dir="$PROFILE_SOURCE_ROOT/$role"
  echo
  echo "[$role]"
  echo "  path: $dir"

  if is_canonical_role "$role"; then
    echo "  status: BLOCKED_CANONICAL_ROLE"
    echo "  cleanup_action: none"
    blocked_count=$((blocked_count + 1))
    continue
  fi

  if [[ ! -e "$dir" ]]; then
    echo "  status: MISSING"
    echo "  cleanup_action: none"
    missing_count=$((missing_count + 1))
    continue
  fi

  if [[ ! -d "$dir" ]]; then
    echo "  status: BLOCKED_NOT_DIRECTORY"
    echo "  cleanup_action: none"
    blocked_count=$((blocked_count + 1))
    continue
  fi

  file_count="$(repo_role_file_count "$dir")"
  dir_count="$(repo_role_dir_count "$dir")"
  echo "  repo_file_count: $file_count"
  echo "  repo_dir_count: $dir_count"
  echo "  status: REPO_CLEANUP_CANDIDATE"
  echo "  cleanup_action: planned repo deletion in later git-reviewed phase"
  candidate_count=$((candidate_count + 1))
done

echo
echo "== Phase 3K-FIX.6 Result =="
echo "REPO_CLEANUP_CANDIDATE_COUNT=$candidate_count"
echo "REPO_BLOCKED_COUNT=$blocked_count"
echo "REPO_MISSING_COUNT=$missing_count"
echo "CANONICAL_ROLE_COUNT=$canonical_count"
echo "REPO_PROFILE_WRITE=false"
echo "REPO_PROFILE_DELETE=false"
echo "REAL_PROFILE_WRITE=false"
echo "REAL_PROFILE_DELETE=false"

if [[ "$blocked_count" -eq 0 ]]; then
  echo "PASS: repo drift source cleanup planning completed in read-only mode"
else
  echo "BLOCKED: repo drift source cleanup planning found blocked entries"
fi
