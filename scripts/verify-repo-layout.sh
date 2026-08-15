#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ISSUES=0

print_header() {
  printf '\n== %s ==\n' "$1"
}

check_file() {
  local path="$1"
  if [ -f "$path" ]; then
    printf 'PASS file %s\n' "$path"
  else
    printf 'MISS file %s\n' "$path"
    ISSUES=$((ISSUES + 1))
  fi
}

check_dir() {
  local path="$1"
  if [ -d "$path" ]; then
    printf 'PASS dir  %s\n' "$path"
  else
    printf 'MISS dir  %s\n' "$path"
    ISSUES=$((ISSUES + 1))
  fi
}

check_syntax() {
  local path="$1"
  check_file "$path"
  if [ -f "$path" ]; then
    if bash -n "$path"; then
      printf 'PASS syntax %s\n' "$path"
    else
      printf 'FAIL syntax %s\n' "$path"
      ISSUES=$((ISSUES + 1))
    fi
  fi
}

check_forbidden() {
  local found=0

  while IFS= read -r path; do
    case "$path" in
      editions/*/profiles/*/.env.template)
        ;;

      archive/*/.env.template|archive/*/*/.env.template|archive/*/*/*/.env.template)
        ;;

      *.env|*.env.*|*/.env|*/.env.*|*.secret|*.secrets|*secrets*|*token*|*TOKEN*|*password*|*PASSWORD*)
        printf 'FAIL forbidden tracked path %s\n' "$path"
        found=1
        ;;
    esac
  done < <(git ls-files)

  if [ "$found" -eq 0 ]; then
    printf 'PASS no forbidden tracked runtime/secrets files\n'
  else
    ISSUES=$((ISSUES + 1))
  fi
}

check_edition_profiles() {
  local edition_dir="$1"
  shift
  local roles=("$@")
  local role

  print_header "Edition profiles: ${edition_dir##*/}"
  for role in "${roles[@]}"; do
    check_dir "${edition_dir}/profiles/${role}"
    check_file "${edition_dir}/profiles/${role}/SOUL.md.template"
  done
}

print_header "Repository root"
printf '%s\n' "$ROOT"

print_header "Required mainline files"
for f in \
  README.md \
  VERSION \
  docs/shared/guarded-apply-contract.md \
  docs/editions/generic \
  docs/editions/opc-personal \
  docs/editions/opc-personal/nim-researcher-moa-profile.md \
  docs/editions/opc-personal/aeon-builder-remote-endpoint.md \
  docs/editions/opc-personal/plur-memory-layer.md \
  docs/editions/opc-personal/a2a-expansion-pi5.md \
  docs/editions/opc-personal/observability-jobs-json.md \
  docs/editions/opc-personal/degradation-matrix.md \
  docs/editions/opc-personal/cron-governance.md \
  docs/editions/opc-personal/destruction-whitelist.md \
  editions/generic/roles.txt \
  editions/generic/config.yaml.example \
  editions/generic/README.md \
  editions/opc-personal/roles.txt \
  editions/opc-personal/config/rss_seeds.json.example \
  editions/opc-personal/README.md \
  archive/v0.16-v0.17/README.md \
  archive/v0.16-v0.17/validation-history/README.md
do
  if [ -d "$f" ]; then
    check_dir "$f"
  else
    check_file "$f"
  fi
done

print_header "Version"
if [ -f VERSION ]; then
  v="$(cat VERSION)"
  printf 'PASS VERSION=%s\n' "$v"
  if [ "$v" = "0.20.1" ]; then
    printf 'PASS VERSION matches 0.20.1\n'
  else
    printf 'FAIL VERSION is not 0.20.1\n'
    ISSUES=$((ISSUES + 1))
  fi
fi

check_edition_profiles editions/generic secretary coordinator researcher builder writer
check_edition_profiles editions/opc-personal secretary coordinator researcher writer builder runes-holder aeon-builder nim-researcher

print_header "Required current mainline scripts"
for s in \
  scripts/deploy-real-profiles.sh \
  scripts/verify-repo-layout.sh \
  scripts/verify-profile-templates.sh \
  scripts/set-local-model-name.sh \
  scripts/m0-capability-check.sh \
  scripts/setup-plur.sh \
  scripts/setup-feishu-gateway.sh \
  scripts/setup-nim-moa-profile.sh \
  scripts/jobs-json-init.sh \
  scripts/approvals-deny-init.sh \
  scripts/sync-soul-to-profiles.sh
do
  check_syntax "$s"
done

print_header "Forbidden tracked runtime/secrets check"
check_forbidden

print_header "Summary"
if [ "$ISSUES" -eq 0 ]; then
  printf 'PASS repository layout is valid.\n'
else
  printf 'FAIL repository layout has %s issue(s).\n' "$ISSUES"
  exit 1
fi
