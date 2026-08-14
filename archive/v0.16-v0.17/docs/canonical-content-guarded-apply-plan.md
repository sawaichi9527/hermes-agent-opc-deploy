# Canonical Content Guarded Apply Plan

Status: Phase 3K-FIX.9 canonical content guarded apply planning documented  
Scope: planning only / no real apply / no real write / no real delete

## Purpose

Phase 3K-FIX.9 defines how to synchronize the corrected canonical profile source content into the real Hermes profile root after the role taxonomy drift has been fully cleaned up.

This phase does not run the guarded deploy. It only records the operator-reviewed plan for the next phase.

## Current Canonical Source Root

```text
profiles/
  secretary/
    README.md
  coordinator/
    README.md
  researcher/
    README.md
  writer/
    README.md
  builder/
    README.md
  runes-holder/
    README.md
```

Canonical roles are loaded from:

```text
config/profile-roles.txt
```

Expected role list:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Current Drift Status

Repo-side drift source artifacts have been removed:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

Real drift profiles have also been removed from:

```text
~/.hermes/profiles/default/
~/.hermes/profiles/developer/
~/.hermes/profiles/reviewer/
~/.hermes/profiles/operator/
~/.hermes/profiles/trial/
```

No drift role should be recreated by the canonical content apply.

## Safety Boundary

The next guarded apply must preserve the existing safety properties:

- default mode is dry-run
- real apply requires `--apply --confirm REAL_DEPLOY_PROFILES`
- source roles are read from `config/profile-roles.txt`
- backup-before-write remains mandatory
- unmarked existing destination role directories remain protected
- cleanup scripts are not used in this phase
- no real profile delete is part of canonical content apply

## Required Preflight Before Phase 3K-FIX.10

Run these checks before any real apply:

```bash
cd ~/workspace/hermes-agent-opc-deploy

git status --short

cat config/profile-roles.txt

for role in secretary coordinator researcher writer builder runes-holder; do
  test -f "profiles/$role/README.md" && echo "PASS source README $role"
done

for role in default developer reviewer operator trial; do
  test ! -e "profiles/$role" && echo "PASS repo drift absent $role"
  test ! -e "$HOME/.hermes/profiles/$role" && echo "PASS real drift absent $role"
done

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

## Required Dry-run Before Phase 3K-FIX.10

```bash
bash scripts/deploy-real-profiles.sh --source-root "$PWD/profiles" | grep -E \
  "PHASE 3K-FIX.2 CANONICAL ROLE GUARDED APPLY|Mode: dry-run|Real deploy: DISABLED|ROLE_COUNT=6|ROLE=secretary|ROLE=runes-holder|SOURCE_ROOT=.*/profiles|SOURCE_STATUS=complete|PREFLIGHT_STATUS=PASS|REAL_PROFILE_WRITE=false"
```

The dry-run must show canonical roles only.

It must not show:

```text
ROLE=default
ROLE=developer
ROLE=reviewer
ROLE=operator
ROLE=trial
```

## Phase 3K-FIX.10 Apply Command

The real apply command is reserved for the next phase:

```bash
bash scripts/deploy-real-profiles.sh \
  --apply \
  --confirm REAL_DEPLOY_PROFILES \
  --source-root "$PWD/profiles"
```

Expected successful apply markers:

```text
Mode: apply
Real deploy: GUARDED_APPLY_REQUESTED
ROLE_COUNT=6
SOURCE_STATUS=complete
PREFLIGHT_STATUS=PASS
BACKUP_STATUS=created
APPLIED_ROLE=secretary
APPLIED_ROLE=coordinator
APPLIED_ROLE=researcher
APPLIED_ROLE=writer
APPLIED_ROLE=builder
APPLIED_ROLE=runes-holder
PASS: guarded real deploy completed
REAL_PROFILE_WRITE=true
```

## Post-apply Verification for Phase 3K-FIX.10

After the real apply, verify:

```bash
for role in secretary coordinator researcher writer builder runes-holder; do
  test -f "$HOME/.hermes/profiles/$role/README.md" && echo "PASS real README $role"
  test -f "$HOME/.hermes/profiles/$role/.opc-managed-profile" && echo "PASS real marker $role"
done

for role in default developer reviewer operator trial; do
  test ! -e "$HOME/.hermes/profiles/$role" && echo "PASS real drift absent $role"
done

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false"
```

## Abort Criteria

Do not run Phase 3K-FIX.10 apply if any of these are true:

- `git status --short` is not clean
- readiness does not report `READINESS_STATUS=READY`
- dry-run does not report `PREFLIGHT_STATUS=PASS`
- dry-run lists any drift role
- any canonical README is missing from repo source
- any drift role still exists in repo source
- any real drift role reappears
- apply command lacks `--confirm REAL_DEPLOY_PROFILES`

## Phase Result

```text
Phase 3K-FIX.9 canonical content guarded apply planning
PASS / canonical apply plan documented / preflight defined / dry-run required / no real write / no real delete
```

## Next Phase

```text
Phase 3K-FIX.10 canonical content guarded apply execution
```
