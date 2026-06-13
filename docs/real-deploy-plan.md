# Real Deploy Plan

Status: Phase 3C dry-run verification locked  
Scope: planning, dry-run, and verification lock only  
Real profile write: disabled  
Target path: `~/.hermes/profiles/`  
Current guarantee: real `~/.hermes/profiles/` remains untouched

---

## Purpose

This plan defines the future real deployment path for OPC Hermes Agent
profiles.

The project has moved from Phase 3A read-only planning into Phase 3B dry-run
implementation, and Phase 3C now locks the verification evidence before any
guarded apply design begins.

The real deployment path must remain simple, personal-use friendly, and
lightweight for Hermes Agent. It should help the user operate local profiles
safely without becoming a second platform or runtime dependency.

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
| Real `~/.hermes/profiles/` untouched | PASS |

Phase 3C verification evidence is recorded in:

- `docs/verification-phase-3c.md`

---

## Phase 3 Boundary

Phase 3 may add repo-local planning, dry-run, and verification files.

Phase 3 must not create, modify, or delete real Hermes profile files until a
future guarded apply contract is explicitly designed, reviewed, and accepted.

Still prohibited in the current locked state:

- creating directories under real `~/.hermes/profiles/`
- copying files into real `~/.hermes/profiles/`
- deleting or resetting real Hermes profile files
- modifying real Hermes runtime state
- creating backup directories as a side effect of dry-run
- introducing daemon, service, database, queue, or enterprise orchestration
- making Hermes Agent depend on this deployment layer at runtime

---

## Future Real Deploy Target

A future real deploy may create or update role-based profile directories under:

- `~/.hermes/profiles/default/`
- `~/.hermes/profiles/developer/`
- `~/.hermes/profiles/reviewer/`
- `~/.hermes/profiles/operator/`
- `~/.hermes/profiles/trial/`

These role names follow the current simulation baseline and should not be
expanded unless there is a clear personal-use need.

Future destination tree:

    ~/.hermes/profiles/
      default/
      developer/
      reviewer/
      operator/
      trial/

Each role directory may contain Hermes profile configuration files, SOUL
instructions, templates, or role-specific policy files, depending on the
validated profile format.

---

## Planned Source Candidates

A future deploy script should inspect simple repo-local source candidates
before copying anything.

Candidate source roots:

- `profiles/`
- `templates/`
- `simulation/profiles/`
- `simulated-home/.hermes/profiles/`

The exact source root must be confirmed by dry-run output before any future
real write is allowed.

A future copy map should be role-based:

| Role | Future destination |
| --- | --- |
| `default` | `~/.hermes/profiles/default/` |
| `developer` | `~/.hermes/profiles/developer/` |
| `reviewer` | `~/.hermes/profiles/reviewer/` |
| `operator` | `~/.hermes/profiles/operator/` |
| `trial` | `~/.hermes/profiles/trial/` |

The copy operation should remain a plain filesystem copy. No hidden installer,
background service, or profile registry should be introduced.

---

## Phase 3A Planning Script

`scripts/plan-real-deploy.sh` is read-only.

It prints:

- repo root
- real profile root
- backup root
- current existence of real `~/.hermes/profiles/`
- candidate source roots
- planned role directories
- possible copy map
- backup policy
- reset policy
- `REAL_PROFILE_WRITE=false`

It must not write into:

- `~/.hermes/profiles/`
- `~/.hermes/backups/opc-profiles/`

Lock wording:

    Phase 3A real deploy read-only planning
    PASS / docs + plan script verified / real ~/.hermes/profiles untouched / no real write

---

## Phase 3B Dry-run Script

`scripts/deploy-real-profiles.sh` is dry-run only in Phase 3B.

Verified dry-run output includes:

- `Status: PHASE 3B DRY-RUN ONLY`
- `Real deploy: DISABLED`
- `PASS: real deploy dry-run completed`
- `REAL_PROFILE_WRITE=false`

Explicit write mode such as `--apply` is rejected.

Lock wording:

    Phase 3B real deploy dry-run implementation
    PASS / dry-run only / write modes rejected / real ~/.hermes/profiles untouched / executable bit fixed

---

## Backup Policy

Before any future real deploy writes to `~/.hermes/profiles/`, it must create a
timestamped backup.

Planned backup root:

- `~/.hermes/backups/opc-profiles/`

Planned backup format:

- `~/.hermes/backups/opc-profiles/YYYYMMDD-HHMMSS/`

Required backup behavior:

1. If `~/.hermes/profiles/` exists, copy the existing tree into the timestamped
   backup directory.
2. If `~/.hermes/profiles/` does not exist, record that no existing profile tree
   was present.
3. Never overwrite an existing backup.
4. Print the exact backup path before a future write.
5. Keep restore instructions explicit and human-triggered.

The backup policy should stay file-based and local. No database-backed backup
index is needed for this personal-use scope.

---

## Reset Policy

Reset must be explicit and human-triggered.

Allowed future reset modes:

| Mode | Meaning |
| --- | --- |
| `preview` | Show what would be restored or removed. No writes. |
| `restore-backup` | Restore from a selected backup path. |
| `remove-opc-managed` | Remove only known OPC-managed files. |
| `full-reset` | Dangerous. Restore or remove the whole profile tree only with explicit confirmation. |

A future reset command must not guess which backup to restore. The user should
provide or confirm the backup path.

---

## Risk Notes

Real profile deployment can affect Hermes Agent behavior.

Main risks:

1. Existing personal Hermes profiles may be overwritten.
2. Role-specific behavior may diverge from upstream Hermes defaults.
3. Incorrect profile layout may make Hermes fail to load a profile.
4. Future upstream Hermes changes may make local OPC templates stale.
5. Reset without backup could permanently lose local profile customization.

Required controls before any future real write:

1. Phase 2 full simulation baseline remains PASS.
2. Phase 3A read-only planning remains PASS.
3. Phase 3B dry-run remains PASS.
4. Phase 3C verification lock remains PASS.
5. Real `~/.hermes/profiles/` is inspected before any write.
6. The selected source root is printed.
7. The destination root is printed.
8. The backup path is printed.
9. Dry-run remains the default behavior.
10. Real write requires explicit confirmation.

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

The deployment layer should help the user operate Hermes Agent safely. It
should not become a second platform that Hermes Agent must depend on.

---

## Phase 3C Acceptance Criteria

Phase 3C is PASS only if:

1. `docs/verification-phase-3c.md` exists.
2. Phase 3A remains PASS.
3. Phase 3B remains PASS.
4. `scripts/deploy-real-profiles.sh` remains executable.
5. The dry-run script emits `REAL_PROFILE_WRITE=false`.
6. Explicit write mode such as `--apply` is rejected.
7. No real `~/.hermes/profiles/` write is introduced.
8. The next phase remains guarded apply planning, not immediate real deploy.

Recommended lock wording:

    Phase 3C dry-run verification lock / docs alignment
    PASS / Phase 3A+3B evidence locked / real ~/.hermes/profiles untouched / no real write

---

## Next Phase

The next recommended phase is:

    Phase 3D real deploy guarded apply planning

Phase 3D should design the guard rails for a future apply mode, but should not
turn real deployment on by default. The apply contract, backup behavior,
confirmation flow, and reset boundary must be documented and reviewed before
any real `~/.hermes/profiles/` write is allowed.
