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
      profiles/*/.env.template)
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

print_header "Repository root"
printf '%s\n' "$ROOT"

print_header "Required mainline documentation"
for f in \
  README.md \
  docs/implementation-roadmap.md \
  docs/opc-profile-set-design.md \
  docs/local-compute-policy.md \
  docs/runes-holder-boundary.md \
  docs/hermes-native-profile-usage.md \
  docs/soul-template-convention.md \
  docs/local-openai-compatible-provider.md \
  docs/maintenance-policy.md \
  docs/migration.md \
  docs/model-routing-policy.md \
  docs/profile-language-policy.md \
  docs/runes-holder.md \
  docs/secretary-profile.md \
  docs/verification-m12-native-opc-runtime-baseline.md \
  archive/validation-history/README.md
do
  check_file "$f"
done

print_header "Required profile template notes"
for p in secretary coordinator researcher writer builder runes-holder; do
  check_dir "profiles/$p"
  check_file "profiles/$p/NOTES.md"
  check_file "profiles/$p/SOUL.md.template"
  check_file "profiles/$p/profile.yaml"
  check_file "profiles/$p/README.md"
done
check_file "profiles/README.md"

print_header "Required current mainline scripts"
for s in \
  scripts/verify-layout.sh \
  scripts/verify-repo-layout.sh \
  scripts/verify-profile-templates.sh \
  scripts/verify-m12-native-opc-runtime-baseline.sh \
  scripts/apply-secretary-runtime-doc-overlay.sh \
  scripts/apply-coordinator-runtime-doc-overlay.sh \
  scripts/apply-researcher-runtime-doc-overlay.sh \
  scripts/apply-writer-runtime-doc-overlay.sh \
  scripts/apply-builder-runtime-doc-overlay.sh \
  scripts/apply-runes-holder-runtime-doc-overlay.sh \
  scripts/create-coordinator-profile-clone.sh \
  scripts/create-researcher-profile-clone.sh \
  scripts/create-writer-profile-clone.sh \
  scripts/create-builder-profile-clone.sh \
  scripts/create-runes-holder-profile-clone.sh
do
  check_syntax "$s"
done

print_header "Optional historical / regression scripts"
for s in \
  scripts/prepare-sim-env.sh \
  scripts/deploy-sim-profiles.sh \
  scripts/inspect-sim-profiles.sh \
  scripts/verify-sim-layout.sh \
  scripts/smoke-local-provider-sequential.sh \
  scripts/set-local-model-name.sh \
  scripts/check-hermes-runtime-readiness.sh \
  scripts/smoke-hermes-runtime-oneshot.sh \
  scripts/check-runtime-baseline.sh \
  scripts/backup-hermes-profiles.sh \
  scripts/check-native-profile-runtime-smoke.sh \
  scripts/check-native-profile-schema.sh \
  scripts/check-native-profile-source-templates.sh \
  scripts/inspect-profile-runtime-state.sh \
  scripts/cleanup-drift-profiles.sh \
  scripts/plan-drift-profile-cleanup.sh \
  scripts/plan-repo-drift-source-cleanup.sh
do
  if [ -f "$s" ]; then
    printf 'PASS optional file %s\n' "$s"
    if bash -n "$s"; then
      printf 'PASS optional syntax %s\n' "$s"
    else
      printf 'FAIL optional syntax %s\n' "$s"
      ISSUES=$((ISSUES + 1))
    fi
  else
    printf 'SKIP optional missing %s\n' "$s"
  fi
done

print_header "M13 archive staging"
if find archive/pre-delete -maxdepth 3 -type f -name MANIFEST.md 2>/dev/null | grep -q .; then
  find archive/pre-delete -maxdepth 3 -type f -name MANIFEST.md | sort | while read -r f; do
    printf 'PASS archive manifest %s\n' "$f"
  done
else
  printf 'MISS archive/pre-delete/*/MANIFEST.md\n'
  ISSUES=$((ISSUES + 1))
fi

print_header "Forbidden tracked runtime/secrets check"
check_forbidden

print_header "Summary"
if [ "$ISSUES" -eq 0 ]; then
  printf 'PASS repository layout is valid.\n'
else
  printf 'FAIL repository layout has %s issue(s).\n' "$ISSUES"
  exit 1
fi
