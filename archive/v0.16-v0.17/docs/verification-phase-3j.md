# Phase 3J First Real Guarded Apply Verification Lock

Status: PASS  
Scope: first real guarded apply verification  
Real profile write: executed  
Restore write: not executed  
Source root: `~/workspace/hermes-agent-opc-deploy/profiles`  
Destination root: `~/.hermes/profiles`  
Backup path: `~/.hermes/backups/opc-profiles/20260613-161857`

---

## Purpose

Phase 3J records the first real guarded apply of the OPC Hermes profile
source root into the user's real Hermes profile directory.

This phase is a verification lock. It does not add new deployment behavior.
It records what was executed locally, what was written, which backup was
created, and which post-apply checks passed.

The current deployed content is intentionally minimal: Phase 3H completed
role directory skeletons under `profiles/` using `.gitkeep` files. Phase 3J
therefore proves the guarded deployment path, backup-before-write behavior,
ownership marker behavior, and post-apply readiness behavior. It does not
claim that final role-specific SOUL/profile content has been completed.

---

## Preconditions

The following phases were already locked before the real apply:

| Phase | Result |
| --- | --- |
| Phase 3E guarded apply implementation draft | PASS |
| Phase 3F guarded apply verification lock / restore planning | PASS |
| Phase 3G real deploy readiness gate | PASS / readiness READY |
| Phase 3H profile source root completion | PASS / canonical source root complete |
| Phase 3I first real guarded apply planning / operator confirmation | PASS / operator checklist documented |

Required gate result before apply:

```text
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

---

## Real Apply Command

The first guarded apply was executed locally with explicit confirmation:

```bash
./scripts/deploy-real-profiles.sh \
  --apply \
  --confirm REAL_DEPLOY_PROFILES \
  --source-root "$PWD/profiles"
```

The confirmation token was required and accepted:

```text
--confirm REAL_DEPLOY_PROFILES
```

---

## Apply Result

Observed result:

```text
Status: PHASE 3E GUARDED APPLY DRAFT
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

## Backup Evidence

Backup path:

```text
~/.hermes/backups/opc-profiles/20260613-161857
```

Observed backup contents:

```text
/home/eye/.hermes/backups/opc-profiles/20260613-161857
/home/eye/.hermes/backups/opc-profiles/20260613-161857/NO_PREVIOUS_PROFILE_TREE.txt
```

Meaning:

- `~/.hermes/profiles` did not exist before the first apply.
- The script still created a timestamped backup record.
- No previous real Hermes profile tree was overwritten.

---

## Applied Real Profile Tree

Observed real profile tree:

```text
/home/eye/.hermes/profiles
/home/eye/.hermes/profiles/default
/home/eye/.hermes/profiles/default/.gitkeep
/home/eye/.hermes/profiles/default/.opc-managed-profile
/home/eye/.hermes/profiles/developer
/home/eye/.hermes/profiles/developer/.gitkeep
/home/eye/.hermes/profiles/developer/.opc-managed-profile
/home/eye/.hermes/profiles/operator
/home/eye/.hermes/profiles/operator/.gitkeep
/home/eye/.hermes/profiles/operator/.opc-managed-profile
/home/eye/.hermes/profiles/reviewer
/home/eye/.hermes/profiles/reviewer/.gitkeep
/home/eye/.hermes/profiles/reviewer/.opc-managed-profile
/home/eye/.hermes/profiles/trial
/home/eye/.hermes/profiles/trial/.gitkeep
/home/eye/.hermes/profiles/trial/.opc-managed-profile
```

Applied roles:

| Role | Status |
| --- | --- |
| `default` | applied |
| `developer` | applied |
| `reviewer` | applied |
| `operator` | applied |
| `trial` | applied |

---

## Managed Marker Evidence

Managed markers were created for all deployed roles:

```text
/home/eye/.hermes/profiles/default/.opc-managed-profile
/home/eye/.hermes/profiles/developer/.opc-managed-profile
/home/eye/.hermes/profiles/operator/.opc-managed-profile
/home/eye/.hermes/profiles/reviewer/.opc-managed-profile
/home/eye/.hermes/profiles/trial/.opc-managed-profile
```

Marker format observed:

```text
managed_by=hermes-agent-opc-deploy
phase=3E
deployed_at=20260613-161857
source_root=/home/eye/workspace/hermes-agent-opc-deploy/profiles
role=<role>
```

The marker `phase=3E` is expected because the apply implementation was
introduced in Phase 3E and reused by Phase 3J.

---

## Post-apply Readiness

Post-apply readiness remained READY:

```text
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

This confirms:

1. The repo-local source root remains complete.
2. The real destination remains acceptable for future guarded apply checks.
3. The restore planner remains available.
4. The readiness checker remains read-only.

---

## Post-apply Dry-run Safety

After the real apply, dry-run mode still remained disabled for writes:

```text
Status: PHASE 3E GUARDED APPLY DRAFT
Mode: dry-run
Real deploy: DISABLED
SOURCE_ROOT=/home/eye/workspace/hermes-agent-opc-deploy/profiles
REAL_PROFILE_WRITE=false
```

This confirms the default mode is still safe.

---

## Git State

Observed local repository state after post-apply verification:

```text
git status --short
```

No output was observed, meaning the working tree was clean.

---

## Boundaries

Phase 3J did not:

- execute restore
- reset profiles
- add role-specific SOUL content
- change deploy script behavior
- introduce daemon, service, database, queue, telemetry, or enterprise orchestration

Phase 3J did:

- execute the first explicit guarded apply
- create real `~/.hermes/profiles/`
- create five managed role directories
- create timestamped backup record
- create managed ownership markers
- verify post-apply readiness

---

## Acceptance Criteria

Phase 3J is PASS if:

1. Guarded apply was executed only with `--apply --confirm REAL_DEPLOY_PROFILES`.
2. Source root was `~/workspace/hermes-agent-opc-deploy/profiles`.
3. Source status was complete.
4. Preflight status was PASS.
5. Backup path was created.
6. All five roles were applied.
7. All five role directories contain `.opc-managed-profile`.
8. Post-apply readiness reports READY.
9. Post-apply dry-run remains non-writing.
10. Git working tree remains clean.

All criteria are met.

---

## Locked Result

```text
Phase 3J first real guarded apply
PASS / guarded token accepted / backup created / five role profiles applied / managed markers present / post-apply readiness READY
```

---

## Next Phase

Recommended next phase:

```text
Phase 3K role profile content hardening
```

Phase 3K should add actual role profile content under `profiles/<role>/`
while keeping the same guarded apply and backup-before-write controls.

Phase 3K should avoid enterprise-grade complexity and keep the profile
content small, readable, local, and easy to inspect.
