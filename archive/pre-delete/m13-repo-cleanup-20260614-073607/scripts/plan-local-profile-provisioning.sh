#!/usr/bin/env bash
set -euo pipefail

# Phase 3K-FIX.18 local-only config/env provisioning planner.
# Read-only: inspects repo templates and real profile local-only gaps.
# It never writes .env, config.yaml, secrets, auth files, runtime state, or profile data.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROLE_CONFIG="$REPO_ROOT/config/profile-roles.txt"
SOURCE_ROOT="$REPO_ROOT/profiles"
REAL_PROFILE_ROOT="${HERMES_PROFILE_ROOT:-$HOME/.hermes/profiles}"

if [[ ! -f "$ROLE_CONFIG" ]]; then
  echo "ERROR: role config missing: $ROLE_CONFIG" >&2
  exit 1
fi

echo "== OPC Hermes Local-only Profile Provisioning Plan =="
echo "Status: PHASE 3K-FIX.18 LOCAL-ONLY CONFIG/ENV PROVISIONING PLANNING ONLY"
echo "Mode: read-only"
echo "Repo root: $REPO_ROOT"
echo "Role config: $ROLE_CONFIG"
echo "Source root: $SOURCE_ROOT"
echo "Real profile root: $REAL_PROFILE_ROOT"
echo "REAL_PROFILE_WRITE=false"
echo "REAL_PROFILE_DELETE=false"
echo "SECRET_WRITE=false"
echo "CONFIG_WRITE=false"
echo "ENV_WRITE=false"
echo "GATEWAY_START=false"
echo "CHAT_SMOKE=false"
echo

role_count=0
missing_source_env_template_count=0
missing_source_config_template_count=0
missing_destination_count=0
real_env_present_count=0
missing_env_count=0
real_config_present_count=0
missing_config_count=0
profile_yaml_present_count=0
soul_present_count=0
local_provisioning_candidate_count=0
blocked_count=0

while IFS= read -r raw_role || [[ -n "$raw_role" ]]; do
  role="${raw_role%%#*}"
  role="$(echo "$role" | xargs)"
  [[ -z "$role" ]] && continue

  role_count=$((role_count + 1))
  src_dir="$SOURCE_ROOT/$role"
  dst_dir="$REAL_PROFILE_ROOT/$role"

  echo "ROLE=$role"
  echo "SOURCE_DIR=$src_dir"
  echo "DESTINATION_DIR=$dst_dir"

  role_blocked=0

  if [[ ! -d "$src_dir" ]]; then
    echo "ROLE_STATUS=BLOCKED_SOURCE_DIR_MISSING"
    blocked_count=$((blocked_count + 1))
    echo
    continue
  fi

  if [[ ! -d "$dst_dir" ]]; then
    echo "ROLE_STATUS=BLOCKED_DESTINATION_DIR_MISSING"
    missing_destination_count=$((missing_destination_count + 1))
    blocked_count=$((blocked_count + 1))
    echo
    continue
  fi

  if [[ -f "$src_dir/.env.template" ]]; then
    echo "SOURCE_TEMPLATE role=$role path=.env.template status=present"
  else
    echo "SOURCE_TEMPLATE role=$role path=.env.template status=missing"
    missing_source_env_template_count=$((missing_source_env_template_count + 1))
    role_blocked=1
  fi

  if [[ -f "$src_dir/config.yaml.template" ]]; then
    echo "SOURCE_TEMPLATE role=$role path=config.yaml.template status=present"
  else
    echo "SOURCE_TEMPLATE role=$role path=config.yaml.template status=missing"
    missing_source_config_template_count=$((missing_source_config_template_count + 1))
    role_blocked=1
  fi

  if [[ -f "$dst_dir/SOUL.md" ]]; then
    echo "RUNTIME_FILE role=$role path=SOUL.md status=present"
    soul_present_count=$((soul_present_count + 1))
  else
    echo "RUNTIME_FILE role=$role path=SOUL.md status=missing"
    role_blocked=1
  fi

  if [[ -f "$dst_dir/profile.yaml" ]]; then
    echo "RUNTIME_FILE role=$role path=profile.yaml status=present"
    profile_yaml_present_count=$((profile_yaml_present_count + 1))
  else
    echo "RUNTIME_FILE role=$role path=profile.yaml status=missing"
    role_blocked=1
  fi

  if [[ -f "$dst_dir/.env" ]]; then
    echo "LOCAL_ONLY_FILE role=$role path=.env status=present_no_touch"
    real_env_present_count=$((real_env_present_count + 1))
  else
    echo "LOCAL_PROVISIONING_CANDIDATE role=$role path=.env action=create_locally_from_env_template status=missing_expected"
    missing_env_count=$((missing_env_count + 1))
    local_provisioning_candidate_count=$((local_provisioning_candidate_count + 1))
  fi

  if [[ -f "$dst_dir/config.yaml" ]]; then
    echo "LOCAL_ONLY_FILE role=$role path=config.yaml status=present_no_touch"
    real_config_present_count=$((real_config_present_count + 1))
  else
    echo "LOCAL_PROVISIONING_CANDIDATE role=$role path=config.yaml action=create_locally_from_config_template status=missing_expected"
    missing_config_count=$((missing_config_count + 1))
    local_provisioning_candidate_count=$((local_provisioning_candidate_count + 1))
  fi

  for protected in auth.json state.db state.db-wal state.db-shm gateway.pid gateway_state.json processes.json; do
    if [[ -e "$dst_dir/$protected" ]]; then
      echo "LOCAL_ONLY_PROTECTED role=$role path=$protected status=present_no_touch"
    else
      echo "LOCAL_ONLY_PROTECTED role=$role path=$protected status=absent_no_create"
    fi
  done

  for protected_dir in memories sessions logs skills cron workspace home plans backups cache; do
    if [[ -d "$dst_dir/$protected_dir" ]]; then
      echo "LOCAL_ONLY_PROTECTED role=$role path=$protected_dir/ status=present_no_touch"
    else
      echo "LOCAL_ONLY_PROTECTED role=$role path=$protected_dir/ status=absent_no_create"
    fi
  done

  if [[ "$role_blocked" -eq 0 ]]; then
    echo "ROLE_STATUS=READY_FOR_LOCAL_PROVISIONING_PLANNING"
  else
    echo "ROLE_STATUS=BLOCKED_SCHEMA_INCOMPLETE"
    blocked_count=$((blocked_count + 1))
  fi

  echo
done < "$ROLE_CONFIG"

echo "== Summary =="
echo "ROLE_COUNT=$role_count"
echo "SOURCE_ENV_TEMPLATE_MISSING_COUNT=$missing_source_env_template_count"
echo "SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=$missing_source_config_template_count"
echo "MISSING_DESTINATION_COUNT=$missing_destination_count"
echo "SOUL_PRESENT_COUNT=$soul_present_count"
echo "PROFILE_YAML_PRESENT_COUNT=$profile_yaml_present_count"
echo "REAL_ENV_PRESENT_COUNT=$real_env_present_count"
echo "MISSING_ENV_COUNT=$missing_env_count"
echo "REAL_CONFIG_PRESENT_COUNT=$real_config_present_count"
echo "MISSING_CONFIG_COUNT=$missing_config_count"
echo "LOCAL_PROVISIONING_CANDIDATE_COUNT=$local_provisioning_candidate_count"
echo "BLOCKED_COUNT=$blocked_count"
echo "REAL_PROFILE_WRITE=false"
echo "REAL_PROFILE_DELETE=false"
echo "SECRET_WRITE=false"
echo "CONFIG_WRITE=false"
echo "ENV_WRITE=false"
echo "GATEWAY_START=false"
echo "CHAT_SMOKE=false"

if [[ "$role_count" -eq 6 \
  && "$missing_source_env_template_count" -eq 0 \
  && "$missing_source_config_template_count" -eq 0 \
  && "$missing_destination_count" -eq 0 \
  && "$soul_present_count" -eq 6 \
  && "$profile_yaml_present_count" -eq 6 \
  && "$blocked_count" -eq 0 ]]; then
  echo "PASS: local-only config/env provisioning planning completed in read-only mode"
else
  echo "PARTIAL: local-only config/env provisioning planning completed with unresolved gaps"
fi
