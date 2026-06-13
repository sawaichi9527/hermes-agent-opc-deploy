# Real Deploy Plan

Status: Phase 3K-FIX.2 canonical role config and readiness rewrite implemented  
Scope: real deploy planning, guarded apply verification, taxonomy correction, and canonical role readiness  
Real profile write: executed only through guarded apply  
Restore execution: disabled  
Target path: `~/.hermes/profiles/`  
Current real apply result: five OPC-managed generic skeleton directories deployed during Phase 3J  
Current correction result: canonical Hermes roles are config-driven; drift cleanup remains pending

---

## Purpose

This plan defines the controlled real deployment path for OPC Hermes Agent profiles.

The project moved from simulation into guarded real deploy. Phase 3J verified that guarded apply, backup-before-write, and managed markers work. Phase 3K then revealed a role taxonomy drift: the generic deployment roles used for pipeline validation were not the same as the existing Hermes profile taxonomy documented in `profiles/README.md`.

Phase 3K-FIX.2 corrects the future deploy path so scripts now read canonical roles from a simple config file instead of hard-coded generic role names.

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
| Phase 3K-FIX.2 canonical role config and readiness rewrite | implemented / pending local verification |

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

Config and scripts:

- `config/profile-roles.txt`
- `scripts/plan-real-deploy.sh`
- `scripts/plan-restore-real-profiles.sh`
- `scripts/check-real-deploy-readiness.sh`
- `scripts/deploy-real-profiles.sh`

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

The scripts must use `config/profile-roles.txt` for future readiness and deploy checks.

---

## Canonical Source Root

Phase 3K-FIX.2 creates canonical repo-local role directories:

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

These are governed drift artifacts, not user-authored personal profiles. No cleanup has been executed yet.

---

## Guarded Apply Boundary

The only implemented write-capable path is:

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

Phase 3K-FIX.2 does not remove generic skeletons.

Future cleanup must only remove directories that are both:

1. In the drift role set: `default`, `developer`, `reviewer`, `operator`, `trial`.
2. Marked with `.opc-managed-profile` containing `managed_by=hermes-agent-opc-deploy`.

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

Evidence file:

```text
docs/verification-phase-3k-fix-2.md
```

Expected local lock wording after verification:

```text
Phase 3K-FIX.2 canonical role config and readiness rewrite
PASS / config-driven canonical roles / readiness READY / deploy dry-run PASS / no real write / drift cleanup still pending
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
8. Cleanup can remove useful data if ownership markers are ignored.

Required controls before future guarded apply:

1. `config/profile-roles.txt` must be reviewed.
2. Readiness checker must emit `READINESS_STATUS=READY`.
3. Deploy script dry-run must emit `PREFLIGHT_STATUS=PASS`.
4. Drift cleanup must be planned separately before any canonical apply.
5. Real write must require `--apply --confirm REAL_DEPLOY_PROFILES`.

---

## Next Phase

Recommended next phase:

```text
Phase 3K-FIX.3 drift cleanup planning
```

Phase 3K-FIX.3 should plan how to safely remove only the OPC-managed generic skeletons. It should remain read-only first and must not delete files until an explicit cleanup command and confirmation token exist.
