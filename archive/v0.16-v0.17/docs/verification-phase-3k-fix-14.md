# Phase 3K-FIX.14 Native Profile Template Guarded Apply Planning

Status: PASS  
Result: read-only apply planner added / repo-owned template apply boundary documented / local-only files protected / no real write / no real delete / no secret write

## Scope

Phase 3K-FIX.14 documents and implements a read-only planning path for future guarded synchronization of repository-owned native profile templates into real Hermes profile directories.

This phase does not write to real profiles.

## Added Files

```text
scripts/plan-native-template-apply.sh
docs/native-profile-template-guarded-apply-plan.md
docs/verification-phase-3k-fix-14.md
docs/real-deploy-plan-phase-3k-fix-14-addendum.md
```

## Planner Boundary

The planner is read-only:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
```

It only compares repository-owned templates under:

```text
profiles/<role>/
```

against real Hermes profile directories under:

```text
~/.hermes/profiles/<role>/
```

## Repository-owned Apply Candidates

A future guarded apply may copy only these files:

```text
SOUL.md
profile.yaml
config.yaml.template
.env.template
```

These are repo-owned templates or metadata.

## Local-only Protected Files

Future apply must preserve and never write:

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

## Local-only Protected Directories

Future apply must preserve and never replace:

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

## Verification Commands

```bash
bash -n scripts/plan-native-template-apply.sh

bash scripts/plan-native-template-apply.sh | grep -E \
  "PHASE 3K-FIX.14|Mode: read-only|ROLE_COUNT=6|MISSING_SOURCE_COUNT=0|MISSING_DESTINATION_COUNT=0|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|CONFIG_WRITE=false|PASS: native profile template guarded apply planning completed in read-only mode"
```

Expected key markers:

```text
Status: PHASE 3K-FIX.14 NATIVE PROFILE TEMPLATE GUARDED APPLY PLANNING ONLY
Mode: read-only
Repo template apply: DISABLED
ROLE_COUNT=6
MISSING_SOURCE_COUNT=0
MISSING_DESTINATION_COUNT=0
BLOCKED_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
PASS: native profile template guarded apply planning completed in read-only mode
```

## Safety Result

```text
no real profile write
no real profile delete
no secret write
no config.yaml write
no .env write
no runtime state mutation
```

## Final Lock

```text
Phase 3K-FIX.14 native profile template guarded apply planning
PASS / read-only apply planner added / repo-owned template apply boundary documented / local-only files protected / no real write / no real delete / no secret write
```

## Next Action

```text
Phase 3K-FIX.15 native profile template guarded apply execution
```
