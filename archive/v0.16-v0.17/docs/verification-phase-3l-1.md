# Phase 3L.1 Local Secret Activation Checklist / Manual-fill Guide

Status: PASS  
Result: local secret activation checklist added / per-profile `.env` model documented / read-only target lister added / no secret write / no secret value print / no gateway start / no chat  
Date: 2026-06-13

## Scope

Phase 3L.1 starts Phase 3L after the Phase 3K final baseline freeze.

The goal is to document and verify how real local secrets should be filled manually without placing secrets in the repository or exposing secret values in logs.

## Key clarification

Each canonical profile owns its own local-only `.env` file:

```text
~/.hermes/profiles/secretary/.env
~/.hermes/profiles/coordinator/.env
~/.hermes/profiles/researcher/.env
~/.hermes/profiles/writer/.env
~/.hermes/profiles/builder/.env
~/.hermes/profiles/runes-holder/.env
```

This is intentional. The repository contains only `.env.template` files.

## Added files

```text
scripts/list-local-secret-fill-targets.sh
docs/phase-3l-local-secret-activation-checklist.md
```

## Safety properties

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

The checker lists target paths and status only. It does not print `.env` values.

## Expected pre-fill result

Before manual secret fill, the expected result remains:

```text
ROLE_COUNT=6
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
PLACEHOLDER_ENV_COUNT=6
MANUAL_ENV_CANDIDATE_COUNT=0
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
BLOCKED_COUNT=0
PASS: local secret manual fill target review completed in read-only mode
```

## Manual-fill boundary

Manual fill must be done locally only, using paths such as:

```bash
vi ~/.hermes/profiles/secretary/.env
```

Do not put real values into:

```text
docs/
profiles/
scripts/
git commit messages
shared terminal logs
ChatGPT conversation
```

## Post-fill verification

After manual local edits, use:

```bash
bash scripts/check-post-secret-fill-readiness.sh
bash scripts/check-post-secret-runtime-smoke.sh
```

Expected post-fill target:

```text
PLACEHOLDER_ENV_COUNT=0
MANUAL_ENV_CANDIDATE_COUNT=6
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
PROFILE_SHOW_PASS_COUNT=6
DOCTOR_PASS_COUNT=6
```

## Lock

Phase 3L.1 local secret activation checklist / manual-fill guide:

```text
PASS / per-profile local .env model documented / read-only secret fill target lister added / manual fill checklist ready / no secret write / no secret value print / no gateway start / no chat
```

## Next action

Phase 3L.2 local secret manual fill execution / post-fill readiness review
