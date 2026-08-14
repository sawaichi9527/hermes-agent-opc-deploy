# Phase 3L.1 Local Secret Activation Checklist

Status: PLANNED / read-only checklist implemented  
Scope: local-only secret manual fill guide for canonical Hermes profiles.  
Date: 2026-06-13

## Answer: one `.env` per profile

Yes. In this deployment model, each canonical profile has its own local-only `.env` file under the real Hermes profile root:

```text
~/.hermes/profiles/secretary/.env
~/.hermes/profiles/coordinator/.env
~/.hermes/profiles/researcher/.env
~/.hermes/profiles/writer/.env
~/.hermes/profiles/builder/.env
~/.hermes/profiles/runes-holder/.env
```

Each profile also has its own local-only `config.yaml`:

```text
~/.hermes/profiles/secretary/config.yaml
~/.hermes/profiles/coordinator/config.yaml
~/.hermes/profiles/researcher/config.yaml
~/.hermes/profiles/writer/config.yaml
~/.hermes/profiles/builder/config.yaml
~/.hermes/profiles/runes-holder/config.yaml
```

The repository keeps only templates:

```text
profiles/<role>/.env.template
profiles/<role>/config.yaml.template
```

Real `.env` and real `config.yaml` files must remain outside git.

## Why per-profile `.env`

The goal is to keep profile activation bounded and auditable:

- `secretary` can use a different provider/model/runtime setting from `builder`.
- A profile can be activated without giving all roles the same credentials.
- Runtime debugging can identify which profile is configured or still placeholder-only.
- Local files remain governed by the same no-secrets-in-repo rule.

## Current expected state after Phase 3K

After Phase 3K-FIX.20 and Phase 3K-FIX.25:

```text
.env exists for 6 profiles               expected
config.yaml exists for 6 profiles        expected
.env still placeholder-only              expected
real secrets filled                      not done yet
repo secret risk                         0 expected
gateway/chat                             not started
```

## Strict secret boundary

Do not paste real secrets into:

```text
docs/
profiles/
scripts/
README.md
git commit messages
terminal logs intended for sharing
ChatGPT conversation
```

Allowed local-only secret locations:

```text
~/.hermes/profiles/<role>/.env
local OS secret store, if used later
```

Do not print `.env` contents when asking for help. Use grep/count/checker output only.

## Manual fill procedure

Use `vi` locally for each role:

```bash
vi ~/.hermes/profiles/secretary/.env
vi ~/.hermes/profiles/coordinator/.env
vi ~/.hermes/profiles/researcher/.env
vi ~/.hermes/profiles/writer/.env
vi ~/.hermes/profiles/builder/.env
vi ~/.hermes/profiles/runes-holder/.env
```

Replace placeholder values with real local-only values as needed.

Do not change repository templates during this step unless a future template policy phase explicitly requires it.

## Minimal safe review before editing

Use the read-only target lister:

```bash
bash scripts/list-local-secret-fill-targets.sh
```

Expected before manual fill:

```text
ROLE_COUNT=6
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
PLACEHOLDER_ENV_COUNT=6
MANUAL_ENV_CANDIDATE_COUNT=0
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
PASS: local secret manual fill target review completed in read-only mode
```

## Minimal safe review after editing

After manually editing `.env`, do not print file contents. Run:

```bash
bash scripts/check-post-secret-fill-readiness.sh
```

Expected after manual fill, if all placeholders are replaced:

```text
ROLE_COUNT=6
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
PLACEHOLDER_ENV_COUNT=0
MANUAL_ENV_CANDIDATE_COUNT=6
REPO_SECRET_RISK_COUNT=0
REPO_LOCAL_CONFIG_RISK_COUNT=0
PASS: post-secret-fill runtime readiness check completed in read-only mode
```

Then run post-secret runtime smoke:

```bash
bash scripts/check-post-secret-runtime-smoke.sh
```

Expected after manual fill:

```text
PROFILE_SHOW_PASS_COUNT=6
PROFILE_SHOW_FAIL_COUNT=0
DOCTOR_PASS_COUNT=6
DOCTOR_FAIL_COUNT=0
PLACEHOLDER_ENV_COUNT=0
MANUAL_ENV_CANDIDATE_COUNT=6
PASS: post-secret runtime smoke completed in read-only mode
```

## Non-goals

Phase 3L.1 does not:

- auto-write real secrets
- print secret values
- start gateway
- run chat
- mutate repo profile templates
- relax the no-secrets-in-git rule

## Verification summary

Phase 3L.1 is complete when:

```text
scripts/list-local-secret-fill-targets.sh exists
manual fill checklist exists
read-only target review passes
repo secret risk remains 0
Phase 3L.2 manual secret fill execution/review is defined as next action
```

## Next action

Phase 3L.2 local secret manual fill execution / post-fill readiness review
