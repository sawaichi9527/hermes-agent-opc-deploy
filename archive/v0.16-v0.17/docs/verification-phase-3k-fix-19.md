# Phase 3K-FIX.19 Local-only Config/Env Guarded Execution Planning

Status: PASS  
Result: read-only guarded provisioning planner added / future token defined / create-only and no-overwrite boundary documented / no real write / no secret write / no config write

## Scope

Phase 3K-FIX.19 prepares guarded execution for local-only `.env` and `config.yaml` provisioning.

This phase does not write:

- real `.env`
- real `config.yaml`
- real secrets
- profile runtime state

## Added Files

```text
scripts/plan-local-profile-provisioning-guarded-apply.sh
docs/local-profile-config-env-guarded-execution-plan.md
docs/verification-phase-3k-fix-19.md
docs/real-deploy-plan-phase-3k-fix-19-addendum.md
```

## Safety Boundary

Required planning markers:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

Future execution token:

```text
REAL_PROVISION_LOCAL_CONFIG_ENV
```

## Expected Planner Markers

The planner should report:

```text
Status: PHASE 3K-FIX.19 LOCAL-ONLY CONFIG/ENV GUARDED EXECUTION PLANNING ONLY
Mode: read-only
ROLE_COUNT=6
SOURCE_ENV_TEMPLATE_MISSING_COUNT=0
SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=0
MISSING_DESTINATION_COUNT=0
ENV_CREATE_CANDIDATE_COUNT=6
CONFIG_CREATE_CANDIDATE_COUNT=6
ENV_EXISTING_PROTECTED_COUNT=0
CONFIG_EXISTING_PROTECTED_COUNT=0
LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=12
BLOCKED_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
PASS: local-only config/env guarded execution planning completed in read-only mode
```

If local `.env` or `config.yaml` files already exist, the candidate/protected counts may differ, but the script must still preserve existing files and keep `BLOCKED_COUNT=0` when templates and destinations are valid.

## Verification Commands

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull
git status
git log --oneline -10

bash -n scripts/plan-local-profile-provisioning-guarded-apply.sh

bash scripts/plan-local-profile-provisioning-guarded-apply.sh | grep -E \
  "PHASE 3K-FIX.19|Mode: read-only|ROLE_COUNT=6|SOURCE_ENV_TEMPLATE_MISSING_COUNT=0|SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=0|MISSING_DESTINATION_COUNT=0|ENV_CREATE_CANDIDATE_COUNT=6|CONFIG_CREATE_CANDIDATE_COUNT=6|ENV_EXISTING_PROTECTED_COUNT=0|CONFIG_EXISTING_PROTECTED_COUNT=0|LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=12|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|CONFIG_WRITE=false|ENV_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS: local-only config/env guarded execution planning completed in read-only mode"

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

test -f docs/local-profile-config-env-guarded-execution-plan.md && echo "PASS guarded provisioning plan exists"
test -f docs/verification-phase-3k-fix-19.md && echo "PASS Phase 3K-FIX.19 verification exists"
test -f docs/real-deploy-plan-phase-3k-fix-19-addendum.md && echo "PASS Phase 3K-FIX.19 addendum exists"

grep -n \
  "Phase 3K-FIX.19 Local-only Config/Env Guarded Execution Plan\|REAL_PROVISION_LOCAL_CONFIG_ENV\|Strict Non-overwrite Rule\|Phase 3K-FIX.20 local-only config/env provisioning guarded execution implementation" \
  docs/local-profile-config-env-guarded-execution-plan.md

git status --short
```

## Pass Criteria

Phase 3K-FIX.19 passes if:

- planner syntax check passes
- planner mode is read-only
- six roles are detected
- env/config templates are present
- destination profiles are present
- local provisioning candidates are measured
- existing local-only files are protected
- no real write occurs
- no secret write occurs
- no config write occurs
- readiness remains READY
- working tree remains clean

## Final Lock

Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning
PASS / read-only guarded provisioning planner added / future token defined / create-only and no-overwrite boundary documented / no real write / no secret write / no config write

## Next Action

Phase 3K-FIX.20 local-only config/env provisioning guarded execution implementation
