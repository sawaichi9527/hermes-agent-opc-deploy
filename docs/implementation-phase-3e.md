# Phase 3E Guarded Apply Implementation Draft

Status: implementation draft / pending local verification  
Scope: guarded apply implementation in `scripts/deploy-real-profiles.sh`  
Default mode: dry-run  
Real profile write: guarded only  
Target path: `~/.hermes/profiles/`

---

## Purpose

Phase 3E implements the guarded apply contract documented in
`docs/guarded-apply-contract.md`.

The implementation keeps the script simple and local-first. It does not add a
daemon, service, database, queue, telemetry, or enterprise deployment framework.
Hermes Agent does not depend on this script at runtime.

Phase 3E is an implementation draft until it is verified from the local checkout.

---

## Implemented Script

Script path:

- `scripts/deploy-real-profiles.sh`

The script now supports:

- default dry-run mode
- explicit `--dry-run`
- guarded `--apply`
- confirmation token check
- optional `--source-root PATH`
- deterministic source root selection
- preflight checks
- backup-before-write
- role copy map
- managed profile marker
- protection for unmarked existing destination role directories

---

## Guarded Apply Command Form

The only allowed apply form is:

    ./scripts/deploy-real-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES

The confirmation token is:

    REAL_DEPLOY_PROFILES

Rejected forms must emit `REAL_PROFILE_WRITE=false` and exit non-zero.

Examples that must be rejected:

- `./scripts/deploy-real-profiles.sh --apply`
- `./scripts/deploy-real-profiles.sh --apply --confirm wrong-token`
- `./scripts/deploy-real-profiles.sh --confirm REAL_DEPLOY_PROFILES`
- `./scripts/deploy-real-profiles.sh --reset`
- `./scripts/deploy-real-profiles.sh --restore`

---

## Dry-run Behavior

Dry-run remains the default.

Dry-run prints:

- Phase 3E status
- selected source root
- real profile destination root
- backup root
- planned backup directory
- confirmation token requirement
- candidate source roots
- planned role copy map
- dry-run preflight preview
- `REAL_PROFILE_WRITE=false`

Dry-run must not create:

- `~/.hermes/profiles/`
- `~/.hermes/backups/opc-profiles/`
- role directories
- managed marker files

---

## Apply Preflight Checks

Before any write, guarded apply checks:

1. The script is not running as root.
2. The destination root is exactly `$HOME/.hermes/profiles`.
3. `docs/guarded-apply-contract.md` exists.
4. `docs/verification-phase-3c.md` exists.
5. `docs/real-deploy-plan.md` exists.
6. A source root is selected.
7. The selected source root contains all required role directories.
8. The planned backup path does not already exist.
9. Existing destination role directories without `.opc-managed-profile` are protected.

If any preflight check fails, the script exits before creating backup or profile
directories.

---

## Source Root Selection

Candidate source roots remain simple and repo-local:

1. `profiles/`
2. `templates/`
3. `simulation/profiles/`
4. `simulated-home/.hermes/profiles/`

For guarded apply, the selected source root must contain all required role
directories:

- `default`
- `developer`
- `reviewer`
- `operator`
- `trial`

Partial guarded apply is not allowed by default.

---

## Backup-before-write

Guarded apply creates a timestamped backup before modifying real profiles.

Backup root:

- `~/.hermes/backups/opc-profiles/`

Backup path format:

- `~/.hermes/backups/opc-profiles/YYYYMMDD-HHMMSS/`

If `~/.hermes/profiles/` exists, it is copied to:

- `<backup-path>/profiles`

If `~/.hermes/profiles/` does not exist, the backup directory receives:

- `NO_PREVIOUS_PROFILE_TREE.txt`

---

## Managed Marker

Each applied role directory receives:

- `.opc-managed-profile`

Marker fields:

- `managed_by=hermes-agent-opc-deploy`
- `phase=3E`
- `deployed_at=<timestamp>`
- `source_root=<selected-source-root>`
- `role=<role>`

The marker is local safety metadata only. It is used to prevent accidental
overwrite of unmarked profile directories and to support future reset planning.

---

## Non-goals

Phase 3E does not implement:

- reset
- restore
- rollback automation
- clean install
- profile deletion
- state database
- background reconciliation
- remote control
- enterprise fleet deployment

Reset and restore should remain explicit future phases.

---

## Local Verification Commands

Recommended pull and smoke check:

    cd ~/workspace/hermes-agent-opc-deploy
    git pull
    git status
    bash -n scripts/deploy-real-profiles.sh
    test -x scripts/deploy-real-profiles.sh && echo "PASS executable"

Dry-run smoke:

    ./scripts/deploy-real-profiles.sh | grep -E \
      "PHASE 3E GUARDED APPLY DRAFT|Mode: dry-run|Real deploy: DISABLED|PASS: guarded deploy dry-run completed|REAL_PROFILE_WRITE=false"

Rejected apply smoke:

    ./scripts/deploy-real-profiles.sh --apply && echo "UNEXPECTED" || echo "PASS: apply without confirm rejected"

Wrong token smoke:

    ./scripts/deploy-real-profiles.sh --apply --confirm wrong-token && echo "UNEXPECTED" || echo "PASS: wrong token rejected"

Dry-run with confirmation token should also be rejected:

    ./scripts/deploy-real-profiles.sh --confirm REAL_DEPLOY_PROFILES && echo "UNEXPECTED" || echo "PASS: confirm without apply rejected"

Apply smoke should only be run after the user intentionally wants real profile
write and has reviewed the selected source root.

---

## Phase 3E Pending Lock Wording

Use this wording only after local verification passes:

    Phase 3E guarded apply implementation draft
    PASS / dry-run default / guarded apply token enforced / backup-before-write implemented / managed marker implemented
