# Real Deploy Plan

Status: Phase 3G readiness gate documented  
Scope: planning, dry-run, guarded apply verification, restore planning, and readiness gating  
Real profile write: guarded apply only  
Restore execution: disabled  
Target path: `~/.hermes/profiles/`  
Current guarantee: normal smoke and readiness checks do not touch real `~/.hermes/profiles/`

---

## Purpose

This plan defines the controlled real deployment path for OPC Hermes Agent profiles.

The project has moved from simulation into staged real-deploy preparation:

- Phase 3A: read-only real deploy planning
- Phase 3B: dry-run deploy script
- Phase 3C: dry-run verification lock
- Phase 3D: guarded apply contract
- Phase 3E: guarded apply implementation draft, verified using temporary `HOME`
- Phase 3F: Phase 3E evidence lock and restore planning
- Phase 3G: real deploy readiness gate and source-root preflight

The deployment path must remain simple, personal-use friendly, and lightweight for Hermes Agent. It should help the user operate local profiles safely without becoming a second platform or runtime dependency.

---

## Current Baseline

| Phase | Result |
| --- | --- |
| Phase 1 repo + simulation foundation | PASS |
| Phase 2A SOUL templates | PASS |
| Phase 2B simulation profile deploy | PASS |
| Phase 2C simulation profile verification | PASS |
| Phase 2D profile template static hardening | PASS |
| Phase 2E simulation inspect / diff tooling | PASS |
| Phase 2F simulation runbook freeze | PASS |
| Phase 2 full simulation baseline | PASS |
| Phase 3A real deploy read-only planning | PASS |
| Phase 3B real deploy dry-run implementation | PASS |
| Phase 3C dry-run verification lock / docs alignment | PASS |
| Phase 3D real deploy guarded apply planning | PASS |
| Phase 3E guarded apply implementation draft | PASS |
| Phase 3F guarded apply verification lock / restore planning | PASS |
| Phase 3G real deploy readiness gate | in verification |
| Real `~/.hermes/profiles/` untouched by normal smoke | PASS |

Evidence and policy files:

- `docs/verification-phase-3c.md`
- `docs/guarded-apply-contract.md`
- `docs/implementation-phase-3e.md`
- `docs/verification-phase-3e.md`
- `docs/restore-policy.md`
- `docs/verification-phase-3g.md`

Read-only planning / verification scripts:

- `scripts/plan-real-deploy.sh`
- `scripts/plan-restore-real-profiles.sh`
- `scripts/check-real-deploy-readiness.sh`

Guarded apply script:

- `scripts/deploy-real-profiles.sh`

---

## Phase 3 Boundary

Phase 3 may add repo-local planning, dry-run, verification, guarded apply, restore planning, and readiness-gate files.

The only implemented write-capable path is guarded apply in `scripts/deploy-real-profiles.sh`.

Guarded apply requires:

    --apply --confirm REAL_DEPLOY_PROFILES

Normal smoke, planning, restore planning, and readiness checks must remain read-only and emit:

    REAL_PROFILE_WRITE=false

Still prohibited in normal planning or smoke paths:

- creating directories under real `~/.hermes/profiles/`
- copying files into real `~/.hermes/profiles/`
- deleting or resetting real Hermes profile files
- modifying real Hermes runtime state
- creating backup directories as a side effect of dry-run or planning
- introducing daemon, service, database, queue, or enterprise orchestration
- making Hermes Agent depend on this deployment layer at runtime

---

## Future Real Deploy Target

A guarded real deploy may create or update role-based profile directories under:

- `~/.hermes/profiles/default/`
- `~/.hermes/profiles/developer/`
- `~/.hermes/profiles/reviewer/`
- `~/.hermes/profiles/operator/`
- `~/.hermes/profiles/trial/`

These role names follow the current simulation baseline and should not be expanded unless there is a clear personal-use need.

Future destination tree:

    ~/.hermes/profiles/
      default/
      developer/
      reviewer/
      operator/
      trial/

---

## Source Root Gate

A real deploy requires one complete source root containing all required role directories:

- `default/`
- `developer/`
- `reviewer/`
- `operator/`
- `trial/`

Candidate source roots:

- `profiles/`
- `templates/`
- `simulation/profiles/`
- `simulated-home/.hermes/profiles/`

A caller may also pass an explicit source root:

    --source-root PATH

The selected source root must be printed before real write.

Phase 3G adds a read-only readiness checker:

    scripts/check-real-deploy-readiness.sh

If the checker reports `READINESS_STATUS=BLOCKED`, real apply must not proceed.

---

## Phase 3A Planning Script

`scripts/plan-real-deploy.sh` is read-only.

It prints planned roles, candidate source roots, backup policy, reset policy, and `REAL_PROFILE_WRITE=false`.

Lock wording:

    Phase 3A real deploy read-only planning
    PASS / docs + plan script verified / real ~/.hermes/profiles untouched / no real write

---

## Phase 3B Dry-run Script

`scripts/deploy-real-profiles.sh` began as a dry-run-only script in Phase 3B.

Verified dry-run output included:

- `Status: PHASE 3B DRY-RUN ONLY`
- `Real deploy: DISABLED`
- `PASS: real deploy dry-run completed`
- `REAL_PROFILE_WRITE=false`

Lock wording:

    Phase 3B real deploy dry-run implementation
    PASS / dry-run only / write modes rejected / real ~/.hermes/profiles untouched / executable bit fixed

---

## Phase 3D Guarded Apply Contract

`docs/guarded-apply-contract.md` defines the contract for guarded real deployment.

It documents:

- apply confirmation token
- required preflight checks
- deterministic source root selection
- backup-before-write contract
- managed marker and ownership policy
- copy contract
- rollback and restore policy
- Phase 3E acceptance gate

Recommended lock wording:

    Phase 3D real deploy guarded apply planning
    PASS / guarded apply contract documented / no real write / Phase 3E gate defined

---

## Phase 3E Guarded Apply Implementation

`scripts/deploy-real-profiles.sh` now implements the guarded apply draft.

Default mode remains dry-run:

    ./scripts/deploy-real-profiles.sh

Dry-run must emit:

    REAL_PROFILE_WRITE=false

Real write requires explicit guarded apply:

    ./scripts/deploy-real-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES

Phase 3E was verified against temporary `HOME`, not the user's real `~/.hermes/profiles/`.

Locked evidence is recorded in:

    docs/verification-phase-3e.md

Recommended lock wording:

    Phase 3E guarded apply implementation draft
    PASS / dry-run default / guarded apply token enforced / backup-before-write implemented / managed marker implemented / temp HOME apply verified / real ~/.hermes untouched by normal smoke

---

## Phase 3F Restore Planning

Phase 3F adds restore planning without implementing real restore.

Policy file:

    docs/restore-policy.md

Read-only planner:

    scripts/plan-restore-real-profiles.sh

The restore planner may list backup candidates and inspect a selected backup path, but must not create, copy, delete, or restore files.

Restore planner output must include:

- `Status: PHASE 3F RESTORE PLANNING ONLY`
- `Real restore: DISABLED`
- `PASS: restore planning completed in read-only mode`
- `REAL_PROFILE_WRITE=false`

Recommended lock wording:

    Phase 3F guarded apply verification lock / restore planning
    PASS / Phase 3E evidence locked / restore policy documented / restore planner read-only / no real restore / executable bit fixed

---

## Phase 3G Readiness Gate

Phase 3G adds the final read-only readiness gate before any real user-HOME deployment.

Documentation:

    docs/verification-phase-3g.md

Readiness checker:

    scripts/check-real-deploy-readiness.sh

The checker verifies:

1. whether a complete source root exists
2. whether required destination role directories are safe or managed
3. whether restore planning files are present
4. whether real apply should remain blocked or may proceed to Phase 3H

Required output markers:

- `Status: PHASE 3G REAL DEPLOY READINESS GATE`
- `REAL_PROFILE_WRITE=false`
- `REAL_RESTORE_WRITE=false`
- `SOURCE_STATUS=complete` or `SOURCE_STATUS=blocked`
- `DESTINATION_STATUS=pass` or `DESTINATION_STATUS=blocked`
- `RESTORE_PLANNER_STATUS=pass` or `RESTORE_PLANNER_STATUS=blocked`
- `READINESS_STATUS=READY` or `READINESS_STATUS=BLOCKED`

Recommended lock wording if a complete source root exists:

    Phase 3G real deploy readiness gate
    PASS / source root readiness checked / destination ownership checked / restore readiness checked / no real write

Recommended lock wording if no complete source root exists yet:

    Phase 3G real deploy readiness gate
    PASS / readiness gate implemented / real apply blocked until complete source root exists / no real write

---

## Backup Policy

Before guarded apply writes to `~/.hermes/profiles/`, it must create a timestamped backup.

Backup root:

    ~/.hermes/backups/opc-profiles/

Backup format:

    ~/.hermes/backups/opc-profiles/YYYYMMDD-HHMMSS/

Required backup behavior:

1. If `~/.hermes/profiles/` exists, copy the existing tree into the timestamped backup directory.
2. If `~/.hermes/profiles/` does not exist, record that no existing profile tree was present.
3. Never overwrite an existing backup.
4. Print the exact backup path before write.
5. Keep restore instructions explicit and human-triggered.

The backup policy stays file-based and local. No database-backed backup index is needed for this personal-use scope.

---

## Restore / Reset Policy

Restore and reset must be explicit and human-triggered.

Allowed future restore/reset modes:

| Mode | Meaning |
| --- | --- |
| `preview` | Show what would be restored or removed. No writes. |
| `restore-backup` | Restore from a selected backup path. |
| `remove-opc-managed` | Remove only known OPC-managed files. |
| `full-reset` | Dangerous. Restore or remove the whole profile tree only with explicit confirmation. |

Phase 3F only plans restore. It does not implement real restore.

A future restore command must not guess which backup to restore. The user should provide or confirm the backup path explicitly.

---

## Risk Notes

Real profile deployment can affect Hermes Agent behavior.

Main risks:

1. Existing personal Hermes profiles may be overwritten.
2. Role-specific behavior may diverge from upstream Hermes defaults.
3. Incorrect profile layout may make Hermes fail to load a profile.
4. Future upstream Hermes changes may make local OPC templates stale.
5. Reset without backup could permanently lose local profile customization.

Required controls before real user-HOME deployment:

1. Phase 2 full simulation baseline remains PASS.
2. Phase 3A read-only planning remains PASS.
3. Phase 3B dry-run remains PASS.
4. Phase 3C verification lock remains PASS.
5. Phase 3D guarded apply contract remains PASS.
6. Phase 3E guarded apply remains PASS.
7. Phase 3F restore planning remains PASS.
8. Phase 3G readiness gate reports `READINESS_STATUS=READY`.
9. Real `~/.hermes/profiles/` is inspected before write.
10. The selected source root is printed.
11. The destination root is printed.
12. The backup path is printed.
13. Dry-run remains the default behavior.
14. Real write requires explicit confirmation.
15. Existing unmarked profile directories are protected.

---

## Simplicity Policy

This project is for personal/local usage, not enterprise fleet management.

Do not add:

- central profile server
- orchestration daemon
- background reconciler
- database-backed deployment state
- remote telemetry
- multi-user RBAC
- automatic mutation of real profiles
- complex package manager behavior

Prefer:

- plain shell scripts
- readable Markdown
- local timestamped backups
- explicit dry-run output
- simple copy/restore semantics
- human-reviewed promotion from simulation to real deploy

The deployment layer should help the user operate Hermes Agent safely. It should not become a second platform that Hermes Agent must depend on.

---

## Phase 3G Acceptance Criteria

Phase 3G is PASS only if:

1. `docs/verification-phase-3g.md` exists.
2. `scripts/check-real-deploy-readiness.sh` exists.
3. Readiness checker is executable.
4. Readiness checker is read-only.
5. Readiness checker emits `REAL_PROFILE_WRITE=false`.
6. Readiness checker emits `REAL_RESTORE_WRITE=false`.
7. Readiness checker reports source status.
8. Readiness checker reports destination ownership status.
9. Readiness checker reports restore planner status.
10. If the repo lacks a complete source root, readiness is explicitly blocked.
11. Deploy script dry-run still works.
12. Deploy script still rejects incomplete apply authorization.
13. Git working tree is clean after verification.

---

## Next Phase

The next phase depends on readiness result.

If readiness is blocked because no complete source root exists:

    Phase 3H profile source root completion

If readiness is ready:

    Phase 3H first real guarded apply

Either path must keep real deployment explicit and human-triggered.
