# Real Deploy Plan

Status: Phase 3K role profile content documented  
Scope: planning, dry-run, guarded apply, verification, restore planning, readiness gating, source-root completion, operator confirmation, first real guarded apply, and role content hardening  
Real profile write: executed only through guarded apply  
Restore execution: disabled  
Target path: `~/.hermes/profiles/`  
Current real apply result: five managed role profile directories deployed  
Current source content result: five role README profiles added under repo-local `profiles/`

---

## Purpose

This plan defines the controlled real deployment path for OPC Hermes Agent profiles.

The project has moved from simulation into staged real-deploy preparation and then through the first guarded real apply:

- Phase 3A: read-only real deploy planning
- Phase 3B: dry-run deploy script
- Phase 3C: dry-run verification lock
- Phase 3D: guarded apply contract
- Phase 3E: guarded apply implementation draft, verified using temporary `HOME`
- Phase 3F: Phase 3E evidence lock and restore planning
- Phase 3G: real deploy readiness gate and source-root preflight
- Phase 3H: canonical repo-local profile source root completion
- Phase 3I: first real guarded apply planning / operator confirmation
- Phase 3J: first real guarded apply verification lock
- Phase 3K: role profile content hardening

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
| Phase 3H profile source root completion | PASS / readiness READY |
| Phase 3I first real guarded apply planning / operator confirmation | PASS / no real write |
| Phase 3J first real guarded apply | PASS / real write executed |
| Phase 3K role profile content hardening | pending local verification |

Evidence and policy files:

- `docs/verification-phase-3c.md`
- `docs/guarded-apply-contract.md`
- `docs/implementation-phase-3e.md`
- `docs/verification-phase-3e.md`
- `docs/restore-policy.md`
- `docs/verification-phase-3g.md`
- `docs/verification-phase-3h.md`
- `docs/verification-phase-3i.md`
- `docs/verification-phase-3j.md`
- `docs/verification-phase-3k.md`

Read-only planning / verification scripts:

- `scripts/plan-real-deploy.sh`
- `scripts/plan-restore-real-profiles.sh`
- `scripts/check-real-deploy-readiness.sh`

Guarded apply script:

- `scripts/deploy-real-profiles.sh`

Canonical guarded deploy source root:

- `profiles/`

Real deployment target after Phase 3J:

- `~/.hermes/profiles/`

---

## Phase 3 Boundary

The only implemented write-capable path is guarded apply in `scripts/deploy-real-profiles.sh`.

Guarded apply requires:

    --apply --confirm REAL_DEPLOY_PROFILES

Normal smoke, planning, restore planning, and readiness checks must remain read-only and emit:

    REAL_PROFILE_WRITE=false

Still prohibited outside explicit guarded apply:

- creating directories under real `~/.hermes/profiles/`
- copying files into real `~/.hermes/profiles/`
- deleting or resetting real Hermes profile files
- modifying real Hermes runtime state
- creating backup directories as a side effect of dry-run or planning
- introducing daemon, service, database, queue, or enterprise orchestration
- making Hermes Agent depend on this deployment layer at runtime

---

## Real Deploy Target

Guarded real deploy manages role-based profile directories under:

- `~/.hermes/profiles/default/`
- `~/.hermes/profiles/developer/`
- `~/.hermes/profiles/reviewer/`
- `~/.hermes/profiles/operator/`
- `~/.hermes/profiles/trial/`

These role names follow the Phase 3 real-deploy baseline and should not be expanded unless there is a clear personal-use need.

Real destination tree after Phase 3J:

    ~/.hermes/profiles/
      default/
      developer/
      reviewer/
      operator/
      trial/

Each deployed role directory contains an `.opc-managed-profile` marker.

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

After Phase 3H, Phase 3J, and Phase 3K:

    SOURCE_STATUS=complete
    SOURCE_ROOT=/home/eye/workspace/hermes-agent-opc-deploy/profiles
    READINESS_STATUS=READY

Phase 3K adds small role README profiles to this source root. Phase 3K does not automatically sync those README files into real `~/.hermes/profiles/`; that is reserved for a later guarded apply phase.

---

## Source Content After Phase 3K

Phase 3K adds readable role profile content under:

    profiles/default/README.md
    profiles/developer/README.md
    profiles/reviewer/README.md
    profiles/operator/README.md
    profiles/trial/README.md

The content documents:

- role purpose
- operating boundary
- intended use
- governance notes

The content remains intentionally small and local. It does not introduce runtime services, enterprise orchestration, remote telemetry, databases, queues, or schedulers.

---

## First Real Guarded Apply Result

Phase 3J executed the first explicit guarded apply locally with:

    ./scripts/deploy-real-profiles.sh \
      --apply \
      --confirm REAL_DEPLOY_PROFILES \
      --source-root "$PWD/profiles"

Observed result:

    Mode: apply
    Real deploy: GUARDED_APPLY_REQUESTED
    SOURCE_ROOT=/home/eye/workspace/hermes-agent-opc-deploy/profiles
    SOURCE_STATUS=complete
    PREFLIGHT_STATUS=PASS
    BACKUP_PATH=/home/eye/.hermes/backups/opc-profiles/20260613-161857
    BACKUP_STATUS=created
    APPLIED_ROLE=default
    APPLIED_ROLE=developer
    APPLIED_ROLE=reviewer
    APPLIED_ROLE=operator
    APPLIED_ROLE=trial
    PASS: guarded real deploy completed
    REAL_PROFILE_WRITE=true

Locked result:

    Phase 3J first real guarded apply
    PASS / guarded token accepted / backup created / five role profiles applied / managed markers present / post-apply readiness READY

---

## Backup Policy

Before guarded apply writes to `~/.hermes/profiles/`, it must create a timestamped backup.

Backup root:

    ~/.hermes/backups/opc-profiles/

Backup format:

    ~/.hermes/backups/opc-profiles/YYYYMMDD-HHMMSS/

Phase 3J backup path:

    ~/.hermes/backups/opc-profiles/20260613-161857

Phase 3J backup contents:

    NO_PREVIOUS_PROFILE_TREE.txt

This means no previous real Hermes profile tree existed before the first apply.

Required backup behavior remains:

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

## Phase Locks

### Phase 3A Planning Script

    Phase 3A real deploy read-only planning
    PASS / docs + plan script verified / real ~/.hermes/profiles untouched / no real write

### Phase 3B Dry-run Script

    Phase 3B real deploy dry-run implementation
    PASS / dry-run only / write modes rejected / real ~/.hermes/profiles untouched / executable bit fixed

### Phase 3C Dry-run Verification Lock

    Phase 3C dry-run verification lock / docs alignment
    PASS / Phase 3A+3B evidence locked / real ~/.hermes/profiles untouched / no real write

### Phase 3D Guarded Apply Contract

    Phase 3D real deploy guarded apply planning
    PASS / guarded apply contract documented / no real write / Phase 3E gate defined

### Phase 3E Guarded Apply Implementation

    Phase 3E guarded apply implementation draft
    PASS / dry-run default / guarded apply token enforced / backup-before-write implemented / managed marker implemented / temp HOME apply verified / real ~/.hermes untouched by normal smoke

### Phase 3F Restore Planning

    Phase 3F guarded apply verification lock / restore planning
    PASS / Phase 3E evidence locked / restore policy documented / restore planner read-only / no real restore / executable bit fixed

### Phase 3G Readiness Gate

    Phase 3G real deploy readiness gate
    PASS / readiness gate implemented / source root blocked / destination ownership passed / restore planner passed / no real write / executable bit fixed

### Phase 3H Profile Source Root Completion

    Phase 3H profile source root completion
    PASS / canonical profiles source root complete / readiness READY / no real write

### Phase 3I Operator Confirmation

    Phase 3I first real guarded apply planning / operator confirmation
    PASS / readiness READY locked / operator confirmation checklist documented / no real write

### Phase 3J First Real Guarded Apply

Evidence file:

    docs/verification-phase-3j.md

Lock wording:

    Phase 3J first real guarded apply
    PASS / guarded token accepted / backup created / five role profiles applied / managed markers present / post-apply readiness READY

### Phase 3K Role Profile Content Hardening

Evidence file:

    docs/verification-phase-3k.md

Lock wording after local verification:

    Phase 3K role profile content hardening
    PASS / five role README profiles added / source root remains READY / no real write

---

## Risk Notes

Real profile deployment can affect Hermes Agent behavior.

Main risks:

1. Existing personal Hermes profiles may be overwritten.
2. Role-specific behavior may diverge from upstream Hermes defaults.
3. Incorrect profile layout may make Hermes fail to load a profile.
4. Future upstream Hermes changes may make local OPC templates stale.
5. Reset without backup could permanently lose local profile customization.
6. Source content changes are not active in real profiles until a guarded apply syncs them.

Required controls for future guarded apply remain:

1. Readiness gate reports `READINESS_STATUS=READY`.
2. Selected source root is printed.
3. Destination root is printed.
4. Backup path is printed.
5. Dry-run remains the default behavior.
6. Real write requires explicit `--apply --confirm REAL_DEPLOY_PROFILES`.
7. Existing unmarked destination role directories remain protected.
8. Restore planning remains available before further apply operations.

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

## Phase 3K Acceptance Criteria

Phase 3K is PASS only if:

1. `profiles/default/README.md` exists.
2. `profiles/developer/README.md` exists.
3. `profiles/reviewer/README.md` exists.
4. `profiles/operator/README.md` exists.
5. `profiles/trial/README.md` exists.
6. `docs/verification-phase-3k.md` exists.
7. Readiness checker still reports `READINESS_STATUS=READY`.
8. Readiness checker still emits `REAL_PROFILE_WRITE=false`.
9. No real guarded apply is executed in Phase 3K.
10. Git working tree remains clean after pull and verification.

---

## Next Phase

Recommended next phase:

    Phase 3L second guarded apply / profile content sync

Phase 3L may sync the Phase 3K role README content into real `~/.hermes/profiles/` through guarded apply.

It must still require:

    --apply --confirm REAL_DEPLOY_PROFILES

and must create a backup before writing.
