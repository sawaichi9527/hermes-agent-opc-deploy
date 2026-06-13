#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
PROFILE="${PROFILE:-secretary}"
PROFILE_DIR="$HERMES_HOME/profiles/$PROFILE"
SRC_DIR="$ROOT/profiles/$PROFILE"
APPLY_SECRETARY_DOCS="${APPLY_SECRETARY_DOCS:-0}"

if [ "$PROFILE" != "secretary" ]; then
  echo "ERROR: this guarded overlay script is secretary-only. PROFILE=$PROFILE"
  exit 1
fi

hash_file() {
  local path="$1"
  if [ -f "$path" ]; then
    sha256sum "$path" | awk '{print $1}'
  else
    echo "MISSING"
  fi
}

show_meta() {
  local path="$1"
  if [ -e "$path" ]; then
    stat -c 'META mode=%a size=%s mtime=%y path=%n' "$path"
  else
    echo "MISSING $path"
  fi
}

copy_doc() {
  local src="$1"
  local dst="$2"

  if [ ! -f "$src" ]; then
    echo "ERROR: missing source file: $src"
    exit 1
  fi

  echo "COPY $src -> $dst"
  if [ "$APPLY_SECRETARY_DOCS" = "1" ]; then
    install -m 600 "$src" "$dst"
  fi
}

echo "== Guarded secretary runtime doc overlay =="
echo "ROOT=$ROOT"
echo "HERMES_HOME=$HERMES_HOME"
echo "PROFILE=$PROFILE"
echo "PROFILE_DIR=$PROFILE_DIR"
echo "SRC_DIR=$SRC_DIR"
echo "APPLY_SECRETARY_DOCS=$APPLY_SECRETARY_DOCS"

echo
echo "== Preflight =="
if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: missing source profile directory: $SRC_DIR"
  exit 1
fi

if [ ! -d "$PROFILE_DIR" ]; then
  echo "ERROR: missing runtime profile directory: $PROFILE_DIR"
  echo "Create it first with:"
  echo "  hermes profile use default"
  echo "  hermes profile create secretary --clone"
  exit 1
fi

for f in \
  "$SRC_DIR/SOUL.md.template" \
  "$SRC_DIR/NOTES.md" \
  "$SRC_DIR/profile.yaml" \
  "$SRC_DIR/README.md" \
  "$PROFILE_DIR/.env" \
  "$PROFILE_DIR/config.yaml"
do
  show_meta "$f"
done

ENV_HASH_BEFORE="$(hash_file "$PROFILE_DIR/.env")"
CONFIG_HASH_BEFORE="$(hash_file "$PROFILE_DIR/config.yaml")"

echo
echo "== Protected inherited file hashes before =="
echo ".env        $ENV_HASH_BEFORE"
echo "config.yaml $CONFIG_HASH_BEFORE"

if [ "$ENV_HASH_BEFORE" = "MISSING" ]; then
  echo "ERROR: runtime .env missing; refusing to proceed."
  exit 1
fi

if [ "$CONFIG_HASH_BEFORE" = "MISSING" ]; then
  echo "ERROR: runtime config.yaml missing; refusing to proceed."
  exit 1
fi

echo
echo "== Planned overlay =="
copy_doc "$SRC_DIR/SOUL.md.template" "$PROFILE_DIR/SOUL.md"
copy_doc "$SRC_DIR/NOTES.md" "$PROFILE_DIR/NOTES.md"
copy_doc "$SRC_DIR/profile.yaml" "$PROFILE_DIR/profile.yaml"
copy_doc "$SRC_DIR/README.md" "$PROFILE_DIR/README.md"

if [ "$APPLY_SECRETARY_DOCS" != "1" ]; then
  echo
  echo "== Dry-run only =="
  echo "No runtime file was changed."
  echo "To apply:"
  echo "  APPLY_SECRETARY_DOCS=1 bash scripts/apply-secretary-runtime-doc-overlay.sh"
  exit 0
fi

ENV_HASH_AFTER="$(hash_file "$PROFILE_DIR/.env")"
CONFIG_HASH_AFTER="$(hash_file "$PROFILE_DIR/config.yaml")"

echo
echo "== Protected inherited file hashes after =="
echo ".env        $ENV_HASH_AFTER"
echo "config.yaml $CONFIG_HASH_AFTER"

if [ "$ENV_HASH_BEFORE" != "$ENV_HASH_AFTER" ]; then
  echo "FAIL: protected .env changed unexpectedly."
  exit 1
fi

if [ "$CONFIG_HASH_BEFORE" != "$CONFIG_HASH_AFTER" ]; then
  echo "FAIL: protected config.yaml changed unexpectedly."
  exit 1
fi

echo
echo "== Post-apply document hashes =="
sha256sum "$SRC_DIR/SOUL.md.template" "$PROFILE_DIR/SOUL.md"
sha256sum "$SRC_DIR/NOTES.md" "$PROFILE_DIR/NOTES.md"
sha256sum "$SRC_DIR/profile.yaml" "$PROFILE_DIR/profile.yaml"
sha256sum "$SRC_DIR/README.md" "$PROFILE_DIR/README.md"

if ! cmp -s "$SRC_DIR/SOUL.md.template" "$PROFILE_DIR/SOUL.md"; then
  echo "FAIL: runtime SOUL.md does not match repository SOUL.md.template"
  exit 1
fi

if ! cmp -s "$SRC_DIR/NOTES.md" "$PROFILE_DIR/NOTES.md"; then
  echo "FAIL: runtime NOTES.md does not match repository NOTES.md"
  exit 1
fi

if ! cmp -s "$SRC_DIR/profile.yaml" "$PROFILE_DIR/profile.yaml"; then
  echo "FAIL: runtime profile.yaml does not match repository profile.yaml"
  exit 1
fi

if ! cmp -s "$SRC_DIR/README.md" "$PROFILE_DIR/README.md"; then
  echo "FAIL: runtime README.md does not match repository README.md"
  exit 1
fi

echo
echo "PASS: secretary runtime doc overlay applied."
echo "PASS: protected .env and config.yaml were preserved."
echo
echo "Next verification:"
echo "  hermes profile show secretary"
echo "  sed -n '1,80p' ~/.hermes/profiles/secretary/SOUL.md"
