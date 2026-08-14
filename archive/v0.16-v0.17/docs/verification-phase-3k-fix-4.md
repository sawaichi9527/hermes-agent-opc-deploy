# Phase 3K-FIX.4 Guarded Drift Cleanup Implementation

Status: implemented / pending local verification  
Scope: guarded cleanup script for OPC-managed generic drift profile directories  
Real profile write: disabled by default  
Real profile delete: disabled by default; requires explicit cleanup token  
Restore execution: disabled

---

## Purpose

Phase 3K-FIX.4 adds a guarded cleanup implementation for the generic role skeletons created during Phase 3J and later classified as taxonomy drift.

This phase does not automatically remove real profiles. It only adds a script that can delete drift directories when the user explicitly runs guarded cleanup with the cleanup confirmation token.

---

## Implemented Script

```text
scripts/cleanup-drift-profiles.sh
```

Default behavior:

```text
Mode: dry-run
Real cleanup: DISABLED
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

Guarded cleanup command:

```bash
bash scripts/cleanup-drift-profiles.sh \
  --apply \
  --confirm REAL_CLEANUP_DRIFT_PROFILES
```

The script is intentionally separate from `scripts/deploy-real-profiles.sh` so deploy and cleanup permissions are not mixed.

---

## Drift Role Set

Only these drift roles are considered:

```text
default
developer
reviewer
operator
trial
```

Canonical roles are never targeted by the drift cleanup script:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

---

## Cleanup Candidate Rules

A real profile directory is eligible for deletion only when all of the following are true:

1. The role is in the drift role set.
2. The path is under the configured real profile root.
3. The path is a directory.
4. The directory contains `.opc-managed-profile`.
5. The marker contains exactly:

```text
managed_by=hermes-agent-opc-deploy
source_root=<repo>/profiles
role=<role>
```

Any mismatch results in a blocked status and no deletion.

---

## Expected Dry-run Verification

```bash
bash -n scripts/cleanup-drift-profiles.sh

bash scripts/cleanup-drift-profiles.sh | grep -E \
  "PHASE 3K-FIX.4 GUARDED DRIFT CLEANUP|Mode: dry-run|Real cleanup: DISABLED|DRIFT_ROLE=default|DRIFT_ROLE=trial|status: CLEANUP_CANDIDATE|cleanup_action: would delete|CLEANUP_CANDIDATE_COUNT=5|BLOCKED_COUNT=0|MISSING_COUNT=0|DELETED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|PASS: guarded drift cleanup dry-run completed"
```

Expected result before real cleanup:

```text
CLEANUP_CANDIDATE_COUNT=5
BLOCKED_COUNT=0
MISSING_COUNT=0
DELETED_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

---

## Expected Guard Rejection Verification

Running apply without the cleanup token must be rejected:

```bash
bash scripts/cleanup-drift-profiles.sh --apply && echo "UNEXPECTED" || echo "PASS: cleanup apply without confirm rejected"
```

Expected rejection markers:

```text
ERROR: guarded cleanup requires: --confirm REAL_CLEANUP_DRIFT_PROFILES
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

Passing a token without `--apply` must also be rejected:

```bash
bash scripts/cleanup-drift-profiles.sh --confirm REAL_CLEANUP_DRIFT_PROFILES && echo "UNEXPECTED" || echo "PASS: confirm without apply rejected"
```

---

## Real Cleanup Command

Real cleanup is not automatic. The operator may run it only after dry-run verification is reviewed:

```bash
bash scripts/cleanup-drift-profiles.sh \
  --apply \
  --confirm REAL_CLEANUP_DRIFT_PROFILES
```

Expected successful apply markers:

```text
Mode: apply
Real cleanup: GUARDED_CLEANUP_REQUESTED
DELETED_ROLE=default
DELETED_ROLE=developer
DELETED_ROLE=reviewer
DELETED_ROLE=operator
DELETED_ROLE=trial
DELETED_COUNT=5
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=true
PASS: guarded drift cleanup completed
```

---

## Post-cleanup Verification

After real cleanup is executed, the planner should show all drift profiles as missing:

```bash
bash scripts/plan-drift-profile-cleanup.sh | grep -E \
  "MISSING_COUNT=5|CLEANUP_CANDIDATE_COUNT=0|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|PASS: drift cleanup planning completed in read-only mode"
```

The real profile root should no longer contain the drift directories:

```bash
for role in default developer reviewer operator trial; do
  test ! -e "$HOME/.hermes/profiles/$role" && echo "PASS removed $role"
done
```

Canonical readiness should remain READY because canonical source roots are repo-local and config-driven:

```bash
./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

---

## Safety Result

Phase 3K-FIX.4 implementation is safe to review because:

1. Default mode is dry-run.
2. Real cleanup requires a cleanup-specific token, not the deploy token.
3. Only known drift roles are targeted.
4. Marker ownership is rechecked before deletion.
5. Canonical roles are not targeted.
6. `REAL_PROFILE_DELETE=true` is emitted only during successful apply.

---

## Lock Wording After Local Verification

If dry-run and guard rejection pass, lock as:

```text
Phase 3K-FIX.4 guarded drift cleanup implementation
PASS / dry-run cleanup PASS / apply requires cleanup token / no real delete during verification
```

If the operator also executes real cleanup successfully, lock the execution as:

```text
Phase 3K-FIX.4 guarded drift cleanup execution
PASS / five OPC-managed drift profiles deleted / planner reports missing / canonical readiness READY
```

---

## Next Step

If implementation verification passes but real cleanup has not run:

```text
Phase 3K-FIX.5 guarded drift cleanup execution
```

If the operator executes cleanup during Phase 3K-FIX.4 verification, the next step becomes:

```text
Phase 3K-FIX.5 post-cleanup source taxonomy cleanup
```
