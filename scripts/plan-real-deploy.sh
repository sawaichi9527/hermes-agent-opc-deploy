#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_PROFILE_ROOT="${HOME}/.hermes/profiles"
BACKUP_ROOT="${HOME}/.hermes/backups/opc-profiles"

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

echo "== OPC Hermes Real Deploy Plan =="
echo
echo "Status: READ-ONLY PLAN ONLY"
echo "Real deploy: DISABLED"
echo "Repo root: ${REPO_ROOT}"
echo "Real profile root: ${REAL_PROFILE_ROOT}"
echo "Backup root: ${BACKUP_ROOT}"
echo

echo "== Safety Guarantee =="
echo "- This script does not create, modify, or delete real Hermes profile files."
echo "- This script does not write to ${REAL_PROFILE_ROOT}."
echo "- This script does not write to ${BACKUP_ROOT}."
echo "- This script only prints the planned future deployment layout."
echo

echo "== Existing Real Profile Root Check =="
if [ -d "${REAL_PROFILE_ROOT}" ]; then
  echo "Real profile root exists: ${REAL_PROFILE_ROOT}"
  echo "Existing role/profile directories:"
  find "${REAL_PROFILE_ROOT}" -maxdepth 1 -mindepth 1 -type d -printf "  - %f\n" 2>/dev/null | sort || true
else
  echo "Real profile root does not exist: ${REAL_PROFILE_ROOT}"
fi
echo

echo "== Candidate Source Roots =="
for src in "${CANDIDATE_SOURCE_ROOTS[@]}"; do
  if [ -d "${src}" ]; then
    echo "FOUND:   ${src}"
  else
    echo "MISSING: ${src}"
  fi
done
echo

echo "== Planned Future Role Directories =="
for role in "${ROLES[@]}"; do
  echo "- ${REAL_PROFILE_ROOT}/${role}/"
done
echo

echo "== Planned Future Copy Map =="
for role in "${ROLES[@]}"; do
  echo
  echo "[${role}]"
  echo "  future destination:"
  echo "    ${REAL_PROFILE_ROOT}/${role}/"
  echo "  possible source candidates:"
  for src in "${CANDIDATE_SOURCE_ROOTS[@]}"; do
    if [ -d "${src}/${role}" ]; then
      echo "    FOUND:   ${src}/${role}/"
    else
      echo "    MISSING: ${src}/${role}/"
    fi
  done
done
echo

echo "== Planned Backup Policy =="
echo "- Before any future write, backup existing real profiles to:"
echo "  ${BACKUP_ROOT}/YYYYMMDD-HHMMSS/"
echo "- Existing backups must never be overwritten."
echo "- If ${REAL_PROFILE_ROOT} does not exist, future deploy records no existing profile tree."
echo "- Backup stays local and file-based; no database or service is introduced."
echo

echo "== Planned Reset Policy =="
echo "- preview: show restore/remove actions only."
echo "- restore-backup: restore from an explicit backup path."
echo "- remove-opc-managed: remove only known OPC-managed files."
echo "- full-reset: dangerous; requires explicit confirmation."
echo

echo "== Simplicity Boundary =="
echo "- Personal/local usage only."
echo "- No daemon, background reconciler, database, remote telemetry, or enterprise orchestration."
echo "- Hermes Agent should not depend on this planning script at runtime."
echo

echo "== Phase 3A Result =="
echo "PASS: real deploy planning completed"
echo "PASS: real deploy planning completed in read-only mode"
echo "REAL_PROFILE_WRITE=false"
