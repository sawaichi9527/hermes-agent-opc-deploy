# Phase 3K-FIX.5 Guarded Drift Cleanup Execution

Status: PASS  
Scope: real guarded cleanup execution  
Real profile delete: yes, token-gated  
Real profile write: no  
Date: 2026-06-13

## Purpose

Phase 3K-FIX.5 records the first guarded cleanup execution for the temporary generic role profile skeletons that were created during the earlier taxonomy drift.

The cleanup removed only the confirmed OPC-managed drift profile directories:

- `~/.hermes/profiles/default/`
- `~/.hermes/profiles/developer/`
- `~/.hermes/profiles/reviewer/`
- `~/.hermes/profiles/operator/`
- `~/.hermes/profiles/trial/`

The canonical Hermes role source root remains config-driven by `config/profile-roles.txt`.

## Executed Command

```bash
bash scripts/cleanup-drift-profiles.sh \
  --apply \
  --confirm REAL_CLEANUP_DRIFT_PROFILES
```

## Guarded Cleanup Result

Observed output:

```text
Status: PHASE 3K-FIX.4 GUARDED DRIFT CLEANUP
Mode: apply
Real cleanup: GUARDED_CLEANUP_REQUESTED
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=pending
```

Deletion result:

```text
DELETED_ROLE=default
DELETED_ROLE=developer
DELETED_ROLE=reviewer
DELETED_ROLE=operator
DELETED_ROLE=trial
```

Final result:

```text
CLEANUP_CANDIDATE_COUNT=5
BLOCKED_COUNT=0
MISSING_COUNT=0
DELETED_COUNT=5
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=true
PASS: guarded drift cleanup completed
```

## Post-cleanup Removal Verification

Observed verification:

```text
PASS removed default
PASS removed developer
PASS removed reviewer
PASS removed operator
PASS removed trial
```

This confirms the five drift profile directories no longer exist under `~/.hermes/profiles/`.

## Planner State After Cleanup

Observed planner output after cleanup:

```text
CLEANUP_CANDIDATE_COUNT=0
BLOCKED_COUNT=0
MISSING_COUNT=5
REAL_PROFILE_DELETE=false
```

Interpretation:

- There are no remaining cleanup candidates.
- No unsafe or blocked drift profile was detected.
- All five known drift roles are now missing from the real profile root, as intended.
- The planner remains read-only and does not delete files.

## Canonical Readiness After Cleanup

Observed readiness output after cleanup:

```text
REAL_PROFILE_WRITE=false
ROLE_COUNT=6
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
```

Canonical roles remain:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Safety Boundary Confirmed

Phase 3K-FIX.5 performed a real delete, but only after:

1. Phase 3K-FIX.3 read-only planner classified the five drift directories as cleanup candidates.
2. Phase 3K-FIX.4 dry-run showed the exact delete plan.
3. Guarded apply required the explicit token `REAL_CLEANUP_DRIFT_PROFILES`.
4. The cleanup script rechecked marker ownership before deletion.
5. Canonical Hermes roles were never targeted by the cleanup script.

No canonical source directories were deleted.

No canonical real profile directories were deleted.

No deploy apply was executed during this phase.

## Locked Result

```text
Phase 3K-FIX.5 guarded drift cleanup execution
PASS / guarded cleanup token accepted / five drift profiles deleted / planner reports missing=5 / canonical readiness READY
```

## Next Step

```text
Phase 3K-FIX.6 repo drift source cleanup planning
```

The real profile drift directories have now been cleaned.

The repo still contains earlier drift source directories and README files:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

Those repo-side source artifacts should be handled separately, preferably by a read-only planning phase first.
