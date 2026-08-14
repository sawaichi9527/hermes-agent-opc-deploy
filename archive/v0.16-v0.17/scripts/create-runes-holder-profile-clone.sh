#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
PROFILE="runes-holder"
PROFILE_DIR="$HERMES_HOME/profiles/$PROFILE"

echo "== Create Hermes native profile clone =="
echo "HERMES_HOME=$HERMES_HOME"
echo "PROFILE=$PROFILE"
echo "PROFILE_DIR=$PROFILE_DIR"

if [ -d "$PROFILE_DIR" ]; then
  echo "SKIP: runtime profile already exists: $PROFILE_DIR"
  hermes profile show "$PROFILE"
  exit 0
fi

echo
echo "== Use default as clone source =="
hermes profile use default
hermes profile show default

echo
echo "== Clone profile from default =="
hermes profile create "$PROFILE" --clone

echo
echo "== Verify cloned profile =="
hermes profile show "$PROFILE"
command -v "$PROFILE" || true

echo
echo "PASS: $PROFILE profile clone is ready."
echo "Next doc overlay:"
echo "  bash scripts/apply-$PROFILE-runtime-doc-overlay.sh"
echo "  APPLY_RUNES_HOLDER_DOCS=1 bash scripts/apply-$PROFILE-runtime-doc-overlay.sh"
