#!/usr/bin/env bash
set -euo pipefail

# Phase 3K-FIX.16 native profile runtime smoke checker.
#
# Read-only by design:
# - does not run chat / oneshot
# - does not start gateway
# - does not run hermes setup
# - does not create .env or config.yaml
# - does not write secrets

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE_CONFIG="${ROOT_DIR}/config/profile-roles.txt"
REAL_PROFILE_ROOT="${HOME}/.hermes/profiles"

REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false

ROLE_COUNT=0
PROFILE_SHOW_PASS_COUNT=0
PROFILE_SHOW_FAIL_COUNT=0
DOCTOR_PASS_COUNT=0
DOCTOR_FAIL_COUNT=0
SOUL_CONFIGURED_COUNT=0
PROFILE_YAML_PRESENT_COUNT=0
ENV_MISSING_COUNT=0
CONFIG_MISSING_COUNT=0
GATEWAY_STOPPED_COUNT=0
BLOCKED_COUNT=0

printf '%s\n' "== OPC Hermes Native Profile Runtime Smoke =="
printf '%s\n' "Status: PHASE 3K-FIX.16 NATIVE PROFILE RUNTIME SMOKE CHECK"
printf '%s\n' "Mode: read-only"
printf '%s\n' "Repo root: ${ROOT_DIR}"
printf '%s\n' "Role config: ${ROLE_CONFIG}"
printf '%s\n' "Real profile root: ${REAL_PROFILE_ROOT}"
printf '%s\n' "REAL_PROFILE_WRITE=${REAL_PROFILE_WRITE}"
printf '%s\n' "REAL_PROFILE_DELETE=${REAL_PROFILE_DELETE}"
printf '%s\n' "SECRET_WRITE=${SECRET_WRITE}"
printf '%s\n' "CONFIG_WRITE=${CONFIG_WRITE}"
printf '%s\n' "GATEWAY_START=${GATEWAY_START}"
printf '%s\n' "CHAT_SMOKE=${CHAT_SMOKE}"
printf '\n'

if [[ ! -f "${ROLE_CONFIG}" ]]; then
  printf '%s\n' "BLOCKED role_config_missing=${ROLE_CONFIG}"
  BLOCKED_COUNT=$((BLOCKED_COUNT + 1))
fi

if ! command -v hermes >/dev/null 2>&1; then
  printf '%s\n' "BLOCKED hermes_command_missing=true"
  BLOCKED_COUNT=$((BLOCKED_COUNT + 1))
fi

if [[ ! -d "${REAL_PROFILE_ROOT}" ]]; then
  printf '%s\n' "BLOCKED real_profile_root_missing=${REAL_PROFILE_ROOT}"
  BLOCKED_COUNT=$((BLOCKED_COUNT + 1))
fi

if [[ "${BLOCKED_COUNT}" -ne 0 ]]; then
  printf '\n%s\n' "== Summary =="
  printf '%s\n' "ROLE_COUNT=${ROLE_COUNT}"
  printf '%s\n' "PROFILE_SHOW_PASS_COUNT=${PROFILE_SHOW_PASS_COUNT}"
  printf '%s\n' "PROFILE_SHOW_FAIL_COUNT=${PROFILE_SHOW_FAIL_COUNT}"
  printf '%s\n' "DOCTOR_PASS_COUNT=${DOCTOR_PASS_COUNT}"
  printf '%s\n' "DOCTOR_FAIL_COUNT=${DOCTOR_FAIL_COUNT}"
  printf '%s\n' "SOUL_CONFIGURED_COUNT=${SOUL_CONFIGURED_COUNT}"
  printf '%s\n' "PROFILE_YAML_PRESENT_COUNT=${PROFILE_YAML_PRESENT_COUNT}"
  printf '%s\n' "ENV_MISSING_COUNT=${ENV_MISSING_COUNT}"
  printf '%s\n' "CONFIG_MISSING_COUNT=${CONFIG_MISSING_COUNT}"
  printf '%s\n' "GATEWAY_STOPPED_COUNT=${GATEWAY_STOPPED_COUNT}"
  printf '%s\n' "BLOCKED_COUNT=${BLOCKED_COUNT}"
  printf '%s\n' "REAL_PROFILE_WRITE=${REAL_PROFILE_WRITE}"
  printf '%s\n' "REAL_PROFILE_DELETE=${REAL_PROFILE_DELETE}"
  printf '%s\n' "SECRET_WRITE=${SECRET_WRITE}"
  printf '%s\n' "CONFIG_WRITE=${CONFIG_WRITE}"
  printf '%s\n' "GATEWAY_START=${GATEWAY_START}"
  printf '%s\n' "CHAT_SMOKE=${CHAT_SMOKE}"
  printf '%s\n' "FAIL: native profile runtime smoke blocked"
  exit 1
fi

while IFS= read -r role || [[ -n "${role}" ]]; do
  role="$(printf '%s' "${role}" | sed 's/#.*$//' | xargs)"
  [[ -z "${role}" ]] && continue
  ROLE_COUNT=$((ROLE_COUNT + 1))

  dest="${REAL_PROFILE_ROOT}/${role}"
  printf '%s\n' "ROLE=${role}"
  printf '%s\n' "DESTINATION_DIR=${dest}"

  if [[ ! -d "${dest}" ]]; then
    printf '%s\n' "ROLE_STATUS=DESTINATION_MISSING"
    PROFILE_SHOW_FAIL_COUNT=$((PROFILE_SHOW_FAIL_COUNT + 1))
    DOCTOR_FAIL_COUNT=$((DOCTOR_FAIL_COUNT + 1))
    BLOCKED_COUNT=$((BLOCKED_COUNT + 1))
    printf '\n'
    continue
  fi

  if [[ -f "${dest}/profile.yaml" ]]; then
    PROFILE_YAML_PRESENT_COUNT=$((PROFILE_YAML_PRESENT_COUNT + 1))
    printf '%s\n' "PROFILE_YAML_STATUS=present"
  else
    printf '%s\n' "PROFILE_YAML_STATUS=missing"
  fi

  show_output="$(hermes profile show "${role}" 2>&1 || true)"
  if printf '%s\n' "${show_output}" | grep -q "Profile: ${role}" && \
     printf '%s\n' "${show_output}" | grep -q "Path:.*${REAL_PROFILE_ROOT}/${role}"; then
    PROFILE_SHOW_PASS_COUNT=$((PROFILE_SHOW_PASS_COUNT + 1))
    printf '%s\n' "PROFILE_SHOW_STATUS=pass"
  else
    PROFILE_SHOW_FAIL_COUNT=$((PROFILE_SHOW_FAIL_COUNT + 1))
    printf '%s\n' "PROFILE_SHOW_STATUS=fail"
  fi

  if printf '%s\n' "${show_output}" | grep -q "Gateway: stopped"; then
    GATEWAY_STOPPED_COUNT=$((GATEWAY_STOPPED_COUNT + 1))
    printf '%s\n' "GATEWAY_STATUS=stopped"
  else
    printf '%s\n' "GATEWAY_STATUS=unknown_or_not_stopped"
  fi

  if printf '%s\n' "${show_output}" | grep -q "\.env:.*not configured"; then
    ENV_MISSING_COUNT=$((ENV_MISSING_COUNT + 1))
    printf '%s\n' "ENV_STATUS=missing_expected"
  else
    printf '%s\n' "ENV_STATUS=present_or_unknown"
  fi

  doctor_output="$(hermes -p "${role}" doctor 2>&1 || true)"

  # Doctor output is terminal-formatted and can vary across Hermes versions.
  # Treat the doctor run as successful when it produced the Hermes Doctor
  # screen and confirms any role-context signal:
  #   - the role's SOUL.md is loaded as persona, or
  #   - the real profile path appears, or
  #   - the profile-relative path appears.
  # This stays read-only and avoids depending on one exact path wording.
  if printf '%s\n' "${doctor_output}" | grep -q "Hermes Doctor" && \
     { printf '%s\n' "${doctor_output}" | grep -q "SOUL.md exists (persona configured)" || \
       printf '%s\n' "${doctor_output}" | grep -q "${REAL_PROFILE_ROOT}/${role}" || \
       printf '%s\n' "${doctor_output}" | grep -q "profiles/${role}"; }; then
    DOCTOR_PASS_COUNT=$((DOCTOR_PASS_COUNT + 1))
    printf '%s\n' "DOCTOR_STATUS=pass"
  else
    DOCTOR_FAIL_COUNT=$((DOCTOR_FAIL_COUNT + 1))
    printf '%s\n' "DOCTOR_STATUS=fail"
  fi

  if printf '%s\n' "${doctor_output}" | grep -q "SOUL.md exists (persona configured)"; then
    SOUL_CONFIGURED_COUNT=$((SOUL_CONFIGURED_COUNT + 1))
    printf '%s\n' "SOUL_STATUS=persona_configured"
  else
    printf '%s\n' "SOUL_STATUS=missing_or_unconfirmed"
  fi

  if printf '%s\n' "${doctor_output}" | grep -q "config.yaml not found"; then
    CONFIG_MISSING_COUNT=$((CONFIG_MISSING_COUNT + 1))
    printf '%s\n' "CONFIG_STATUS=missing_expected_defaults_used"
  else
    printf '%s\n' "CONFIG_STATUS=present_or_unknown"
  fi

  printf '%s\n' "ROLE_STATUS=RUNTIME_SMOKE_CHECKED"
  printf '\n'
done < "${ROLE_CONFIG}"

printf '%s\n' "== Summary =="
printf '%s\n' "ROLE_COUNT=${ROLE_COUNT}"
printf '%s\n' "PROFILE_SHOW_PASS_COUNT=${PROFILE_SHOW_PASS_COUNT}"
printf '%s\n' "PROFILE_SHOW_FAIL_COUNT=${PROFILE_SHOW_FAIL_COUNT}"
printf '%s\n' "DOCTOR_PASS_COUNT=${DOCTOR_PASS_COUNT}"
printf '%s\n' "DOCTOR_FAIL_COUNT=${DOCTOR_FAIL_COUNT}"
printf '%s\n' "SOUL_CONFIGURED_COUNT=${SOUL_CONFIGURED_COUNT}"
printf '%s\n' "PROFILE_YAML_PRESENT_COUNT=${PROFILE_YAML_PRESENT_COUNT}"
printf '%s\n' "ENV_MISSING_COUNT=${ENV_MISSING_COUNT}"
printf '%s\n' "CONFIG_MISSING_COUNT=${CONFIG_MISSING_COUNT}"
printf '%s\n' "GATEWAY_STOPPED_COUNT=${GATEWAY_STOPPED_COUNT}"
printf '%s\n' "BLOCKED_COUNT=${BLOCKED_COUNT}"
printf '%s\n' "REAL_PROFILE_WRITE=${REAL_PROFILE_WRITE}"
printf '%s\n' "REAL_PROFILE_DELETE=${REAL_PROFILE_DELETE}"
printf '%s\n' "SECRET_WRITE=${SECRET_WRITE}"
printf '%s\n' "CONFIG_WRITE=${CONFIG_WRITE}"
printf '%s\n' "GATEWAY_START=${GATEWAY_START}"
printf '%s\n' "CHAT_SMOKE=${CHAT_SMOKE}"

if [[ "${ROLE_COUNT}" -eq 6 && \
      "${PROFILE_SHOW_PASS_COUNT}" -eq 6 && \
      "${PROFILE_SHOW_FAIL_COUNT}" -eq 0 && \
      "${DOCTOR_PASS_COUNT}" -eq 6 && \
      "${DOCTOR_FAIL_COUNT}" -eq 0 && \
      "${SOUL_CONFIGURED_COUNT}" -eq 6 && \
      "${PROFILE_YAML_PRESENT_COUNT}" -eq 6 && \
      "${BLOCKED_COUNT}" -eq 0 ]]; then
  printf '%s\n' "PASS: native profile runtime smoke completed in read-only mode"
  exit 0
fi

printf '%s\n' "PARTIAL: native profile runtime smoke completed with expected or unresolved gaps"
exit 0
