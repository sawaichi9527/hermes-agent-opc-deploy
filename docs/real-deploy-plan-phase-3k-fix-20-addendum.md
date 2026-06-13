# Real Deploy Plan Addendum — Phase 3K-FIX.20

Status: Phase 3K-FIX.20 local-only config/env provisioning guarded execution implementation prepared  
Scope: guarded local provisioning script / dry-run first / local apply pending  
Write mode: guarded local apply only  
Repo write: false during local execution  
Secret write: false  
Gateway start: false  
Chat smoke: false

## Purpose

Phase 3K-FIX.20 implements the local guarded provisioning script that can create missing per-profile local `.env` and `config.yaml` files from repo-owned templates.

This phase does not itself prove execution until the user runs the guarded apply command locally.

## New Script

```text
scripts/provision-local-profile-config-env.sh
```

## Guard Token

```text
REAL_PROVISION_LOCAL_CONFIG_ENV
```

## Dry-run Command

```bash
bash scripts/provision-local-profile-config-env.sh
```

Expected dry-run markers:

```text
Mode: dry-run
ROLE_COUNT=6
ENV_CREATE_CANDIDATE_COUNT=6
CONFIG_CREATE_CANDIDATE_COUNT=6
LOCAL_PROVISIONING_WRITE_CANDIDATE_COUNT=12
LOCAL_PROVISIONING_CREATED_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
ENV_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
PASS: local-only config/env guarded provisioning dry-run completed
```

## Guarded Apply Command

```bash
bash scripts/provision-local-profile-config-env.sh \
  --apply \
  --confirm REAL_PROVISION_LOCAL_CONFIG_ENV
```

Expected apply markers on the current clean local state:

```text
Mode: apply
Real provisioning: GUARDED_APPLY_REQUESTED
ROLE_COUNT=6
ENV_CREATED_COUNT=6
CONFIG_CREATED_COUNT=6
LOCAL_PROVISIONING_CREATED_COUNT=12
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

## Safety Boundary

The script is create-only.

It must not overwrite:

```text
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/config.yaml
```

It must not touch:

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

## Secret Policy

Created `.env` files are placeholder/template-derived only. They must not contain real tokens from git.

Real API tokens remain manually edited local-only secrets.

## Post-apply Checks

After guarded apply, verify:

```bash
bash scripts/plan-local-profile-provisioning.sh | grep -E \
  "MISSING_ENV_COUNT=0|MISSING_CONFIG_COUNT=0|LOCAL_PROVISIONING_CANDIDATE_COUNT=0|REAL_PROFILE_WRITE=false|SECRET_WRITE=false|CONFIG_WRITE=false|ENV_WRITE=false"

bash scripts/check-native-profile-schema.sh | grep -E \
  "ROLE_COUNT=6|MISSING_PROFILE_YAML_COUNT=0|MISSING_ENV_COUNT=0|MISSING_CONFIG_COUNT=0|REAL_PROFILE_WRITE=false|SECRET_WRITE=false"

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

## Final Lock Target

After user-local guarded apply:

```text
Phase 3K-FIX.20 local-only config/env provisioning guarded execution
PASS / guarded provisioning token accepted / six .env placeholders created / six config.yaml files created / no overwrite / no secret write / no gateway start / no chat
```

## Next Step

Phase 3K-FIX.21 local-only secret manual fill plan / runtime readiness review
