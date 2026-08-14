#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_HERMES="$ROOT/simulate_env/.hermes"
REAL_HERMES="${HERMES_HOME:-$HOME/.hermes}"
require_profiles=0

usage() {
  cat <<'USAGE'
Usage: scripts/verify-sim-layout.sh [options]

Options:
  --require-profiles   Treat simulated OPC profile directories and SOUL.md files as required.
  -h, --help           Show this help.

Default mode allows profile directories to be missing before scripts/deploy-sim-profiles.sh is run.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --require-profiles)
      require_profiles=1
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

fail_count=0

pass() {
  printf 'PASS %s\n' "$1"
}

miss() {
  printf 'MISS %s\n' "$1"
  fail_count=$((fail_count + 1))
}

warn() {
  printf 'WARN %s\n' "$1"
}

check_file() {
  local path="$1"
  if [ -f "$path" ]; then
    pass "$path"
  else
    miss "$path"
  fi
}

check_dir() {
  local path="$1"
  if [ -d "$path" ]; then
    pass "$path"
  else
    miss "$path"
  fi
}

check_profile_path() {
  local path="$1"
  if [ -e "$path" ]; then
    pass "$path"
  else
    if [ "$require_profiles" -eq 1 ]; then
      miss "$path"
    else
      warn "optional missing $path"
    fi
  fi
}

printf 'Simulated Hermes root: %s\n' "$SIM_HERMES"
printf 'Real Hermes root:      %s\n' "$REAL_HERMES"
printf 'Require profiles:      %s\n\n' "$require_profiles"

if [ "$SIM_HERMES" = "$REAL_HERMES" ]; then
  printf 'FAIL simulation path equals real Hermes path.\n' >&2
  exit 1
fi

case "$SIM_HERMES" in
  "$ROOT"/simulate_env/.hermes) ;;
  *)
    printf 'FAIL simulation path is outside expected repository path: %s\n' "$SIM_HERMES" >&2
    exit 1
    ;;
esac

printf '== Required simulation root files ==\n'
check_dir "$SIM_HERMES"
check_dir "$SIM_HERMES/profiles"
check_file "$SIM_HERMES/SOUL.md"
check_file "$SIM_HERMES/README.simulated-hermes-home.md"

printf '\n== Maintainer OPC profile directories ==\n'
profiles=(
  "secretary"
  "coordinator"
  "researcher"
  "writer"
  "builder"
  "runes-holder"
)
for profile in "${profiles[@]}"; do
  check_profile_path "$SIM_HERMES/profiles/$profile"
  check_profile_path "$SIM_HERMES/profiles/$profile/SOUL.md"
  if [ -d "$SIM_HERMES/profiles/$profile" ]; then
    check_profile_path "$SIM_HERMES/profiles/$profile/OPC_NOTES.md"
    check_profile_path "$SIM_HERMES/profiles/$profile/DEPLOYED_FROM.txt"
  fi
done

printf '\n== Forbidden simulation files inside git tracking ==\n'
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -t tracked_sim < <(git -C "$ROOT" ls-files 'simulate_env/*' || true)
  if [ "${#tracked_sim[@]}" -eq 0 ]; then
    pass "no tracked simulate_env files"
  else
    for path in "${tracked_sim[@]}"; do
      printf 'FAIL tracked simulation file %s\n' "$path"
      fail_count=$((fail_count + 1))
    done
  fi
else
  warn "not inside git work tree"
fi

printf '\n== Summary ==\n'
if [ "$fail_count" -eq 0 ]; then
  if [ "$require_profiles" -eq 1 ]; then
    printf 'PASS simulation layout is valid with deployed OPC profiles.\n'
  else
    printf 'PASS simulation layout is valid. Profile directories may remain optional until simulation deploy is implemented.\n'
  fi
  exit 0
fi

printf 'FAIL simulation layout has %s issue(s).\n' "$fail_count"
exit 1
