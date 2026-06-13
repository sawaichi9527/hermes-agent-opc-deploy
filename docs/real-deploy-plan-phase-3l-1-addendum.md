# Real Deploy Plan Addendum — Phase 3L.1

Status: Phase 3L.1 local secret activation checklist completed  
Date: 2026-06-13

## Context

Phase 3K is frozen as a profile pipeline baseline. Phase 3L begins local secret activation and runtime activation work.

Phase 3L.1 does not fill real secrets. It documents and verifies where secrets must be filled manually and how to validate readiness without printing secret values.

## Per-profile `.env` model

Yes, each profile has its own local-only `.env` file:

```text
~/.hermes/profiles/secretary/.env
~/.hermes/profiles/coordinator/.env
~/.hermes/profiles/researcher/.env
~/.hermes/profiles/writer/.env
~/.hermes/profiles/builder/.env
~/.hermes/profiles/runes-holder/.env
```

This remains outside git.

## Added assets

```text
scripts/list-local-secret-fill-targets.sh
docs/phase-3l-local-secret-activation-checklist.md
docs/verification-phase-3l-1.md
```

## Safety boundary

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

## Expected local verification

Run:

```bash
bash scripts/list-local-secret-fill-targets.sh
```

Expected before manual secret fill:

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

## Manual fill rule

Only edit local `.env` files directly, for example:

```bash
vi ~/.hermes/profiles/secretary/.env
```

Never paste real secrets into repo files, docs, terminal logs shared externally, or ChatGPT.

## Next action

Phase 3L.2 local secret manual fill execution / post-fill readiness review
