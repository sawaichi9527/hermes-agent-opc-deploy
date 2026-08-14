# Phase 3K-FIX.20 Local-only Config/Env Provisioning Guarded Execution

Status: PASS  
Result: guarded provisioning token accepted / six `.env` placeholders created / six `config.yaml` files created / create-only boundary preserved / no secret write / no gateway start / no chat

## Scope

Phase 3K-FIX.20 executed the guarded local-only provisioning script for missing native Hermes profile local files:

- `~/.hermes/profiles/<role>/.env`
- `~/.hermes/profiles/<role>/config.yaml`

The provisioning remained local-only and create-only.

## Implemented Script

```text
scripts/provision-local-profile-config-env.sh
```

## Guard Token

```text
REAL_PROVISION_LOCAL_CONFIG_ENV
```

## Default Mode Verified

The default mode remains dry-run:

```text
Mode: dry-run
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

Dry-run evidence:

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

## Apply Command Executed

The user executed:

```bash
bash scripts/provision-local-profile-config-env.sh \
  --apply \
  --confirm REAL_PROVISION_LOCAL_CONFIG_ENV
```

Apply mode reported:

```text
Mode: apply
Real provisioning: GUARDED_APPLY_REQUESTED
REAL_PROFILE_WRITE=true
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=true
ENV_WRITE=true
GATEWAY_START=false
CHAT_SMOKE=false
```

## Apply Evidence

The guarded apply created local-only placeholder/config files for all six canonical profiles:

```text
ROLE_COUNT=6
SOURCE_ENV_TEMPLATE_MISSING_COUNT=0
SOURCE_CONFIG_TEMPLATE_MISSING_COUNT=0
MISSING_DESTINATION_COUNT=0
ENV_CREATE_CANDIDATE_COUNT=6
CONFIG_CREATE_CANDIDATE_COUNT=6
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

Per-role created outputs:

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

## Local-only Protection Evidence

For each role, the script reported protected runtime paths as no-touch:

```text
LOCAL_ONLY_PROTECTED path=memories/ status=no_touch
LOCAL_ONLY_PROTECTED path=sessions/ status=no_touch
LOCAL_ONLY_PROTECTED path=logs/ status=no_touch
LOCAL_ONLY_PROTECTED path=skills/ status=no_touch
LOCAL_ONLY_PROTECTED path=cron/ status=no_touch
LOCAL_ONLY_PROTECTED path=state.db* status=no_touch
LOCAL_ONLY_PROTECTED path=auth.json status=no_touch
LOCAL_ONLY_PROTECTED path=gateway_state.json status=no_touch
```

## Secret Policy

`SECRET_WRITE=false` remains the governing marker.

Created `.env` files are placeholder/template-derived local files only. They do not prove real tokens are configured. Real API tokens remain local-only manual edits outside git.

## Post-apply Verification

Post-apply provisioning planner result:

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

Post-apply native profile schema result:

```text
ROLE_COUNT=6
MISSING_CONFIG_COUNT=0
MISSING_ENV_COUNT=0
MISSING_PROFILE_YAML_COUNT=0
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

## Runtime Non-actions

Phase 3K-FIX.20 did not:

- start gateway
- run chat
- run model calls
- clone default profile secrets
- overwrite existing local `.env`
- overwrite existing local `config.yaml`
- write repo files from local execution

## Final Lock

```text
Phase 3K-FIX.20 local-only config/env provisioning guarded execution
PASS / guarded provisioning token accepted / six .env placeholders created / six config.yaml files created / create-only boundary preserved / no secret write / no gateway start / no chat / readiness READY
```

## Next Step

Phase 3K-FIX.21 local-only secret manual fill plan / runtime readiness review
