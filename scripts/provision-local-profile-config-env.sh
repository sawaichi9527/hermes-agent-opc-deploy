#!/usr/bin/env bash
set -euo pipefail

APPLY=false
CONFIRM=""
CONFIRM_TOKEN="REAL_PROVISION_LOCAL_CONFIG_ENV"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=true
      shift
      ;;
    --confirm)
      CONFIRM="${2:-}"
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
role_config="$repo_root/config/profile-roles.txt"
source_root="$repo_root/profiles"
real_profile_root="${HERMES_REAL_PROFILE_ROOT:-$HOME/.hermes/profiles}"

mode="dry-run"
real_apply="DISABLED"
if [[ "$APPLY" == "true" ]]; then
  mode="apply"
  if [[ "$CONFIRM" != "$CONFIRM_TOKEN" ]]; then
    echo "ERROR: guarded provisioning requires --confirm $CONFIRM_TOKEN" >&2
    echo "REAL_PROFILE_WRITE=false"
    echo "SECRET_WRITE=false"
    echo "CONFIG_WRITE=false"
    echo "ENV_WRITE=false"
    exit 3
  fi
  real_apply="GUARDED_APPLY_REQUESTED"
fi

role_count=0
env_create_candidate_count=0
config_create_candidate_count=0
env_created_count=0
config_created_count=0
env_existing_protected_count=0
config_existing_protected_count=0
source_env_template_missing_count=0
source_config_template_missing_count=0
missing_destination_count=0
blocked_count=0

printf '%s\n' "== OPC Hermes Local Config/Env Guarded Provisioning =="
printf 'Status: PHASE 3K-FIX.20 LOCAL-ONLY CONFIG/ENV GUARDED PROVISIONING\n'
printf 'Mode: %s\n' "$mode"
printf 'Real provisioning: %s\n' "$real_apply"
printf 'Repo root: %s\n' "$repo_root"
printf 'Role config: %s\n' "$role_config"
printf 'Source root: %s\n' "$source_root"
printf 'Real profile root: %s\n' "$real_profile_root"
printf 'Confirmation token required for apply: %s\n' "$CONFIRM_TOKEN"
if [[ "$APPLY" == "true" ]]; then
  echo "REAL_PROFILE_WRITE=true"
  echo "REAL_PROFILE_DELETE=false"
  echo "SECRET_WRITE=false"
  echo "CONFIG_WRITE=true"
  echo "ENV_WRITE=true"
else
  echo "REAL_PROFILE_WRITE=false"
  echo "REAL_PROFILE_DELETE=false"
  echo "SECRET_WRITE=false"
  echo "CONFIG_WRITE=false"
  echo "ENV_WRITE=false"
fi
echo "GATEWAY_START=false"
echo "CHAT_SMOKE=false"
echo

if [[ ! -f "$role_config" ]]; then
  echo "ERROR: missing role config: $role_config" >&2
  exit 4
fi

while IFS= read -r role || [[ -n "$role" ]]; do
  role="${role%%#*}"
  role="$(echo "$role" | xargs)"
  [[ -z "$role" ]] && continue
  role_count=$((role_count + 1))

  source_dir="$source_root/$role"
  dest_dir="$real_profile_root/$role"
  env_template="$source_dir/.env.template"
  config_template="$source_dir/config.yaml.template"
  env_dest="$dest_dir/.env"
  config_dest="$dest_dir/config.yaml"

  echo "ROLE=$role"
  echo "SOURCE_DIR=$source_dir"
  echo "DESTINATION_DIR=$dest_dir"

  if [[ ! -d "$dest_dir" ]]; then
    echo "ROLE_STATUS=MISSING_DESTINATION"
    missing_destination_count=$((missing_destination_count + 1))
    blocked_count=$((blocked_count + 1))
    echo
    continue
  fi

  role_blocked=false
  if [[ ! -f "$env_template" ]]; then
    echo "SOURCE_ENV_TEMPLATE_STATUS=missing"
    source_env_template_missing_count=$((source_env_template_missing_count + 1))
    role_blocked=true
  else
    echo "SOURCE_ENV_TEMPLATE_STATUS=present"
  fi

  if [[ ! -f "$config_template" ]]; then
    echo "SOURCE_CONFIG_TEMPLATE_STATUS=missing"
    source_config_template_missing_count=$((source_config_template_missing_count + 1))
    role_blocked=true
  else
    echo "SOURCE_CONFIG_TEMPLATE_STATUS=present"
  fi

  if [[ "$role_blocked" == "true" ]]; then
    echo "ROLE_STATUS=BLOCKED_TEMPLATE_MISSING"
    blocked_count=$((blocked_count + 1))
    echo
    continue
  fi

  echo "ROLE_STATUS=READY_FOR_LOCAL_PROVISIONING"

  if [[ -e "$env_dest" ]]; then
    echo "LOCAL_ONLY_PROTECTED role=$role path=.env status=present_no_overwrite"
    env_existing_protected_count=$((env_existing_protected_count + 1))
  else
    echo "LOCAL_PROVISIONING_CANDIDATE role=$role path=.env action=create_from_template placeholder_only"
    env_create_candidate_count=$((env_create_candidate_count + 1))
    if [[ "$APPLY" == "true" ]]; then
      cp "$env_template" "$env_dest"
      chmod 600 "$env_dest" || true
      echo "CREATED_LOCAL_ENV role=$role path=.env"
      env_created_count=$((env_created_count + 1))
    fi
  fi

  if [[ -e "$config_dest" ]]; then
    echo "LOCAL_ONLY_PROTECTED role=$role path=config.yaml status=present_no_overwrite"
    config_existing_protected_count=$((config_existing_protected_count + 1))
  else
    echo "LOCAL_PROVISIONING_CANDIDATE role=$role path=config.yaml action=create_from_template local_config"
    config_create_candidate_count=$((config_create_candidate_count + 1))
    if [[ "$APPLY" == "true" ]]; then
      cp "$config_template" "$config_dest"
      chmod 600 "$config_dest" || true
      echo "CREATED_LOCAL_CONFIG role=$role path=config.yaml"
      config_created_count=$((config_created_count + 1))
    fi
  fi

  echo "LOCAL_ONLY_PROTECTED role=$role path=memories/ status=no_touch"
  echo "LOCAL_ONLY_PROTECTED role=$role path=sessions/ status=no_touch"
  echo "LOCAL_ONLY_PROTECTED role=$role path=logs/ status=no_touch"
  echo "LOCAL_ONLY_PROTECTED role=$role path=skills/ status=no_touch"
  echo "LOCAL_ONLY_PROTECTED role=$role path=cron/ status=no_touch"
  echo "LOCAL_ONLY_PROTECTED role=$role path=state.db* status=no_touch"
  echo "LOCAL_ONLY_PROTECTED role=$role path=auth.json status=no_touch"
  echo "LOCAL_ONLY_PROTECTED role=$role path=gateway_state.json status=no_touch"
  echo
done < "$role_config"

write_candidate_count=$((env_create_candidate_count + config_create_candidate_count))
created_count=$((env_created_count + config_created_count))

printf '== Summary ==\n'
printf 'ROLE_COUNT=%s\n' "$role_count"
printf 'SOURCE_ENV_TEMPLATE_MISSING_COUNT=%s\n' "$source_env_template_missing_count"
printf 'SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=%s\n' "$source_config_template_missing_count"
printf 'MISSING_DESTINATION_COUNT=%s\n' "$missing_destination_count"
printf 'ENV_CREATE_CANDIDATE_COUNT=%s\n' "$env_create_candidate_count"
printf 'CONFIG_CREATE_CANDIDATE_COUNT=%s\n' "$config_create_candidate_count"
printf 'ENV_CREATED_COUNT=%s\n' "$env_created_count"
printf 'CONFIG_CREATED_COUNT=%s\n' "$config_created_count"
printf 'LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=%s\n' "$write_candidate_count"
printf 'LOCAL_PROVISIONING_CREATED_COUNT=%s\n' "$created_count"
printf 'ENV_EXISTING_PROTECTED_COUNT=%s\n' "$env_existing_protected_count"
printf 'CONFIG_EXISTING_PROTECTED_COUNT=%s\n' "$config_existing_protected_count"
printf 'BLOCKED_COUNT=%s\n' "$blocked_count"
if [[ "$APPLY" == "true" ]]; then
  echo "REAL_PROFILE_WRITE=true"
  echo "REAL_PROFILE_DELETE=false"
  echo "SECRET_WRITE=false"
  echo "CONFIG_WRITE=true"
  echo "ENV_WRITE=true"
else
  echo "REAL_PROFILE_WRITE=false"
  echo "REAL_PROFILE_DELETE=false"
  echo "SECRET_WRITE=false"
  echo "CONFIG_WRITE=false"
  echo "ENV_WRITE=false"
fi
echo "GATEWAY_START=false"
echo "CHAT_SMOKE=false"

if [[ "$blocked_count" -eq 0 ]]; then
  if [[ "$APPLY" == "true" ]]; then
    echo "PASS: local-only config/env guarded provisioning completed"
  else
    echo "PASS: local-only config/env guarded provisioning dry-run completed"
  fi
else
  echo "PARTIAL: local-only config/env guarded provisioning completed with blocked items"
fi
