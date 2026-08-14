#!/usr/bin/env bash
set -euo pipefail

DOC_CANDIDATES=(
  docs/verification-m4-minimal.md
  docs/verification-m5-soul-convention.md
  docs/verification-m6-maintenance-planning.md
  docs/verification-m7-profile-deployment-planning.md
  docs/verification-m8-secretary-apply.md
  docs/verification-m9-secretary-smoke-partial.md
  docs/roadmap-m8-status-sync.md
  docs/secretary-only-behavior-smoke.md
  docs/phase-6-hermes-native-profile-alignment.md
  docs/pre-production-profile-maintenance.md
  docs/pre-production-cleanup-dry-run.md
  docs/pre-production-profile-deployment.md
  docs/profile-deployment-dry-run.md
  docs/real-profile-backup-and-secretary-apply.md
)

SCRIPT_CANDIDATES=(
  scripts/apply-secretary-soul-template.sh
  scripts/apply-native-profile-templates.sh
  scripts/plan-native-template-apply.sh
  scripts/dry-run-profile-deployment.sh
  scripts/plan-local-profile-provisioning.sh
  scripts/plan-local-profile-provisioning-guarded-apply.sh
  scripts/provision-local-profile-config-env.sh
  scripts/check-post-secret-fill-readiness.sh
  scripts/check-post-secret-runtime-smoke.sh
  scripts/check-local-secret-manual-fill-readiness.sh
  scripts/list-local-secret-fill-targets.sh
  scripts/smoke-secretary-profile-local.sh
  scripts/diagnose-secretary-local-smoke.sh
)

echo "== M13 repo archive staging plan =="
echo "This is read-only. No files will be moved."
echo

echo "== Git state =="
git status --short --branch
echo

echo "== Documentation candidates =="
for f in "${DOC_CANDIDATES[@]}"; do
  if [ -e "$f" ]; then
    echo "CANDIDATE $f"
  else
    echo "MISSING   $f"
  fi
done

echo
echo "== Script candidates =="
for f in "${SCRIPT_CANDIDATES[@]}"; do
  if [ -e "$f" ]; then
    echo "CANDIDATE $f"
  else
    echo "MISSING   $f"
  fi
done

echo
echo "== Protected current baseline files =="
for f in \
  docs/verification-m12-native-opc-runtime-baseline.md \
  scripts/verify-m12-native-opc-runtime-baseline.sh \
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
  test -e "$f"
  echo "KEEP $f"
done

echo
echo "PASS M13 archive staging plan generated."
