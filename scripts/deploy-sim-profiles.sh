#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM_HERMES="$ROOT/simulate_env/.hermes"
REAL_HERMES="${HERMES_HOME:-$HOME/.hermes}"

force=0
dry_run=0
clean=0

usage() {
  cat <<'USAGE'
Usage: scripts/deploy-sim-profiles.sh [options]

Deploy OPC profile SOUL templates into the repository-local simulated Hermes home:

  simulate_env/.hermes/profiles/<profile>/SOUL.md

This script never writes to real ~/.hermes.

Options:
  --dry-run       Show what would be created/copied without changing files.
  --force         Overwrite existing simulated profile SOUL.md files.
  --clean         Remove simulated OPC profile directories before deploying.
  -h, --help      Show this help.

Notes:
  - Default behavior is conservative: create missing files, skip changed existing SOUL.md.
  - Use --force only in simulate_env when you intentionally want templates to replace prior simulated edits.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --force|--overwrite)
      force=1
      ;;
    --clean)
      clean=1
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

say() {
  printf '%s\n' "$1"
}

run() {
  if [ "$dry_run" -eq 1 ]; then
    printf 'DRY-RUN %s\n' "$*"
  else
    "$@"
  fi
}

copy_file() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    printf 'ERROR missing template: %s\n' "$src" >&2
    return 1
  fi

  if [ -f "$dst" ]; then
    if cmp -s "$src" "$dst"; then
      printf 'PASS unchanged %s\n' "$dst"
      return 0
    fi

    if [ "$force" -eq 1 ]; then
      printf 'OVERWRITE %s\n' "$dst"
      run cp "$src" "$dst"
      return 0
    fi

    printf 'SKIP changed existing file %s\n' "$dst"
    printf '     use --force to overwrite simulated profile output\n'
    return 0
  fi

  printf 'CREATE %s\n' "$dst"
  run cp "$src" "$dst"
}

printf 'Repository root:      %s\n' "$ROOT"
printf 'Simulated Hermes root: %s\n' "$SIM_HERMES"
printf 'Real Hermes root:      %s\n\n' "$REAL_HERMES"

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

if [ "$clean" -eq 1 ]; then
  printf '== Clean simulated OPC profile directories ==\n'
  for profile in "${profiles[@]}"; do
    target="$SIM_HERMES/profiles/$profile"
    if [ -e "$target" ]; then
      printf 'REMOVE %s\n' "$target"
      run rm -rf "$target"
    else
      printf 'PASS absent %s\n' "$target"
    fi
  done
  printf '\n'
fi

printf '== Deploy simulated OPC profile SOUL templates ==\n'
run mkdir -p "$SIM_HERMES/profiles"

for profile in "${profiles[@]}"; do
  src="$ROOT/profiles/$profile/SOUL.md.template"
  profile_dir="$SIM_HERMES/profiles/$profile"
  dst="$profile_dir/SOUL.md"

  printf '\n-- %s --\n' "$profile"
  run mkdir -p "$profile_dir"
  copy_file "$src" "$dst"

  if [ -f "$ROOT/profiles/$profile/NOTES.md" ]; then
    notes_dst="$profile_dir/OPC_NOTES.md"
    copy_file "$ROOT/profiles/$profile/NOTES.md" "$notes_dst"
  fi

  manifest="$profile_dir/DEPLOYED_FROM.txt"
  if [ "$dry_run" -eq 1 ]; then
    printf 'DRY-RUN write %s\n' "$manifest"
  else
    cat > "$manifest" <<EOF
This simulated profile was deployed by hermes-agent-opc-deploy.

Source repository:
  $ROOT

Source templates:
  profiles/$profile/SOUL.md.template
  profiles/$profile/NOTES.md

Target:
  $profile_dir

This is simulation output only. Do not commit simulate_env/.
EOF
    printf 'WRITE %s\n' "$manifest"
  fi
done

printf '\n== Summary ==\n'
printf 'Simulation profile deployment completed.\n'
printf 'Next command:\n'
printf '  scripts/verify-sim-layout.sh --require-profiles\n'
