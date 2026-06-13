#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-/home/eye/.hermes}"
PROFILES_DIR="$HERMES_HOME/profiles"
SECRETARY_DIR="$PROFILES_DIR/secretary"
TEMPLATE="$ROOT/profiles/secretary/SOUL.md.template"
RUNTIME_SOUL="$SECRETARY_DIR/SOUL.md"
APPLY_SECRETARY_SOUL="${APPLY_SECRETARY_SOUL:-0}"
BACKUP_DIR="${BACKUP_DIR:-}"

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

file_hash() {
  local path="$1"
  if [ -f "$path" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$path" | awk '{print "SHA256 " $1 " " $2}'
    else
      shasum -a 256 "$path" | awk '{print "SHA256 " $1 " " $2}'
    fi
  fi
}

print_header "M8 guarded secretary SOUL.md apply"
printf 'Repository root=%s\n' "$ROOT"
printf 'HERMES_HOME=%s\n' "$HERMES_HOME"
printf 'TEMPLATE=%s\n' "$TEMPLATE"
printf 'RUNTIME_SOUL=%s\n' "$RUNTIME_SOUL"
printf 'APPLY_SECRETARY_SOUL=%s\n' "$APPLY_SECRETARY_SOUL"
if [ -n "$BACKUP_DIR" ]; then
  printf 'BACKUP_DIR=%s\n' "$BACKUP_DIR"
fi

print_header "Preflight metadata"
file_meta "$TEMPLATE"
file_meta "$SECRETARY_DIR"
file_meta "$RUNTIME_SOUL"
file_hash "$TEMPLATE"
file_hash "$RUNTIME_SOUL"

if [ ! -f "$TEMPLATE" ]; then
  printf 'ERROR missing repository secretary template: %s\n' "$TEMPLATE" >&2
  exit 1
fi

if [ ! -d "$SECRETARY_DIR" ]; then
  printf 'ERROR missing runtime secretary profile directory: %s\n' "$SECRETARY_DIR" >&2
  exit 1
fi

if [ ! -f "$RUNTIME_SOUL" ]; then
  printf 'ERROR missing runtime secretary SOUL.md: %s\n' "$RUNTIME_SOUL" >&2
  exit 1
fi

if cmp -s "$TEMPLATE" "$RUNTIME_SOUL"; then
  print_header "Already aligned"
  printf 'Runtime secretary SOUL.md already matches repository template. No apply needed.\n'
  exit 0
fi

if [ "$APPLY_SECRETARY_SOUL" != "1" ]; then
  print_header "Dry-run only"
  printf 'No runtime file was changed.\n'
  printf 'To apply, first create backup with CREATE_BACKUP=1 bash scripts/backup-hermes-profiles.sh\n'
  printf 'Then re-run with BACKUP_DIR=<backup-dir> APPLY_SECRETARY_SOUL=1 bash scripts/apply-secretary-soul-template.sh\n'
  exit 0
fi

if [ -z "$BACKUP_DIR" ]; then
  printf 'ERROR BACKUP_DIR is required when APPLY_SECRETARY_SOUL=1.\n' >&2
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  printf 'ERROR BACKUP_DIR does not exist: %s\n' "$BACKUP_DIR" >&2
  exit 1
fi

if [ ! -f "$BACKUP_DIR/profiles/secretary/SOUL.md" ]; then
  printf 'ERROR backup does not contain profiles/secretary/SOUL.md: %s\n' "$BACKUP_DIR" >&2
  exit 1
fi

print_header "Applying secretary SOUL.md"
printf 'COPY %s -> %s\n' "$TEMPLATE" "$RUNTIME_SOUL"
cp "$TEMPLATE" "$RUNTIME_SOUL"

print_header "Post-apply verification metadata"
file_meta "$RUNTIME_SOUL"
file_hash "$RUNTIME_SOUL"

if cmp -s "$TEMPLATE" "$RUNTIME_SOUL"; then
  printf 'PASS secretary runtime SOUL.md now matches repository template.\n'
else
  printf 'FAIL secretary runtime SOUL.md still differs from repository template.\n' >&2
  exit 1
fi

print_header "Next verification commands"
printf 'hermes profile show secretary\n'
printf 'PROFILE=secretary bash scripts/dry-run-profile-deployment.sh\n'
printf 'No gateway restart or Lark cutover was performed by this script.\n'
