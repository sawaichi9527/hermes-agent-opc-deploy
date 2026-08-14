# Real Deploy Plan Addendum — Phase 3K-FIX.19

Status: Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning implemented  
Scope: read-only planning only / no real provisioning / no secret write / no config write

## Summary

Phase 3K-FIX.19 adds a guarded execution plan for future local-only `.env` and `config.yaml` provisioning.

It does not execute the provisioning. It only defines and verifies the future guarded boundary.

## Added Planner

```text
scripts/plan-local-profile-provisioning-guarded-apply.sh
```

The planner checks:

- canonical role list
- repo `.env.template` availability
- repo `config.yaml.template` availability
- real profile destination directories
- missing real `.env` candidates
- missing real `config.yaml` candidates
- existing local-only files that must be protected

## Safety Markers

The planner must emit:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

## Future Execution Token

A future guarded execution step must require:

```text
REAL_PROVISION_LOCAL_CONFIG_ENV
```

Without that token, no real provisioning is allowed.

## Expected Current Counts

Given the current real profile state after Phase 3K-FIX.18, the expected planning result is:

```text
ROLE_COUNT=6
SOURCE_ENV_TEMPLATE_MISSING_COUNT=0
SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=0
MISSING_DESTINATION_COUNT=0
ENV_CREATE_CANDIDATE_COUNT=6
CONFIG_CREATE_CANDIDATE_COUNT=6
ENV_EXISTING_PROTECTED_COUNT=0
CONFIG_EXISTING_PROTECTED_COUNT=0
LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=12
BLOCKED_COUNT=0
```

If local provisioning has already occurred in a future phase, the create/protected counts may change, but existing local-only files must remain protected unless a later phase explicitly defines safe overwrite semantics.

## Non-overwrite Rule

The future execution must be create-only by default:

```text
.env present        -> protect / no overwrite
config.yaml present -> protect / no overwrite
.env absent         -> eligible for placeholder creation from .env.template
config.yaml absent  -> eligible for creation from config.yaml.template
```

## Secret Boundary

`.env` is local-only and must never be committed to git.

A future guarded execution script may create placeholder `.env` files from `.env.template`, but must not inject real API keys, tokens, passwords, OAuth credentials, or service secrets.

## Config Boundary

`config.yaml` is local-only in this phase.

A future guarded execution script may create `config.yaml` from `config.yaml.template`, but must not overwrite an existing local `config.yaml` by default.

## Forbidden Operations

Phase 3K-FIX.19 and its future execution boundary forbid:

- git-tracked `.env`
- real secret write
- default overwrite of `.env`
- default overwrite of `config.yaml`
- gateway start
- chat/session smoke
- `hermes setup`
- profile deletion
- runtime state mutation

## Verification Status

Phase 3K-FIX.19 is considered PASS after local verification confirms:

- planner syntax passes
- planner runs read-only
- templates exist
- destinations exist
- candidates/protected counts are measured
- readiness remains READY
- working tree remains clean

## Final Lock

Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning
PASS / read-only guarded provisioning planner added / future token defined / create-only and no-overwrite boundary documented / no real write / no secret write / no config write

## Next Action

Phase 3K-FIX.20 local-only config/env provisioning guarded execution implementation
