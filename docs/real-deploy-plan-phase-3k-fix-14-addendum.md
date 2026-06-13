# Real Deploy Plan Addendum - Phase 3K-FIX.14

Status: Phase 3K-FIX.14 native profile template guarded apply planning implemented

## Result

```text
Phase 3K-FIX.14 native profile template guarded apply planning
PASS / read-only apply planner added / repo-owned template apply boundary documented / local-only files protected / no real write / no real delete / no secret write
```

## Purpose

This addendum records the transition from repository-side native profile source templates to a future guarded apply path.

The goal is to make the future real apply safe, narrow, and auditable.

## Read-only Planner

```text
scripts/plan-native-template-apply.sh
```

The planner does not write to real profile directories.

It reports future apply candidates and protected local-only state.

## Future Apply Scope

Future guarded apply may copy only:

```text
SOUL.md
profile.yaml
config.yaml.template
.env.template
```

from:

```text
profiles/<role>/
```

to:

```text
~/.hermes/profiles/<role>/
```

## Protected Local-only Scope

Future guarded apply must never create, overwrite, delete, or mutate:

```text
.env
config.yaml
auth.json
state.db
state.db-wal
state.db-shm
gateway.pid
gateway_state.json
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

## Guard Token for Future Apply

```text
REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

## Safety Flags

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
```

## What Is Still Not Done

```text
no native template apply execution yet
no real .env provisioning
no real config.yaml provisioning
no alias creation
no skills initialization
no gateway start
no chat/oneshot smoke
```

## Next Action

```text
Phase 3K-FIX.15 native profile template guarded apply execution
```
