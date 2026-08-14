# Real Deploy Plan Addendum — Phase 3K-FIX.18

Status: Phase 3K-FIX.18 local-only config/env provisioning planning implemented  
Result: read-only local provisioning planner added / repo templates confirmed as inputs / real `.env` and `config.yaml` remain local-only  
Date: 2026-06-13

## Purpose

This addendum extends the real deploy plan after Phase 3K-FIX.16 runtime smoke PASS.

The next unresolved runtime health gap is local-only provisioning:

```text
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/config.yaml
```

These files must be treated as local-only artifacts and must not be committed to the repository.

## Phase 3K-FIX.18 Action

Phase 3K-FIX.18 adds a read-only planner:

```text
scripts/plan-local-profile-provisioning.sh
```

The planner checks:

- six canonical roles;
- repo `.env.template` presence;
- repo `config.yaml.template` presence;
- real profile destination presence;
- real `SOUL.md` presence;
- real `profile.yaml` presence;
- real `.env` presence or missing state;
- real `config.yaml` presence or missing state;
- local provisioning candidates;
- protected runtime state.

## Safety Boundary

The planner reports but never writes:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

## Expected Current State

At this phase, missing `.env` and missing `config.yaml` are expected:

```text
MISSING_ENV_COUNT=6
MISSING_CONFIG_COUNT=6
LOCAL_PROVISIONING_CANDIDATE_COUNT=12
```

This means there are twelve future local-only provisioning candidates:

```text
6 x .env
6 x config.yaml
```

They are not repository apply candidates.

## Local-only Protected Files

The following are explicitly protected:

```text
.env
config.yaml
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

## Repository Rule

The repository may contain templates only:

```text
profiles/<role>/.env.template
profiles/<role>/config.yaml.template
```

The repository must not contain real `.env`, real `config.yaml`, secrets, tokens, passwords, OAuth credentials, or machine-private runtime state.

## Validation Command

```bash
bash -n scripts/plan-local-profile-provisioning.sh

bash scripts/plan-local-profile-provisioning.sh | grep -E \
  "PHASE 3K-FIX.18|Mode: read-only|ROLE_COUNT=6|SOURCE_ENV_TEMPLATE_MISSING_COUNT=0|SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=0|MISSING_DESTINATION_COUNT=0|SOUL_PRESENT_COUNT=6|PROFILE_YAML_PRESENT_COUNT=6|MISSING_ENV_COUNT=6|MISSING_CONFIG_COUNT=6|LOCAL_PROVISIONING_CANDIDATE_COUNT=12|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|CONFIG_WRITE=false|ENV_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS: local-only config/env provisioning planning completed in read-only mode"
```

## Lock Statement

```text
Phase 3K-FIX.18 local-only config/env provisioning planning
PASS / read-only provisioning planner added / local-only .env and config.yaml boundary documented / provisioning candidates measured / no real write / no secret write / no config write
```

## Next Step

Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning

This next phase may define a guarded local generator, but it must continue to keep real secrets out of the repository and out of verification logs.
