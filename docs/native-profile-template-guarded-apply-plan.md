# Phase 3K-FIX.14 Native Profile Template Guarded Apply Plan

Status: Phase 3K-FIX.14 native profile template guarded apply planning documented

## Scope

This phase defines the future guarded apply boundary for synchronizing repository-owned native profile templates into real Hermes profiles under `~/.hermes/profiles/<role>/`.

This phase is planning-only.

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
```

## Background

Phase 3K-FIX.13 completed repository-side native profile template source alignment.

Each canonical role now has:

```text
profiles/<role>/SOUL.md
profiles/<role>/profile.yaml
profiles/<role>/config.yaml.template
profiles/<role>/.env.template
```

The real profile filesystem already exists under:

```text
~/.hermes/profiles/secretary
~/.hermes/profiles/coordinator
~/.hermes/profiles/researcher
~/.hermes/profiles/writer
~/.hermes/profiles/builder
~/.hermes/profiles/runes-holder
```

Hermes CLI profile discovery and per-profile doctor inspection have confirmed that the profiles are visible and resolvable by `hermes profile` / `hermes -p <role> doctor`, but runtime health remains partial because local-only `.env`, `config.yaml`, aliases, and optional skills are not configured.

## Future Apply Target

A future guarded apply MAY copy these repository-owned files from `profiles/<role>/` into `~/.hermes/profiles/<role>/`:

```text
SOUL.md
profile.yaml
config.yaml.template
.env.template
```

These are source-controlled templates or metadata.

They do not contain real secrets.

## Local-only Protected Files

The future apply MUST NOT create, overwrite, delete, or modify these local-only files:

```text
.env
config.yaml
auth.json
state.db
state.db-wal
state.db-shm
gateway.pid
gateway_state.json
```

Rationale:

- `.env` may contain real API keys or local tokens.
- `config.yaml` may contain real provider/model/user-local settings.
- auth/runtime/state files belong to Hermes Agent runtime.
- state databases and gateway state must not be source-controlled or overwritten by repo apply.

## Local-only Protected Directories

The future apply MUST NOT delete, overwrite, replace, or recursively copy over these directories:

```text
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

Rationale:

- They contain runtime data, user data, profile-local history, generated state, skills installed by Hermes, or future local customization.
- They are not part of repo-owned profile template alignment.

## Guard Token for Future Apply

A future real apply must require the explicit confirmation token:

```text
REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

Without this token, the apply path must remain dry-run/read-only.

## Read-only Planner

The read-only planner is:

```bash
bash scripts/plan-native-template-apply.sh
```

It reports:

```text
APPLY_CANDIDATE role=<role> path=<template> action=create_repo_owned_template
APPLY_CANDIDATE role=<role> path=<template> action=replace_repo_owned_template
APPLY_STATUS role=<role> path=<template> status=already_in_sync
LOCAL_ONLY_PROTECTED role=<role> path=<local-only> status=present_no_touch
LOCAL_ONLY_PROTECTED role=<role> path=<local-only> status=absent_no_create
```

The planner must always report:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
```

## Expected Planning Result

Current expected planning outcome after Phase 3K-FIX.13 and Phase 3K-FIX.10:

```text
ROLE_COUNT=6
MISSING_SOURCE_COUNT=0
MISSING_DESTINATION_COUNT=0
BLOCKED_COUNT=0
```

`APPLY_CANDIDATE_COUNT` may be greater than zero because real profile templates may not yet match repo source templates.

This does not indicate failure.

## Non-goals

This phase does not:

- run `hermes setup`
- run `hermes profile create`
- create `.env`
- copy secrets from the default profile
- overwrite `config.yaml`
- install skills
- start gateways
- create aliases
- run chat/oneshot smoke
- modify real profile files

## Future Execution Boundary

The future guarded apply may only implement this exact behavior:

```text
for each canonical role:
  source = profiles/<role>/<repo-owned-template>
  destination = ~/.hermes/profiles/<role>/<same-template>
  copy source to destination only after explicit guard token
  preserve local-only files and directories
  preserve real .env
  preserve real config.yaml
  preserve runtime state
```

## Final Lock Target

```text
Phase 3K-FIX.14 native profile template guarded apply planning
PASS / read-only apply planner added / repo-owned template apply boundary documented / local-only files protected / no real write / no real delete / no secret write
```

## Next Action

```text
Phase 3K-FIX.15 native profile template guarded apply execution
```
