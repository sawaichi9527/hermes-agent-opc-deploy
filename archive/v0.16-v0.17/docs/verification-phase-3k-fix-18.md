# Phase 3K-FIX.18 Local-only Config/Env Provisioning Planning

Status: PASS  
Result: read-only provisioning planner added / local-only `.env` and `config.yaml` boundary documented / no real write / no secret write / no config write  
Date: 2026-06-13

## Scope

Phase 3K-FIX.18 prepares the project for local-only profile provisioning.

It does not create real `.env` or real `config.yaml` files.

It adds a read-only planner that detects the expected provisioning gaps and records how they must be handled in later guarded local-only phases.

## Added Files

```text
scripts/plan-local-profile-provisioning.sh
docs/local-profile-config-env-provisioning-plan.md
docs/verification-phase-3k-fix-18.md
docs/real-deploy-plan-phase-3k-fix-18-addendum.md
```

## Safety Properties

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

The planner does not:

- write `.env`;
- write `config.yaml`;
- clone default profile secrets;
- call `hermes setup`;
- call `hermes auth`;
- call `hermes model`;
- start gateways;
- run chat or oneshot;
- mutate memories, sessions, logs, skills, cron, state, or auth files.

## Expected Local Validation

Run:

```bash
cd ~/workspace/hermes-agent-opc-deploy

bash -n scripts/plan-local-profile-provisioning.sh

bash scripts/plan-local-profile-provisioning.sh | grep -E \
  "PHASE 3K-FIX.18|Mode: read-only|ROLE_COUNT=6|SOURCE_ENV_TEMPLATE_MISSING_COUNT=0|SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=0|MISSING_DESTINATION_COUNT=0|SOUL_PRESENT_COUNT=6|PROFILE_YAML_PRESENT_COUNT=6|MISSING_ENV_COUNT=6|MISSING_CONFIG_COUNT=6|LOCAL_PROVISIONING_CANDIDATE_COUNT=12|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|CONFIG_WRITE=false|ENV_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS: local-only config/env provisioning planning completed in read-only mode"
```

Expected current result:

```text
ROLE_COUNT=6
SOURCE_ENV_TEMPLATE_MISSING_COUNT=0
SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=0
MISSING_DESTINATION_COUNT=0
SOUL_PRESENT_COUNT=6
PROFILE_YAML_PRESENT_COUNT=6
REAL_ENV_PRESENT_COUNT=0
MISSING_ENV_COUNT=6
REAL_CONFIG_PRESENT_COUNT=0
MISSING_CONFIG_COUNT=6
LOCAL_PROVISIONING_CANDIDATE_COUNT=12
BLOCKED_COUNT=0
PASS: local-only config/env provisioning planning completed in read-only mode
```

`MISSING_ENV_COUNT=6` and `MISSING_CONFIG_COUNT=6` are expected because real `.env` and real `config.yaml` are local-only and have not been provisioned yet.

## Readiness Cross-check

Run:

```bash
./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

Expected:

```text
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

## Documentation Checks

Run:

```bash
test -f docs/local-profile-config-env-provisioning-plan.md && echo "PASS local provisioning plan exists"
test -f docs/verification-phase-3k-fix-18.md && echo "PASS Phase 3K-FIX.18 verification exists"
test -f docs/real-deploy-plan-phase-3k-fix-18-addendum.md && echo "PASS Phase 3K-FIX.18 addendum exists"

grep -n \
  "Phase 3K-FIX.18 Local-only Config/Env Provisioning Plan\|Local-only Outputs\|Provisioning Candidate Semantics\|Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning" \
  docs/local-profile-config-env-provisioning-plan.md
```

## Final Lock Statement

```text
Phase 3K-FIX.18 local-only config/env provisioning planning
PASS / read-only provisioning planner added / local-only .env and config.yaml boundary documented / provisioning candidates measured / no real write / no secret write / no config write
```

## Next Step

Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning
