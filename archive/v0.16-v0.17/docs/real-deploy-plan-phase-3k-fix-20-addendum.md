# Real Deploy Plan Addendum — Phase 3K-FIX.20

Status: Phase 3K-FIX.20 local-only config/env provisioning guarded execution completed  
Scope: guarded local provisioning executed / placeholder `.env` created / local `config.yaml` created  
Write mode: guarded local apply only  
Repo write: false during local execution  
Secret write: false  
Gateway start: false  
Chat smoke: false

## Purpose

Phase 3K-FIX.20 implemented and executed the local guarded provisioning script that creates missing per-profile local `.env` and `config.yaml` files from repo-owned templates.

This phase closes the previously measured local-only provisioning gap:

```text
MISSING_ENV_COUNT=6 -> 0
MISSING_CONFIG_COUNT=6 -> 0
LOCAL_PROVISIONING_CANDIDATE_COUNT=12 -> 0
```

## Script

```text
scripts/provision-local-profile-config-env.sh
```

## Guard Token Used

```text
REAL_PROVISION_LOCAL_CONFIG_ENV
```

## Dry-run Evidence

Dry-run completed before apply:

```text
Status: PHASE 3K-FIX.20 LOCAL-ONLY CONFIG/ENV GUARDED PROVISIONING
Mode: dry-run
ROLE_COUNT=6
ENV_CREATE_CANDIDATE_COUNT=6
CONFIG_CREATE_CANDIDATE_COUNT=6
LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=12
LOCAL_PROVISIONING_CREATED_COUNT=0
ENV_EXISTING_PROTECTED_COUNT=0
CONFIG_EXISTING_PROTECTED_COUNT=0
BLOCKED_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
PASS: local-only config/env guarded provisioning dry-run completed
```

## Guarded Apply Evidence

The user executed:

```bash
bash scripts/provision-local-profile-config-env.sh \
  --apply \
  --confirm REAL_PROVISION_LOCAL_CONFIG_ENV
```

Apply result:

```text
Mode: apply
Real provisioning: GUARDED_APPLY_REQUESTED
ROLE_COUNT=6
ENV_CREATED_COUNT=6
CONFIG_CREATED_COUNT=6
LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=12
LOCAL_PROVISIONING_CREATED_COUNT=12
ENV_EXISTING_PROTECTED_COUNT=0
CONFIG_EXISTING_PROTECTED_COUNT=0
BLOCKED_COUNT=0
REAL_PROFILE_WRITE=true
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=true
ENV_WRITE=true
GATEWAY_START=false
CHAT_SMOKE=false
PASS: local-only config/env guarded provisioning completed
```

## Created Local Files

For each canonical role, the script created:

```text
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/config.yaml
```

Canonical roles covered:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Created file evidence:

```text
CREATED_LOCAL_ENV role=secretary path=.env
CREATED_LOCAL_CONFIG role=secretary path=config.yaml
CREATED_LOCAL_ENV role=coordinator path=.env
CREATED_LOCAL_CONFIG role=coordinator path=config.yaml
CREATED_LOCAL_ENV role=researcher path=.env
CREATED_LOCAL_CONFIG role=researcher path=config.yaml
CREATED_LOCAL_ENV role=writer path=.env
CREATED_LOCAL_CONFIG role=writer path=config.yaml
CREATED_LOCAL_ENV role=builder path=.env
CREATED_LOCAL_CONFIG role=builder path=config.yaml
CREATED_LOCAL_ENV role=runes-holder path=.env
CREATED_LOCAL_CONFIG role=runes-holder path=config.yaml
```

## Safety Boundary Preserved

The script is create-only and did not overwrite existing local files.

It did not touch:

```text
memories/
sessions/
logs/
skills/
cron/
state.db*
auth.json
gateway_state.json
```

The script reported these runtime paths as protected no-touch paths for each role.

## Secret Policy

Created `.env` files are placeholder/template-derived local files only.

The key marker remains:

```text
SECRET_WRITE=false
```

Real API tokens remain manual local-only edits. They must not be committed to git.

## Post-apply Checks

Post-apply local provisioning planner:

```text
ROLE_COUNT=6
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
LOCAL_PROVISIONING_CANDIDATE_COUNT=0
REAL_PROFILE_WRITE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
```

Post-apply native profile schema:

```text
ROLE_COUNT=6
MISSING_PROFILE_YAML_COUNT=0
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
```

Readiness remained green:

```text
ROLE_COUNT=6
SOURCE_STATUS=complete
DESTINATION_STATUS=pass
RESTORE_PLANNER_STATUS=pass
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

## Final Lock

```text
Phase 3K-FIX.20 local-only config/env provisioning guarded execution
PASS / guarded provisioning token accepted / six .env placeholders created / six config.yaml files created / create-only boundary preserved / no secret write / no gateway start / no chat / readiness READY
```

## Next Step

Phase 3K-FIX.21 local-only secret manual fill plan / runtime readiness review
