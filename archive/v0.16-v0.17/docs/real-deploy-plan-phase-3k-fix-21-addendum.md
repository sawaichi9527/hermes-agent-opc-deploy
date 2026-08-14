# Real Deploy Plan Addendum: Phase 3K-FIX.21

Status: Phase 3K-FIX.21 local-only secret manual fill plan / runtime readiness review prepared  
Date: 2026-06-13

## Summary

Phase 3K-FIX.21 adds a read-only review layer after Phase 3K-FIX.20 local provisioning.

Phase 3K-FIX.20 created local `.env` placeholder files and local `config.yaml` files. Phase 3K-FIX.21 does not fill secrets. It defines how a human should review and later fill local-only secrets safely.

## Added Files

```text
scripts/check-local-secret-manual-fill-readiness.sh
docs/local-secret-manual-fill-runtime-readiness-plan.md
docs/verification-phase-3k-fix-21.md
docs/real-deploy-plan-phase-3k-fix-21-addendum.md
```

## Non-negotiable Boundary

This phase must not:

- write real secrets;
- print secret values;
- copy real `.env` into repo;
- copy real `config.yaml` into repo;
- start Hermes gateway;
- start chat;
- validate online model/API connectivity;
- mutate runtime state.

Expected markers:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
SECRET_READ_VALUE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

## Expected State Before Human Secret Fill

After Phase 3K-FIX.20, expected Phase 21 checker state is:

```text
ROLE_COUNT=6
CONFIG_PRESENT_COUNT=6
MISSING_CONFIG_COUNT=0
MISSING_ENV_COUNT=0
PLACEHOLDER_ENV_COUNT=6
MANUAL_ENV_CANDIDATE_COUNT=0
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
BLOCKED_COUNT=0
```

`PLACEHOLDER_ENV_COUNT=6` is expected before human manual fill.

## Human Manual Fill Path

For each role, when ready:

```bash
vi ~/.hermes/profiles/<role>/.env
```

Rules:

1. Replace placeholders locally only.
2. Do not paste secret values into any repo file or chat.
3. Re-run the checker.
4. Keep git clean.
5. Proceed to runtime only after review.

## Verification

```bash
cd ~/workspace/hermes-agent-opc-deploy

bash -n scripts/check-local-secret-manual-fill-readiness.sh

bash scripts/check-local-secret-manual-fill-readiness.sh | grep -E \
  "PHASE 3K-FIX.21|Mode: read-only|ROLE_COUNT=6|CONFIG_PRESENT_COUNT=6|MISSING_CONFIG_COUNT=0|MISSING_ENV_COUNT=0|PLACEHOLDER_ENV_COUNT=6|MANUAL_ENV_CANDIDATE_COUNT=0|REPO_SECRET_RISK_COUNT=0|REPO_LOCAL_CONFIG_RISK_COUNT=0|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|SECRET_WRITE=false|SECRET_READ_VALUE=false|CONFIG_WRITE=false|ENV_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS: local-only secret manual fill readiness review completed in read-only mode"

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

## Status Lock

Phase 3K-FIX.21 local-only secret manual fill plan / runtime readiness review

PASS / read-only secret manual-fill readiness checker added / repo secret risk scan defined / local placeholder review documented / no secret write / no secret value print / no gateway start / no chat

## Next Action

Phase 3K-FIX.22 local-only secret manual fill review execution / runtime readiness lock
