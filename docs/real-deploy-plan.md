# Real Deploy Plan

Status: Phase 3K-FIX.4 guarded drift cleanup implemented  
Scope: real deploy planning, guarded apply verification, taxonomy correction, canonical role readiness, drift cleanup planning, and guarded cleanup implementation  
Real profile write: executed only through guarded apply  
Real profile delete: implemented only through guarded cleanup  
Restore execution: disabled  
Target path: `~/.hermes/profiles/`  
Current real apply result: five OPC-managed generic skeleton directories deployed during Phase 3J  
Current correction result: canonical Hermes roles are config-driven; drift cleanup is guarded and token-gated

---

## Purpose

This plan defines the controlled real deployment path for OPC Hermes Agent profiles.

The project moved from simulation into guarded real deploy. Phase 3J verified that guarded apply, backup-before-write, and managed markers work. Phase 3K then revealed a role taxonomy drift: the generic deployment roles used for pipeline validation were not the same as the existing Hermes profile taxonomy documented in `profiles/README.md`.

Phase 3K-FIX.2 corrected the future deploy path so scripts read canonical roles from a simple config file instead of hard-coded generic role names.

Phase 3K-FIX.3 added read-only drift cleanup planning for the generic skeleton profiles created during the first guarded apply.

Phase 3K-FIX.4 adds a guarded cleanup implementation. Default mode remains dry-run. Real deletion requires `--apply --confirm REAL_CLEANUP_DRIFT_PROFILES` and rechecks marker ownership before deleting anything.

The deployment layer must remain simple, personal-use friendly, local, and lightweight for Hermes Agent. It must not become a daemon, enterprise orchestrator, or runtime dependency.

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
| Phase 3H profile source root completion | PASS / generic readiness READY |
| Phase 3I first real guarded apply planning / operator confirmation | PASS / no real write |
| Phase 3J first real guarded apply | PASS / real write executed |
| Phase 3K role profile content hardening | DRIFT DETECTED |
| Phase 3K-FIX role taxonomy alignment | PASS / drift identified / Phase 3L blocked |
| Phase 3K-FIX.1 taxonomy correction plan | PASS / canonical Hermes roles selected / cleanup planned / no real write |
| Phase 3K-FIX.2 canonical role config and readiness rewrite | PASS / config-driven canonical roles / no real write |
| Phase 3K-FIX.3 drift cleanup planning | PASS / read-only planner / no real delete |
| Phase 3K-FIX.4 guarded drift cleanup implementation | implemented / pending local verification |

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
- `docs/verification-phase-3k-fix-2.md`
- `docs/verification-phase-3k-fix-3.md`
- `docs/verification-phase-3k-fix-4.md`

Config and scripts:

- `config/profile-roles.txt`
- `scripts/plan-real-deploy.sh`
- `scripts/plan-restore-real-profiles.sh`
- `scripts/check-real-deploy-readiness.sh`
- `scripts/deploy-real-profiles.sh`
- `scripts/plan-drift-profile-cleanup.sh`
- `scripts/cleanup-drift-profiles.sh`

---

## Canonical Role Decision

The canonical deploy role set is stored in:

```text
config/profile-roles.txt
```

Current canonical Hermes roles:

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

The readiness checker and guarded deploy script now read `config/profile-roles.txt` for future canonical deploy operations.

---

## Canonical Source Root

Phase 3K-FIX.2 created canonical repo-local role directories:

```text
profiles/secretary/
profiles/coordinator/
profiles/researcher/
profiles/writer/
profiles/builder/
profiles/runes-holder/
```

These are skeleton source directories only. They have not been synced to real `~/.hermes/profiles/`.

---

## Current Real Profile State

Phase 3J created five real OPC-managed generic skeleton profile directories:

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

These are governed drift artifacts, not user-authored personal profiles. Cleanup is now implemented but has not been executed unless explicitly run with the cleanup token.

---

## Drift Cleanup Planning

Phase 3K-FIX.3 added a read-only planner:

```text
scripts/plan-drift-profile-cleanup.sh
```

The planner only inspects the known drift role set:

```text
default
developer
reviewer
operator
trial
```

A directory can be marked as a cleanup candidate only when it is under the real profile root and has a matching `.opc-managed-profile` marker with:

```text
managed_by=hermes-agent-opc-deploy
source_root=<repo>/profiles
role=<role>
```

The planner must emit:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

---

## Guarded Drift Cleanup

Phase 3K-FIX.4 adds the guarded cleanup script:

```text
scripts/cleanup-drift-profiles.sh
```

Default mode is dry-run:

```bash
bash scripts/cleanup-drift-profiles.sh
```

Expected dry-run markers:

```text
Mode: dry-run
Real cleanup: DISABLED
cleanup_action: would delete
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
PASS: guarded drift cleanup dry-run completed
```

Real cleanup requires the cleanup-specific token:

```bash
bash scripts/cleanup-drift-profiles.sh \
  --apply \
  --confirm REAL_CLEANUP_DRIFT_PROFILES
```

Expected successful cleanup markers:

```text
Mode: apply
Real cleanup: GUARDED_CLEANUP_REQUESTED
DELETED_ROLE=default
DELETED_ROLE=developer
DELETED_ROLE=reviewer
DELETED_ROLE=operator
DELETED_ROLE=trial
DELETED_COUNT=5
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=true
PASS: guarded drift cleanup completed
```

Cleanup must never target canonical roles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

---

## Guarded Apply Boundary

The only implemented profile write-capable path is:

```text
scripts/deploy-real-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES
```

Normal smoke, planning, restore planning, readiness checks, taxonomy correction, and cleanup planning must remain read-only and emit:

```text
REAL_PROFILE_WRITE=false
```

Guarded apply must remain:

- explicit
- local
- user-triggered
- backup-before-write
- token-gated
- marker-based
- non-daemonized

---

## Backup Policy

Before guarded apply writes to `~/.hermes/profiles/`, it must create a timestamped backup under:

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

Guarded drift cleanup may remove generic skeletons only when all are true:

1. The role is in the drift role set: `default`, `developer`, `reviewer`, `operator`, `trial`.
2. The directory is marked with `.opc-managed-profile` containing `managed_by=hermes-agent-opc-deploy`.
3. The marker source root matches `<repo>/profiles`.
4. The marker role matches the directory role.
5. Cleanup is confirmed with `--apply --confirm REAL_CLEANUP_DRIFT_PROFILES`.

---

## Phase Locks

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

```text
Phase 3K-FIX role taxonomy alignment
PASS / drift identified / generic role skeletons confirmed OPC-managed / Phase 3L blocked until taxonomy alignment
```

### Phase 3K-FIX.1 Taxonomy Correction Plan

```text
Phase 3K-FIX.1 taxonomy correction plan
PASS / canonical Hermes roles selected / generic OPC roles marked drift / cleanup planned / no real write
```

### Phase 3K-FIX.2 Canonical Role Config and Readiness Rewrite

```text
Phase 3K-FIX.2 canonical role config and readiness rewrite
PASS / config-driven canonical roles / readiness READY / deploy dry-run PASS / no real write / drift cleanup still pending
```

### Phase 3K-FIX.3 Drift Cleanup Planning

```text
Phase 3K-FIX.3 drift cleanup planning
PASS / read-only cleanup planner implemented / five OPC-managed drift candidates detected / no real delete / no real write
```

### Phase 3K-FIX.4 Guarded Drift Cleanup Implementation

Evidence file:

```text
docs/verification-phase-3k-fix-4.md
```

Expected local lock wording after dry-run verification:

```text
Phase 3K-FIX.4 guarded drift cleanup implementation
PASS / dry-run cleanup PASS / apply requires cleanup token / no real delete during verification
```

If cleanup execution is also run:

```text
Phase 3K-FIX.4 guarded drift cleanup execution
PASS / five OPC-managed drift profiles deleted / planner reports missing / canonical readiness READY
```

---

## Risk Notes

Real profile deployment or cleanup can affect Hermes Agent behavior.

Main risks:

1. Existing personal Hermes profiles may be overwritten.
2. Role-specific behavior may diverge from upstream Hermes defaults.
3. Incorrect profile layout may make Hermes fail to load a profile.
4. Future upstream Hermes changes may make local OPC templates stale.
5. Reset without backup could permanently lose local profile customization.
6. Source content changes are not active in real profiles until a guarded apply syncs them.
7. Role taxonomy drift can create unnecessary or misleading Hermes profile directories.
8. Cleanup can remove useful data if ownership markers are ignored.

Required controls before future guarded apply or cleanup:

1. `config/profile-roles.txt` must be reviewed.
2. Readiness checker must emit `READINESS_STATUS=READY`.
3. Deploy script dry-run must emit `PREFLIGHT_STATUS=PASS`.
4. Drift cleanup planner must identify only expected `CLEANUP_CANDIDATE` directories.
5. Real write must require `--apply --confirm REAL_DEPLOY_PROFILES`.
6. Real cleanup must require `--apply --confirm REAL_CLEANUP_DRIFT_PROFILES`.

---

## Next Phase

Recommended next phase after dry-run verification:

```text
Phase 3K-FIX.5 guarded drift cleanup execution
```

If the operator executes guarded cleanup during Phase 3K-FIX.4 verification, the next phase should become:

```text
Phase 3K-FIX.5 post-cleanup source taxonomy cleanup
```
