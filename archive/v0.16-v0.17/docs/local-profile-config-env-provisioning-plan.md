# Phase 3K-FIX.18 Local-only Config/Env Provisioning Plan

Status: Phase 3K-FIX.18 local-only config/env provisioning planning documented  
Scope: planning only / read-only planner / no real write / no secret write / no config write  
Date: 2026-06-13

## Purpose

Phase 3K-FIX.18 defines how the six canonical Hermes profiles should be prepared for future runtime use without putting local secrets or local machine configuration into the repository.

This phase intentionally does **not** run `hermes setup`, does **not** create real `.env`, does **not** create real `config.yaml`, and does **not** start gateways or chat sessions.

The goal is to make the local-only provisioning boundary explicit before any real local profile configuration is created.

## Current Context

Earlier phases established:

- six canonical profile source directories exist in the repo;
- six real profile directories exist under `~/.hermes/profiles/<role>/`;
- Hermes CLI discovers all six profiles;
- `SOUL.md` and `profile.yaml` are present after guarded template apply;
- runtime smoke checker passes `hermes profile show` and `hermes -p <role> doctor`;
- `.env` and `config.yaml` are still missing for all six profiles by design.

The missing `.env` and `config.yaml` state is not a deployment failure. It is a local-only provisioning boundary.

## Canonical Roles

The canonical role set remains:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

No obsolete drift roles may be reintroduced:

```text
default
developer
reviewer
operator
trial
```

## Repository-owned Inputs

The repository may contain templates only:

```text
profiles/<role>/.env.template
profiles/<role>/config.yaml.template
```

These files may contain placeholders, comments, safe defaults, and role-specific guidance.

They must not contain:

- real API keys;
- OAuth tokens;
- database passwords;
- Telegram tokens;
- GitHub tokens;
- OpenRouter/OpenAI/LM Studio private endpoints when sensitive;
- workstation-specific local-only secrets;
- user-private credentials.

## Local-only Outputs

The following target files are local-only and must not be committed:

```text
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/config.yaml
```

They may eventually be created manually or by a guarded local script, but they remain outside git.

## Protected Runtime State

The following must not be overwritten or created by repo-side automation in this phase:

```text
auth.json
state.db
state.db-wal
state.db-shm
gateway.pid
gateway_state.json
processes.json
memories/
sessions/
logs/
skills/
cron/
workspace/
home/
plans/
backups/
cache/
```

## Provisioning Candidate Semantics

A missing local `.env` means:

```text
LOCAL_PROVISIONING_CANDIDATE path=.env action=create_locally_from_env_template
```

A missing local `config.yaml` means:

```text
LOCAL_PROVISIONING_CANDIDATE path=config.yaml action=create_locally_from_config_template
```

These are not repo apply candidates. They are future local-only manual or guarded-local-generation candidates.

## Phase 3K-FIX.18 Planner

Phase 3K-FIX.18 adds:

```text
scripts/plan-local-profile-provisioning.sh
```

The planner is read-only.

It reports:

```text
ROLE_COUNT
SOURCE_ENV_TEMPLATE_MISSING_COUNT
SOURCE_CONFIG_TEMPLATE_MISSING_COUNT
MISSING_DESTINATION_COUNT
SOUL_PRESENT_COUNT
PROFILE_YAML_PRESENT_COUNT
REAL_ENV_PRESENT_COUNT
MISSING_ENV_COUNT
REAL_CONFIG_PRESENT_COUNT
MISSING_CONFIG_COUNT
LOCAL_PROVISIONING_CANDIDATE_COUNT
BLOCKED_COUNT
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

## Expected Current Result

Before local-only provisioning, the expected state is:

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

`MISSING_ENV_COUNT=6` and `MISSING_CONFIG_COUNT=6` are expected at this phase.

## Non-goals

Phase 3K-FIX.18 does not:

- run `hermes setup`;
- run `hermes model`;
- run `hermes auth`;
- create real `.env`;
- create real `config.yaml`;
- copy default profile secrets;
- start any gateway;
- run chat or oneshot;
- mutate memory, sessions, logs, or skills;
- write secrets to git.

## Safety Rule

Repo source may define what should be provisioned.

Only local guarded action may create real `.env` or `config.yaml`.

No real secret may enter repo, docs, logs, or verification output.

## Phase 3K-FIX.18 Lock Target

Phase 3K-FIX.18 can be locked when:

```text
planner syntax PASS
planner read-only PASS
ROLE_COUNT=6
source templates complete
real profile destinations present
SOUL/profile.yaml present
.env missing count measured
config.yaml missing count measured
local provisioning candidates measured
BLOCKED_COUNT=0
READINESS_STATUS=READY
working tree clean
```

## Next Step

Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning

That phase may define a guarded local generator, but it must still keep real secrets outside git.
