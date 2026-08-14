# Real Deploy Plan Addendum: Phase 3K-FIX.6

Status: Phase 3K-FIX.6 repo drift source cleanup planning implemented  
Scope: repo-local drift source cleanup planning only  
Real profile write: no  
Real profile delete: no  
Repo delete: no  

---

## Purpose

This addendum records the Phase 3K-FIX.6 plan alignment without rewriting the long consolidated `docs/real-deploy-plan.md`.

Phase 3K-FIX.5 completed real guarded cleanup of the accidental generic drift profiles under `~/.hermes/profiles/`.

Phase 3K-FIX.6 now plans cleanup of the remaining repo-local drift source directories:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

This phase does not delete those directories. It only classifies them as repo cleanup candidates.

---

## Added Planner

```text
scripts/plan-repo-drift-source-cleanup.sh
```

The planner is read-only and must emit:

```text
REPO_PROFILE_WRITE=false
REPO_PROFILE_DELETE=false
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

---

## Expected Result

While the old repo drift directories still exist, expected classification is:

```text
REPO_CLEANUP_CANDIDATE_COUNT=5
REPO_BLOCKED_COUNT=0
REPO_MISSING_COUNT=0
CANONICAL_ROLE_COUNT=6
```

Canonical roles remain protected by `config/profile-roles.txt`:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

---

## Phase Lock After Local Verification

```text
Phase 3K-FIX.6 repo drift source cleanup planning
PASS / read-only repo cleanup planner implemented / five repo drift source candidates detected / no repo delete / no real write / no real delete
```

---

## Next Phase

```text
Phase 3K-FIX.7 repo drift source cleanup execution
```

Phase 3K-FIX.7 may remove the old repo-local drift directories through reviewed git changes only. It must not touch real `~/.hermes/profiles/`.
