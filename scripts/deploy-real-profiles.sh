#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_PROFILE_ROOT="${HOME}/.hermes/profiles"
BACKUP_ROOT="${HOME}/.hermes/backups/opc-profiles"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
PLANNED_BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

DRY_RUN=true
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
Usage: scripts/deploy-real-profiles.sh [--dry-run] [--source-root PATH] [--help]

Phase 3B real deploy dry-run implementation.

This script is intentionally dry-run only. It prints the future deployment
plan for real ~/.hermes/profiles/ but does not create, copy, delete, reset,
or back up any real profile files.

Options:
  --dry-run           Explicit dry-run mode. This is the only supported mode.
  --source-root PATH  Use a specific source root for planning output.
  --help              Show this help message.

Unsupported by design in Phase 3B:
  --apply
  --write
  --execute
  --reset
USAGE
}

fail_unsupported_write_mode() {
  echo "ERROR: real write mode is not supported in Phase 3B." >&2
  echo "This script is dry-run only and must not touch real ~/.hermes/profiles/." >&2
  echo "REAL_PROFILE_WRITE=false" >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --source-root)
      if [ "$#" -lt 2 ]; then
        echo "ERROR: --source-root requires a path." >&2
        exit 2
      fi
      SOURCE_ROOT="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --apply|--write|--execute|--reset)
      fail_unsupported_write_mode
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

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

select_source_root() {
  local best_root=""
  local best_count=0
  local src
  local count

  if [ -n "${SOURCE_ROOT}" ]; then
    echo "${SOURCE_ROOT}"
    return 0
  fi

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

SELECTED_SOURCE_ROOT="$(select_source_root)"

cat <<HEADER
== OPC Hermes Real Profile Deploy ==

Status: PHASE 3B DRY-RUN ONLY
Real deploy: DISABLED
Dry-run: ${DRY_RUN}
Repo root: ${REPO_ROOT}
Real profile root: ${REAL_PROFILE_ROOT}
Backup root: ${BACKUP_ROOT}
Planned backup dir: ${PLANNED_BACKUP_DIR}
HEADER

echo
cat <<SAFETY
== Safety Boundary ==
- This script does not create ${REAL_PROFILE_ROOT}.
- This script does not create ${BACKUP_ROOT}.
- This script does not copy profile files.
- This script does not delete or reset profile files.
- This script only prints the future deployment plan.
- Hermes Agent does not depend on this script at runtime.
SAFETY

echo
cat <<REALCHECK
== Existing Real Profile Root Check ==
REAL_PROFILE_ROOT=${REAL_PROFILE_ROOT}
REAL_PROFILE_WRITE=false
REALCHECK
if [ -d "${REAL_PROFILE_ROOT}" ]; then
  echo "Real profile root exists: ${REAL_PROFILE_ROOT}"
  echo "Existing real profile directories:"
  find "${REAL_PROFILE_ROOT}" -maxdepth 1 -mindepth 1 -type d -printf "  - %f\n" 2>/dev/null | sort || true
else
  echo "Real profile root does not exist: ${REAL_PROFILE_ROOT}"
fi

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
echo "== Selected Source Root =="
if [ -n "${SELECTED_SOURCE_ROOT}" ]; then
  echo "SOURCE_ROOT=${SELECTED_SOURCE_ROOT}"
  if [ -d "${SELECTED_SOURCE_ROOT}" ]; then
    echo "SOURCE_STATUS=found"
  else
    echo "SOURCE_STATUS=missing"
    echo "WARNING: selected source root does not exist. Dry-run continues for planning only."
  fi
else
  echo "SOURCE_ROOT="
  echo "SOURCE_STATUS=missing"
  echo "WARNING: no candidate source root found. Dry-run continues for planning only."
fi

echo
echo "== Planned Backup Step =="
echo "Would backup existing real profile tree before any future write:"
echo "  from: ${REAL_PROFILE_ROOT}"
echo "  to:   ${PLANNED_BACKUP_DIR}"
echo "DRY_RUN_ACTION: no backup directory is created"

echo
echo "== Planned Directory Creation =="
for role in "${ROLES[@]}"; do
  echo "Would ensure destination directory: ${REAL_PROFILE_ROOT}/${role}/"
done
echo "DRY_RUN_ACTION: no destination directories are created"

echo
echo "== Planned Copy Map =="
for role in "${ROLES[@]}"; do
  src_path="${SELECTED_SOURCE_ROOT}/${role}"
  dst_path="${REAL_PROFILE_ROOT}/${role}"
  echo
  echo "[${role}]"
  echo "  source:      ${src_path}/"
  echo "  destination: ${dst_path}/"
  if [ -n "${SELECTED_SOURCE_ROOT}" ] && [ -d "${src_path}" ]; then
    echo "  source_status: found"
    echo "  future_copy: cp -a '${src_path}/.' '${dst_path}/'"
  else
    echo "  source_status: missing"
    echo "  future_copy: skipped until source exists"
  fi
done
echo
echo "DRY_RUN_ACTION: no files are copied"

echo
echo "== Unsupported Write Modes =="
echo "Phase 3B intentionally rejects --apply, --write, --execute, and --reset."
echo "Real writes may only be considered in a later phase after explicit review."

echo
echo "== Simplicity Boundary =="
echo "- Personal/local usage only."
echo "- Plain shell + Markdown only."
echo "- No daemon, database, background reconciler, remote telemetry, or enterprise orchestration."
echo "- No runtime burden added to Hermes Agent."

echo
echo "== Phase 3B Result =="
echo "PASS: real deploy dry-run completed"
echo "REAL_PROFILE_WRITE=false"
