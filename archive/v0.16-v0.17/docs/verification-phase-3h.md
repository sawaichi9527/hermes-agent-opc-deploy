# Phase 3H Profile Source Root Completion

Status: source root completed / pending local readiness verification  
Scope: repo-local profile source only  
Real deploy: disabled  
Real restore: disabled

---

## Purpose

Phase 3H completes the repo-local profile source root required by the Phase 3G readiness gate.

This phase does not perform real deployment. It only ensures the repository contains the required role directories for a future guarded apply.

---

## Source Root

Canonical source root:

```text
profiles/
```

Required guarded deploy roles:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

Phase 3H adds minimal placeholder files in each required role directory so the directories are tracked by git.

---

## Boundary

Phase 3H does not:

- run guarded apply
- write to real `~/.hermes/profiles/`
- create real backup directories
- restore or reset profiles
- add daemon, database, service, remote telemetry, or orchestration
- make Hermes Agent depend on the deployment scripts at runtime

---

## Expected Readiness Change

Before Phase 3H, the readiness gate reported:

```text
SOURCE_STATUS=blocked
READINESS_STATUS=BLOCKED
```

After Phase 3H, assuming real destination ownership is safe and restore planning remains present, the readiness gate should report:

```text
SOURCE_STATUS=complete
SOURCE_ROOT=<repo>/profiles
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
```

---

## Verification Commands

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull

for role in default developer reviewer operator trial; do
  test -d "profiles/$role" && echo "PASS profiles/$role exists"
done

./scripts/check-real-deploy-readiness.sh | grep -E \
  "PHASE 3G REAL DEPLOY READINESS GATE|SOURCE_STATUS=complete|SOURCE_ROOT=.*/profiles|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

./scripts/deploy-real-profiles.sh | grep -E \
  "PHASE 3E GUARDED APPLY DRAFT|Mode: dry-run|Real deploy: DISABLED|REAL_PROFILE_WRITE=false"

./scripts/deploy-real-profiles.sh --apply && echo "UNEXPECTED" || echo "PASS: apply without confirm rejected"

git status --short
```

---

## Acceptance Criteria

Phase 3H is PASS only if:

1. `profiles/default/` exists.
2. `profiles/developer/` exists.
3. `profiles/reviewer/` exists.
4. `profiles/operator/` exists.
5. `profiles/trial/` exists.
6. `profiles/README.md` documents the Phase 3H guarded deploy role set.
7. `docs/verification-phase-3h.md` exists.
8. Readiness checker reports `SOURCE_STATUS=complete`.
9. Readiness checker reports `READINESS_STATUS=READY`, unless destination ownership blocks real apply.
10. Deploy script default dry-run still reports `REAL_PROFILE_WRITE=false`.
11. Deploy script still rejects incomplete apply authorization.
12. No real deploy is performed.
13. Git working tree is clean after verification.

---

## Lock Wording

If readiness becomes READY:

```text
Phase 3H profile source root completion
PASS / canonical profiles source root complete / readiness READY / no real write
```

If destination ownership blocks readiness:

```text
Phase 3H profile source root completion
PASS / canonical profiles source root complete / readiness blocked by destination ownership / no real write
```

---

## Next Phase

If readiness is READY, the next phase may be:

```text
Phase 3I first real guarded apply planning / operator confirmation
```

Phase 3I should still begin with an explicit dry-run review before any real apply command is executed.
