# Real Deploy Plan

Status: Phase 3H source root completed  
Scope: planning, dry-run, guarded apply verification, restore planning, readiness gating, and source root completion  
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
- Phase 3H: canonical repo-local profile source root completion

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
| Phase 3G real deploy readiness gate | PASS / source root blocked before Phase 3H |
| Phase 3H profile source root completion | pending local verification |
| Real `~/.hermes/profiles/` untouched by normal smoke | PASS |

Evidence and policy files:

- `docs/verification-phase-3c.md`
- `docs/guarded-apply-contract.md`
- `docs/implementation-phase-3e.md`
- `docs/verification-phase-3e.md`
- `docs/restore-policy.md`
- `docs/verification-phase-3g.md`
- `docs/verification-phase-3h.md`

Read-only planning / verification scripts:

- `scripts/plan-real-deploy.sh`
- `scripts/plan-restore-real-profiles.sh`
- `scripts/check-real-deploy-readiness.sh`

Guarded apply script:

- `scripts/deploy-real-profiles.sh`

Canonical guarded deploy source root:

- `profiles/`

---

## Phase 3 Boundary

Phase 3 may add repo-local planning, dry-run, verification, guarded apply, restore planning, readiness-gate, and source-root files.

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

These role names follow the Phase 3 real-deploy baseline and should not be expanded unless there is a clear personal-use need.

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

Canonical source root after Phase 3H:

    profiles/

Candidate source roots remain:

- `profiles/`
- `templates/`
- `simulation/profiles/`
- `simulated-home/.hermes/profiles/`

A caller may also pass an explicit source root:

    --source-root PATH

The selected source root must be printed before real write.

Phase 3G added a read-only readiness checker:

    scripts/check-real-deploy-readiness.sh

If the checker reports `READINESS_STATUS=BLOCKED`, real apply must not proceed.

After Phase 3H, expected source-root result is:

    SOURCE_STATUS=complete
    SOURCE_ROOT=<repo>/profiles

If destination ownership and restore readiness are safe, expected overall result is:

    READINESS_STATUS=READY

---

## Phase Locks

### Phase 3A Planning Script

`scripts/plan-real-deploy.sh` is read-only.

Lock wording:

    Phase 3A real deploy read-only planning
    PASS / docs + plan script verified / real ~/.hermes/profiles untouched / no real write

### Phase 3B Dry-run Script

`scripts/deploy-real-profiles.sh` began as a dry-run-only script in Phase 3B.

Lock wording:

    Phase 3B real deploy dry-run implementation
    PASS / dry-run only / write modes rejected / real ~/.hermes/profiles untouched / executable bit fixed

### Phase 3C Dry-run Verification Lock

`docs/verification-phase-3c.md` locks Phase 3A and Phase 3B evidence.

Lock wording:

    Phase 3C dry-run verification lock / docs alignment
    PASS / Phase 3A+3B evidence locked / real ~/.hermes/profiles untouched / no real write

### Phase 3D Guarded Apply Contract

`docs/guarded-apply-contract.md` defines the guarded real deployment contract.

Lock wording:

    Phase 3D real deploy guarded apply planning
    PASS / guarded apply contract documented / no real write / Phase 3E gate defined

### Phase 3E Guarded Apply Implementation

`scripts/deploy-real-profiles.sh` now implements the guarded apply draft.

Default mode remains dry-run:

    ./scripts/deploy-real-profiles.sh

Real write requires explicit guarded apply:

    ./scripts/deploy-real-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES

Phase 3E was verified against temporary `HOME`, not the user's real `~/.hermes/profiles/`.

Lock wording:

    Phase 3E guarded apply implementation draft
    PASS / dry-run default / guarded apply token enforced / backup-before-write implemented / managed marker implemented / temp HOME apply verified / real ~/.hermes untouched by normal smoke

### Phase 3F Restore Planning

Phase 3F adds restore planning without implementing real restore.

Policy file:

    docs/restore-policy.md

Read-only planner:

    scripts/plan-restore-real-profiles.sh

Lock wording:

    Phase 3F guarded apply verification lock / restore planning
    PASS / Phase 3E evidence locked / restore policy documented / restore planner read-only / no real restore / executable bit fixed

### Phase 3G Readiness Gate

Phase 3G adds the final read-only readiness gate before any real user-HOME deployment.

Readiness checker:

    scripts/check-real-deploy-readiness.sh

Phase 3G was verified as implemented and read-only. Before Phase 3H, it correctly blocked real apply because no complete source root existed.

Lock wording:

    Phase 3G real deploy readiness gate
    PASS / readiness gate implemented / source root blocked / destination ownership passed / restore planner passed / no real write / executable bit fixed

### Phase 3H Profile Source Root Completion

Phase 3H completes the canonical repo-local source root:

    profiles/

Required guarded deploy role directories now exist:

    profiles/default/
    profiles/developer/
    profiles/reviewer/
    profiles/operator/
    profiles/trial/

Evidence file:

    docs/verification-phase-3h.md

Phase 3H does not perform a real apply.

Recommended lock wording if readiness becomes READY:

    Phase 3H profile source root completion
    PASS / canonical profiles source root complete / readiness READY / no real write

Recommended lock wording if destination ownership blocks readiness:

    Phase 3H profile source root completion
    PASS / canonical profiles source root complete / readiness blocked by destination ownership / no real write

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
8. Phase 3G readiness gate remains PASS.
9. Phase 3H source root is complete.
10. Readiness gate reports `READINESS_STATUS=READY`.
11. Real `~/.hermes/profiles/` is inspected before write.
12. The selected source root is printed.
13. The destination root is printed.
14. The backup path is printed.
15. Dry-run remains the default behavior.
16. Real write requires explicit confirmation.
17. Existing unmarked profile directories are protected.

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
- human-reviewed promotion from source root to real deploy

The deployment layer should help the user operate Hermes Agent safely. It should not become a second platform that Hermes Agent must depend on.

---

## Phase 3H Acceptance Criteria

Phase 3H is PASS only if:

1. `profiles/default/` exists.
2. `profiles/developer/` exists.
3. `profiles/reviewer/` exists.
4. `profiles/operator/` exists.
5. `profiles/trial/` exists.
6. `profiles/README.md` documents the Phase 3H guarded deploy role set.
7. `docs/verification-phase-3h.md` exists.
8. Readiness checker reports `SOURCE_STATUS=complete`.
9. Readiness checker reports `READINESS_STATUS=READY`, unless destination ownership blocks real apply.
10. Deploy script default dry-run still reports `REAL_PROFILE_WRITE=false`.
11. Deploy script still rejects incomplete apply authorization.
12. No real deploy is performed.
13. Git working tree is clean after verification.

---

## Next Phase

If readiness becomes READY:

    Phase 3I first real guarded apply planning / operator confirmation

Phase 3I should still begin with explicit dry-run review before any real apply command is executed.
