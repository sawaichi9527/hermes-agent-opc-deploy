# Phase 3G Real Deploy Readiness Gate

Status: readiness gate documented / pending local verification  
Scope: read-only readiness verification  
Real deploy: disabled  
Real restore: disabled  
Current guarantee: this phase does not write to real `~/.hermes/profiles/`

---

## Purpose

Phase 3G adds the final read-only gate before any real user-HOME deployment.

The project already has guarded apply implemented in `scripts/deploy-real-profiles.sh`, but a real apply should not happen until the deploy source root is known to be complete and the user's real profile tree has been inspected for ownership risk.

Phase 3G therefore locks the readiness rule:

- if no complete source root exists, real apply remains blocked
- if real destination roles exist without the managed marker, real apply remains blocked
- if restore planning is unavailable, real apply remains blocked
- if all checks pass, Phase 3H may perform the first explicit guarded apply

This is still personal/local usage only. No daemon, database, service, or enterprise orchestration is introduced.

---

## Required Roles

The deployable source root must contain all required role directories:

- `default/`
- `developer/`
- `reviewer/`
- `operator/`
- `trial/`

Partial source roots are not accepted for real apply.

---

## Candidate Source Roots

The readiness checker inspects the same simple candidate roots used by the deploy script:

- `profiles/`
- `templates/`
- `simulation/profiles/`
- `simulated-home/.hermes/profiles/`

The user may also pass:

    --source-root PATH

An explicit source root must still contain all required roles.

---

## Readiness Script

Phase 3G adds:

    scripts/check-real-deploy-readiness.sh

The script is read-only. It must not create, copy, delete, restore, or reset any real Hermes profile files.

Required output markers:

- `Status: PHASE 3G REAL DEPLOY READINESS GATE`
- `REAL_PROFILE_WRITE=false`
- `REAL_RESTORE_WRITE=false`
- `SOURCE_STATUS=complete` or `SOURCE_STATUS=blocked`
- `DESTINATION_STATUS=pass` or `DESTINATION_STATUS=blocked`
- `RESTORE_PLANNER_STATUS=pass` or `RESTORE_PLANNER_STATUS=blocked`
- `READINESS_STATUS=READY` or `READINESS_STATUS=BLOCKED`

---

## Readiness Rules

### Source root rule

A complete source root is required.

Ready only if:

1. a source root exists, and
2. it contains all required role directories.

Blocked if:

- no candidate source root exists
- only a partial source root exists
- explicit `--source-root` path is missing
- explicit `--source-root` path lacks one or more required role directories

### Destination ownership rule

Existing destination role directories under real `~/.hermes/profiles/` are safe only if they either do not exist or contain the managed marker:

    .opc-managed-profile

Blocked if any required role destination exists without that marker.

This protects pre-existing personal Hermes profiles from accidental overwrite.

### Restore readiness rule

Restore planning must be available before real apply.

Ready only if:

- `docs/restore-policy.md` exists
- `scripts/plan-restore-real-profiles.sh` exists

The restore planner may be executable locally after `chmod +x`.

---

## Phase 3G Acceptance Criteria

Phase 3G is PASS only if:

1. `docs/verification-phase-3g.md` exists.
2. `scripts/check-real-deploy-readiness.sh` exists.
3. The readiness checker is executable.
4. The readiness checker is read-only.
5. The readiness checker emits `REAL_PROFILE_WRITE=false`.
6. The readiness checker emits `REAL_RESTORE_WRITE=false`.
7. The readiness checker reports source status.
8. The readiness checker reports destination ownership status.
9. The readiness checker reports restore planner status.
10. If the repo lacks a complete source root, readiness is explicitly blocked.
11. The deploy script dry-run still works.
12. The deploy script still rejects incomplete apply authorization.
13. Git working tree is clean after verification.

---

## Expected Lock Wording

If verification passes:

    Phase 3G real deploy readiness gate
    PASS / source root readiness checked / destination ownership checked / restore readiness checked / no real write

If no complete source root exists yet, the phase may still PASS as a gate, but real deployment remains blocked:

    Phase 3G real deploy readiness gate
    PASS / readiness gate implemented / real apply blocked until complete source root exists / no real write

---

## Next Phase

The next phase depends on readiness result.

If `READINESS_STATUS=BLOCKED`:

    Phase 3H profile source root completion

If `READINESS_STATUS=READY`:

    Phase 3H first real guarded apply

Either path must keep real deployment explicit and human-triggered.
