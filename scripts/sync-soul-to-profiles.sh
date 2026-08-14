#!/usr/bin/env bash
set -euo pipefail

# sync-soul-to-profiles.sh — guarded SOUL.md.template → real ~/.hermes/profiles SOUL.md
#
# Purpose: Stage-2 (M8) sync of the v4.1 SOUL templates into real Hermes profile
# directories. The deploy-real-profiles.sh script copies profile dirs wholesale,
# but the canonical repo only carries SOUL.md.template while real profiles use
# SOUL.md — this script bridges that gap with backup-before-write + dry-run default.
#
# Design (matches guarded-apply contract):
#   - Dry-run by default; nothing is written without --apply.
#   - --apply requires --confirm REAL_DEPLOY_PROFILES.
#   - Backup of each existing SOUL.md to SOUL.md.bak.<timestamp> before write.
#   - Writes .opc-managed-profile marker on first touch (so future guarded applies
#     are allowed). Leaves non-SOUL files untouched.
#
# Usage:
#   bash scripts/sync-soul-to-profiles.sh                     # dry-run
#   bash scripts/sync-soul-to-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES
#
# Environment:
#   HERMES_PROFILES_ROOT   Default: $HOME/.hermes/profiles
#   EDITION                Default: opc-personal (generic also supported)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES_ROOT="${HERMES_PROFILES_ROOT:-$HOME/.hermes/profiles}"
EDITION="${EDITION:-opc-personal}"
CONFIRM_TOKEN="REAL_DEPLOY_PROFILES"
MANAGED_MARKER=".opc-managed-profile"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
MODE="dry-run"
CONFIRM_VALUE=""
CHANGED=0
SKIPPED=0

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/sync-soul-to-profiles.sh [--edition generic|opc-personal]
  ./scripts/sync-soul-to-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES [--edition ...]

Dry-run is the default. --apply requires the exact confirm token.
For each role, the repo SOUL.md.template is compared to the real profile SOUL.md
and copied over when different (with SOUL.md.bak.<ts> backup).
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 2
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
    --edition)
      [ "$#" -ge 2 ] || fail "--edition requires a value"
      EDITION="$2"
      shift 2
      ;;
    --confirm)
      [ "$#" -ge 2 ] || fail "--confirm requires a token. Expected: ${CONFIRM_TOKEN}"
      CONFIRM_VALUE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "${EDITION}" in
  generic|opc-personal) ;;
  *) fail "unsupported edition: ${EDITION}" ;;
esac

ROLES_FILE="${REPO_ROOT}/editions/${EDITION}/roles.txt"
[ -f "${ROLES_FILE}" ] || fail "role config not found: ${ROLES_FILE}"

ROLES=()
while IFS= read -r line || [ -n "${line}" ]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [ -n "${line}" ] || continue
  ROLES+=("${line}")
done < "${ROLES_FILE}"

if [ "${MODE}" = "apply" ] && [ "${CONFIRM_VALUE}" != "${CONFIRM_TOKEN}" ]; then
  fail "guarded apply requires: --confirm ${CONFIRM_TOKEN}"
fi
[ "${MODE}" = "dry-run" ] && [ -n "${CONFIRM_VALUE}" ] \
  && fail "--confirm is only valid with --apply."

echo "== sync-soul-to-profiles (v0.20.0, edition=${EDITION}) =="
echo "Mode: ${MODE}"
echo "Template root: ${REPO_ROOT}/editions/${EDITION}/profiles"
echo "Real profiles root: ${PROFILES_ROOT}"
echo "Roles: ${#ROLES[@]}"
echo

for role in "${ROLES[@]}"; do
  src="${REPO_ROOT}/editions/${EDITION}/profiles/${role}/SOUL.md.template"
  dst="${PROFILES_ROOT}/${role}/SOUL.md"

  echo "== ${role} =="
  if [ ! -f "${src}" ]; then
    echo "  SKIP template missing: ${src}"
    continue
  fi
  if [ ! -f "${dst}" ]; then
    echo "  SKIP real profile SOUL.md missing: ${dst}"
    continue
  fi

  if cmp -s "${src}" "${dst}"; then
    echo "  PASS already in sync"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ "${MODE}" = "apply" ]; then
    marker="${PROFILES_ROOT}/${role}/${MANAGED_MARKER}"
    backup="${dst}.bak.${TIMESTAMP}"
    cp "${dst}" "${backup}"
    cp "${src}" "${dst}"
    if [ ! -f "${marker}" ]; then
      cat > "${marker}" <<MARKER
managed_by=hermes-agent-opc-deploy
edition=${EDITION}
phase=v0.20.0
synced_at=${TIMESTAMP}
role=${role}
MARKER
    fi
    echo "  APPLIED backup=${backup}"
    CHANGED=$((CHANGED + 1))
  else
    echo "  DRY-RUN would replace ${dst} (backup .bak.${TIMESTAMP})"
    CHANGED=$((CHANGED + 1))
  fi
done

echo
echo "== Summary =="
if [ "${MODE}" = "apply" ]; then
  echo "PASS sync-soul-to-profiles apply completed; changed=${CHANGED} in-sync=${SKIPPED}."
else
  echo "PASS sync-soul-to-profiles dry-run completed; would_change=${CHANGED} in-sync=${SKIPPED}."
  echo "Re-run with --apply --confirm ${CONFIRM_TOKEN} to write."
fi
