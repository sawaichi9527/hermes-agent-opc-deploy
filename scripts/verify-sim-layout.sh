#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_HERMES="$ROOT/simulate_env/.hermes"
REAL_HERMES="${HERMES_HOME:-$HOME/.hermes}"

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

printf 'Simulated Hermes root: %s\n' "$SIM_HERMES"
printf 'Real Hermes root:      %s\n\n' "$REAL_HERMES"

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

printf '\n== Maintainer OPC profile directories, optional before simulation deploy ==\n'
profiles=(
  "secretary"
  "coordinator"
  "researcher"
  "writer"
  "builder"
  "runes-holder"
)
for profile in "${profiles[@]}"; do
  if [ -d "$SIM_HERMES/profiles/$profile" ]; then
    pass "$SIM_HERMES/profiles/$profile"
  else
    warn "optional missing $SIM_HERMES/profiles/$profile"
  fi
  if [ -f "$SIM_HERMES/profiles/$profile/SOUL.md" ]; then
    pass "$SIM_HERMES/profiles/$profile/SOUL.md"
  else
    warn "optional missing $SIM_HERMES/profiles/$profile/SOUL.md"
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
  printf 'PASS simulation layout is valid. Profile directories may remain optional until simulation deploy is implemented.\n'
  exit 0
fi

printf 'FAIL simulation layout has %s issue(s).\n' "$fail_count"
exit 1
