# Real Deploy Plan Addendum — Phase 3K-FIX.15

Status: Phase 3K-FIX.15 native profile template guarded apply executed  
Scope: guarded local real write completed / no real delete / no secret write / no config write

## Summary

Phase 3K-FIX.15 executed the guarded synchronization of repository-owned native
profile templates into existing Hermes real profile directories.

This phase deliberately separated:

1. Script implementation in the repository.
2. Local dry-run verification.
3. Local guarded apply execution with explicit token.
4. Post-apply verification lock.

All four steps were completed.

## Script

```text
scripts/apply-native-profile-templates.sh
```

## Apply Token

```text
REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

## Files Eligible for Apply

For each canonical role:

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

## Files and State Protected from Apply

The script did not write or remove:

```text
.env
config.yaml
auth.json
state.db*
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

Observed output reported protected local-only paths as either:

```text
present_no_touch
absent_no_create
```

## Local Verification Sequence

Repository sync and clean working tree were verified before execution:

```text
main == origin/main
working tree clean
```

Dry-run passed:

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

Guarded apply executed:

```bash
bash scripts/apply-native-profile-templates.sh \
  --apply \
  --confirm REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

Guarded apply markers:

```text
Mode: apply
Real template apply: GUARDED_APPLY_REQUESTED
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
REAL_PROFILE_WRITE=true
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
PASS: native profile template guarded apply completed
```

Backup path:

```text
/home/eye/.hermes/backups/opc-native-templates/20260613-191800
```

## Post-apply Checks

Native schema checker:

```text
ROLE_COUNT=6
MISSING_PROFILE_YAML_COUNT=0
MISSING_ENV_COUNT=6
MISSING_CONFIG_COUNT=6
MISSING_ALIAS_COUNT=6
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
PASS: native profile schema inspection completed
```

Source template checker:

```text
ROLE_COUNT=6
MISSING_SOURCE_TEMPLATE_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
PASS: native profile source templates complete
```

Readiness checker:

```text
ROLE_COUNT=6
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

## Phase 3K-FIX.15 Final Lock

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
