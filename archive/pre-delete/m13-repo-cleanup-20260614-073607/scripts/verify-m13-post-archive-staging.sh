#!/usr/bin/env bash
set -euo pipefail

echo "== M13 post-archive sanity check =="

echo
echo "== M12 runtime baseline =="
bash scripts/verify-m12-native-opc-runtime-baseline.sh

echo
echo "== Current independent overlay scripts syntax =="
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
echo "== Archive staging presence =="
find archive/pre-delete -maxdepth 3 -type f 2>/dev/null | sort | sed -n '1,120p' || true

echo
echo "PASS M13 post-archive sanity check completed."
echo "NOTE: scripts/verify-repo-layout.sh may need M13.2 update if it still requires archived files."
