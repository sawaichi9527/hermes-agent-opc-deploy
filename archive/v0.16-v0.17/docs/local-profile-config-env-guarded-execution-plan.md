# Phase 3K-FIX.19 Local-only Config/Env Guarded Execution Plan

Status: Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning implemented
Scope: planning only / no real write / no secret write / no config write / no env write

## Purpose

Phase 3K-FIX.18 measured the remaining local-only provisioning gap:

- six `.env` files are missing from real Hermes profiles
- six `config.yaml` files are missing from real Hermes profiles
- repo-owned `.env.template` and `config.yaml.template` files exist for all six canonical roles

Phase 3K-FIX.19 defines the guarded execution boundary for a future local-only provisioning step.
It does **not** execute provisioning.

## Canonical Roles

The guarded plan applies only to the canonical roles in `config/profile-roles.txt`:

- `secretary`
- `coordinator`
- `researcher`
- `writer`
- `builder`
- `runes-holder`

## Future Confirmation Token

A future guarded execution script must require the exact token:

```text
REAL_PROVISION_LOCAL_CONFIG_ENV
```

Without this token, execution must remain dry-run/read-only.

## Allowed Future Local-only Writes

The future guarded execution may create the following files if they are missing:

```text
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/config.yaml
```

The creation source must be:

```text
profiles/<role>/.env.template
profiles/<role>/config.yaml.template
```

## Strict Non-overwrite Rule

If either real local-only file already exists, it must be preserved by default:

```text
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/config.yaml
```

Future guarded execution must report them as:

```text
LOCAL_ONLY_PROTECTED role=<role> path=.env status=present_no_overwrite
LOCAL_ONLY_PROTECTED role=<role> path=config.yaml status=present_no_overwrite
```

No default overwrite mode is allowed for Phase 3K-FIX.19.
A later phase may define explicit overwrite semantics if needed.

## Secret Policy

`.env` is local-only and must never be committed to git.

The repo may contain `.env.template`, but the real `.env` must be created only under the user's local Hermes profile directory.

A future guarded execution script may create a placeholder `.env` from `.env.template`, but it must not inject real secrets.
Real token values must be filled manually by the user or by a separate local-only secret workflow outside git.

Required marker:

```text
SECRET_WRITE=false
```

## Config Policy

`config.yaml` is local-only in this phase.

The repo may contain `config.yaml.template`, but the real `config.yaml` must be created only under the user's local Hermes profile directory.

A future guarded execution script may create `config.yaml` from `config.yaml.template` when absent.
It must not overwrite existing `config.yaml` by default.

Required marker:

```text
CONFIG_WRITE=false
```

in planning/dry-run mode.

## Forbidden Operations

Phase 3K-FIX.19 must not perform or imply any of the following:

- write real `.env`
- write real `config.yaml`
- inject real secrets
- overwrite existing `.env`
- overwrite existing `config.yaml`
- delete profile files
- start gateway
- run chat/session smoke
- run `hermes setup`
- modify memories, sessions, logs, skills, cron, workspace, home, plans, backups, or cache

## Planner Script

Implemented planner:

```bash
bash scripts/plan-local-profile-provisioning-guarded-apply.sh
```

The planner is read-only and reports:

```text
ROLE_COUNT=<n>
SOURCE_ENV_TEMPLATE_MISSING_COUNT=<n>
SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=<n>
MISSING_DESTINATION_COUNT=<n>
ENV_CREATE_CANDIDATE_COUNT=<n>
CONFIG_CREATE_CANDIDATE_COUNT=<n>
ENV_EXISTING_PROTECTED_COUNT=<n>
CONFIG_EXISTING_PROTECTED_COUNT=<n>
LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=<n>
BLOCKED_COUNT=<n>
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

Expected current result after Phase 3K-FIX.18:

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

## Execution Boundary for Future Phase

Phase 3K-FIX.19 only prepares the execution boundary.

A future Phase 3K-FIX.20 may implement the guarded local provisioning script:

```bash
bash scripts/provision-local-profile-config-env.sh \
  --apply \
  --confirm REAL_PROVISION_LOCAL_CONFIG_ENV
```

The future execution script must remain create-only by default.

## Final Lock

Phase 3K-FIX.19 local-only config/env provisioning guarded execution planning
PASS / read-only guarded provisioning planner added / future token defined / create-only and no-overwrite boundary documented / no real write / no secret write / no config write

## Next Action

Phase 3K-FIX.20 local-only config/env provisioning guarded execution implementation
