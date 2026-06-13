# Phase 3K-FIX.10 Canonical Content Guarded Apply Execution

Status: PASS  
Scope: guarded real apply executed / canonical content deployed / no drift profile restore

## Purpose

Phase 3K-FIX.10 executes the guarded canonical content apply planned in Phase 3K-FIX.9.

This phase deploys the canonical six Hermes role profile sources from the repository into the real local Hermes profile root:

```text
source root: /home/eye/workspace/hermes-agent-opc-deploy/profiles
real root:   /home/eye/.hermes/profiles
```

This phase is intentionally narrow:

- deploy canonical role README content
- preserve `.opc-managed-profile` ownership markers
- require guarded token acceptance
- create backup before write
- keep drift roles absent
- keep readiness gate passing after apply

## Guarded Apply Command

The guarded apply command was executed locally:

```bash
bash scripts/deploy-real-profiles.sh \
  --apply \
  --confirm REAL_DEPLOY_PROFILES \
  --source-root "$PWD/profiles"
```

## Apply Evidence

Observed apply output:

```text
Status: PHASE 3K-FIX.2 CANONICAL ROLE GUARDED APPLY
Mode: apply
Real deploy: GUARDED_APPLY_REQUESTED
Repo root: /home/eye/workspace/hermes-agent-opc-deploy
Role config: /home/eye/workspace/hermes-agent-opc-deploy/config/profile-roles.txt
Selected source root: /home/eye/workspace/hermes-agent-opc-deploy/profiles
Real profile root: /home/eye/.hermes/profiles
Backup root: /home/eye/.hermes/backups/opc-profiles
Planned backup dir: /home/eye/.hermes/backups/opc-profiles/20260613-172245
Confirmation token required for apply: REAL_DEPLOY_PROFILES
ROLE_COUNT=6
ROLE=secretary
ROLE=coordinator
ROLE=researcher
ROLE=writer
ROLE=builder
ROLE=runes-holder
SOURCE_ROOT=/home/eye/workspace/hermes-agent-opc-deploy/profiles
SOURCE_STATUS=complete
PREFLIGHT_STATUS=PASS
BACKUP_PATH=/home/eye/.hermes/backups/opc-profiles/20260613-172245
BACKUP_STATUS=created
APPLIED_ROLE=secretary
APPLIED_ROLE=coordinator
APPLIED_ROLE=researcher
APPLIED_ROLE=writer
APPLIED_ROLE=builder
APPLIED_ROLE=runes-holder
PASS: guarded real deploy completed
REAL_PROFILE_WRITE=true
```

## Deployed Canonical Roles

The following real profile README files were verified after apply:

```text
PASS real README secretary
PASS real README coordinator
PASS real README researcher
PASS real README writer
PASS real README builder
PASS real README runes-holder
```

The following real managed markers were verified after apply:

```text
PASS real marker secretary
PASS real marker coordinator
PASS real marker researcher
PASS real marker writer
PASS real marker builder
PASS real marker runes-holder
```

## Marker Evidence

Each canonical role has a managed marker with the expected ownership fields.

Secretary:

```text
managed_by=hermes-agent-opc-deploy
phase=3K-FIX.2
deployed_at=20260613-172245
source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles
role=secretary
```

Coordinator:

```text
managed_by=hermes-agent-opc-deploy
phase=3K-FIX.2
deployed_at=20260613-172245
source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles
role=coordinator
```

Researcher:

```text
managed_by=hermes-agent-opc-deploy
phase=3K-FIX.2
deployed_at=20260613-172245
source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles
role=researcher
```

Writer:

```text
managed_by=hermes-agent-opc-deploy
phase=3K-FIX.2
deployed_at=20260613-172245
source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles
role=writer
```

Builder:

```text
managed_by=hermes-agent-opc-deploy
phase=3K-FIX.2
deployed_at=20260613-172245
source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles
role=builder
```

Runes-holder:

```text
managed_by=hermes-agent-opc-deploy
phase=3K-FIX.2
deployed_at=20260613-172245
source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles
role=runes-holder
```

## Backup Evidence

Backup path created during guarded apply:

```text
/home/eye/.hermes/backups/opc-profiles/20260613-172245
/home/eye/.hermes/backups/opc-profiles/20260613-172245/profiles
```

The backup-before-write requirement was satisfied:

```text
BACKUP_STATUS=created
```

## Drift Profile Absence

The old drift real profiles remained absent after canonical apply:

```text
PASS real drift absent default
PASS real drift absent developer
PASS real drift absent reviewer
PASS real drift absent operator
PASS real drift absent trial
```

## Readiness After Apply

Readiness gate still passes after canonical apply:

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

## Git Working Tree

No repo-side working tree changes were produced by the real apply:

```text
git status --short
```

Observed output: empty.

## Result Lock

```text
Phase 3K-FIX.10 canonical content guarded apply execution
PASS / guarded apply token accepted / backup created / six canonical role READMEs deployed / managed markers present / drift profiles absent / readiness READY
```

## Next Action

Phase 3K-FIX.11 real profile runtime inspection / smoke planning

Purpose:

- inspect how Hermes Agent discovers and consumes `~/.hermes/profiles/*`
- confirm whether README-only role profiles are sufficient for the current runtime
- keep scope read-only first
- avoid introducing daemon / DB / orchestration / telemetry
