# Phase 3K-FIX.15 Native Profile Template Guarded Apply Execution

Status: PASS  
Result: guarded apply token accepted / repo-owned templates applied / backup created / local-only files protected / no secret write / no config write

## Scope

Phase 3K-FIX.15 executes the guarded synchronization of repository-owned native
profile templates into existing Hermes real profile directories.

This phase writes only repository-owned template files into:

```text
~/.hermes/profiles/<role>/
```

It does not create or modify real secrets, local config, memory, sessions, logs,
gateway state, or runtime databases.

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

## Repo-owned Files Applied

For each canonical role, only these files were eligible for creation or
replacement:

```text
SOUL.md
profile.yaml
config.yaml.template
.env.template
```

Canonical roles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Local-only Files Protected

The guarded apply script must not create, replace, remove, or modify:

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

Observed apply output confirmed protected local-only paths were reported as
`present_no_touch` or `absent_no_create`, not modified.

## Dry-run Evidence

Local dry-run completed before real apply:

```text
Status: PHASE 3K-FIX.15 NATIVE PROFILE TEMPLATE GUARDED APPLY
Mode: dry-run
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ROLE_COUNT=6
APPLY_CANDIDATE_COUNT=24
APPLIED_TEMPLATE_COUNT=0
MISSING_SOURCE_COUNT=0
MISSING_DESTINATION_COUNT=0
BLOCKED_COUNT=0
PASS: native profile template guarded apply dry-run completed
```

## Guarded Apply Evidence

Local guarded apply command executed:

```bash
bash scripts/apply-native-profile-templates.sh \
  --apply \
  --confirm REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

Observed guarded apply markers:

```text
Status: PHASE 3K-FIX.15 NATIVE PROFILE TEMPLATE GUARDED APPLY
Mode: apply
Real template apply: GUARDED_APPLY_REQUESTED
REAL_PROFILE_WRITE=true
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
BACKUP_STATUS=created
ROLE_COUNT=6
APPLY_CANDIDATE_COUNT=24
APPLIED_TEMPLATE_COUNT=24
ALREADY_IN_SYNC_COUNT=0
MISSING_SOURCE_COUNT=0
MISSING_DESTINATION_COUNT=0
LOCAL_ONLY_PROTECTED_PRESENT_COUNT=30
LOCAL_ONLY_PROTECTED_ABSENT_COUNT=78
BLOCKED_COUNT=0
PASS: native profile template guarded apply completed
```

Backup path recorded by local execution:

```text
/home/eye/.hermes/backups/opc-native-templates/20260613-191800
```

Each role had the following applied templates:

```text
SOUL.md
profile.yaml
config.yaml.template
.env.template
```

Existing `SOUL.md` files were backed up before replacement. New
`profile.yaml`, `config.yaml.template`, and `.env.template` files were created
where absent.

## Post-apply Schema Evidence

After apply, `check-native-profile-schema.sh` reported:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
ROLE_COUNT=6
MISSING_CONFIG_COUNT=6
MISSING_ENV_COUNT=6
MISSING_PROFILE_YAML_COUNT=0
MISSING_ALIAS_COUNT=6
PASS: native profile schema inspection completed
```

`MISSING_PROFILE_YAML_COUNT=0` is the key Phase 3K-FIX.15 improvement.

`MISSING_ENV_COUNT=6`, `MISSING_CONFIG_COUNT=6`, and `MISSING_ALIAS_COUNT=6`
remain expected because real `.env`, real `config.yaml`, and wrapper aliases
are local-only / operator-controlled artifacts and are not created by this
phase.

## Post-apply Source Template Evidence

After apply, repository source templates still passed:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
ROLE_COUNT=6
MISSING_SOURCE_TEMPLATE_COUNT=0
PASS: native profile source templates complete
```

## Post-apply Readiness Evidence

Real deploy readiness remained ready:

```text
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
ROLE_COUNT=6
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

## Safety Result

```text
real profile write: true, guarded and token-confirmed
real profile delete: false
secret write: false
config write: false
local-only state: protected
readiness: READY
```

## Final Lock

```text
Phase 3K-FIX.15 native profile template guarded apply execution
PASS / guarded apply token accepted / repo-owned templates applied / backup created / local-only files protected / no secret write / no config write
```

## Next Planned Phase

```text
Phase 3K-FIX.16 native profile runtime smoke planning
```

Phase 3K-FIX.16 should validate Hermes runtime behavior after template apply,
including `hermes profile show`, `hermes -p <role> doctor`, and a minimal
non-destructive invocation strategy.
