# Phase 3K-FIX Role Taxonomy Alignment

Status: drift identified / correction required  
Scope: documentation and correction plan  
Real profile write: disabled  
Real profile delete: disabled  
Current guarantee: no automatic cleanup is performed by this phase

---

## Summary

Phase 3K introduced five generic OPC deploy role profiles:

- `default`
- `developer`
- `reviewer`
- `operator`
- `trial`

These roles were created as generic deployment roles during Phase 3A to Phase 3K planning and readiness work. They were useful for validating the guarded deploy pipeline, but they are not the same as the profile taxonomy already described by the existing Hermes profile documentation.

The existing profile taxonomy in `profiles/README.md` is closer to:

- `secretary`
- `coordinator`
- `researcher`
- `writer`
- `builder`
- `runes-holder`

Therefore, Phase 3K-FIX records this as a role taxonomy drift and blocks continued content sync until the taxonomy is realigned.

---

## What Happened

The generic role set was introduced to give the real deploy pipeline a simple, complete source root to validate:

```text
profiles/
  default/
  developer/
  reviewer/
  operator/
  trial/
```

Phase 3J then performed the first guarded apply and created matching real skeleton directories under:

```text
~/.hermes/profiles/default/
~/.hermes/profiles/developer/
~/.hermes/profiles/reviewer/
~/.hermes/profiles/operator/
~/.hermes/profiles/trial/
```

The real directories are OPC-managed and contain `.opc-managed-profile` markers.

---

## Confirmed Real Skeleton Evidence

The user verified that each real skeleton directory contains only a small managed skeleton:

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

This means the directories are not user-authored profiles. They were created by the guarded apply pipeline and may be governed by this repo.

---

## Correction Decision

Do not continue Phase 3L content sync with the generic role set.

Phase 3L is blocked until role taxonomy is aligned.

Recommended correction path:

1. Stop Phase 3L.
2. Keep real skeleton directories untouched until an explicit cleanup plan exists.
3. Update docs to mark generic roles as deployment-pipeline validation roles, not final Hermes runtime taxonomy.
4. Decide the canonical profile taxonomy before further content hardening.
5. Prefer aligning with the existing Hermes profile taxonomy unless there is a clear reason to keep separate OPC runtime roles.

---

## Allowed Next Actions

Allowed:

- document the taxonomy drift
- update readiness and real deploy plan wording
- add a read-only cleanup plan
- add a read-only taxonomy migration plan
- decide canonical roles before real content sync

Not allowed in this phase:

- do not run another guarded apply
- do not sync Phase 3K README content into real profiles
- do not delete real `~/.hermes/profiles/*` automatically
- do not create new real profiles
- do not reset real profiles

---

## Current Status

| Item | Status |
| --- | --- |
| Generic role drift identified | PASS |
| Real skeletons confirmed as OPC-managed | PASS |
| Real profile cleanup executed | NOT DONE |
| Role taxonomy aligned | NOT DONE |
| Phase 3L content sync allowed | BLOCKED |

---

## Lock Wording

```text
Phase 3K-FIX role taxonomy alignment
PASS / drift identified / generic role skeletons confirmed OPC-managed / Phase 3L blocked until taxonomy alignment
```

---

## Next Recommended Phase

```text
Phase 3K-FIX.1 taxonomy correction plan
```

Goal:

- choose canonical role taxonomy
- decide whether generic role skeletons should be removed, retained, or migrated
- update readiness scripts accordingly
- keep all real cleanup explicit and human-triggered
