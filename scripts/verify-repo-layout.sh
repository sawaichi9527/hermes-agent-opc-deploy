#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail_count=0

pass() {
  printf 'PASS %s\n' "$1"
}

miss() {
  printf 'MISS %s\n' "$1"
  fail_count=$((fail_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1"
  fail_count=$((fail_count + 1))
}

check_file() {
  local path="$1"
  if [ -f "$path" ]; then
    pass "file $path"
  else
    miss "file $path"
  fi
}

check_dir() {
  local path="$1"
  if [ -d "$path" ]; then
    pass "dir  $path"
  else
    miss "dir  $path"
  fi
}

printf 'Repository root: %s\n\n' "$ROOT"

printf '== Required documentation ==\n'
required_docs=(
  "README.md"
  "docs/architecture.md"
  "docs/compatibility-matrix.md"
  "docs/deployment.md"
  "docs/developer-local-workflow.md"
  "docs/implementation-roadmap.md"
  "docs/local-openai-compatible-provider.md"
  "docs/verification-phase-3l-local-provider.md"
  "docs/phase-3l5-local-model-name-cleanup.md"
  "docs/phase-3m-runtime-readiness.md"
  "docs/phase-3n-profile-invocation.md"
  "docs/runtime-baseline.md"
  "docs/local-runtime-runbook.md"
  "docs/maintenance-policy.md"
  "docs/migration.md"
  "docs/model-routing-policy.md"
  "docs/consult-subagent-upgrade-policy.md"
  "docs/deploy-reset-policy.md"
  "docs/opc-gap-analysis.md"
  "docs/profile-interaction-loop.md"
  "docs/profile-language-policy.md"
  "docs/runes-holder.md"
  "docs/secretary-profile.md"
  "docs/simulation-and-deploy-policy.md"
  "docs/simulation-runbook.md"
)
for path in "${required_docs[@]}"; do
  check_file "$path"
done

printf '\n== Required profile template notes ==\n'
required_profiles=(
  "secretary"
  "coordinator"
  "researcher"
  "writer"
  "builder"
  "runes-holder"
)
for profile in "${required_profiles[@]}"; do
  check_dir "profiles/$profile"
  check_file "profiles/$profile/NOTES.md"
  check_file "profiles/$profile/SOUL.md.template"
done
check_file "profiles/README.md"

printf '\n== Required scripts ==\n'
required_scripts=(
  "scripts/verify-layout.sh"
  "scripts/verify-repo-layout.sh"
  "scripts/verify-profile-templates.sh"
  "scripts/prepare-sim-env.sh"
  "scripts/deploy-sim-profiles.sh"
  "scripts/inspect-sim-profiles.sh"
  "scripts/verify-sim-layout.sh"
  "scripts/smoke-local-provider-sequential.sh"
  "scripts/set-local-model-name.sh"
  "scripts/check-hermes-runtime-readiness.sh"
  "scripts/smoke-hermes-runtime-oneshot.sh"
  "scripts/check-runtime-baseline.sh"
)
for path in "${required_scripts[@]}"; do
  check_file "$path"
  if [ -f "$path" ]; then
    if bash -n "$path"; then
      pass "syntax $path"
    else
      fail "syntax $path"
    fi
  fi
done

printf '\n== Forbidden tracked runtime/secrets check ==\n'
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Trackable environment templates are allowed as documentation/configuration examples.
  # Real local runtime env files remain forbidden, including `.env`, `.env.local`,
  # `.env.production`, and other non-template `.env.*` files.
  forbidden_regex='(^|/)(\.env($|\.)|secrets/|credentials/|sessions/|logs/|cache/|state/|simulate_env/)|\.(db|sqlite|sqlite3)(-|$|\.)|\.db-(wal|shm)$|\.sqlite-(wal|shm)$|\.sqlite3-(wal|shm)$'
  allowed_env_template_regex='(^|/)\.env\.template$'
  mapfile -t forbidden_files < <(
    git ls-files \
      | grep -E "$forbidden_regex" \
      | grep -Ev "$allowed_env_template_regex" \
      || true
  )
  if [ "${#forbidden_files[@]}" -eq 0 ]; then
    pass "no forbidden tracked runtime/secrets files"
  else
    for path in "${forbidden_files[@]}"; do
      fail "forbidden tracked file $path"
    done
  fi
else
  printf 'SKIP not inside git work tree\n'
fi

printf '\n== Summary ==\n'
if [ "$fail_count" -eq 0 ]; then
  printf 'PASS repository layout is valid.\n'
  exit 0
fi

printf 'FAIL repository layout has %s issue(s).\n' "$fail_count"
exit 1
