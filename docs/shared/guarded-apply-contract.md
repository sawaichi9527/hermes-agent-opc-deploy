# Phase 3D Guarded Apply Contract

Status: PASS candidate  
Scope: contract and planning only  
Real profile write: disabled  
Target path: `~/.hermes/profiles/`  
Current guarantee: real `~/.hermes/profiles/` remains untouched

---

## Purpose

Phase 3D defines the contract for a future guarded real deployment mode.

It does not enable real deployment. It only documents the rules that a future
implementation must follow before any script is allowed to write into real
`~/.hermes/profiles/`.

The goal is to keep the deployment path safe, understandable, and personal-use
friendly while avoiding enterprise-grade operational complexity.

---

## Current Locked Baseline

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

Phase 3D extends the planning baseline only. It does not change the Phase 3B
script behavior: `--apply` must still be rejected until a later implementation
phase.

---

## Non-goals

Phase 3D must not:

- modify `scripts/deploy-real-profiles.sh` to make `--apply` succeed
- create real `~/.hermes/profiles/`
- create real `~/.hermes/backups/opc-profiles/`
- copy profile files into the real Hermes profile tree
- reset or delete real Hermes profile files
- introduce a daemon, service, database, queue, or remote control plane
- make Hermes Agent depend on this deployment layer at runtime

---

## Future Apply Entry Point

A future guarded apply implementation may use the existing script path:

- `scripts/deploy-real-profiles.sh`

The default behavior must remain dry-run.

Future apply may only be enabled through an explicit command form such as:

    ./scripts/deploy-real-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES

The confirmation token must be intentionally awkward enough to prevent
accidental execution from a short typo or copied dry-run command.

Recommended token:

    REAL_DEPLOY_PROFILES

The script must reject all incomplete write forms, including:

- `--apply`
- `--apply --yes`
- `--apply --confirm`
- `--apply --confirm wrong-token`

All rejected forms must print:

- a clear error message
- `REAL_PROFILE_WRITE=false`

---

## Required Preflight Checks Before Future Apply

A future guarded apply implementation must perform all checks before any write.

Required preflight checks:

1. Confirm Phase 2 full simulation baseline files still exist.
2. Confirm Phase 3C verification document exists.
3. Confirm selected source root exists.
4. Confirm every planned role source directory exists.
5. Confirm destination root is exactly `$HOME/.hermes/profiles`.
6. Refuse to run as root unless explicitly supported by a later policy.
7. Print the selected source root.
8. Print the destination root.
9. Print the backup root.
10. Print the timestamped backup path.
11. Print the exact role copy map.
12. Print the confirmation token requirement.

If any preflight check fails, the script must exit before creating backup or
profile directories.

---

## Source Root Selection Rule

The future implementation should keep source selection simple.

Candidate source roots, in preferred order:

1. `profiles/`
2. `templates/`
3. `simulation/profiles/`
4. `simulated-home/.hermes/profiles/`

The first candidate containing all required role directories may be selected.

Required roles:

- `default`
- `developer`
- `reviewer`
- `operator`
- `trial`

If no candidate contains all required roles, guarded apply must fail before any
write.

Partial deployment is not allowed by default. Personal use is safer when all
roles are deployed from one consistent source root.

---

## Backup-before-write Contract

A future guarded apply must create a backup before modifying real profiles.

Backup root:

- `~/.hermes/backups/opc-profiles/`

Backup path format:

- `~/.hermes/backups/opc-profiles/YYYYMMDD-HHMMSS/`

Required behavior:

1. Generate the timestamped backup path.
2. Print the backup path before writing.
3. Create the backup directory only after all preflight checks pass.
4. If `~/.hermes/profiles/` exists, copy the full existing profile tree into the
   backup path.
5. If `~/.hermes/profiles/` does not exist, write a small local note inside the
   backup path stating that no previous profile tree existed.
6. Never overwrite an existing backup directory.
7. Abort if backup creation fails.
8. Abort if backup verification fails.

The backup mechanism must remain local and file-based. No backup database or
index service should be introduced.

---

## Managed Marker and Ownership Policy

A future guarded apply should mark files or role directories it manages.

Recommended marker filename:

- `.opc-managed-profile`

Recommended marker content fields:

- `managed_by=hermes-agent-opc-deploy`
- `phase=3E-or-later`
- `source_root=<selected-source-root>`
- `deployed_at=<timestamp>`

The marker is used only for local safety and future reset decisions.

Ownership rules:

1. A future `remove-opc-managed` reset may only remove role directories that
   contain the marker.
2. A role directory without the marker must be treated as user-owned or
   externally managed.
3. If a destination role directory exists without the marker, guarded apply must
   either refuse or require an extra explicit overwrite policy in a later phase.
4. Phase 3D does not define automatic overwrite of unmarked user data.

This keeps the system safe for personal profiles without requiring enterprise
state tracking.

---

## Copy Contract

A future guarded apply should use plain filesystem copy semantics.

Recommended behavior:

1. Create destination role directories only after backup succeeds.
2. Copy role contents from the selected source root into matching destination
   role directories.
3. Preserve file content and executable bits where applicable.
4. Write or update the `.opc-managed-profile` marker for each managed role.
5. Print every copied role directory.
6. Avoid hidden mutation outside `~/.hermes/profiles/<role>/`.

The future copy operation should not use a package manager, installer daemon,
background reconciler, or database-backed deployment state.

---

## Rollback and Restore Policy

Rollback must be explicit and human-triggered.

Recommended future restore command form:

    ./scripts/deploy-real-profiles.sh --restore <backup-path> --confirm RESTORE_OPC_PROFILES

Recommended restore token:

    RESTORE_OPC_PROFILES

Restore rules:

1. The backup path must be supplied explicitly.
2. The script must not guess the newest backup automatically.
3. The restore operation must print the source backup path and destination path.
4. Restore must require a confirmation token.
5. Restore must not run as a side effect of failed apply unless a later phase
   explicitly implements and verifies that behavior.

Phase 3D only defines the policy. It does not implement restore.

---

## Future Phase 3E Acceptance Gate

Phase 3E may implement guarded apply only if all of the following are true:

1. Phase 3D contract exists and is reviewed.
2. Phase 2 full simulation baseline remains PASS.
3. Phase 3A read-only planning remains PASS.
4. Phase 3B dry-run remains PASS.
5. Phase 3C verification lock remains PASS.
6. Future guarded apply defaults to dry-run.
7. `--apply` requires the exact confirmation token.
8. Backup-before-write is implemented.
9. Source root selection is deterministic.
10. Existing unmarked real profile directories are protected.
11. Reset/restore remains explicit and human-triggered.
12. No daemon, service, database, queue, or enterprise orchestration is added.

---

## Simplicity Boundary

This project remains a personal/local deployment helper.

Prefer:

- shell scripts
- readable Markdown
- explicit dry-run output
- timestamped local backups
- human confirmation tokens
- simple copy and restore semantics

Avoid:

- fleet management
- policy servers
- remote execution
- background reconciliation
- profile databases
- complex installer frameworks

Hermes Agent should not carry this deployment logic at runtime. The deployment
helper exists only to prepare local profile files safely.

---

## Phase 3D Lock Wording

Recommended lock wording after verification:

    Phase 3D real deploy guarded apply planning
    PASS / guarded apply contract documented / no real write / Phase 3E gate defined
