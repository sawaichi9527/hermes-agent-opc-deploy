#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/home/eye/.hermes}"
PROFILES_DIR="$HERMES_HOME/profiles"

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

path_status() {
  local path="$1"
  if [ -e "$path" ]; then
    printf 'PRESENT %s\n' "$path"
  else
    printf 'MISSING %s\n' "$path"
  fi
}

file_meta() {
  local path="$1"
  if [ -e "$path" ]; then
    # Read-only metadata only. Do not print file contents.
    if stat --version >/dev/null 2>&1; then
      stat -c 'META type=%F size=%s mtime=%y path=%n' "$path"
    else
      # Fallback for non-GNU stat, kept simple.
      ls -ld "$path"
    fi
  fi
}

list_if_dir() {
  local label="$1"
  local path="$2"
  print_header "$label"
  if [ -d "$path" ]; then
    find "$path" -maxdepth 2 -mindepth 1 -printf '%y size=%s mtime=%TY-%Tm-%Td %TH:%TM path=%p\n' 2>/dev/null | sort || true
  else
    printf 'SKIP not a directory: %s\n' "$path"
  fi
}

classify_profile_paths() {
  local profile_dir="$1"
  print_header "Classification hints"

  printf 'Preserve candidates:\n'
  for name in "SOUL.md" "NOTES.md" ".env" "config.yaml" "distribution.yaml" "profile.yaml" "metadata.json"; do
    if [ -e "$profile_dir/$name" ]; then
      printf '  PRESERVE %s\n' "$profile_dir/$name"
    fi
  done

  printf 'Cleanup candidates after backup:\n'
  find "$profile_dir" -maxdepth 3 \
    \( -iname '*session*' -o -iname '*history*' -o -iname '*cache*' -o -iname '*log*' -o -iname '*tmp*' -o -iname '*kanban*' -o -iname '*task*' -o -iname '*memory*' \) \
    -printf '  REVIEW %p\n' 2>/dev/null | sort || true

  printf 'Defer unknown databases/state:\n'
  find "$profile_dir" -maxdepth 3 \
    \( -iname '*.db' -o -iname '*.sqlite' -o -iname '*.sqlite3' -o -iname '*state*' \) \
    -printf '  DEFER %p\n' 2>/dev/null | sort || true
}

print_header "M6 read-only Hermes profile runtime inspection"
printf 'HERMES_HOME=%s\n' "$HERMES_HOME"
printf 'Mode=read-only metadata inspection; no file contents are printed; no changes are made.\n'

print_header "Root"
path_status "$HERMES_HOME"
file_meta "$HERMES_HOME"
path_status "$PROFILES_DIR"
file_meta "$PROFILES_DIR"

for profile in "${profiles[@]}"; do
  profile_dir="$PROFILES_DIR/$profile"
  print_header "Profile: $profile"
  path_status "$profile_dir"
  file_meta "$profile_dir"

  if [ ! -d "$profile_dir" ]; then
    continue
  fi

  print_header "Core files: $profile"
  for name in "SOUL.md" "NOTES.md" ".env" "config.yaml" "distribution.yaml" "profile.yaml" "metadata.json"; do
    path="$profile_dir/$name"
    path_status "$path"
    file_meta "$path"
  done

  list_if_dir "Top-level runtime entries: $profile" "$profile_dir"
  classify_profile_paths "$profile_dir"
done

print_header "Global Hermes runtime hints"
for name in "sessions" "logs" "cache" "state" "kanban" "memory" "gateways" "tools" "skills"; do
  path="$HERMES_HOME/$name"
  path_status "$path"
  file_meta "$path"
  if [ -d "$path" ]; then
    find "$path" -maxdepth 2 -mindepth 1 -printf '%y size=%s mtime=%TY-%Tm-%Td %TH:%TM path=%p\n' 2>/dev/null | sort || true
  fi
done

print_header "Final note"
printf 'This script is inspection-only. Review docs/pre-production-profile-maintenance.md before any real cleanup.\n'
printf 'Do not commit runtime backups, secrets, .env values, session dumps, caches, logs, or databases to this repository.\n'
