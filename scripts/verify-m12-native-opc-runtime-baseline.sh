#!/usr/bin/env bash
set -euo pipefail

PROFILES=(
  secretary
  coordinator
  researcher
  writer
  builder
  runes-holder
)

echo "== M12 Hermes Native OPC Runtime Baseline =="

for p in "${PROFILES[@]}"; do
  echo
  echo "== profile: $p =="

  hermes profile show "$p"

  profile_dir="$HOME/.hermes/profiles/$p"

  test -d "$profile_dir"
  test -f "$profile_dir/.env"
  test -f "$profile_dir/config.yaml"
  test -f "$profile_dir/SOUL.md"
  test -f "$profile_dir/NOTES.md"
  test -f "$profile_dir/profile.yaml"
  test -f "$profile_dir/README.md"

  grep -q "# SOUL: $p" "$profile_dir/SOUL.md"

  echo "PASS runtime files exist for $p"
done

echo
echo "== Protected overlay scripts syntax =="
for s in \
  scripts/apply-secretary-runtime-doc-overlay.sh \
  scripts/apply-coordinator-runtime-doc-overlay.sh \
  scripts/apply-researcher-runtime-doc-overlay.sh \
  scripts/apply-writer-runtime-doc-overlay.sh \
  scripts/apply-builder-runtime-doc-overlay.sh \
  scripts/apply-runes-holder-runtime-doc-overlay.sh \
  scripts/create-coordinator-profile-clone.sh \
  scripts/create-researcher-profile-clone.sh \
  scripts/create-writer-profile-clone.sh \
  scripts/create-builder-profile-clone.sh \
  scripts/create-runes-holder-profile-clone.sh
do
  bash -n "$s"
  echo "PASS syntax $s"
done

echo
echo "PASS M12 native OPC runtime baseline verified."
