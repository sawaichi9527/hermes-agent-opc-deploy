# Real Deploy Plan Addendum - Phase 3K-FIX.10

Status: Phase 3K-FIX.10 canonical content guarded apply executed  
Date: 2026-06-13  
Scope: real local guarded apply / canonical profile content deployment / no repo mutation during local apply

## Result

Phase 3K-FIX.10 is locked as:

```text
PASS / guarded apply token accepted / backup created / six canonical role READMEs deployed / managed markers present / drift profiles absent / readiness READY
```

## What Changed

The canonical six role profile sources from the repository were applied into the real local Hermes profile root.

Source root:

```text
/home/eye/workspace/hermes-agent-opc-deploy/profiles
```

Real profile root:

```text
/home/eye/.hermes/profiles
```

Applied roles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Guarded Apply Evidence

The guarded apply accepted the required token:

```text
--apply --confirm REAL_DEPLOY_PROFILES
```

Observed result:

```text
PREFLIGHT_STATUS=PASS
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

Backup path:

```text
/home/eye/.hermes/backups/opc-profiles/20260613-172245
```

## Post-Apply Verification

Canonical README files exist in real profile root:

```text
PASS real README secretary
PASS real README coordinator
PASS real README researcher
PASS real README writer
PASS real README builder
PASS real README runes-holder
```

Managed markers exist in real profile root:

```text
PASS real marker secretary
PASS real marker coordinator
PASS real marker researcher
PASS real marker writer
PASS real marker builder
PASS real marker runes-holder
```

The old drift roles remain absent:

```text
PASS real drift absent default
PASS real drift absent developer
PASS real drift absent reviewer
PASS real drift absent operator
PASS real drift absent trial
```

Readiness after apply remains READY:

```text
ROLE_COUNT=6
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

## Current Baseline

The profile deployment baseline is now:

```text
repo canonical source complete
repo drift source removed
real drift profiles removed
real canonical README profiles deployed
real canonical managed markers present
readiness READY
```

## Safety Boundary

Phase 3K-FIX.10 was a real local write, but only through the guarded deploy script.

No additional runtime authority was introduced:

- no daemon
- no database
- no background sync
- no orchestration
- no telemetry
- no automatic mutation path

## Verification Reference

See:

```text
docs/verification-phase-3k-fix-10.md
```

## Next Action

Phase 3K-FIX.11 real profile runtime inspection / smoke planning

Purpose:

- inspect how Hermes Agent discovers profile files
- confirm whether README-only canonical profiles are sufficient for current runtime behavior
- plan a read-only runtime smoke before changing profile schema further
- keep the system personal-local and bounded
