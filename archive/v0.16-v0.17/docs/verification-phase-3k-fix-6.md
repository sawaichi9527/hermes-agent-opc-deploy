# Phase 3K-FIX.6 Repo Drift Source Cleanup Planning

Status: implemented / pending local verification  
Scope: repo-local drift source cleanup planning only  
Real profile write: no  
Real profile delete: no  
Repo delete: no  

---

## Purpose

Phase 3K-FIX.5 cleaned the accidental real drift skeleton profiles from `~/.hermes/profiles/`.

Phase 3K-FIX.6 addresses the remaining repo-local artifacts:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

These directories were created during the generic OPC role drift period. They should not be synced to real Hermes profiles again.

This phase does not delete them. It only adds a read-only planner that classifies them as repo cleanup candidates.

---

## Added File

```text
scripts/plan-repo-drift-source-cleanup.sh
```

The script must:

1. Inspect only repo-local `profiles/<role>/` directories.
2. Never touch `~/.hermes/profiles/`.
3. Never delete repo files.
4. Never delete real profile files.
5. Read canonical roles from `config/profile-roles.txt`.
6. Refuse to classify canonical roles as cleanup candidates.
7. Classify the old generic roles as repo cleanup candidates when present.

---

## Canonical Roles

Canonical roles are still:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

These are not cleanup targets.

---

## Repo Drift Roles

Repo drift roles are:

```text
default
developer
reviewer
operator
trial
```

These are expected to be classified as repo cleanup candidates while they still exist in the repository source tree.

---

## Safety Markers

The planner must emit:

```text
REPO_PROFILE_WRITE=false
REPO_PROFILE_DELETE=false
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

This phase is planning only.

---

## Expected Local Verification

Run:

```bash
bash -n scripts/plan-repo-drift-source-cleanup.sh

bash scripts/plan-repo-drift-source-cleanup.sh | grep -E \
  "PHASE 3K-FIX.6 REPO DRIFT SOURCE CLEANUP PLANNING ONLY|Mode: read-only|Repo cleanup: DISABLED|CANONICAL_ROLE_COUNT=6|DRIFT_ROLE=default|DRIFT_ROLE=trial|status: REPO_CLEANUP_CANDIDATE|REPO_CLEANUP_CANDIDATE_COUNT=5|REPO_BLOCKED_COUNT=0|REPO_MISSING_COUNT=0|REPO_PROFILE_WRITE=false|REPO_PROFILE_DELETE=false|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|PASS: repo drift source cleanup planning completed in read-only mode"
```

Expected output markers:

```text
Status: PHASE 3K-FIX.6 REPO DRIFT SOURCE CLEANUP PLANNING ONLY
Mode: read-only
Repo cleanup: DISABLED
CANONICAL_ROLE_COUNT=6
DRIFT_ROLE=default
DRIFT_ROLE=trial
status: REPO_CLEANUP_CANDIDATE
REPO_CLEANUP_CANDIDATE_COUNT=5
REPO_BLOCKED_COUNT=0
REPO_MISSING_COUNT=0
REPO_PROFILE_WRITE=false
REPO_PROFILE_DELETE=false
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
PASS: repo drift source cleanup planning completed in read-only mode
```

---

## Non-Goals

This phase does not:

- delete repo files
- delete real profile files
- run guarded cleanup
- run guarded deploy
- create canonical profile content
- sync canonical roles to real `~/.hermes/profiles/`

---

## Verification Checklist

Expected PASS conditions:

1. `scripts/plan-repo-drift-source-cleanup.sh` exists.
2. `bash -n scripts/plan-repo-drift-source-cleanup.sh` passes.
3. Planner emits `Mode: read-only`.
4. Planner emits `Repo cleanup: DISABLED`.
5. Planner emits `CANONICAL_ROLE_COUNT=6`.
6. Planner emits `REPO_CLEANUP_CANDIDATE_COUNT=5` while old repo drift dirs exist.
7. Planner emits `REPO_BLOCKED_COUNT=0`.
8. Planner emits `REPO_MISSING_COUNT=0` while old repo drift dirs exist.
9. Planner emits `REPO_PROFILE_WRITE=false`.
10. Planner emits `REPO_PROFILE_DELETE=false`.
11. Planner emits `REAL_PROFILE_WRITE=false`.
12. Planner emits `REAL_PROFILE_DELETE=false`.
13. Working tree remains clean after verification.

---

## Lock Wording After Local Verification

```text
Phase 3K-FIX.6 repo drift source cleanup planning
PASS / read-only repo cleanup planner implemented / five repo drift source candidates detected / no repo delete / no real write / no real delete
```

---

## Next Phase

```text
Phase 3K-FIX.7 repo drift source cleanup execution
```

That phase may remove the old repo-local drift directories through reviewed git changes.
