# Phase 3K Role Profile Content Hardening

Status: source content documented / pending local verification  
Scope: repo-local profile content only  
Real deploy: not executed in this phase  
Real profile write: disabled for Phase 3K  

---

## Purpose

Phase 3K adds small, readable role profile content under the canonical repo-local source root:

```text
profiles/
```

This phase does not sync the new content into real `~/.hermes/profiles/`.

Real synchronization is reserved for a later guarded apply phase.

---

## Baseline Before Phase 3K

| Item | Status |
| --- | --- |
| Phase 3J first real guarded apply | PASS |
| Real profile root exists | PASS |
| Managed markers present | PASS |
| Readiness gate | READY |
| Source root | `profiles/` |
| Existing deployed content | skeleton `.gitkeep` files only |

---

## Added Source Content

Phase 3K adds README content for the five OPC guarded deploy roles:

| Role | Source file |
| --- | --- |
| default | `profiles/default/README.md` |
| developer | `profiles/developer/README.md` |
| reviewer | `profiles/reviewer/README.md` |
| operator | `profiles/operator/README.md` |
| trial | `profiles/trial/README.md` |

The content is intentionally lightweight. It documents role purpose, operating boundary, intended use, and governance notes.

---

## Boundary

Phase 3K does not:

- run guarded apply
- write to real `~/.hermes/profiles/`
- create new backups
- reset or restore profiles
- add daemons, databases, queues, schedulers, or remote services
- make Hermes Agent depend on this repo at runtime

---

## Local Verification Commands

```bash
cd ~/workspace/hermes-agent-opc-deploy

for role in default developer reviewer operator trial; do
  test -f "profiles/$role/README.md" && echo "PASS profiles/$role/README.md exists"
done

grep -n \
  "Status: Phase 3K role profile content hardening\|Real deployment: managed by guarded apply only\|Operating Boundary\|Governance Notes" \
  profiles/default/README.md \
  profiles/developer/README.md \
  profiles/reviewer/README.md \
  profiles/operator/README.md \
  profiles/trial/README.md

./scripts/check-real-deploy-readiness.sh | grep -E \
  "SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

git status --short
```

---

## Expected Result

Expected local verification result:

```text
profiles/default/README.md exists      PASS
profiles/developer/README.md exists    PASS
profiles/reviewer/README.md exists     PASS
profiles/operator/README.md exists     PASS
profiles/trial/README.md exists        PASS
READINESS_STATUS=READY                 PASS
REAL_PROFILE_WRITE=false               PASS
REAL_RESTORE_WRITE=false               PASS
working tree clean                     PASS
```

---

## Phase 3K Lock Wording

If local verification passes, lock Phase 3K as:

```text
Phase 3K role profile content hardening
PASS / five role README profiles added / source root remains READY / no real write
```

---

## Next Phase

Recommended next phase:

```text
Phase 3L second guarded apply / profile content sync
```

Phase 3L may sync the Phase 3K README content into real `~/.hermes/profiles/` through guarded apply.

It must still require:

```text
--apply --confirm REAL_DEPLOY_PROFILES
```

and must create a backup before writing.
