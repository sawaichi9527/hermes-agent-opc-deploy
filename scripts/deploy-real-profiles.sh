#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_PROFILE_ROOT="${HOME}/.hermes/profiles"
BACKUP_ROOT="${HOME}/.hermes/backups/opc-profiles"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
PLANNED_BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
CONFIRM_TOKEN="REAL_DEPLOY_PROFILES"
MANAGED_MARKER=".opc-managed-profile"

MODE="dry-run"
SOURCE_ROOT=""
CONFIRM_VALUE=""

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
Usage: scripts/deploy-real-profiles.sh [--dry-run] [--source-root PATH]
       scripts/deploy-real-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES [--source-root PATH]

Phase 3E guarded apply implementation draft.

Default mode is dry-run. Dry-run prints the selected source root, destination
root, backup path, preflight result, and copy map without creating or modifying
real ~/.hermes/profiles/ files.

Guarded apply is allowed only with the exact confirmation token:

  --apply --confirm REAL_DEPLOY_PROFILES

Options:
  --dry-run           Explicit dry-run mode. This is the default.
  --apply             Enable guarded real profile deployment.
  --confirm TOKEN     Required for --apply. Must equal REAL_DEPLOY_PROFILES.
  --source-root PATH  Use a specific source root instead of auto-selection.
  --help              Show this help message.

Unsupported in Phase 3E:
  --write
  --execute
  --reset
  --restore
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  echo "REAL_PROFILE_WRITE=false" >&2
  exit 2
}

is_apply() {
  [ "${MODE}" = "apply" ]
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
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --confirm)
      if [ "$#" -lt 2 ]; then
        fail "--confirm requires a token. Expected: ${CONFIRM_TOKEN}"
      fi
      CONFIRM_VALUE="$2"
      shift 2
      ;;
    --source-root)
      if [ "$#" -lt 2 ]; then
        fail "--source-root requires a path."
      fi
      SOURCE_ROOT="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --write|--execute|--reset|--restore)
      fail "unsupported write/reset mode in Phase 3E: $1"
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if is_apply && [ "${CONFIRM_VALUE}" != "${CONFIRM_TOKEN}" ]; then
  fail "guarded apply requires: --confirm ${CONFIRM_TOKEN}"
fi

if [ "${MODE}" = "dry-run" ] && [ -n "${CONFIRM_VALUE}" ]; then
  fail "--confirm is only valid with --apply."
fi

SELECTED_SOURCE_ROOT="$(select_source_root)"

print_header() {
  cat <<HEADER
== OPC Hermes Real Profile Deploy ==

Status: PHASE 3E GUARDED APPLY DRAFT
Mode: ${MODE}
Real deploy: $(is_apply && echo "GUARDED_APPLY_REQUESTED" || echo "DISABLED")
Repo root: ${REPO_ROOT}
Selected source root: ${SELECTED_SOURCE_ROOT}
Real profile root: ${REAL_PROFILE_ROOT}
Backup root: ${BACKUP_ROOT}
Planned backup dir: ${PLANNED_BACKUP_DIR}
Confirmation token required for apply: ${CONFIRM_TOKEN}
HEADER
}

print_safety_boundary() {
  echo
  cat <<SAFETY
== Safety Boundary ==
- Default mode is dry-run and does not write real Hermes profile files.
- Guarded apply requires --apply --confirm ${CONFIRM_TOKEN}.
- Backup-before-write is mandatory for guarded apply.
- Existing unmarked destination role directories are protected.
- Hermes Agent does not depend on this script at runtime.
SAFETY
}

print_existing_real_profiles() {
  echo
  cat <<REALCHECK
== Existing Real Profile Root Check ==
REAL_PROFILE_ROOT=${REAL_PROFILE_ROOT}
REAL_PROFILE_WRITE=$(is_apply && echo "pending" || echo "false")
REALCHECK
  if [ -d "${REAL_PROFILE_ROOT}" ]; then
    echo "Real profile root exists: ${REAL_PROFILE_ROOT}"
    echo "Existing real profile directories:"
    find "${REAL_PROFILE_ROOT}" -maxdepth 1 -mindepth 1 -type d -printf "  - %f\n" 2>/dev/null | sort || true
  else
    echo "Real profile root does not exist: ${REAL_PROFILE_ROOT}"
  fi
}

print_candidate_sources() {
  local src
  echo
  echo "== Candidate Source Roots =="
  for src in "${CANDIDATE_SOURCE_ROOTS[@]}"; do
    if [ -d "${src}" ]; then
      echo "FOUND:   ${src} roles=$(role_dir_count "${src}")/${#ROLES[@]}"
    else
      echo "MISSING: ${src}"
    fi
  done
}

print_selected_source() {
  echo
  echo "== Selected Source Root =="
  if [ -n "${SELECTED_SOURCE_ROOT}" ]; then
    echo "SOURCE_ROOT=${SELECTED_SOURCE_ROOT}"
    if source_has_all_roles "${SELECTED_SOURCE_ROOT}"; then
      echo "SOURCE_STATUS=complete"
    elif [ -d "${SELECTED_SOURCE_ROOT}" ]; then
      echo "SOURCE_STATUS=partial"
      echo "WARNING: selected source root exists but does not contain all required roles."
    else
      echo "SOURCE_STATUS=missing"
      echo "WARNING: selected source root does not exist."
    fi
  else
    echo "SOURCE_ROOT="
    echo "SOURCE_STATUS=missing"
    echo "WARNING: no candidate source root found."
  fi
}

print_copy_map() {
  local role
  local src_path
  local dst_path

  echo
  echo "== Planned Role Copy Map =="
  for role in "${ROLES[@]}"; do
    src_path="${SELECTED_SOURCE_ROOT}/${role}"
    dst_path="${REAL_PROFILE_ROOT}/${role}"
    echo
    echo "[${role}]"
    echo "  source:      ${src_path}/"
    echo "  destination: ${dst_path}/"
    if [ -n "${SELECTED_SOURCE_ROOT}" ] && [ -d "${src_path}" ]; then
      echo "  source_status: found"
      echo "  copy_action: cp -a '${src_path}/.' '${dst_path}/'"
      echo "  marker: ${dst_path}/${MANAGED_MARKER}"
    else
      echo "  source_status: missing"
      echo "  copy_action: blocked until source exists"
    fi
  done
}

preflight_check() {
  local role
  local dst_path
  local marker_path

  [ "${EUID}" -ne 0 ] || fail "refusing to run as root. Use the normal user account."
  [ "${REAL_PROFILE_ROOT}" = "${HOME}/.hermes/profiles" ] || fail "unexpected destination root: ${REAL_PROFILE_ROOT}"
  [ -f "${REPO_ROOT}/docs/guarded-apply-contract.md" ] || fail "missing docs/guarded-apply-contract.md"
  [ -f "${REPO_ROOT}/docs/verification-phase-3c.md" ] || fail "missing docs/verification-phase-3c.md"
  [ -f "${REPO_ROOT}/docs/real-deploy-plan.md" ] || fail "missing docs/real-deploy-plan.md"
  [ -n "${SELECTED_SOURCE_ROOT}" ] || fail "no source root selected"
  source_has_all_roles "${SELECTED_SOURCE_ROOT}" || fail "selected source root does not contain all required role directories: ${SELECTED_SOURCE_ROOT}"
  [ ! -e "${PLANNED_BACKUP_DIR}" ] || fail "planned backup path already exists: ${PLANNED_BACKUP_DIR}"

  for role in "${ROLES[@]}"; do
    dst_path="${REAL_PROFILE_ROOT}/${role}"
    marker_path="${dst_path}/${MANAGED_MARKER}"
    if [ -e "${dst_path}" ] && [ ! -f "${marker_path}" ]; then
      fail "destination role exists without managed marker; refusing overwrite: ${dst_path}"
    fi
  done
}

print_preflight() {
  echo
  echo "== Preflight Check =="
  if preflight_check; then
    echo "PREFLIGHT_STATUS=PASS"
  fi
}

create_backup() {
  mkdir -p "${BACKUP_ROOT}"
  mkdir "${PLANNED_BACKUP_DIR}"

  if [ -d "${REAL_PROFILE_ROOT}" ]; then
    cp -a "${REAL_PROFILE_ROOT}" "${PLANNED_BACKUP_DIR}/profiles"
    [ -d "${PLANNED_BACKUP_DIR}/profiles" ] || fail "backup verification failed: ${PLANNED_BACKUP_DIR}/profiles"
  else
    cat > "${PLANNED_BACKUP_DIR}/NO_PREVIOUS_PROFILE_TREE.txt" <<NOTE
No previous real Hermes profile tree existed at apply time.
real_profile_root=${REAL_PROFILE_ROOT}
created_at=${TIMESTAMP}
NOTE
    [ -f "${PLANNED_BACKUP_DIR}/NO_PREVIOUS_PROFILE_TREE.txt" ] || fail "backup note verification failed"
  fi
}

write_marker() {
  local role="$1"
  local dst_path="$2"
  cat > "${dst_path}/${MANAGED_MARKER}" <<MARKER
managed_by=hermes-agent-opc-deploy
phase=3E
deployed_at=${TIMESTAMP}
source_root=${SELECTED_SOURCE_ROOT}
role=${role}
MARKER
}

apply_profiles() {
  local role
  local src_path
  local dst_path

  echo
  echo "== Guarded Apply =="
  echo "BACKUP_PATH=${PLANNED_BACKUP_DIR}"
  create_backup
  echo "BACKUP_STATUS=created"

  mkdir -p "${REAL_PROFILE_ROOT}"

  for role in "${ROLES[@]}"; do
    src_path="${SELECTED_SOURCE_ROOT}/${role}"
    dst_path="${REAL_PROFILE_ROOT}/${role}"
    mkdir -p "${dst_path}"
    cp -a "${src_path}/." "${dst_path}/"
    write_marker "${role}" "${dst_path}"
    echo "APPLIED_ROLE=${role}"
  done
}

print_header
print_safety_boundary
print_existing_real_profiles
print_candidate_sources
print_selected_source
print_copy_map

if is_apply; then
  print_preflight
  apply_profiles
  echo
  echo "== Phase 3E Result =="
  echo "PASS: guarded real deploy completed"
  echo "REAL_PROFILE_WRITE=true"
else
  echo
  echo "== Planned Backup Step =="
  echo "Would backup existing real profile tree before guarded apply:"
  echo "  from: ${REAL_PROFILE_ROOT}"
  echo "  to:   ${PLANNED_BACKUP_DIR}"
  echo "DRY_RUN_ACTION: no backup directory is created"

  echo
  echo "== Dry-run Preflight Preview =="
  if preflight_check >/tmp/hermes-opc-deploy-preflight.$$ 2>&1; then
    rm -f /tmp/hermes-opc-deploy-preflight.$$
    echo "PREFLIGHT_STATUS=PASS"
  else
    cat /tmp/hermes-opc-deploy-preflight.$$ || true
    rm -f /tmp/hermes-opc-deploy-preflight.$$
    echo "PREFLIGHT_STATUS=BLOCKED_FOR_APPLY"
  fi

  echo
  echo "== Simplicity Boundary =="
  echo "- Personal/local usage only."
  echo "- Plain shell + Markdown only."
  echo "- No daemon, database, background reconciler, remote telemetry, or enterprise orchestration."
  echo "- No runtime burden added to Hermes Agent."

  echo
  echo "== Phase 3E Result =="
  echo "PASS: guarded deploy dry-run completed"
  echo "REAL_PROFILE_WRITE=false"
fi
