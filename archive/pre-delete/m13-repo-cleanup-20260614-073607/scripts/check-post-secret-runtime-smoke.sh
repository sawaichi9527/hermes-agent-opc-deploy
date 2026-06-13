#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE_FILE="${REPO_ROOT}/config/profile-roles.txt"
REAL_PROFILE_ROOT="${HERMES_PROFILE_ROOT:-${HOME}/.hermes/profiles}"

real_profile_write=false
real_profile_delete=false
secret_write=false
secret_read_value=false
config_write=false
env_write=false
gateway_start=false
chat_smoke=false

role_count=0
manual_env_candidate_count=0
placeholder_env_count=0
missing_env_count=0
missing_config_count=0
profile_show_pass_count=0
profile_show_fail_count=0
doctor_pass_count=0
doctor_fail_count=0
repo_secret_risk_count=0
repo_local_config_risk_count=0
blocked_count=0

placeholder_patterns=("CHANGEME" "CHANGE_ME" "PLACEHOLDER" "TODO" "REPLACE_ME" "example" "dummy" "not-set" "not_set" "your_" "local-placeholder")

has_placeholder_env() {
  local file="$1" pattern
  for pattern in "${placeholder_patterns[@]}"; do
    if grep -Eiq "${pattern}" "$file"; then
      return 0
    fi
  done
  return 1
}

has_noncomment_assignment() {
  local file="$1"
  grep -Eq '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*[^[:space:]#]+' "$file"
}

print_header() {
  cat <<EOF
== OPC Hermes Post-secret Runtime Smoke Check ==
Status: PHASE 3K-FIX.24 POST-SECRET-FILL RUNTIME SMOKE CHECK
Mode: read-only
Repo root: ${REPO_ROOT}
Role config: ${ROLE_FILE}
Real profile root: ${REAL_PROFILE_ROOT}
REAL_PROFILE_WRITE=${real_profile_write}
REAL_PROFILE_DELETE=${real_profile_delete}
SECRET_WRITE=${secret_write}
SECRET_READ_VALUE=${secret_read_value}
CONFIG_WRITE=${config_write}
ENV_WRITE=${env_write}
GATEWAY_START=${gateway_start}
CHAT_SMOKE=${chat_smoke}
EOF
}

scan_repo_risk() {
  local risk
  risk="$(find "${REPO_ROOT}" -path "${REPO_ROOT}/.git" -prune -o -type f \( -name ".env" -o -name "config.yaml" \) -print || true)"
  if [[ -n "${risk}" ]]; then
    repo_local_config_risk_count="$(printf '%s\n' "${risk}" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  fi

  local secret_hits
  secret_hits="$(grep -RIE --exclude-dir=.git --exclude='*.template' --exclude='*.md' \
    '(api[_-]?key|secret|token|password)[[:space:]]*=[[:space:]]*[^[:space:]#]+' "${REPO_ROOT}" || true)"
  if [[ -n "${secret_hits}" ]]; then
    repo_secret_risk_count="$(printf '%s\n' "${secret_hits}" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  fi
}

run_profile_show() {
  local role="$1"
  if ! command -v hermes >/dev/null 2>&1; then
    return 1
  fi
  local out
  out="$(hermes profile show "${role}" 2>&1 || true)"
  if printf '%s\n' "${out}" | grep -Eq "${role}|${REAL_PROFILE_ROOT}/${role}|profiles/${role}"; then
    return 0
  fi
  return 1
}

run_doctor() {
  local role="$1"
  if ! command -v hermes >/dev/null 2>&1; then
    return 1
  fi
  local out
  out="$(hermes -p "${role}" doctor 2>&1 || true)"
  if printf '%s\n' "${out}" | grep -Eq "Hermes Doctor" && \
     printf '%s\n' "${out}" | grep -Eq "SOUL.md exists|${REAL_PROFILE_ROOT}/${role}|profiles/${role}|config.yaml"; then
    return 0
  fi
  return 1
}

main() {
  print_header

  if [[ ! -f "${ROLE_FILE}" ]]; then
    echo "BLOCKED reason=missing_role_file path=${ROLE_FILE}"
    blocked_count=$((blocked_count + 1))
  fi

  scan_repo_risk

  if [[ -f "${ROLE_FILE}" ]]; then
    while IFS= read -r role || [[ -n "${role}" ]]; do
      role="${role%%#*}"
      role="$(printf '%s' "${role}" | xargs || true)"
      [[ -n "${role}" ]] || continue
      role_count=$((role_count + 1))

      local dest env_file config_file env_status config_status
      dest="${REAL_PROFILE_ROOT}/${role}"
      env_file="${dest}/.env"
      config_file="${dest}/config.yaml"

      echo
      echo "ROLE=${role}"
      echo "DESTINATION_DIR=${dest}"

      if [[ -f "${env_file}" ]]; then
        if has_placeholder_env "${env_file}"; then
          env_status="placeholder"
          placeholder_env_count=$((placeholder_env_count + 1))
        elif has_noncomment_assignment "${env_file}"; then
          env_status="manual_candidate"
          manual_env_candidate_count=$((manual_env_candidate_count + 1))
        else
          env_status="empty_or_comment_only"
          placeholder_env_count=$((placeholder_env_count + 1))
        fi
      else
        env_status="missing"
        missing_env_count=$((missing_env_count + 1))
      fi

      if [[ -f "${config_file}" ]]; then
        config_status="present"
      else
        config_status="missing"
        missing_config_count=$((missing_config_count + 1))
      fi

      echo "ENV_STATUS=${env_status}"
      echo "CONFIG_STATUS=${config_status}"
      echo "SECRET_VALUE_PRINTED=false"

      if run_profile_show "${role}"; then
        profile_show_pass_count=$((profile_show_pass_count + 1))
        echo "PROFILE_SHOW_STATUS=pass"
      else
        profile_show_fail_count=$((profile_show_fail_count + 1))
        echo "PROFILE_SHOW_STATUS=fail"
      fi

      if run_doctor "${role}"; then
        doctor_pass_count=$((doctor_pass_count + 1))
        echo "DOCTOR_STATUS=pass"
      else
        doctor_fail_count=$((doctor_fail_count + 1))
        echo "DOCTOR_STATUS=fail"
      fi
    done < "${ROLE_FILE}"
  fi

  echo
  echo "== Summary =="
  cat <<EOF
ROLE_COUNT=${role_count}
MISSING_ENV_COUNT=${missing_env_count}
MISSING_CONFIG_COUNT=${missing_config_count}
PLACEHOLDER_ENV_COUNT=${placeholder_env_count}
MANUAL_ENV_CANDIDATE_COUNT=${manual_env_candidate_count}
PROFILE_SHOW_PASS_COUNT=${profile_show_pass_count}
PROFILE_SHOW_FAIL_COUNT=${profile_show_fail_count}
DOCTOR_PASS_COUNT=${doctor_pass_count}
DOCTOR_FAIL_COUNT=${doctor_fail_count}
REPO_SECRET_RISK_COUNT=${repo_secret_risk_count}
REPO_LOCAL_CONFIG_RISK_COUNT=${repo_local_config_risk_count}
BLOCKED_COUNT=${blocked_count}
REAL_PROFILE_WRITE=${real_profile_write}
REAL_PROFILE_DELETE=${real_profile_delete}
SECRET_WRITE=${secret_write}
SECRET_READ_VALUE=${secret_read_value}
CONFIG_WRITE=${config_write}
ENV_WRITE=${env_write}
GATEWAY_START=${gateway_start}
CHAT_SMOKE=${chat_smoke}
EOF

  if [[ "${blocked_count}" -ne 0 || "${repo_secret_risk_count}" -ne 0 || "${repo_local_config_risk_count}" -ne 0 ]]; then
    echo "FAIL: post-secret runtime smoke blocked or repo risk detected"
    exit 1
  fi

  if [[ "${role_count}" -eq 6 && "${missing_env_count}" -eq 0 && "${missing_config_count}" -eq 0 && "${placeholder_env_count}" -eq 0 && "${manual_env_candidate_count}" -eq 6 && "${profile_show_pass_count}" -eq 6 && "${doctor_pass_count}" -eq 6 ]]; then
    echo "PASS: post-secret-fill runtime smoke completed in read-only mode"
    exit 0
  fi

  echo "PENDING: post-secret runtime smoke preconditions are not fully met yet"
  exit 0
}

main "$@"
