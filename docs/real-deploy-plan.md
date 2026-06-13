# Real Deploy Plan

Status: Phase 3K-FIX.1 taxonomy correction plan documented  
Scope: real deploy planning, guarded apply verification, and taxonomy correction  
Real profile write: executed only through guarded apply  
Restore execution: disabled  
Target path: `~/.hermes/profiles/`  
Current real apply result: five OPC-managed generic skeleton directories deployed  
Current correction result: canonical Hermes roles selected; Phase 3L content sync remains blocked

---

## Purpose

This plan defines the controlled real deployment path for OPC Hermes Agent profiles.

The project moved from simulation into staged real-deploy preparation, then through the first guarded real apply. Phase 3K later revealed a role taxonomy drift: the generic deployment roles used for pipeline validation are not the same as the existing Hermes profile taxonomy documented in `profiles/README.md`.

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
| Phase 3K role profile content hardening | DRIFT DETECTED |
| Phase 3K-FIX role taxonomy alignment | PASS / drift identified / Phase 3L blocked |
| Phase 3K-FIX.1 taxonomy correction plan | PASS / canonical Hermes roles selected / cleanup planned / no real write |

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
- `docs/verification-phase-3k-fix.md`
- `docs/taxonomy-correction-plan.md`

Read-only planning / verification scripts:

- `scripts/plan-real-deploy.sh`
- `scripts/plan-restore-real-profiles.sh`
- `scripts/check-real-deploy-readiness.sh`

Guarded apply script:

- `scripts/deploy-real-profiles.sh`

---

## Canonical Role Decision

Phase 3K-FIX.1 selects the existing Hermes maintainer role taxonomy as the canonical future deploy role set:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

The earlier generic OPC deploy roles are now classified as drift artifacts:

```text
default
developer
reviewer
operator
trial
```

This means Phase 3L content sync remains blocked. The next implementation work should rewrite readiness/deploy expectations around the canonical Hermes roles before any additional real apply.

---

## Phase 3K-FIX Correction Summary

Phase 3K added README content under this generic role source root:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

These generic roles were introduced during Phase 3A through Phase 3K to validate the guarded deploy pipeline. They are not the same as the existing Hermes profile taxonomy already documented in `profiles/README.md`:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Therefore, Phase 3K-FIX records this as role taxonomy drift.

Do not continue Phase 3L content sync while this drift is unresolved.

---

## Current Real Profile State

Phase 3J created five real OPC-managed skeleton profile directories:

```text
~/.hermes/profiles/default/
~/.hermes/profiles/developer/
~/.hermes/profiles/reviewer/
~/.hermes/profiles/operator/
~/.hermes/profiles/trial/
```

The user verified each directory contains only:

```text
.gitkeep
.opc-managed-profile
```

Each marker contains:

```text
managed_by=hermes-agent-opc-deploy
phase=3E
deployed_at=20260613-161857
source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles
role=<role>
```

This means the real generic skeletons are governed by this repo and were not user-authored personal profiles.

No cleanup has been executed yet.

---

## Phase 3 Boundary

The only implemented write-capable path is guarded apply in `scripts/deploy-real-profiles.sh`.

Guarded apply requires:

```text
--apply --confirm REAL_DEPLOY_PROFILES
```

Normal smoke, planning, restore planning, readiness checks, and taxonomy correction must remain read-only and emit:

```text
REAL_PROFILE_WRITE=false
```

Still prohibited outside explicit guarded apply or future explicit cleanup command:

- creating directories under real `~/.hermes/profiles/`
- copying files into real `~/.hermes/profiles/`
- deleting or resetting real Hermes profile files
- modifying real Hermes runtime state
- creating backup directories as a side effect of dry-run or planning
- introducing daemon, service, database, queue, or enterprise orchestration
- making Hermes Agent depend on this deployment layer at runtime

---

## First Real Guarded Apply Result

Phase 3J executed the first explicit guarded apply locally with:

```bash
./scripts/deploy-real-profiles.sh \
  --apply \
  --confirm REAL_DEPLOY_PROFILES \
  --source-root "$PWD/profiles"
```

Observed result:

```text
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
```

Locked result:

```text
Phase 3J first real guarded apply
PASS / guarded token accepted / backup created / five role profiles applied / managed markers present / post-apply readiness READY
```

---

## Backup Policy

Before guarded apply writes to `~/.hermes/profiles/`, it must create a timestamped backup.

Backup root:

```text
~/.hermes/backups/opc-profiles/
```

Phase 3J backup path:

```text
~/.hermes/backups/opc-profiles/20260613-161857
```

Phase 3J backup contents:

```text
NO_PREVIOUS_PROFILE_TREE.txt
```

This means no previous real Hermes profile tree existed before the first apply.

The backup policy stays file-based and local. No database-backed backup index is needed for this personal-use scope.

---

## Restore / Reset / Cleanup Policy

Restore, reset, and cleanup must be explicit and human-triggered.

Allowed future restore/reset modes:

| Mode | Meaning |
| --- | --- |
| `preview` | Show what would be restored or removed. No writes. |
| `restore-backup` | Restore from a selected backup path. |
| `remove-opc-managed` | Remove only known OPC-managed files. |
| `full-reset` | Dangerous. Restore or remove the whole profile tree only with explicit confirmation. |

Phase 3F only plans restore. It does not implement real restore.

Phase 3K-FIX.1 does not remove the generic skeletons. Any cleanup must be added as a separate explicit, human-triggered phase.

Future cleanup must only remove directories that are both:

1. In the drift role set: `default`, `developer`, `reviewer`, `operator`, `trial`.
2. Marked with `.opc-managed-profile` containing `managed_by=hermes-agent-opc-deploy`.

---

## Phase Locks

### Phase 3A Planning Script

```text
Phase 3A real deploy read-only planning
PASS / docs + plan script verified / real ~/.hermes/profiles untouched / no real write
```

### Phase 3B Dry-run Script

```text
Phase 3B real deploy dry-run implementation
PASS / dry-run only / write modes rejected / real ~/.hermes/profiles untouched / executable bit fixed
```

### Phase 3C Dry-run Verification Lock

```text
Phase 3C dry-run verification lock / docs alignment
PASS / Phase 3A+3B evidence locked / real ~/.hermes/profiles untouched / no real write
```

### Phase 3D Guarded Apply Contract

```text
Phase 3D real deploy guarded apply planning
PASS / guarded apply contract documented / no real write / Phase 3E gate defined
```

### Phase 3E Guarded Apply Implementation

```text
Phase 3E guarded apply implementation draft
PASS / dry-run default / guarded apply token enforced / backup-before-write implemented / managed marker implemented / temp HOME apply verified / real ~/.hermes untouched by normal smoke
```

### Phase 3F Restore Planning

```text
Phase 3F guarded apply verification lock / restore planning
PASS / Phase 3E evidence locked / restore policy documented / restore planner read-only / no real restore / executable bit fixed
```

### Phase 3G Readiness Gate

```text
Phase 3G real deploy readiness gate
PASS / readiness gate implemented / source root blocked / destination ownership passed / restore planner passed / no real write / executable bit fixed
```

### Phase 3H Profile Source Root Completion

```text
Phase 3H profile source root completion
PASS / canonical profiles source root complete / readiness READY / no real write
```

Note: Phase 3H used the generic source root that was later classified as drift. Its pipeline result remains useful, but the role taxonomy must be corrected before further real apply.

### Phase 3I Operator Confirmation

```text
Phase 3I first real guarded apply planning / operator confirmation
PASS / readiness READY locked / operator confirmation checklist documented / no real write
```

### Phase 3J First Real Guarded Apply

```text
Phase 3J first real guarded apply
PASS / guarded token accepted / backup created / five role profiles applied / managed markers present / post-apply readiness READY
```

Note: Phase 3J applied the generic role skeletons that were later classified as drift. The apply mechanism is verified, but the role taxonomy must be corrected before future content sync.

### Phase 3K Role Profile Content Hardening

```text
Phase 3K role profile content hardening
DRIFT DETECTED / generic roles do not align with existing Hermes profile taxonomy / do not sync to real profiles
```

### Phase 3K-FIX Role Taxonomy Alignment

Evidence file:

```text
docs/verification-phase-3k-fix.md
```

Lock wording:

```text
Phase 3K-FIX role taxonomy alignment
PASS / drift identified / generic role skeletons confirmed OPC-managed / Phase 3L blocked until taxonomy alignment
```

### Phase 3K-FIX.1 Taxonomy Correction Plan

Evidence file:

```text
docs/taxonomy-correction-plan.md
```

Lock wording:

```text
Phase 3K-FIX.1 taxonomy correction plan
PASS / canonical Hermes roles selected / generic OPC roles marked drift / cleanup planned / no real write
```

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
7. Role taxonomy drift can create unnecessary or misleading Hermes profile directories.

Required controls before future guarded apply:

1. Taxonomy alignment is complete.
2. Readiness gate reports `READINESS_STATUS=READY` for the canonical role set.
3. Selected source root is printed.
4. Destination root is printed.
5. Backup path is printed.
6. Dry-run remains the default behavior.
7. Real write requires explicit `--apply --confirm REAL_DEPLOY_PROFILES`.
8. Existing unmarked destination role directories remain protected.
9. Restore planning remains available before further apply operations.
10. Managed drift cleanup is explicit and human-triggered.

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
- human-reviewed promotion from source root to real profiles

---

## Next Phase

Do not continue Phase 3L content sync yet.

Recommended next phase:

```text
Phase 3K-FIX.2 canonical role config and readiness rewrite
```

Goal:

- add a plain canonical role config, such as `config/profile-roles.txt`
- update readiness/deploy scripts to read canonical roles
- create repo-local canonical role directories
- keep generic drift role cleanup separate and human-triggered
- avoid adding enterprise-grade profile management complexity
