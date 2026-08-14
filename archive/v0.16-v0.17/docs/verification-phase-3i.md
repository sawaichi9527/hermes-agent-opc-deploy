# Phase 3I First Real Guarded Apply Planning / Operator Confirmation

Status: operator confirmation plan documented / no real apply  
Scope: final human confirmation checklist before first real guarded apply  
Real profile write: disabled in this phase  
Restore execution: disabled  
Current guarantee: Phase 3I does not modify real `~/.hermes/profiles/`

---

## Purpose

Phase 3I records the final operator confirmation plan before the first real guarded apply.

Phase 3H completed the canonical repo-local source root and the readiness gate reported `READINESS_STATUS=READY` during local verification. Phase 3I does not execute the real deployment. It only locks the evidence and defines the exact human-reviewed steps required before Phase 3J.

This keeps the personal/local deployment path simple while preventing accidental mutation of the real Hermes profile directory.

---

## Confirmed Inputs

| Item | Result |
| --- | --- |
| Canonical source root | `profiles/` |
| Required role directories | present |
| Readiness checker | PASS |
| Source status | `SOURCE_STATUS=complete` |
| Destination status | `DESTINATION_STATUS=pass` |
| Restore planner status | `RESTORE_PLANNER_STATUS=pass` |
| Overall readiness | `READINESS_STATUS=READY` |
| Normal smoke write status | `REAL_PROFILE_WRITE=false` |
| Restore write status | `REAL_RESTORE_WRITE=false` |

Required guarded deploy roles:

- `profiles/default/`
- `profiles/developer/`
- `profiles/reviewer/`
- `profiles/operator/`
- `profiles/trial/`

---

## Real Apply Boundary

Phase 3I must not run real apply.

The first real apply is reserved for Phase 3J and must use the guarded command form:

    ./scripts/deploy-real-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES

A source root may be explicit if the operator wants to avoid candidate-root ambiguity:

    ./scripts/deploy-real-profiles.sh \
      --apply \
      --confirm REAL_DEPLOY_PROFILES \
      --source-root "$PWD/profiles"

The command must not be hidden inside another script or run automatically by Hermes Agent.

---

## Operator Confirmation Checklist

Before Phase 3J real apply, the operator should manually confirm:

1. The repository is clean.
2. `main == origin/main`.
3. `scripts/check-real-deploy-readiness.sh` reports `READINESS_STATUS=READY`.
4. The selected source root is `profiles/`.
5. The destination is `~/.hermes/profiles/`.
6. The operator accepts that real `~/.hermes/profiles/` may be created or updated.
7. Backup-before-write is expected under `~/.hermes/backups/opc-profiles/YYYYMMDD-HHMMSS/`.
8. Existing unmarked profile directories are protected by the guarded apply script.
9. Restore execution is not yet implemented, but restore planning exists.
10. The apply command includes `--confirm REAL_DEPLOY_PROFILES`.

---

## Expected Pre-Apply Verification Commands

Repository state:

    git status --short
    git log --oneline -5

Readiness gate:

    ./scripts/check-real-deploy-readiness.sh | grep -E \
      "SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

Dry-run preview:

    ./scripts/deploy-real-profiles.sh --source-root "$PWD/profiles"

Guard rejection sanity check:

    ./scripts/deploy-real-profiles.sh --apply && echo "UNEXPECTED" || echo "PASS: apply without confirm rejected"

---

## Expected Phase 3J Command

Only Phase 3J should run the first real guarded apply:

    ./scripts/deploy-real-profiles.sh \
      --apply \
      --confirm REAL_DEPLOY_PROFILES \
      --source-root "$PWD/profiles"

Expected successful output should include:

- `PREFLIGHT_STATUS=PASS`
- `BACKUP_STATUS=created`
- `APPLIED_ROLE=default`
- `APPLIED_ROLE=developer`
- `APPLIED_ROLE=reviewer`
- `APPLIED_ROLE=operator`
- `APPLIED_ROLE=trial`
- `PASS: guarded real deploy completed`
- `REAL_PROFILE_WRITE=true`

---

## Post-Apply Verification Planned for Phase 3J

After the first real guarded apply, Phase 3J should verify:

1. `~/.hermes/profiles/default/.opc-managed-profile` exists.
2. `~/.hermes/profiles/developer/.opc-managed-profile` exists.
3. `~/.hermes/profiles/reviewer/.opc-managed-profile` exists.
4. `~/.hermes/profiles/operator/.opc-managed-profile` exists.
5. `~/.hermes/profiles/trial/.opc-managed-profile` exists.
6. Backup directory was created under `~/.hermes/backups/opc-profiles/`.
7. The repo remains clean.
8. No restore/reset is attempted.

---

## Risk Acceptance Notes

Phase 3J is the first point where the real profile directory may be created or updated.

This is acceptable only because the following controls already exist:

- dry-run default
- explicit confirmation token
- source root readiness gate
- destination ownership inspection
- backup-before-write
- managed ownership marker
- restore planning document
- read-only restore planner

This remains a personal/local workflow. It must not grow into a daemon, background sync service, enterprise profile registry, or automatic Hermes Agent dependency.

---

## Phase 3I Acceptance Criteria

Phase 3I is PASS only if:

1. `docs/verification-phase-3i.md` exists.
2. The file records `READINESS_STATUS=READY` from Phase 3H validation.
3. The file documents the explicit Phase 3J apply command.
4. The file records that Phase 3I performs no real apply.
5. `docs/real-deploy-plan.md` is aligned to Phase 3I.
6. The guarded apply script still defaults to dry-run.
7. Unauthorized `--apply` remains rejected.
8. The working tree is clean after pull.

Recommended lock wording:

    Phase 3I first real guarded apply planning / operator confirmation
    PASS / readiness READY locked / operator confirmation checklist documented / no real write

---

## Next Phase

If Phase 3I is verified, the next phase is:

    Phase 3J first real guarded apply

Phase 3J is allowed to perform the first real guarded apply only with explicit operator command execution.
