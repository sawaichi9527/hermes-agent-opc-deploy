# Phase 3K-FIX.2 Canonical Role Config and Readiness Rewrite

Status: implementation committed / pending local verification  
Scope: canonical role config, readiness rewrite, deploy script role-list rewrite  
Real profile write: disabled during verification  
Real cleanup: not implemented  
Real restore: disabled

---

## Purpose

Phase 3K-FIX.2 corrects the role taxonomy drift found after Phase 3K.

The earlier deploy scripts hard-coded these generic OPC roles:

```text
default
developer
reviewer
operator
trial
```

Phase 3K-FIX.1 selected the canonical Hermes maintainer role taxonomy instead:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Phase 3K-FIX.2 implements that correction by moving the role list into a plain config file and making the readiness/deploy scripts read that config.

---

## Added Config

Canonical role config:

```text
config/profile-roles.txt
```

Expected content:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

The config is intentionally simple: one role per line, blank lines and comments ignored.

---

## Added Canonical Source Directories

Phase 3K-FIX.2 adds repo-local source root directories:

```text
profiles/secretary/
profiles/coordinator/
profiles/researcher/
profiles/writer/
profiles/builder/
profiles/runes-holder/
```

These are skeleton directories only. They are not synced to real `~/.hermes/profiles/` in this phase.

---

## Script Changes

Updated scripts:

```text
scripts/check-real-deploy-readiness.sh
scripts/deploy-real-profiles.sh
```

Both scripts now load roles from:

```text
config/profile-roles.txt
```

Both scripts support an optional override:

```text
--role-config PATH
```

Expected readiness output after local verification:

```text
Status: PHASE 3K-FIX.2 CANONICAL ROLE READINESS GATE
ROLE_COUNT=6
ROLE=secretary
ROLE=coordinator
ROLE=researcher
ROLE=writer
ROLE=builder
ROLE=runes-holder
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

Expected deploy dry-run output after local verification:

```text
Status: PHASE 3K-FIX.2 CANONICAL ROLE GUARDED APPLY
Mode: dry-run
Real deploy: DISABLED
ROLE_COUNT=6
SOURCE_STATUS=complete
PREFLIGHT_STATUS=PASS
REAL_PROFILE_WRITE=false
```

---

## Explicit Non-goals

Phase 3K-FIX.2 does not:

- delete real `default/developer/reviewer/operator/trial` skeletons
- run real guarded apply
- create real canonical Hermes profile directories
- create a new backup
- restore or reset anything
- change Hermes Agent runtime behavior

The existing drift skeletons remain present until a separate cleanup phase.

---

## Acceptance Criteria

Phase 3K-FIX.2 is PASS only if:

1. `config/profile-roles.txt` exists.
2. `config/profile-roles.txt` lists the six canonical Hermes roles.
3. Canonical source directories exist under `profiles/`.
4. `scripts/check-real-deploy-readiness.sh` passes `bash -n`.
5. `scripts/deploy-real-profiles.sh` passes `bash -n`.
6. Readiness checker emits `ROLE_COUNT=6`.
7. Readiness checker emits `SOURCE_STATUS=complete`.
8. Readiness checker emits `READINESS_STATUS=READY`.
9. Deploy script dry-run emits `PHASE 3K-FIX.2 CANONICAL ROLE GUARDED APPLY`.
10. Deploy script dry-run emits `PREFLIGHT_STATUS=PASS`.
11. Deploy script remains dry-run by default.
12. `--apply` without `--confirm REAL_DEPLOY_PROFILES` is still rejected.
13. `REAL_PROFILE_WRITE=false` is emitted during smoke.
14. No real cleanup or restore is performed.
15. Git working tree is clean after verification.

---

## Lock Wording

If local verification passes, lock as:

```text
Phase 3K-FIX.2 canonical role config and readiness rewrite
PASS / config-driven canonical roles / readiness READY / deploy dry-run PASS / no real write / drift cleanup still pending
```

---

## Next Phase

Recommended next phase:

```text
Phase 3K-FIX.3 drift cleanup planning
```

Phase 3K-FIX.3 should plan how to safely remove only the OPC-managed generic skeletons:

```text
~/.hermes/profiles/default/
~/.hermes/profiles/developer/
~/.hermes/profiles/reviewer/
~/.hermes/profiles/operator/
~/.hermes/profiles/trial/
```

Cleanup should remain read-only planning first. Any real delete must require an explicit confirmation token.
