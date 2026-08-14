#!/usr/bin/env bash
set -euo pipefail

REAL_PROFILE_ROOT="${HOME}/.hermes/profiles"
BACKUP_ROOT="${HOME}/.hermes/backups/opc-profiles"
SELECTED_BACKUP=""
LIST_LIMIT="20"

usage() {
  cat <<'USAGE'
Usage: scripts/plan-restore-real-profiles.sh [options]

Read-only restore planner for OPC Hermes real profiles.

Options:
  --backup-path PATH   Inspect a specific backup path.
  --list-limit N       Maximum backup candidates to list. Default: 20.
  -h, --help           Show this help.

Phase 3F safety boundary:
  - Does not create files or directories.
  - Does not copy files.
  - Does not delete files.
  - Does not restore real ~/.hermes/profiles/.
  - Always emits REAL_PROFILE_WRITE=false.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --backup-path)
      if [ "$#" -lt 2 ]; then
        echo "ERROR: --backup-path requires a value." >&2
        echo "REAL_PROFILE_WRITE=false"
        exit 2
      fi
      SELECTED_BACKUP="$2"
      shift 2
      ;;
    --list-limit)
      if [ "$#" -lt 2 ]; then
        echo "ERROR: --list-limit requires a value." >&2
        echo "REAL_PROFILE_WRITE=false"
        exit 2
      fi
      LIST_LIMIT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      echo "REAL_PROFILE_WRITE=false"
      exit 2
      ;;
  esac
done

case "${LIST_LIMIT}" in
  ''|*[!0-9]*)
    echo "ERROR: --list-limit must be a non-negative integer." >&2
    echo "REAL_PROFILE_WRITE=false"
    exit 2
    ;;
esac

echo "== OPC Hermes Restore Plan =="
echo
echo "Status: PHASE 3F RESTORE PLANNING ONLY"
echo "Mode: read-only"
echo "Real restore: DISABLED"
echo "Real profile root: ${REAL_PROFILE_ROOT}"
echo "Backup root: ${BACKUP_ROOT}"
echo "REAL_PROFILE_WRITE=false"
echo

echo "== Safety Guarantee =="
echo "- This script does not create, copy, delete, or restore files."
echo "- This script does not write to ${REAL_PROFILE_ROOT}."
echo "- This script does not write to ${BACKUP_ROOT}."
echo "- This script only prints restore planning information."
echo

echo "== Current Real Profile Root =="
if [ -d "${REAL_PROFILE_ROOT}" ]; then
  echo "FOUND: ${REAL_PROFILE_ROOT}"
  echo "Current role/profile directories:"
  find "${REAL_PROFILE_ROOT}" -maxdepth 1 -mindepth 1 -type d -printf "  - %f\n" 2>/dev/null | sort || true
else
  echo "MISSING: ${REAL_PROFILE_ROOT}"
fi
echo

echo "== Backup Candidates =="
if [ -d "${BACKUP_ROOT}" ]; then
  mapfile -t backups < <(find "${BACKUP_ROOT}" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" 2>/dev/null | sort -r | head -n "${LIST_LIMIT}")
  if [ "${#backups[@]}" -eq 0 ]; then
    echo "No backup candidates found under ${BACKUP_ROOT}."
  else
    for backup in "${backups[@]}"; do
      echo "- ${BACKUP_ROOT}/${backup}/"
    done
  fi
else
  echo "Backup root does not exist: ${BACKUP_ROOT}"
fi
echo

if [ -n "${SELECTED_BACKUP}" ]; then
  echo "== Selected Backup Inspection =="
  echo "Selected backup: ${SELECTED_BACKUP}"
  if [ -d "${SELECTED_BACKUP}" ]; then
    echo "SELECTED_BACKUP_STATUS=FOUND"
    echo "Top-level entries:"
    find "${SELECTED_BACKUP}" -maxdepth 1 -mindepth 1 -printf "  - %f\n" 2>/dev/null | sort || true
  else
    echo "SELECTED_BACKUP_STATUS=MISSING"
  fi
  echo

  echo "== Planned Restore Map =="
  echo "source:      ${SELECTED_BACKUP}"
  echo "destination: ${REAL_PROFILE_ROOT}"
  echo "action:      preview only; restore execution disabled"
  echo
else
  echo "== Selected Backup Inspection =="
  echo "No --backup-path provided."
  echo "Provide --backup-path to preview a specific restore source."
  echo
fi

echo "== Restore Execution Policy =="
echo "- Future restore must require explicit backup path."
echo "- Future restore must require explicit confirmation token."
echo "- Future restore must create a fresh safety backup before overwrite."
echo "- Future remove-opc-managed may only remove directories with .opc-managed-profile."
echo "- Phase 3F does not implement real restore."
echo

echo "== Phase 3F Result =="
echo "PASS: restore planning completed in read-only mode"
echo "REAL_PROFILE_WRITE=false"
