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
missing_destination_count=0
missing_env_count=0
missing_config_count=0
placeholder_env_count=0
manual_env_candidate_count=0
repo_secret_risk_count=0
repo_local_config_risk_count=0
blocked_count=0

placeholder_patterns=(
  "CHANGEME"
  "CHANGE_ME"
  "PLACEHOLDER"
  "TODO"
  "REPLACE_ME"
  "example"
  "dummy"
  "not-set"
  "not_set"
  "your_"
  "local-placeholder"
)

has_placeholder_env() {
  local file="$1"
  local pattern
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
== OPC Hermes Post-secret Fill Runtime Readiness Check ==
Status: PHASE 3K-FIX.23 POST-SECRET-FILL RUNTIME READINESS CHECK
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
    while IFS= read -r _line; do
      [[ -n "${_line}" ]] || continue
      case "${_line}" in
        */profiles/*/.env|*/profiles/*/config.yaml|*/.env|*/config.yaml)
          repo_local_config_risk_count=$((repo_local_config_risk_count + 1))
          ;;
      esac
    done <<< "${risk}"
  fi

  local secret_hits
  secret_hits="$(grep -RIE --exclude-dir=.git --exclude='*.template' --exclude='*.md' \
    '(api[_-]?key|secret|token|password)[[:space:]]*=[[:space:]]*[^[:space:]#]+' "${REPO_ROOT}" || true)"
  if [[ -n "${secret_hits}" ]]; then
    repo_secret_risk_count="$(printf '%s\n' "${secret_hits}" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
  fi
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

      if [[ ! -d "${dest}" ]]; then
        echo "DESTINATION_STATUS=missing"
        missing_destination_count=$((missing_destination_count + 1))
        continue
      fi
      echo "DESTINATION_STATUS=present"

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
    done < "${ROLE_FILE}"
  fi

  echo
  echo "== Summary =="
  cat <<EOF
ROLE_COUNT=${role_count}
MISSING_DESTINATION_COUNT=${missing_destination_count}
MISSING_ENV_COUNT=${missing_env_count}
MISSING_CONFIG_COUNT=${missing_config_count}
PLACEHOLDER_ENV_COUNT=${placeholder_env_count}
MANUAL_ENV_CANDIDATE_COUNT=${manual_env_candidate_count}
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
    echo "FAIL: post-secret readiness review blocked or repo risk detected"
    exit 1
  fi

  if [[ "${missing_destination_count}" -eq 0 && "${missing_env_count}" -eq 0 && "${missing_config_count}" -eq 0 && "${manual_env_candidate_count}" -eq "${role_count}" && "${placeholder_env_count}" -eq 0 ]]; then
    echo "PASS: post-secret-fill runtime readiness review completed in read-only mode"
    exit 0
  fi

  echo "PENDING: manual secret fill not complete yet; placeholders still present or manual candidates incomplete"
  exit 0
}

main "$@"
