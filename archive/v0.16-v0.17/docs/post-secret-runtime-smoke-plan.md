# Phase 3K-FIX.24 Post-secret-fill Runtime Smoke Plan

Status: PASS / checker and plan added  
Result: post-secret-fill runtime smoke checker implemented / profile show and doctor checks gated by manual secret readiness / no gateway start / no chat / no secret value print

## Purpose

Phase 3K-FIX.24 prepares the runtime smoke checker that should be run after local `.env` files have been manually filled.

The checker performs read-only profile runtime checks:

- `hermes profile show <role>`
- `hermes -p <role> doctor`

It does not start gateway and does not start chat.

## Checker

```text
scripts/check-post-secret-runtime-smoke.sh
```

## Expected Pre-fill State

Before manual secret fill, the checker is expected to report pending:

```text
PLACEHOLDER_ENV_COUNT=6
MANUAL_ENV_CANDIDATE_COUNT=0
PENDING: post-secret runtime smoke preconditions are not fully met yet
```

This is not a failure of the checker. It means real secret fill has not yet happened.

## Expected Post-fill State

After local `.env` values are manually filled:

```text
ROLE_COUNT=6
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
PLACEHOLDER_ENV_COUNT=0
MANUAL_ENV_CANDIDATE_COUNT=6
PROFILE_SHOW_PASS_COUNT=6
PROFILE_SHOW_FAIL_COUNT=0
DOCTOR_PASS_COUNT=6
DOCTOR_FAIL_COUNT=0
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
PASS: post-secret-fill runtime smoke completed in read-only mode
```

## Boundaries

The checker must not:

- print secret values,
- write `.env`,
- write `config.yaml`,
- write repo files,
- start gateway,
- run chat,
- run an agent session.

## Verification Command

```bash
bash scripts/check-post-secret-runtime-smoke.sh | grep -E \
  "PHASE 3K-FIX.24|Mode: read-only|ROLE_COUNT=6|MISSING_ENV_COUNT=0|MISSING_CONFIG_COUNT=0|PLACEHOLDER_ENV_COUNT=|MANUAL_ENV_CANDIDATE_COUNT=|PROFILE_SHOW_PASS_COUNT=|PROFILE_SHOW_FAIL_COUNT=|DOCTOR_PASS_COUNT=|DOCTOR_FAIL_COUNT=|REPO_SECRET_RISK_COUNT=0|REPO_LOCAL_CONFIG_RISK_COUNT=0|BLOCKED_COUNT=0|SECRET_READ_VALUE=false|SECRET_WRITE=false|CONFIG_WRITE=false|ENV_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS:|PENDING:"
```

## Next Action

```text
Phase 3K-FIX.25 Phase 3K final baseline / Phase 3L transition
```
