#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_PROFILE_ROOT="${HOME}/.hermes/profiles"
MANAGED_MARKER=".opc-managed-profile"
SOURCE_ROOT=""

ROLES=(
  default
  developer
  reviewer
  operator
  trial
)

CANDIDATE_SOURCE_ROOTS=(
  "${REPO_ROOT}/profiles"
  "${REPO_ROOT}/templates"
  "${REPO_ROOT}/simulation/profiles"
  "${REPO_ROOT}/simulated-home/.hermes/profiles"
)

usage() {
  cat <<'USAGE'
Usage: scripts/check-real-deploy-readiness.sh [--source-root PATH]

Phase 3G real deploy readiness gate.

This script is read-only. It checks whether a future real guarded apply is
allowed from a source-root and destination-ownership perspective.

Options:
  --source-root PATH  Check an explicit source root instead of auto-selection.
  --help              Show this help message.

This script never creates, copies, deletes, restores, or resets real Hermes
profile files.
USAGE
}

fail_usage() {
  echo "ERROR: $*" >&2
  echo "REAL_PROFILE_WRITE=false" >&2
  echo "REAL_RESTORE_WRITE=false" >&2
  exit 2
}

role_dir_count() {
  local root="$1"
  local count=0
  local role
  for role in "${ROLES[@]}"; do
    if [ -d "${root}/${role}" ]; then
      count=$((count + 1))
    fi
  done
  echo "${count}"
}

source_has_all_roles() {
  local root="$1"
  local role
  [ -n "${root}" ] || return 1
  [ -d "${root}" ] || return 1
  for role in "${ROLES[@]}"; do
    [ -d "${root}/${role}" ] || return 1
  done
  return 0
}

select_source_root() {
  local src
  local best_root=""
  local best_count=0
  local count

  if [ -n "${SOURCE_ROOT}" ]; then
    echo "${SOURCE_ROOT}"
    return 0
  fi

  for src in "${CANDIDATE_SOURCE_ROOTS[@]}"; do
    if source_has_all_roles "${src}"; then
      echo "${src}"
      return 0
    fi
  done

  for src in "${CANDIDATE_SOURCE_ROOTS[@]}"; do
    if [ -d "${src}" ]; then
      count="$(role_dir_count "${src}")"
      if [ "${count}" -gt "${best_count}" ]; then
        best_count="${count}"
        best_root="${src}"
      fi
    fi
  done

  echo "${best_root}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source-root)
      if [ "$#" -lt 2 ]; then
        fail_usage "--source-root requires a path."
      fi
      SOURCE_ROOT="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --apply|--confirm|--restore|--reset|--write|--execute)
      fail_usage "write/restore option is not supported by the Phase 3G readiness checker: $1"
      ;;
    *)
      fail_usage "unknown option: $1"
      ;;
  esac
done

SELECTED_SOURCE_ROOT="$(select_source_root)"
SOURCE_READY=false
DESTINATION_READY=true
RESTORE_READY=true

missing_roles=()
if source_has_all_roles "${SELECTED_SOURCE_ROOT}"; then
  SOURCE_READY=true
else
  for role in "${ROLES[@]}"; do
    if [ -z "${SELECTED_SOURCE_ROOT}" ] || [ ! -d "${SELECTED_SOURCE_ROOT}/${role}" ]; then
      missing_roles+=("${role}")
    fi
  done
fi

unmanaged_destinations=()
for role in "${ROLES[@]}"; do
  dst_path="${REAL_PROFILE_ROOT}/${role}"
  marker_path="${dst_path}/${MANAGED_MARKER}"
  if [ -e "${dst_path}" ] && [ ! -f "${marker_path}" ]; then
    DESTINATION_READY=false
    unmanaged_destinations+=("${dst_path}")
  fi
done

if [ ! -f "${REPO_ROOT}/docs/restore-policy.md" ] || [ ! -f "${REPO_ROOT}/scripts/plan-restore-real-profiles.sh" ]; then
  RESTORE_READY=false
fi

cat <<HEADER
== OPC Hermes Real Deploy Readiness Gate ==

Status: PHASE 3G REAL DEPLOY READINESS GATE
Mode: read-only
Real deploy: DISABLED
Real restore: DISABLED
Repo root: ${REPO_ROOT}
Real profile root: ${REAL_PROFILE_ROOT}
Selected source root: ${SELECTED_SOURCE_ROOT}
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
HEADER

echo
echo "== Candidate Source Roots =="
for src in "${CANDIDATE_SOURCE_ROOTS[@]}"; do
  if [ -d "${src}" ]; then
    echo "FOUND:   ${src} roles=$(role_dir_count "${src}")/${#ROLES[@]}"
  else
    echo "MISSING: ${src}"
  fi
done

echo
echo "== Source Root Status =="
if [ "${SOURCE_READY}" = true ]; then
  echo "SOURCE_STATUS=complete"
  echo "SOURCE_ROOT=${SELECTED_SOURCE_ROOT}"
else
  echo "SOURCE_STATUS=blocked"
  echo "SOURCE_ROOT=${SELECTED_SOURCE_ROOT}"
  if [ -z "${SELECTED_SOURCE_ROOT}" ]; then
    echo "SOURCE_BLOCK_REASON=no candidate source root found"
  else
    echo "SOURCE_BLOCK_REASON=missing required role directories"
  fi
  if [ "${#missing_roles[@]}" -gt 0 ]; then
    printf 'MISSING_ROLES='
    printf '%s ' "${missing_roles[@]}"
    echo
  fi
fi

echo
echo "== Destination Ownership Status =="
if [ "${DESTINATION_READY}" = true ]; then
  echo "DESTINATION_STATUS=pass"
else
  echo "DESTINATION_STATUS=blocked"
  echo "DESTINATION_BLOCK_REASON=existing role destination without ${MANAGED_MARKER}"
  printf 'UNMANAGED_DESTINATIONS='
  printf '%s ' "${unmanaged_destinations[@]}"
  echo
fi

echo
echo "== Restore Planner Status =="
if [ "${RESTORE_READY}" = true ]; then
  echo "RESTORE_PLANNER_STATUS=pass"
else
  echo "RESTORE_PLANNER_STATUS=blocked"
  echo "RESTORE_BLOCK_REASON=missing docs/restore-policy.md or scripts/plan-restore-real-profiles.sh"
fi

echo
echo "== Readiness Decision =="
if [ "${SOURCE_READY}" = true ] && [ "${DESTINATION_READY}" = true ] && [ "${RESTORE_READY}" = true ]; then
  echo "READINESS_STATUS=READY"
  echo "NEXT_ALLOWED_PHASE=Phase 3H first real guarded apply"
else
  echo "READINESS_STATUS=BLOCKED"
  echo "NEXT_ALLOWED_PHASE=Phase 3H profile source root completion"
fi

echo
echo "== Phase 3G Result =="
echo "PASS: real deploy readiness gate completed in read-only mode"
echo "REAL_PROFILE_WRITE=false"
echo "REAL_RESTORE_WRITE=false"
