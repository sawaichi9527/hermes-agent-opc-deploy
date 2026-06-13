# Phase 3K-FIX.3 Drift Cleanup Planning

Status: read-only cleanup planner implemented  
Scope: plan cleanup for OPC-managed generic profile skeleton drift artifacts  
Real profile write: disabled  
Real profile delete: disabled  

---

## Purpose

Phase 3K-FIX.3 adds a read-only planner for the generic profile skeletons created during Phase 3J before the role taxonomy correction.

The drift roles are:

```text
default
developer
reviewer
operator
trial
```

The canonical Hermes deploy roles are now driven by:

```text
config/profile-roles.txt
```

and are:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Phase 3K-FIX.3 does not remove the drift directories. It only identifies which real directories are safe candidates for a future guarded cleanup phase.

---

## Added Script

```text
scripts/plan-drift-profile-cleanup.sh
```

The script is read-only and must emit:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

It must not call `rm`, `mv`, `cp`, or any other file mutation operation against `~/.hermes/profiles/`.

---

## Cleanup Candidate Rules

A real drift profile directory may be marked as `CLEANUP_CANDIDATE` only when all of these conditions are true:

1. The role is one of the known drift roles:

   ```text
   default
   developer
   reviewer
   operator
   trial
   ```

2. The directory exists under the real profile root:

   ```text
   ~/.hermes/profiles/<role>/
   ```

3. The directory contains:

   ```text
   .opc-managed-profile
   ```

4. The marker contains:

   ```text
   managed_by=hermes-agent-opc-deploy
   ```

5. The marker source root matches the current repo profile source root:

   ```text
   source_root=<repo>/profiles
   ```

6. The marker role matches the inspected role:

   ```text
   role=<role>
   ```

If any of these conditions fail, the role must be reported as blocked or missing, not as a cleanup candidate.

---

## Expected Local Verification

Run:

```bash
cd ~/workspace/hermes-agent-opc-deploy

bash -n scripts/plan-drift-profile-cleanup.sh

bash scripts/plan-drift-profile-cleanup.sh | grep -E \
  "PHASE 3K-FIX.3 DRIFT CLEANUP PLANNING ONLY|Mode: read-only|Real cleanup: DISABLED|DRIFT_ROLE=default|DRIFT_ROLE=trial|status: CLEANUP_CANDIDATE|CLEANUP_CANDIDATE_COUNT=5|BLOCKED_COUNT=0|MISSING_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|PASS: drift cleanup planning completed in read-only mode"
```

Because the user already verified that the five drift real profile directories are OPC-managed skeletons, the expected result on the current machine is:

```text
CLEANUP_CANDIDATE_COUNT=5
BLOCKED_COUNT=0
MISSING_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
PASS: drift cleanup planning completed in read-only mode
```

---

## Non-Goals

Phase 3K-FIX.3 does not:

- delete real profiles
- restore backups
- deploy canonical profiles
- update real `~/.hermes/profiles/`
- sync Phase 3K content
- remove repo drift directories
- perform Phase 3L

---

## Lock Wording

After local verification, Phase 3K-FIX.3 may be locked as:

```text
Phase 3K-FIX.3 drift cleanup planning
PASS / read-only cleanup planner implemented / five OPC-managed drift candidates expected / no real delete / no real write
```

---

## Next Phase

Recommended next phase:

```text
Phase 3K-FIX.4 guarded drift cleanup implementation
```

Phase 3K-FIX.4 should add a separate guarded cleanup command that can remove only confirmed OPC-managed drift directories, with an explicit confirmation token. It should not remove canonical roles or unmarked user-authored profiles.
