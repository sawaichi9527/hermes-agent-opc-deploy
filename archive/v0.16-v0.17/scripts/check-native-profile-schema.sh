#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLE_CONFIG="$REPO_ROOT/config/profile-roles.txt"
REAL_PROFILE_ROOT="${HERMES_PROFILE_ROOT:-$HOME/.hermes/profiles}"

if [[ ! -f "$ROLE_CONFIG" ]]; then
  echo "ERROR: role config missing: $ROLE_CONFIG" >&2
  exit 2
fi

mapfile -t ROLES < <(grep -Ev '^\s*(#|$)' "$ROLE_CONFIG")

missing_profile_dirs=0
missing_soul=0
missing_config=0
missing_env=0
missing_profile_yaml=0
missing_skills_dir=0
missing_alias=0
profile_show_missing_soul=0

printf '== OPC Hermes Native Profile Schema Check ==\n\n'
printf 'Status: PHASE 3K-FIX.12 NATIVE PROFILE SCHEMA ALIGNMENT CHECK\n'
printf 'Mode: read-only\n'
printf 'Repo root: %s\n' "$REPO_ROOT"
printf 'Role config: %s\n' "$ROLE_CONFIG"
printf 'Real profile root: %s\n' "$REAL_PROFILE_ROOT"
printf 'REAL_PROFILE_WRITE=false\n'
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n\n'

printf '== Canonical Roles ==\n'
printf 'ROLE_COUNT=%s\n' "${#ROLES[@]}"
for role in "${ROLES[@]}"; do
  printf 'ROLE=%s\n' "$role"
done
printf '\n'

printf '== Native Schema Signals ==\n'
printf 'Expected native profile signals checked by this script:\n'
printf -- '- profile directory exists under ~/.hermes/profiles/<role>\n'
printf -- '- SOUL.md exists\n'
printf -- '- config.yaml exists\n'
printf -- '- .env exists\n'
printf -- '- profile.yaml exists\n'
printf -- '- skills/ exists\n'
printf -- '- shell alias exists on PATH\n'
printf -- '- hermes profile show does not report SOUL.md: not configured\n\n'

for role in "${ROLES[@]}"; do
  dir="$REAL_PROFILE_ROOT/$role"
  printf '[%s]\n' "$role"
  printf '  profile_dir: %s\n' "$dir"

  if [[ -d "$dir" ]]; then
    printf '  profile_dir_status: found\n'
  else
    printf '  profile_dir_status: missing\n'
    missing_profile_dirs=$((missing_profile_dirs + 1))
    printf '\n'
    continue
  fi

  if [[ -f "$dir/SOUL.md" ]]; then
    printf '  soul_status: found\n'
  else
    printf '  soul_status: missing\n'
    missing_soul=$((missing_soul + 1))
  fi

  if [[ -f "$dir/config.yaml" ]]; then
    printf '  config_status: found\n'
  else
    printf '  config_status: missing\n'
    missing_config=$((missing_config + 1))
  fi

  if [[ -f "$dir/.env" ]]; then
    printf '  env_status: found\n'
  else
    printf '  env_status: missing\n'
    missing_env=$((missing_env + 1))
  fi

  if [[ -f "$dir/profile.yaml" ]]; then
    printf '  profile_yaml_status: found\n'
  else
    printf '  profile_yaml_status: missing\n'
    missing_profile_yaml=$((missing_profile_yaml + 1))
  fi

  if [[ -d "$dir/skills" ]]; then
    printf '  skills_dir_status: found\n'
  else
    printf '  skills_dir_status: missing\n'
    missing_skills_dir=$((missing_skills_dir + 1))
  fi

  if command -v "$role" >/dev/null 2>&1; then
    printf '  alias_status: found\n'
  else
    printf '  alias_status: missing\n'
    missing_alias=$((missing_alias + 1))
  fi

  if command -v hermes >/dev/null 2>&1; then
    show_output="$(hermes profile show "$role" 2>/dev/null || true)"
    if printf '%s\n' "$show_output" | grep -q 'SOUL.md: not configured'; then
      printf '  profile_show_soul_status: not_configured\n'
      profile_show_missing_soul=$((profile_show_missing_soul + 1))
    elif printf '%s\n' "$show_output" | grep -q 'SOUL.md:'; then
      printf '  profile_show_soul_status: configured_or_present\n'
    else
      printf '  profile_show_soul_status: unknown\n'
    fi
  else
    printf '  profile_show_soul_status: hermes_cli_unavailable\n'
  fi

  printf '\n'
done

printf '== Phase 3K-FIX.12 Summary ==\n'
printf 'MISSING_PROFILE_DIR_COUNT=%s\n' "$missing_profile_dirs"
printf 'MISSING_SOUL_COUNT=%s\n' "$missing_soul"
printf 'MISSING_CONFIG_COUNT=%s\n' "$missing_config"
printf 'MISSING_ENV_COUNT=%s\n' "$missing_env"
printf 'MISSING_PROFILE_YAML_COUNT=%s\n' "$missing_profile_yaml"
printf 'MISSING_SKILLS_DIR_COUNT=%s\n' "$missing_skills_dir"
printf 'MISSING_ALIAS_COUNT=%s\n' "$missing_alias"
printf 'PROFILE_SHOW_SOUL_NOT_CONFIGURED_COUNT=%s\n' "$profile_show_missing_soul"
printf 'REAL_PROFILE_WRITE=false\n'
printf 'REAL_PROFILE_DELETE=false\n'
printf 'SECRET_WRITE=false\n'

printf '\n== Phase 3K-FIX.12 Result ==\n'
if [[ "$missing_profile_dirs" -eq 0 && "$missing_soul" -eq 0 && "$missing_skills_dir" -eq 0 ]]; then
  printf 'PASS: native profile schema inspection completed\n'
else
  printf 'PARTIAL: native profile schema inspection completed with required runtime gaps\n'
fi

exit 0
