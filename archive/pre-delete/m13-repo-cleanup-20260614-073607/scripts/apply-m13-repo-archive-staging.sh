#!/usr/bin/env bash
set -euo pipefail

TS="${M13_ARCHIVE_TS:-$(date +%Y%m%d-%H%M%S)}"
ARCHIVE_ROOT="archive/pre-delete/m13-repo-cleanup-$TS"
MANIFEST="$ARCHIVE_ROOT/MANIFEST.md"

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

move_one() {
  local src="$1"
  local category="$2"
  local dst="$ARCHIVE_ROOT/$category/${src#*/}"

  if [ ! -e "$src" ]; then
    echo "SKIP missing $src"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"

  echo "MOVE $src -> $dst"
  if git ls-files --error-unmatch "$src" >/dev/null 2>&1; then
    git mv "$src" "$dst"
  else
    mv "$src" "$dst"
    git add "$dst"
  fi

  printf -- '- `%s` -> `%s`\n' "$src" "$dst" >> "$MANIFEST"
}

echo "== M13 repo archive staging apply =="
echo "ARCHIVE_ROOT=$ARCHIVE_ROOT"

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository."
  exit 1
fi

mkdir -p "$ARCHIVE_ROOT/docs" "$ARCHIVE_ROOT/scripts"

cat > "$MANIFEST" <<MD
# M13 Repo Cleanup Archive Manifest

Status: archive staging / no deletion

Archive root:

\`\`\`text
$ARCHIVE_ROOT
\`\`\`

## Moved files

MD

echo
echo "== Move documentation candidates =="
for f in "${DOC_CANDIDATES[@]}"; do
  move_one "$f" "docs"
done

echo
echo "== Move script candidates =="
for f in "${SCRIPT_CANDIDATES[@]}"; do
  move_one "$f" "scripts"
done

git add "$MANIFEST"

echo
echo "== Current git status =="
git status --short

echo
echo "PASS M13 archive staging applied."
echo "Review with:"
echo "  git status --short"
echo "  git diff --stat --cached"
echo
echo "Then commit with:"
echo "  git commit -m \"Stage M13 repo cleanup archive candidates\""
