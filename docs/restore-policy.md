# Restore Policy

Status: Phase 3F restore planning  
Scope: read-only policy and planning  
Real restore: disabled  
Real profile write: disabled by this phase  
Target profile root: `~/.hermes/profiles/`  
Backup root: `~/.hermes/backups/opc-profiles/`

---

## Purpose

This document defines the restore and rollback policy for OPC Hermes real
profile deployment.

Phase 3E introduced guarded apply with backup-before-write. Phase 3F adds the
other side of the operational boundary: how a future restore should be planned
and verified before it is allowed to modify real `~/.hermes/profiles/`.

Phase 3F is read-only. It does not implement real restore.

---

## Personal-use Boundary

This project remains personal/local tooling, not enterprise fleet management.

Do not add:

- restore daemon
- backup database
- background reconciler
- remote restore service
- central backup server
- RBAC workflow
- automatic profile mutation

Prefer:

- explicit backup paths
- readable shell output
- local filesystem backups
- dry-run restore planning
- manual confirmation before any future restore

---

## Backup Source

Guarded apply writes timestamped backups under:

    ~/.hermes/backups/opc-profiles/YYYYMMDD-HHMMSS/

A backup directory may contain:

- a copy of the previous `~/.hermes/profiles/` tree
- metadata noting that no previous profile tree existed
- future restore metadata

A future restore operation must never guess silently. It must print and require
an explicit backup path.

---

## Restore Modes

Allowed future restore modes:

| Mode | Meaning | Phase 3F status |
| --- | --- | --- |
| `preview` | Show restore plan only | planned |
| `restore-backup` | Restore from an explicit backup path | not implemented |
| `remove-opc-managed` | Remove only OPC-managed role directories | not implemented |
| `full-reset` | Dangerous full profile reset | not implemented |

Phase 3F only supports planning/preview.

---

## Restore Safety Rules

A future restore implementation must follow these rules:

1. Default mode must be preview/read-only.
2. Real restore must require an explicit confirmation token.
3. Real restore must require an explicit backup path.
4. Restore must print source and destination before writing.
5. Restore must refuse to overwrite without a fresh safety backup.
6. Restore must preserve unknown non-OPC user files unless full reset is
   explicitly confirmed.
7. Restore must not delete real profiles without a backup.
8. Restore must emit `REAL_PROFILE_WRITE=false` in preview mode.
9. Restore must emit `REAL_PROFILE_WRITE=true` only after a real write.

---

## Managed Ownership Policy

OPC-managed role directories are identified by:

    .opc-managed-profile

A future `remove-opc-managed` mode may only remove directories containing this
marker.

If a role directory exists without `.opc-managed-profile`, future tools must
classify it as user-owned or unknown-owned and refuse overwrite/delete unless a
separate explicit full-reset flow exists.

---

## Restore Planning Script

Phase 3F introduces:

    scripts/plan-restore-real-profiles.sh

The script must be read-only.

It may:

- print real profile root
- print backup root
- list backup candidates
- inspect an explicitly selected backup path
- print planned restore destination
- classify whether restore execution is disabled

It must not:

- create backup directories
- create profile directories
- copy files
- delete files
- mutate real `~/.hermes/profiles/`

---

## Phase 3F Acceptance Criteria

Phase 3F is PASS only if:

1. `docs/verification-phase-3e.md` exists.
2. `docs/restore-policy.md` exists.
3. `scripts/plan-restore-real-profiles.sh` exists.
4. Restore planning script is executable.
5. Restore planning script is read-only.
6. Restore planning script emits `REAL_PROFILE_WRITE=false`.
7. Restore planning script clearly says real restore is disabled.
8. Phase 3E evidence remains locked.
9. Git working tree is clean after verification.

Recommended lock wording:

    Phase 3F guarded apply verification lock / restore planning
    PASS / Phase 3E evidence locked / restore policy documented / restore planner read-only / no real restore

---

## Next Phase

After Phase 3F is locked, the next recommended phase is:

    Phase 3G real deploy readiness gate

Phase 3G should decide whether real deployment to the user's actual
`~/.hermes/profiles/` is allowed, still with explicit guarded apply only.
