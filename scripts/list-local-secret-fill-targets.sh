#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE_FILE="$REPO_ROOT/config/profile-roles.txt"
REAL_PROFILE_ROOT="${HERMES_PROFILE_ROOT:-$HOME/.hermes/profiles}"

role_count=0
missing_env_count=0
missing_config_count=0
placeholder_env_count=0
manual_candidate_count=0
blocked_count=0
repo_secret_risk_count=0
repo_local_config_risk_count=0

printf '%s\n' '== OPC Hermes Phase 3L.1 Local Secret Manual Fill Targets =='
printf '%s\n' 'Status: PHASE 3L.1 LOCAL SECRET ACTIVATION CHECKLIST'
printf '%s\n' 'Mode: read-only'
printf 'Repo root: %s\n' "$REPO_ROOT"
printf 'Role config: %s\n' "$ROLE_FILE"
printf 'Real profile root: %s\n' "$REAL_PROFILE_ROOT"
printf '%s\n' 'REAL_PROFILE_WRITE=false'
printf '%s\n' 'REAL_PROFILE_DELETE=false'
printf '%s\n' 'SECRET_WRITE=false'
printf '%s\n' 'SECRET_READ_VALUE=false'
printf '%s\n' 'CONFIG_WRITE=false'
printf '%s\n' 'ENV_WRITE=false'
printf '%s\n' 'GATEWAY_START=false'
printf '%s\n' 'CHAT_SMOKE=false'
printf '\n'

if [[ ! -f "$ROLE_FILE" ]]; then
  printf 'BLOCKED role_config_missing path=%s\n' "$ROLE_FILE"
  blocked_count=$((blocked_count + 1))
else
  while IFS= read -r role || [[ -n "$role" ]]; do
    [[ -z "$role" ]] && continue
    [[ "$role" =~ ^# ]] && continue
    role_count=$((role_count + 1))
    dest_dir="$REAL_PROFILE_ROOT/$role"
    env_file="$dest_dir/.env"
    config_file="$dest_dir/config.yaml"

    printf 'ROLE=%s\n' "$role"
    printf 'ENV_FILE=%s\n' "$env_file"
    printf 'CONFIG_FILE=%s\n' "$config_file"

    if [[ -f "$env_file" ]]; then
      printf 'ENV_STATUS=present\n'
      if grep -Eq 'PLACEHOLDER|TODO|REPLACE_ME|CHANGE_ME|INSERT_|FILL_ME|dummy|example' "$env_file"; then
        printf 'ENV_SECRET_STATUS=placeholder_review_required\n'
        placeholder_env_count=$((placeholder_env_count + 1))
      else
        printf 'ENV_SECRET_STATUS=manual_candidate_no_value_printed\n'
        manual_candidate_count=$((manual_candidate_count + 1))
      fi
    else
      printf 'ENV_STATUS=missing\n'
      missing_env_count=$((missing_env_count + 1))
    fi

    if [[ -f "$config_file" ]]; then
      printf 'CONFIG_STATUS=present\n'
    else
      printf 'CONFIG_STATUS=missing\n'
      missing_config_count=$((missing_config_count + 1))
    fi

    printf 'MANUAL_ACTION role=%s file=.env action=edit_locally_only tool=vi secret_value_print=false\n' "$role"
    printf 'MANUAL_ACTION role=%s file=config.yaml action=review_locally_only tool=vi secret_value_print=false\n' "$role"
    printf 'VERIFY_AFTER_FILL role=%s command="bash scripts/check-post-secret-fill-readiness.sh"\n' "$role"
    printf '\n'
  done < "$ROLE_FILE"
fi

# Repo risk guard: only templates are allowed. Real profile-local .env/config.yaml files must never be committed.
while IFS= read -r tracked; do
  case "$tracked" in
    *.env|*/.env|.env)
      repo_secret_risk_count=$((repo_secret_risk_count + 1))
      printf 'REPO_SECRET_RISK path=%s\n' "$tracked"
      ;;
    profiles/*/config.yaml)
      repo_local_config_risk_count=$((repo_local_config_risk_count + 1))
      printf 'REPO_LOCAL_CONFIG_RISK path=%s\n' "$tracked"
      ;;
  esac
done < <(cd "$REPO_ROOT" && git ls-files)

printf '== Summary ==\n'
printf 'ROLE_COUNT=%s\n' "$role_count"
printf 'MISSING_ENV_COUNT=%s\n' "$missing_env_count"
printf 'MISSING_CONFIG_COUNT=%s\n' "$missing_config_count"
printf 'PLACEHOLDER_ENV_COUNT=%s\n' "$placeholder_env_count"
printf 'MANUAL_ENV_CANDIDATE_COUNT=%s\n' "$manual_candidate_count"
printf 'REPO_SECRET_RISK_COUNT=%s\n' "$repo_secret_risk_count"
printf 'REPO_LOCAL_CONFIG_RISK_COUNT=%s\n' "$repo_local_config_risk_count"
printf 'BLOCKED_COUNT=%s\n' "$blocked_count"
printf '%s\n' 'REAL_PROFILE_WRITE=false'
printf '%s\n' 'REAL_PROFILE_DELETE=false'
printf '%s\n' 'SECRET_WRITE=false'
printf '%s\n' 'SECRET_READ_VALUE=false'
printf '%s\n' 'CONFIG_WRITE=false'
printf '%s\n' 'ENV_WRITE=false'
printf '%s\n' 'GATEWAY_START=false'
printf '%s\n' 'CHAT_SMOKE=false'

if [[ "$blocked_count" -eq 0 && "$repo_secret_risk_count" -eq 0 && "$repo_local_config_risk_count" -eq 0 ]]; then
  printf '%s\n' 'PASS: local secret manual fill target review completed in read-only mode'
else
  printf '%s\n' 'FAIL: local secret manual fill target review found blockers'
  exit 1
fi
