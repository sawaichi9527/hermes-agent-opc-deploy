#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_HERMES="$ROOT/simulate_env/.hermes"
REAL_HERMES="${HERMES_HOME:-$HOME/.hermes}"

show_diff=0
strict=0

usage() {
  cat <<'USAGE'
Usage: scripts/inspect-sim-profiles.sh [options]

Inspect repository-local simulated OPC profiles and compare deployed SOUL.md files
against repository templates.

This script is read-only and never writes to real ~/.hermes.

Options:
  --diff        Show unified diff for mismatched deployed SOUL.md files.
  --strict      Exit non-zero if any simulated SOUL.md differs from its template.
  -h, --help    Show this help.

Typical flow:
  scripts/prepare-sim-env.sh
  scripts/deploy-sim-profiles.sh --force
  scripts/inspect-sim-profiles.sh --strict
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --diff)
      show_diff=1
      ;;
    --strict)
      strict=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'ERROR unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

profiles=(
  "secretary"
  "coordinator"
  "researcher"
  "writer"
  "builder"
  "runes-holder"
)

fail_count=0
warn_count=0

pass() {
  printf 'PASS %s\n' "$1"
}

warn() {
  printf 'WARN %s\n' "$1"
  warn_count=$((warn_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1"
  fail_count=$((fail_count + 1))
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    printf 'unavailable'
  fi
}

printf 'Repository root:       %s\n' "$ROOT"
printf 'Simulated Hermes root: %s\n' "$SIM_HERMES"
printf 'Real Hermes root:      %s\n' "$REAL_HERMES"
printf 'Strict mode:           %s\n\n' "$strict"

if [ "$SIM_HERMES" = "$REAL_HERMES" ]; then
  printf 'ERROR simulation path equals real Hermes path. Refusing to continue.\n' >&2
  exit 1
fi

case "$SIM_HERMES" in
  "$ROOT"/simulate_env/.hermes) ;;
  *)
    printf 'ERROR simulation path is outside expected repository path: %s\n' "$SIM_HERMES" >&2
    exit 1
    ;;
esac

if [ ! -d "$SIM_HERMES" ]; then
  printf 'ERROR simulated Hermes home does not exist: %s\n' "$SIM_HERMES" >&2
  printf 'Run first: scripts/prepare-sim-env.sh\n' >&2
  exit 1
fi

printf '== Simulation profile inventory ==\n'
for profile in "${profiles[@]}"; do
  template="$ROOT/profiles/$profile/SOUL.md.template"
  notes_template="$ROOT/profiles/$profile/NOTES.md"
  profile_dir="$SIM_HERMES/profiles/$profile"
  deployed="$profile_dir/SOUL.md"
  notes_deployed="$profile_dir/OPC_NOTES.md"
  manifest="$profile_dir/DEPLOYED_FROM.txt"

  printf '\n-- %s --\n' "$profile"
  printf 'template:       profiles/%s/SOUL.md.template\n' "$profile"
  printf 'deployed:       simulate_env/.hermes/profiles/%s/SOUL.md\n' "$profile"

  if [ -d "$profile_dir" ]; then
    pass "profile dir exists"
  else
    fail "profile dir missing: $profile_dir"
    continue
  fi

  if [ -f "$template" ]; then
    pass "template exists"
  else
    fail "template missing: $template"
    continue
  fi

  if [ -f "$deployed" ]; then
    pass "deployed SOUL.md exists"
  else
    fail "deployed SOUL.md missing: $deployed"
    continue
  fi

  template_sha="$(sha256_file "$template")"
  deployed_sha="$(sha256_file "$deployed")"
  printf 'template sha256: %s\n' "$template_sha"
  printf 'deployed sha256: %s\n' "$deployed_sha"

  if cmp -s "$template" "$deployed"; then
    pass "deployed SOUL.md matches template"
  else
    if [ "$strict" -eq 1 ]; then
      fail "deployed SOUL.md differs from template"
    else
      warn "deployed SOUL.md differs from template"
    fi

    if [ "$show_diff" -eq 1 ]; then
      printf '\nDIFF profiles/%s/SOUL.md.template vs simulated SOUL.md\n' "$profile"
      diff -u "$template" "$deployed" || true
    fi
  fi

  if [ -f "$notes_template" ]; then
    if [ -f "$notes_deployed" ]; then
      if cmp -s "$notes_template" "$notes_deployed"; then
        pass "OPC_NOTES.md matches NOTES.md"
      else
        warn "OPC_NOTES.md differs from NOTES.md"
      fi
    else
      warn "OPC_NOTES.md missing"
    fi
  fi

  if [ -f "$manifest" ]; then
    pass "DEPLOYED_FROM.txt exists"
    printf 'manifest preview:\n'
    sed -n '1,12p' "$manifest" | sed 's/^/  /'
  else
    warn "DEPLOYED_FROM.txt missing"
  fi
done

printf '\n== Git tracking guard ==\n'
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -t tracked_sim_files < <(git ls-files 'simulate_env/*' || true)
  if [ "${#tracked_sim_files[@]}" -eq 0 ]; then
    pass "no tracked simulate_env files"
  else
    for path in "${tracked_sim_files[@]}"; do
      fail "tracked simulation output: $path"
    done
  fi
else
  warn "not inside git work tree"
fi

printf '\n== Summary ==\n'
if [ "$fail_count" -eq 0 ]; then
  printf 'PASS simulation profile inspection completed with %s warning(s).\n' "$warn_count"
  exit 0
fi

printf 'FAIL simulation profile inspection found %s issue(s) and %s warning(s).\n' "$fail_count" "$warn_count"
exit 1
