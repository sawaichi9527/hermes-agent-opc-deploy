# Taxonomy Correction Plan

Status: Phase 3K-FIX.1 correction plan documented  
Scope: planning only  
Real profile cleanup: disabled  
Real profile apply: disabled

---

## Purpose

Phase 3K introduced and documented a role taxonomy drift.

The generic OPC deploy roles were:

- `default`
- `developer`
- `reviewer`
- `operator`
- `trial`

These roles were useful for early guarded deploy mechanics, but they do not match the Hermes maintainer role taxonomy already described by the project.

Phase 3K-FIX.1 defines the correction plan. It does not delete repo files, remove real profiles, or perform another guarded apply.

---

## Canonical Role Decision

The canonical deploy role taxonomy should align with the existing Hermes maintainer model:

- `secretary`
- `coordinator`
- `researcher`
- `writer`
- `builder`
- `runes-holder`

This set should replace the generic OPC deploy role set for future real profile deployment.

---

## Drift Artifacts

The following repo-local directories are drift artifacts:

- `profiles/default/`
- `profiles/developer/`
- `profiles/reviewer/`
- `profiles/operator/`
- `profiles/trial/`

The following real directories are drift artifacts from the first guarded apply:

- `~/.hermes/profiles/default/`
- `~/.hermes/profiles/developer/`
- `~/.hermes/profiles/reviewer/`
- `~/.hermes/profiles/operator/`
- `~/.hermes/profiles/trial/`

They were confirmed to be OPC-managed skeletons because each real directory contains `.opc-managed-profile` with:

- `managed_by=hermes-agent-opc-deploy`
- `phase=3E`
- `deployed_at=20260613-161857`
- `source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles`

Because they are managed drift artifacts, they may be cleaned later by a guarded cleanup step.

---

## Correction Sequence

Recommended correction sequence:

1. Stop Phase 3L content sync.
2. Lock this taxonomy correction plan.
3. Update scripts to use canonical roles.
4. Create repo-local canonical role directories under `profiles/`.
5. Update readiness checks to require the canonical roles.
6. Add a read-only cleanup planner for the drift real profiles.
7. Execute guarded cleanup only after human review.
8. Re-run readiness using canonical roles.
9. Perform a new guarded apply only after readiness is `READY` for the canonical role set.

---

## Script Updates Required

The following scripts should stop hardcoding the generic role set:

- `scripts/deploy-real-profiles.sh`
- `scripts/check-real-deploy-readiness.sh`
- `scripts/plan-restore-real-profiles.sh` if it reports role expectations

The canonical role list should become:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

A small shared role config file may be added if it keeps scripts simpler, but no database, daemon, or orchestration layer should be introduced.

Preferred simple option:

```text
config/profile-roles.txt
```

The scripts can read this file line by line. This avoids repeating role lists across scripts while remaining plain and transparent.

---

## Repo Cleanup Plan

Future repo cleanup should remove the generic source role directories after canonical directories exist and pass readiness.

Remove later:

- `profiles/default/`
- `profiles/developer/`
- `profiles/reviewer/`
- `profiles/operator/`
- `profiles/trial/`

Add later:

- `profiles/secretary/`
- `profiles/coordinator/`
- `profiles/researcher/`
- `profiles/writer/`
- `profiles/builder/`
- `profiles/runes-holder/`

The repo cleanup should be committed before any new real guarded apply.

---

## Real Cleanup Plan

Future real cleanup should remove only managed drift artifacts.

A cleanup script must verify each candidate directory contains `.opc-managed-profile` and that the marker contains:

```text
managed_by=hermes-agent-opc-deploy
```

It should also verify that the role is one of the drift roles:

```text
default
developer
reviewer
operator
trial
```

The cleanup should default to read-only planning. Any real delete must require an explicit confirmation token.

Suggested command shape:

```bash
./scripts/cleanup-drift-profiles.sh --apply --confirm CLEANUP_DRIFT_PROFILES
```

Phase 3K-FIX.1 does not implement cleanup.

---

## Backup / Restore Requirement

Before deleting any real drift profile, the existing restore policy remains active.

Required controls:

1. Preserve the Phase 3J backup record.
2. Print the current real profile tree before cleanup.
3. Print every managed drift role planned for deletion.
4. Refuse to delete unmarked directories.
5. Refuse to delete directories with unknown ownership.
6. Keep cleanup local and filesystem-based.

---

## What This Phase Does Not Do

Phase 3K-FIX.1 does not:

- delete repo profile directories
- delete real `~/.hermes/profiles/` directories
- perform real guarded apply
- perform restore
- introduce enterprise orchestration
- introduce daemon or database state

---

## Acceptance Criteria

Phase 3K-FIX.1 is PASS if:

1. `docs/taxonomy-correction-plan.md` exists.
2. Canonical roles are documented.
3. Drift roles are documented.
4. Real drift artifacts are documented as OPC-managed skeletons.
5. Phase 3L remains blocked.
6. Future cleanup is planned but not executed.
7. No real write occurs.

---

## Lock Wording

```text
Phase 3K-FIX.1 taxonomy correction plan
PASS / canonical Hermes roles selected / generic OPC roles marked drift / cleanup planned / no real write
```

---

## Next Phase

Recommended next phase:

```text
Phase 3K-FIX.2 canonical role config and readiness rewrite
```

That phase should update scripts and repo role source roots to use the canonical Hermes role taxonomy.
