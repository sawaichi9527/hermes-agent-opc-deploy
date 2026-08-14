# Phase 3K-FIX.23 Post-secret-fill Runtime Readiness Plan

Status: PASS / checker and plan added  
Result: post-secret-fill read-only readiness checker implemented / manual secret values are never printed / repo risk checks defined / actual manual secret fill remains pending

## Purpose

Phase 3K-FIX.23 prepares the check that should be run after a human manually fills local `.env` values under the real Hermes profiles.

The checker is intentionally read-only and does not print secret values.

## Checker

```text
scripts/check-post-secret-fill-readiness.sh
```

The checker reports only status counters:

- `PLACEHOLDER_ENV_COUNT`
- `MANUAL_ENV_CANDIDATE_COUNT`
- `MISSING_ENV_COUNT`
- `MISSING_CONFIG_COUNT`
- `REPO_SECRET_RISK_COUNT`
- `REPO_LOCAL_CONFIG_RISK_COUNT`

It does not print the contents of `.env` values.

## Expected Current State

Immediately after Phase 3K-FIX.22, before manual secret fill:

```text
ROLE_COUNT=6
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
PLACEHOLDER_ENV_COUNT=6
MANUAL_ENV_CANDIDATE_COUNT=0
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
```

This is an expected pending state.

## Expected Post-secret State

After a human fills local `.env` values on the target host:

```text
ROLE_COUNT=6
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
PLACEHOLDER_ENV_COUNT=0
MANUAL_ENV_CANDIDATE_COUNT=6
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
PASS: post-secret-fill runtime readiness review completed in read-only mode
```

## Strict Boundary

Phase 3K-FIX.23 must not:

- write `.env`,
- write `config.yaml`,
- print secret values,
- stage or commit local secrets,
- start gateway,
- start chat,
- run agent sessions.

## Manual Secret Fill Procedure

A human may edit local files only under:

```text
~/.hermes/profiles/<role>/.env
```

Allowed manual operation:

```bash
vi ~/.hermes/profiles/<role>/.env
```

The repo must remain clean and must not contain real `.env` or `config.yaml` files.

## Verification Command

```bash
bash scripts/check-post-secret-fill-readiness.sh | grep -E \
  "PHASE 3K-FIX.23|Mode: read-only|ROLE_COUNT=6|MISSING_ENV_COUNT=0|MISSING_CONFIG_COUNT=0|PLACEHOLDER_ENV_COUNT=|MANUAL_ENV_CANDIDATE_COUNT=|REPO_SECRET_RISK_COUNT=0|REPO_LOCAL_CONFIG_RISK_COUNT=0|BLOCKED_COUNT=0|SECRET_READ_VALUE=false|SECRET_WRITE=false|CONFIG_WRITE=false|ENV_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS:|PENDING:"
```

## Next Action

```text
Phase 3K-FIX.24 post-secret-fill runtime smoke execution planning / checker
```
