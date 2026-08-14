# Real Deploy Plan Addendum - Phase 3K-FIX.7

Status: Phase 3K-FIX.7 repo drift source cleanup implemented  
Scope: repo source cleanup only  
Real profile write: no  
Real profile delete: no

## Phase result

Phase 3K-FIX.7 removes obsolete repo-local drift source artifacts from the earlier generic OPC role taxonomy:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

The cleanup is repo-only. It does not write to or delete from real `~/.hermes/profiles/`.

## Preserved canonical roles

The canonical Hermes role source directories remain:

```text
profiles/secretary/
profiles/coordinator/
profiles/researcher/
profiles/writer/
profiles/builder/
profiles/runes-holder/
```

The deploy/readiness role list remains config-driven by:

```text
config/profile-roles.txt
```

## Expected post-cleanup planner state

The repo drift source planner should now report:

```text
REPO_CLEANUP_CANDIDATE_COUNT=0
REPO_BLOCKED_COUNT=0
REPO_MISSING_COUNT=5
REPO_PROFILE_WRITE=false
REPO_PROFILE_DELETE=false
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

## Expected readiness state

Canonical readiness should remain:

```text
ROLE_COUNT=6
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

## Verification lock

See:

```text
docs/verification-phase-3k-fix-7.md
```

Expected final lock:

```text
Phase 3K-FIX.7 repo drift source cleanup execution
PASS / obsolete repo drift source artifacts removed / canonical source roles preserved / planner missing=5 / readiness READY / no real write / no real delete
```

## Next phase

```text
Phase 3K-FIX.8 canonical role content hardening
```

Phase 3K-FIX.8 should add small, readable source content to the canonical six role directories only. It should not deploy to real `~/.hermes/profiles/` yet.
