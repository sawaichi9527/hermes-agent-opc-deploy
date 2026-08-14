#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/home/eye/.hermes}"
PROFILES_DIR="$HERMES_HOME/profiles"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/hermes-backups}"
CREATE_BACKUP="${CREATE_BACKUP:-0}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_DIR:-$BACKUP_ROOT/preprod-profile-deploy-$STAMP}"

profiles=(
  "secretary"
  "coordinator"
  "researcher"
  "writer"
  "builder"
  "runes-holder"
)

print_header() {
  printf '\n== %s ==\n' "$1"
}

file_meta() {
  local path="$1"
  if [ -e "$path" ]; then
    if stat --version >/dev/null 2>&1; then
      stat -c 'META type=%F size=%s mtime=%y path=%n' "$path"
    else
      ls -ld "$path"
    fi
  else
    printf 'MISSING %s\n' "$path"
  fi
}

print_header "M8 guarded Hermes profile backup"
printf 'HERMES_HOME=%s\n' "$HERMES_HOME"
printf 'BACKUP_ROOT=%s\n' "$BACKUP_ROOT"
printf 'BACKUP_DIR=%s\n' "$BACKUP_DIR"
printf 'CREATE_BACKUP=%s\n' "$CREATE_BACKUP"

if [ ! -d "$PROFILES_DIR" ]; then
  printf 'ERROR missing profiles directory: %s\n' "$PROFILES_DIR" >&2
  exit 1
fi

print_header "Planned profile backup inputs"
for profile in "${profiles[@]}"; do
  profile_dir="$PROFILES_DIR/$profile"
  printf '\nProfile: %s\n' "$profile"
  file_meta "$profile_dir"
  for name in "SOUL.md" "NOTES.md" ".env" "config.yaml" "profile.yaml"; do
    file_meta "$profile_dir/$name"
  done
done

if [ "$CREATE_BACKUP" != "1" ]; then
  print_header "Dry-run only"
  printf 'No backup was created. Re-run with CREATE_BACKUP=1 to create the backup.\n'
  printf 'This script does not print file contents or secret values.\n'
  exit 0
fi

print_header "Creating backup"
mkdir -p "$BACKUP_DIR/profiles"

manifest="$BACKUP_DIR/manifest.txt"
{
  printf 'M8 Hermes profile backup\n'
  printf 'created_at=%s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
  printf 'hermes_home=%s\n' "$HERMES_HOME"
  printf 'profiles_dir=%s\n' "$PROFILES_DIR"
  printf 'backup_dir=%s\n' "$BACKUP_DIR"
  printf 'note=Backup may contain .env and private runtime files. Do not commit to git.\n'
} > "$manifest"

for profile in "${profiles[@]}"; do
  profile_dir="$PROFILES_DIR/$profile"
  if [ -d "$profile_dir" ]; then
    printf 'COPY %s -> %s\n' "$profile_dir" "$BACKUP_DIR/profiles/$profile"
    cp -a "$profile_dir" "$BACKUP_DIR/profiles/$profile"
    printf 'BACKED_UP %s\n' "$profile" >> "$manifest"
  else
    printf 'SKIP missing profile %s\n' "$profile"
    printf 'MISSING %s\n' "$profile" >> "$manifest"
  fi
done

print_header "Backup complete"
printf 'BACKUP_DIR=%s\n' "$BACKUP_DIR"
printf 'Manifest: %s\n' "$manifest"
printf 'Do not commit this backup directory to git or copy it into docs/wiki candidates.\n'
