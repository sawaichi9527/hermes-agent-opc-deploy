#!/usr/bin/env bash
set -euo pipefail

# Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning.
#
# This script is intentionally read-only. It plans a future guarded local
# provisioning step for real ~/.hermes/profiles/<role>/.env and config.yaml
# files, but never writes local secrets or real config files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROLE_CONFIG="$REPO_ROOT/config/profile-roles.txt"
SOURCE_ROOT="$REPO_ROOT/profiles"
REAL_PROFILE_ROOT="${HERMES_REAL_PROFILE_ROOT:-$HOME/.hermes/profiles}"
FUTURE_CONFIRM_TOKEN="REAL_PROVISION_LOCAL_CONFIG_ENV"

printf '%s\n' "== OPC Hermes Local-only Config/Env Provisioning Guarded Execution Planning =="
printf '%s\n' "Status: PHASE 3K-FIX.19 LOCAL-ONLY CONFIG/ENV GUARDED EXECUTION PLANNING ONLY"
printf '%s\n' "Mode: read-only"
printf '%s\n' "Repo root: $REPO_ROOT"
printf '%s\n' "Role config: $ROLE_CONFIG"
printf '%s\n' "Source root: $SOURCE_ROOT"
printf '%s\n' "Real profile root: $REAL_PROFILE_ROOT"
printf '%s\n' "Future confirmation token: $FUTURE_CONFIRM_TOKEN"
printf '%s\n' "REAL_PROFILE_WRITE=false"
printf '%s\n' "REAL_PROFILE_DELETE=false"
printf '%s\n' "SECRET_WRITE=false"
printf '%s\n' "CONFIG_WRITE=false"
printf '%s\n' "ENV_WRITE=false"
printf '%s\n' "GATEWAY_START=false"
printf '%s\n' "CHAT_SMOKE=false"
printf '%s\n' ""

if [[ ! -f "$ROLE_CONFIG" ]]; then
  printf '%s\n' "BLOCKED reason=missing_role_config path=$ROLE_CONFIG"
  printf '%s\n' "BLOCKED_COUNT=1"
  printf '%s\n' "REAL_PROFILE_WRITE=false"
  printf '%s\n' "REAL_PROFILE_DELETE=false"
  printf '%s\n' "SECRET_WRITE=false"
  printf '%s\n' "CONFIG_WRITE=false"
  printf '%s\n' "ENV_WRITE=false"
  printf '%s\n' "FAIL: missing role config"
  exit 1
fi

mapfile -t ROLES < <(grep -Ev '^\s*(#|$)' "$ROLE_CONFIG")

role_count=0
missing_source_env_template_count=0
missing_source_config_template_count=0
missing_destination_count=0
env_create_candidate_count=0
config_create_candidate_count=0
env_existing_protected_count=0
config_existing_protected_count=0
local_provisioning_write_candidate_count=0
blocked_count=0

for role in "${ROLES[@]}"; do
  role_count=$((role_count + 1))
  source_dir="$SOURCE_ROOT/$role"
  dest_dir="$REAL_PROFILE_ROOT/$role"
  env_template="$source_dir/.env.template"
  config_template="$source_dir/config.yaml.template"
  dest_env="$dest_dir/.env"
  dest_config="$dest_dir/config.yaml"

  printf '%s\n' "ROLE=$role"
  printf '%s\n' "SOURCE_DIR=$source_dir"
  printf '%s\n' "DESTINATION_DIR=$dest_dir"

  role_blocked=0
  if [[ ! -f "$env_template" ]]; then
    printf '%s\n' "MISSING_SOURCE role=$role path=.env.template"
    missing_source_env_template_count=$((missing_source_env_template_count + 1))
    role_blocked=1
  else
    printf '%s\n' "SOURCE_TEMPLATE_PRESENT role=$role path=.env.template"
  fi

  if [[ ! -f "$config_template" ]]; then
    printf '%s\n' "MISSING_SOURCE role=$role path=config.yaml.template"
    missing_source_config_template_count=$((missing_source_config_template_count + 1))
    role_blocked=1
  else
    printf '%s\n' "SOURCE_TEMPLATE_PRESENT role=$role path=config.yaml.template"
  fi

  if [[ ! -d "$dest_dir" ]]; then
    printf '%s\n' "MISSING_DESTINATION role=$role path=$dest_dir"
    missing_destination_count=$((missing_destination_count + 1))
    role_blocked=1
  else
    printf '%s\n' "DESTINATION_PRESENT role=$role"
  fi

  if [[ "$role_blocked" -ne 0 ]]; then
    blocked_count=$((blocked_count + 1))
    printf '%s\n' "ROLE_STATUS=BLOCKED"
    printf '%s\n' ""
    continue
  fi

  printf '%s\n' "ROLE_STATUS=READY_FOR_LOCAL_PROVISIONING_PLAN"

  if [[ -f "$dest_env" ]]; then
    printf '%s\n' "LOCAL_ONLY_PROTECTED role=$role path=.env status=present_no_overwrite"
    env_existing_protected_count=$((env_existing_protected_count + 1))
  else
    printf '%s\n' "LOCAL_PROVISIONING_CANDIDATE role=$role path=.env action=create_from_env_template"
    env_create_candidate_count=$((env_create_candidate_count + 1))
    local_provisioning_write_candidate_count=$((local_provisioning_write_candidate_count + 1))
  fi

  if [[ -f "$dest_config" ]]; then
    printf '%s\n' "LOCAL_ONLY_PROTECTED role=$role path=config.yaml status=present_no_overwrite"
    config_existing_protected_count=$((config_existing_protected_count + 1))
  else
    printf '%s\n' "LOCAL_PROVISIONING_CANDIDATE role=$role path=config.yaml action=create_from_config_template"
    config_create_candidate_count=$((config_create_candidate_count + 1))
    local_provisioning_write_candidate_count=$((local_provisioning_write_candidate_count + 1))
  fi

  printf '%s\n' "SECRET_POLICY role=$role path=.env status=placeholder_only_future_manual_secret_fill_required"
  printf '%s\n' "CONFIG_POLICY role=$role path=config.yaml status=create_only_no_overwrite_future_guarded"
  printf '%s\n' ""
done

printf '%s\n' "== Summary =="
printf '%s\n' "ROLE_COUNT=$role_count"
printf '%s\n' "SOURCE_ENV_TEMPLATE_MISSING_COUNT=$missing_source_env_template_count"
printf '%s\n' "SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=$missing_source_config_template_count"
printf '%s\n' "MISSING_DESTINATION_COUNT=$missing_destination_count"
printf '%s\n' "ENV_CREATE_CANDIDATE_COUNT=$env_create_candidate_count"
printf '%s\n' "CONFIG_CREATE_CANDIDATE_COUNT=$config_create_candidate_count"
printf '%s\n' "ENV_EXISTING_PROTECTED_COUNT=$env_existing_protected_count"
printf '%s\n' "CONFIG_EXISTING_PROTECTED_COUNT=$config_existing_protected_count"
printf '%s\n' "LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=$local_provisioning_write_candidate_count"
printf '%s\n' "BLOCKED_COUNT=$blocked_count"
printf '%s\n' "REAL_PROFILE_WRITE=false"
printf '%s\n' "REAL_PROFILE_DELETE=false"
printf '%s\n' "SECRET_WRITE=false"
printf '%s\n' "CONFIG_WRITE=false"
printf '%s\n' "ENV_WRITE=false"
printf '%s\n' "GATEWAY_START=false"
printf '%s\n' "CHAT_SMOKE=false"

if [[ "$blocked_count" -eq 0 ]]; then
  printf '%s\n' "PASS: local-only config/env guarded execution planning completed in read-only mode"
else
  printf '%s\n' "PARTIAL: local-only config/env guarded execution planning completed with blocked roles"
fi
