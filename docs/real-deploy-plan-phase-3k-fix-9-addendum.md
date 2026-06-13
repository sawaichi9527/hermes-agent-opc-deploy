# Real Deploy Plan Addendum - Phase 3K-FIX.9

Status: Phase 3K-FIX.9 canonical content guarded apply planning implemented  
Scope: planning only / no real apply / no real write / no real delete

## Phase Result

```text
Phase 3K-FIX.9 canonical content guarded apply planning
PASS candidate / pending local verification
```

## What Changed

This phase adds a dedicated planning document for syncing canonical profile README content into real `~/.hermes/profiles/` in the next phase.

Added:

```text
docs/canonical-content-guarded-apply-plan.md
docs/verification-phase-3k-fix-9.md
```

## Current Canonical Profile Source

```text
profiles/secretary/README.md
profiles/coordinator/README.md
profiles/researcher/README.md
profiles/writer/README.md
profiles/builder/README.md
profiles/runes-holder/README.md
```

Canonical role source is driven by:

```text
config/profile-roles.txt
```

Expected role count:

```text
ROLE_COUNT=6
```

## Current Drift State

Repo drift source artifacts remain removed:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

Real drift profiles remain removed:

```text
~/.hermes/profiles/default/
~/.hermes/profiles/developer/
~/.hermes/profiles/reviewer/
~/.hermes/profiles/operator/
~/.hermes/profiles/trial/
```

## Guarded Apply Boundary

Phase 3K-FIX.9 does not execute:

```text
bash scripts/deploy-real-profiles.sh --apply --confirm REAL_DEPLOY_PROFILES --source-root "$PWD/profiles"
```

That command is reserved for Phase 3K-FIX.10.

## Local Verification Targets

Expected verification signals:

```text
READINESS_STATUS=READY
PREFLIGHT_STATUS=PASS
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
repo drift absent
real drift absent
```

## Next Phase

```text
Phase 3K-FIX.10 canonical content guarded apply execution
```
