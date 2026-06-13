#!/usr/bin/env bash
set -euo pipefail

# Phase 3K-FIX.21
# Read-only local secret manual fill readiness checker.
#
# This script never prints secret values. It only reports whether each local
# .env still appears to contain placeholders, appears manually filled, is
# missing, or contains unresolved template markers.

PHASE="PHASE 3K-FIX.21 LOCAL-ONLY SECRET MANUAL FILL READINESS REVIEW"
ROLE_FILE="config/profile-roles.txt"
SOURCE_ROOT="profiles"
REAL_PROFILE_ROOT="${HERMES_PROFILE_ROOT:-$HOME/.hermes/profiles}"

role_count=0
missing_destination_count=0
missing_env_count=0
missing_config_count=0
placeholder_env_count=0
manual_env_candidate_count=0
env_unresolved_marker_count=0
config_present_count=0
repo_secret_risk_count=0
repo_local_config_risk_count=0
blocked_count=0

placeholder_pattern='(__PLACEHOLDER__|PLACEHOLDER|CHANGE_ME|TODO|your_|example|dummy|REPLACE_ME|<.*>)'
secret_key_pattern='(TOKEN|SECRET|PASSWORD|PASS|KEY|API|AUTH|BEARER)'

printf '== OPC Hermes Local Secret Manual Fill Readiness ==\n'
printf 'Status: %s\n' "$PHASE"
printf 'Mode: read-only\n'
printf 'Repo root: %s\n' "$(pwd)"
printf 'Role config: %s\n' "$(pwd)/$ROLE_FILE"
printf 'Source root: %s\n' "$(pwd)/$SOURCE_ROOT"
printf 'Real profile root: %s\n' "$REAL_PROFILE_ROOT"
printf 'REAL_PROFILE_WRITE=false\n'
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n'
printf 'SECRET_READ_VALUE=false\n'
printf 'CONFIG_WRITE=false\n'
printf 'ENV_WRITE=false\n'
printf 'GATEWAY_START=false\n'
printf 'CHAT_SMOKE=false\n'
printf '\n'

if [[ ! -f "$ROLE_FILE" ]]; then
  printf 'BLOCKED reason=missing_role_file path=%s\n' "$ROLE_FILE"
  blocked_count=$((blocked_count + 1))
fi

# Repo-side guardrails: these files should not exist in repo profile sources.
while IFS= read -r repo_file; do
  [[ -z "$repo_file" ]] && continue
  case "$repo_file" in
    profiles/*/.env|profiles/*/.env.*|profiles/*/config.yaml)
      case "$repo_file" in
        *.template) ;;
        *)
          if [[ "$repo_file" == profiles/*/config.yaml ]]; then
            repo_local_config_risk_count=$((repo_local_config_risk_count + 1))
            printf 'REPO_LOCAL_CONFIG_RISK path=%s\n' "$repo_file"
          else
            repo_secret_risk_count=$((repo_secret_risk_count + 1))
            printf 'REPO_SECRET_RISK path=%s\n' "$repo_file"
          fi
          ;;
      esac
      ;;
  esac
done < <(find profiles -type f \( -name '.env' -o -name '.env.*' -o -name 'config.yaml' \) 2>/dev/null | sort || true)

printf '\n'

if [[ -f "$ROLE_FILE" ]]; then
  while IFS= read -r role || [[ -n "$role" ]]; do
    role="${role%%#*}"
    role="$(printf '%s' "$role" | xargs)"
    [[ -z "$role" ]] && continue

    role_count=$((role_count + 1))
    dest_dir="$REAL_PROFILE_ROOT/$role"
    env_file="$dest_dir/.env"
    config_file="$dest_dir/config.yaml"

    printf 'ROLE=%s\n' "$role"
    printf 'DESTINATION_DIR=%s\n' "$dest_dir"

    if [[ ! -d "$dest_dir" ]]; then
      printf 'ROLE_STATUS=BLOCKED_MISSING_DESTINATION\n'
      missing_destination_count=$((missing_destination_count + 1))
      blocked_count=$((blocked_count + 1))
      printf '\n'
      continue
    fi

    if [[ -f "$config_file" ]]; then
      config_present_count=$((config_present_count + 1))
      printf 'CONFIG_STATUS=present\n'
    else
      missing_config_count=$((missing_config_count + 1))
      printf 'CONFIG_STATUS=missing\n'
    fi

    if [[ ! -f "$env_file" ]]; then
      missing_env_count=$((missing_env_count + 1))
      printf 'ENV_STATUS=missing\n'
      printf 'SECRET_MANUAL_FILL_STATUS=not_ready_missing_env\n'
      printf '\n'
      continue
    fi

    # Never print values. Only classify lines and markers.
    if grep -Eiq "$placeholder_pattern" "$env_file"; then
      placeholder_env_count=$((placeholder_env_count + 1))
      printf 'ENV_STATUS=present_placeholder\n'
      printf 'SECRET_MANUAL_FILL_STATUS=needed\n'
    else
      if grep -Eiq "^[A-Z0-9_]*$secret_key_pattern[A-Z0-9_]*=" "$env_file"; then
        manual_env_candidate_count=$((manual_env_candidate_count + 1))
        printf 'ENV_STATUS=present_no_placeholder_secret_keys_detected\n'
        printf 'SECRET_MANUAL_FILL_STATUS=review_candidate_no_values_printed\n'
      else
        printf 'ENV_STATUS=present_no_placeholder_no_secret_key_detected\n'
        printf 'SECRET_MANUAL_FILL_STATUS=review_needed_no_values_printed\n'
      fi
    fi

    if grep -Eq '__[A-Z0-9_]+__|<[^>]+>' "$env_file"; then
      env_unresolved_marker_count=$((env_unresolved_marker_count + 1))
      printf 'ENV_UNRESOLVED_MARKER_STATUS=present\n'
    else
      printf 'ENV_UNRESOLVED_MARKER_STATUS=absent\n'
    fi

    printf '\n'
  done < "$ROLE_FILE"
fi

printf '== Summary ==\n'
printf 'ROLE_COUNT=%d\n' "$role_count"
printf 'CONFIG_PRESENT_COUNT=%d\n' "$config_present_count"
printf 'MISSING_CONFIG_COUNT=%d\n' "$missing_config_count"
printf 'MISSING_ENV_COUNT=%d\n' "$missing_env_count"
printf 'PLACEHOLDER_ENV_COUNT=%d\n' "$placeholder_env_count"
printf 'MANUAL_ENV_CANDIDATE_COUNT=%d\n' "$manual_env_candidate_count"
printf 'ENV_UNRESOLVED_MARKER_COUNT=%d\n' "$env_unresolved_marker_count"
printf 'REPO_SECRET_RISK_COUNT=%d\n' "$repo_secret_risk_count"
printf 'REPO_LOCAL_CONFIG_RISK_COUNT=%d\n' "$repo_local_config_risk_count"
printf 'MISSING_DESTINATION_COUNT=%d\n' "$missing_destination_count"
printf 'BLOCKED_COUNT=%d\n' "$blocked_count"
printf 'REAL_PROFILE_WRITE=false\n'
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n'
printf 'SECRET_READ_VALUE=false\n'
printf 'CONFIG_WRITE=false\n'
printf 'ENV_WRITE=false\n'
printf 'GATEWAY_START=false\n'
printf 'CHAT_SMOKE=false\n'

if [[ "$blocked_count" -eq 0 && "$repo_secret_risk_count" -eq 0 && "$repo_local_config_risk_count" -eq 0 && "$missing_env_count" -eq 0 && "$missing_config_count" -eq 0 ]]; then
  printf 'PASS: local-only secret manual fill readiness review completed in read-only mode\n'
else
  printf 'PARTIAL: local-only secret manual fill readiness review completed with expected or unresolved gaps\n'
fi
