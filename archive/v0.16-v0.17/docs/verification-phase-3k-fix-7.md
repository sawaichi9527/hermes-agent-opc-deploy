# Phase 3K-FIX.7 Repo Drift Source Cleanup Execution

Status: implemented / pending local verification  
Write scope: repo source cleanup only  
Real profile write: no  
Real profile delete: no

## Purpose

Phase 3K-FIX.7 removes the obsolete repo-local drift source artifacts created during the earlier generic role taxonomy drift.

This phase does not touch real Hermes profile directories under `~/.hermes/profiles/`.

Real drift skeleton cleanup was already completed in Phase 3K-FIX.5.

## Removed repo drift roles

The following obsolete repo-local role source directories were removed by deleting their tracked files:

- `profiles/default/`
- `profiles/developer/`
- `profiles/reviewer/`
- `profiles/operator/`
- `profiles/trial/`

Deleted tracked files:

- `profiles/default/.gitkeep`
- `profiles/default/README.md`
- `profiles/developer/.gitkeep`
- `profiles/developer/README.md`
- `profiles/reviewer/.gitkeep`
- `profiles/reviewer/README.md`
- `profiles/operator/.gitkeep`
- `profiles/operator/README.md`
- `profiles/trial/.gitkeep`
- `profiles/trial/README.md`

## Preserved canonical profile roles

The canonical Hermes role source directories remain:

- `profiles/secretary/`
- `profiles/coordinator/`
- `profiles/researcher/`
- `profiles/writer/`
- `profiles/builder/`
- `profiles/runes-holder/`

The canonical role list remains config-driven by:

```text
config/profile-roles.txt
```

Expected canonical roles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Expected planner state after cleanup

After pulling this phase, the repo drift planner should report that the old five repo source artifacts are missing, not candidates:

```text
REPO_CLEANUP_CANDIDATE_COUNT=0
REPO_BLOCKED_COUNT=0
REPO_MISSING_COUNT=5
REPO_PROFILE_WRITE=false
REPO_PROFILE_DELETE=false
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
PASS: repo drift source cleanup planning completed in read-only mode
```

## Expected readiness state after cleanup

Canonical readiness should remain READY:

```text
ROLE_COUNT=6
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

## Verification commands

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull

git status

git log --oneline -20
```

Verify obsolete repo source paths are gone:

```bash
for role in default developer reviewer operator trial; do
  test ! -e "profiles/$role" && echo "PASS repo drift source removed $role"
done
```

Verify canonical source paths remain:

```bash
for role in secretary coordinator researcher writer builder runes-holder; do
  test -d "profiles/$role" && echo "PASS canonical source exists $role"
done
```

Verify repo drift planner post-cleanup state:

```bash
bash scripts/plan-repo-drift-source-cleanup.sh | grep -E \
  "REPO_CLEANUP_CANDIDATE_COUNT=0|REPO_BLOCKED_COUNT=0|REPO_MISSING_COUNT=5|REPO_PROFILE_WRITE=false|REPO_PROFILE_DELETE=false|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|PASS: repo drift source cleanup planning completed in read-only mode"
```

Verify canonical readiness remains READY:

```bash
./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

Verify real drift profiles remain removed:

```bash
for role in default developer reviewer operator trial; do
  test ! -e "$HOME/.hermes/profiles/$role" && echo "PASS real drift profile absent $role"
done
```

Verify working tree is clean:

```bash
git status --short
```

## Expected final lock

If all checks pass, lock Phase 3K-FIX.7 as:

```text
Phase 3K-FIX.7 repo drift source cleanup execution
PASS / obsolete repo drift source artifacts removed / canonical source roles preserved / planner missing=5 / readiness READY / no real write / no real delete
```

## Next phase

```text
Phase 3K-FIX.8 canonical role content hardening
```

Phase 3K-FIX.8 can now add real profile content to the canonical six role directories without the old generic role taxonomy remaining in the repo.
