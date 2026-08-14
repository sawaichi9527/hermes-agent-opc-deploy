# Phase 3K-FIX.21 Local-only Secret Manual Fill / Runtime Readiness Review Plan

Status: PASS / planning implemented  
Scope: local-only secret manual fill plan and read-only runtime readiness review  
Date: 2026-06-13

## Purpose

Phase 3K-FIX.20 created local `.env` placeholders and local `config.yaml` files under the real Hermes profile root.

Phase 3K-FIX.21 defines the next safe boundary:

- humans may manually fill secrets on the local machine only;
- the repo must never receive real secrets;
- automation must not print secret values;
- runtime readiness must be reviewed before gateway/chat usage;
- no gateway or chat should be started in this phase.

## Profile Roles

Canonical roles remain:

- `secretary`
- `coordinator`
- `researcher`
- `writer`
- `builder`
- `runes-holder`

Real profile root:

```text
~/.hermes/profiles/<role>/
```

Local-only files now expected:

```text
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/config.yaml
```

Repo-owned template files remain:

```text
profiles/<role>/.env.template
profiles/<role>/config.yaml.template
```

## Strict Secret Boundary

The following are prohibited from repo and documentation:

- real LM Studio / OpenAI-compatible API keys;
- Telegram bot tokens;
- PostgreSQL passwords;
- Tavily or search API keys;
- any bearer token;
- any OAuth token;
- any production credential;
- copied full `.env` contents from real profile directories.

The repo may only store:

- `.env.template`
- `config.yaml.template`
- docs that describe keys by name, not value;
- redacted examples.

## Phase 21 Checker

Added script:

```bash
scripts/check-local-secret-manual-fill-readiness.sh
```

The checker is read-only.

It reports:

- real profile role count;
- whether local `.env` exists;
- whether local `config.yaml` exists;
- whether `.env` still appears placeholder-like;
- whether `.env` may be manually filled, without printing values;
- whether unresolved markers remain;
- whether repo accidentally contains real local `.env` or `config.yaml` files;
- whether runtime can proceed to a later readiness phase.

It must never print actual secret values.

Expected output after Phase 3K-FIX.20, before manual secret fill:

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
PASS: local-only secret manual fill readiness review completed in read-only mode
```

After a human manually fills secrets, the expected marker may become:

```text
PLACEHOLDER_ENV_COUNT=0
MANUAL_ENV_CANDIDATE_COUNT=6
```

The checker still does not prove a secret is semantically valid. It only verifies that the placeholders appear to have been replaced and that no repo leak is detected.

## Manual Fill Checklist

For each profile:

```bash
vi ~/.hermes/profiles/<role>/.env
```

The human reviewer should:

1. Replace placeholder values only on the local machine.
2. Keep comments or redacted sample lines if useful.
3. Never paste the resulting `.env` into chat, docs, git, issues, logs, or screenshots.
4. Run the read-only checker afterward.
5. Confirm repo remains clean.

Do not use automation to inject real secrets in this phase.

## Runtime Readiness Review Criteria

Before entering any real gateway/chat runtime phase, the following should be true:

```text
ROLE_COUNT=6
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
BLOCKED_COUNT=0
READINESS_STATUS=READY
```

Optionally, after human fill:

```text
PLACEHOLDER_ENV_COUNT=0
MANUAL_ENV_CANDIDATE_COUNT=6
```

However, a profile can still be held at review if the human wants to keep placeholders until final runtime tests.

## Explicit Non-goals

Phase 3K-FIX.21 does not:

- write real secrets;
- validate API connectivity;
- start Hermes gateway;
- start a chat session;
- run agent tasks;
- send Telegram messages;
- mutate repo files after provisioning;
- import secrets into docs.

## Recommended Verification

```bash
cd ~/workspace/hermes-agent-opc-deploy

bash -n scripts/check-local-secret-manual-fill-readiness.sh

bash scripts/check-local-secret-manual-fill-readiness.sh | grep -E \
  "PHASE 3K-FIX.21|Mode: read-only|ROLE_COUNT=6|CONFIG_PRESENT_COUNT=6|MISSING_CONFIG_COUNT=0|MISSING_ENV_COUNT=0|PLACEHOLDER_ENV_COUNT=6|MANUAL_ENV_CANDIDATE_COUNT=0|REPO_SECRET_RISK_COUNT=0|REPO_LOCAL_CONFIG_RISK_COUNT=0|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|SECRET_WRITE=false|SECRET_READ_VALUE=false|CONFIG_WRITE=false|ENV_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS: local-only secret manual fill readiness review completed in read-only mode"

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

git status --short
```

## Status Lock

Phase 3K-FIX.21 local-only secret manual fill plan / runtime readiness review

PASS / read-only secret manual-fill readiness checker added / repo secret risk scan defined / local placeholder review documented / no secret write / no secret value print / no gateway start / no chat

## Next Action

Phase 3K-FIX.22 local-only secret manual fill review execution / runtime readiness lock
