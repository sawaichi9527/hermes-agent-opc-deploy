# Phase 3E Guarded Apply Verification Lock

Status: PASS  
Scope: verification lock only  
Real deploy default: dry-run  
Real profile write by normal smoke: disabled  
Current guarantee: real `~/.hermes/profiles/` remains untouched by normal verification

---

## Purpose

This document locks the Phase 3E guarded apply verification result.

Phase 3E introduced a guarded real deploy implementation draft in
`scripts/deploy-real-profiles.sh`, but the normal execution path remains
read-only dry-run. Real write is only allowed when the user explicitly runs
`--apply --confirm REAL_DEPLOY_PROFILES`.

The local verification used a temporary `HOME` directory so that the real
user profile tree was not touched.

---

## Locked Result

    Phase 3E guarded apply implementation draft
    PASS / dry-run default / guarded apply token enforced / backup-before-write implemented / managed marker implemented / temp HOME apply verified / real ~/.hermes untouched by normal smoke

---

## Verification Evidence

### Repository sync

Observed result:

- `git pull`: PASS
- `main == origin/main`: PASS
- working tree before verification: clean
- latest Phase 3E commits present:
  - `adb14b3 Implement Phase 3E guarded apply draft`
  - `e3fd744 Document Phase 3E guarded apply implementation draft`

### Static script validation

Observed commands:

    bash -n scripts/deploy-real-profiles.sh
    test -x scripts/deploy-real-profiles.sh

Observed result:

- shell syntax: PASS
- executable bit: PASS

### Documentation validation

Observed file:

    docs/implementation-phase-3e.md

Observed result:

- file exists: PASS
- documents guarded apply draft: PASS
- documents `REAL_DEPLOY_PROFILES` confirmation token: PASS
- documents backup-before-write: PASS
- documents managed profile marker: PASS

### Dry-run default validation

Observed command:

    ./scripts/deploy-real-profiles.sh

Observed output markers:

- `Status: PHASE 3E GUARDED APPLY DRAFT`
- `Mode: dry-run`
- `Real deploy: DISABLED`
- `REAL_PROFILE_WRITE=false`

Result:

    PASS / dry-run default preserved

### Guarded apply rejection validation

Observed rejection cases:

    ./scripts/deploy-real-profiles.sh --apply
    ./scripts/deploy-real-profiles.sh --apply --confirm wrong-token
    ./scripts/deploy-real-profiles.sh --confirm REAL_DEPLOY_PROFILES

Observed results:

- `--apply` without confirm: rejected
- `--apply` with wrong token: rejected
- `--confirm` without `--apply`: rejected
- all rejection paths emit `REAL_PROFILE_WRITE=false`

Result:

    PASS / guarded apply token enforced

### Temporary HOME apply validation

Observed approach:

- create temporary `HOME`
- create temporary source root
- create role directories:
  - `default`
  - `developer`
  - `reviewer`
  - `operator`
  - `trial`
- run guarded apply with explicit token and temporary source root

Observed command shape:

    HOME="$tmp_home" ./scripts/deploy-real-profiles.sh \
      --apply \
      --confirm REAL_DEPLOY_PROFILES \
      --source-root "$tmp_src"

Observed output markers:

- `PREFLIGHT_STATUS=PASS`
- `BACKUP_STATUS=created`
- `APPLIED_ROLE=default`
- `APPLIED_ROLE=trial`
- `PASS: guarded real deploy completed`
- `REAL_PROFILE_WRITE=true`

Observed marker files:

- `.opc-managed-profile` created under each temporary role directory

Result:

    PASS / guarded apply works against temporary HOME only

### Final repository state

Observed result:

- `git status --short`: clean

---

## Safety Boundary

Phase 3E verification did not require writing to the real user profile tree.

Normal smoke commands must continue to use dry-run mode and must emit:

    REAL_PROFILE_WRITE=false

Real apply remains explicitly gated by:

    --apply --confirm REAL_DEPLOY_PROFILES

The confirmation token is intentionally verbose and human-readable to reduce
accidental execution.

---

## Phase 3E Controls Verified

| Control | Result |
| --- | --- |
| Dry-run is default | PASS |
| Real deploy disabled in dry-run | PASS |
| `REAL_PROFILE_WRITE=false` in dry-run | PASS |
| `--apply` requires explicit confirmation token | PASS |
| Wrong confirmation token is rejected | PASS |
| Confirmation token without `--apply` is rejected | PASS |
| Backup-before-write implemented | PASS |
| Managed profile marker implemented | PASS |
| Temporary HOME apply works | PASS |
| Real `~/.hermes/profiles/` untouched by normal smoke | PASS |

---

## Not Covered Yet

Phase 3E does not lock restore behavior.

Not covered in Phase 3E:

- real restore from backup
- rollback apply
- delete/reset real profile tree
- partial restore
- backup pruning
- real `~/.hermes/profiles/` deployment on the production user HOME

These must be handled in later phases.

---

## Phase 3F Recommendation

Proceed to:

    Phase 3F guarded apply verification lock / restore planning

Phase 3F should add restore planning only:

- document restore policy
- add read-only restore planner script
- list available backup directories
- show planned restore source and destination
- keep restore execution disabled

Phase 3F must not implement real restore.
