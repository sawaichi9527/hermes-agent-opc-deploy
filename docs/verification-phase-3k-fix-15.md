# Phase 3K-FIX.15 Native Profile Template Guarded Apply Execution Prep

Status: PREPARED  
Result: guarded apply script implemented / local guarded apply execution pending / no remote real write / no secret write

## Scope

Phase 3K-FIX.15 adds the guarded execution script for syncing repository-owned
native profile templates into real Hermes profile directories.

This verification file intentionally does not claim real execution PASS yet.
Real execution must be performed locally because the target paths live under:

```text
~/.hermes/profiles/<role>/
```

## Implemented Script

```text
scripts/apply-native-profile-templates.sh
```

## Guarded Apply Token

```text
REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

## Execution Boundary

The script is dry-run by default.

Real writes require:

```bash
bash scripts/apply-native-profile-templates.sh \
  --apply \
  --confirm REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

## Repo-owned Files Eligible for Apply

For each canonical role, only these files may be created or replaced:

```text
SOUL.md
profile.yaml
config.yaml.template
.env.template
```

## Local-only Files Protected

The script must not create, replace, remove, or modify:

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

## Expected Dry-run Evidence

Before real apply:

```bash
bash -n scripts/apply-native-profile-templates.sh

bash scripts/apply-native-profile-templates.sh | grep -E \
  "PHASE 3K-FIX.15|Mode: dry-run|ROLE_COUNT=6|APPLY_CANDIDATE_COUNT=24|APPLIED_TEMPLATE_COUNT=0|MISSING_SOURCE_COUNT=0|MISSING_DESTINATION_COUNT=0|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|CONFIG_WRITE=false|PASS: native profile template guarded apply dry-run completed"
```

## Expected Guarded Apply Evidence

Real apply should show:

```text
Status: PHASE 3K-FIX.15 NATIVE PROFILE TEMPLATE GUARDED APPLY
Mode: apply
Real template apply: GUARDED_APPLY_REQUESTED
BACKUP_STATUS=created
ROLE_COUNT=6
MISSING_SOURCE_COUNT=0
MISSING_DESTINATION_COUNT=0
BLOCKED_COUNT=0
REAL_PROFILE_WRITE=true
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
PASS: native profile template guarded apply completed
```

The first apply is expected to create or replace up to 24 repo-owned template
files:

```text
APPLIED_TEMPLATE_COUNT=24
```

If some files are already synchronized, `APPLIED_TEMPLATE_COUNT` may be lower
and `ALREADY_IN_SYNC_COUNT` higher.

## Post-apply Expected Runtime Evidence

After real apply, these should continue to pass:

```bash
bash scripts/check-native-profile-schema.sh
bash scripts/check-native-profile-source-templates.sh
./scripts/check-real-deploy-readiness.sh
```

The important status transition expected from `check-native-profile-schema.sh` is:

```text
MISSING_PROFILE_YAML_COUNT=0
```

The checker should still report:

```text
MISSING_ENV_COUNT=6
MISSING_CONFIG_COUNT=6
MISSING_ALIAS_COUNT=6
```

That is expected because real `.env`, real `config.yaml`, and aliases are
local-only / operator-controlled artifacts and are not created by Phase
3K-FIX.15.

## Current Lock

```text
Phase 3K-FIX.15 native profile template guarded apply execution prep
PREPARED / guarded apply script implemented / dry-run available / local guarded apply pending / no remote real write / no secret write
```

## Next Verification Step

After local guarded apply succeeds, create a final execution lock:

```text
Phase 3K-FIX.15 native profile template guarded apply execution
PASS / guarded apply token accepted / repo-owned templates applied / backup created / local-only files protected / no secret write / no config write
```
