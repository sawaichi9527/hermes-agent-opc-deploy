# Phase 3K-FIX.9 Canonical Content Guarded Apply Planning

Status: PASS candidate / pending local verification  
Scope: planning only / no real apply / no real write / no real delete

## Purpose

Phase 3K-FIX.9 records the plan for applying the corrected canonical profile content into real `~/.hermes/profiles/`.

This phase does not execute the apply. It only verifies that the plan is documented and that all preconditions remain ready.

## Inputs

```text
docs/canonical-content-guarded-apply-plan.md
config/profile-roles.txt
profiles/secretary/README.md
profiles/coordinator/README.md
profiles/researcher/README.md
profiles/writer/README.md
profiles/builder/README.md
profiles/runes-holder/README.md
```

## Expected Canonical Roles

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Expected Drift Status

Repo drift source artifacts should remain absent:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

Real drift profiles should remain absent:

```text
~/.hermes/profiles/default/
~/.hermes/profiles/developer/
~/.hermes/profiles/reviewer/
~/.hermes/profiles/operator/
~/.hermes/profiles/trial/
```

## Verification Commands

```bash
cd ~/workspace/hermes-agent-opc-deploy

test -f docs/canonical-content-guarded-apply-plan.md && echo "PASS canonical apply plan exists"

for role in secretary coordinator researcher writer builder runes-holder; do
  test -f "profiles/$role/README.md" && echo "PASS source README $role"
done

for role in default developer reviewer operator trial; do
  test ! -e "profiles/$role" && echo "PASS repo drift absent $role"
  test ! -e "$HOME/.hermes/profiles/$role" && echo "PASS real drift absent $role"
done

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

bash scripts/deploy-real-profiles.sh --source-root "$PWD/profiles" | grep -E \
  "PHASE 3K-FIX.2 CANONICAL ROLE GUARDED APPLY|Mode: dry-run|Real deploy: DISABLED|ROLE_COUNT=6|ROLE=secretary|ROLE=runes-holder|SOURCE_ROOT=.*/profiles|SOURCE_STATUS=complete|PREFLIGHT_STATUS=PASS|REAL_PROFILE_WRITE=false"

grep -n \
  "Phase 3K-FIX.9 canonical content guarded apply planning|REAL_DEPLOY_PROFILES|Phase 3K-FIX.10 canonical content guarded apply execution|no real write|no real delete" \
  docs/canonical-content-guarded-apply-plan.md

git status --short
```

## Expected Verification Result

- `docs/canonical-content-guarded-apply-plan.md` exists.
- Six canonical source README files exist.
- Repo drift sources remain absent.
- Real drift profiles remain absent.
- Readiness reports `READINESS_STATUS=READY`.
- Deploy dry-run reports `PREFLIGHT_STATUS=PASS`.
- Deploy dry-run reports `REAL_PROFILE_WRITE=false`.
- No real apply is executed in Phase 3K-FIX.9.
- No real delete is executed in Phase 3K-FIX.9.
- Working tree remains clean.

## Locked Result

When local verification passes, lock Phase 3K-FIX.9 as:

```text
Phase 3K-FIX.9 canonical content guarded apply planning
PASS / canonical apply plan documented / preflight defined / dry-run required / no real write / no real delete
```

## Next Phase

```text
Phase 3K-FIX.10 canonical content guarded apply execution
```
