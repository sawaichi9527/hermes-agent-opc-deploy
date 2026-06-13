# Phase 3K-FIX.20 Local-only Config/Env Provisioning Guarded Execution Implementation

Status: PREPARED  
Result: guarded local provisioning script implemented / dry-run available / local guarded apply pending / no remote real write / no secret write

## Scope

Phase 3K-FIX.20 implements the guarded local-only provisioning script for missing native Hermes profile local files:

- `~/.hermes/profiles/<role>/.env`
- `~/.hermes/profiles/<role>/config.yaml`

The implementation is intentionally guarded and create-only.

## Implemented Script

```text
scripts/provision-local-profile-config-env.sh
```

## Guard Token

```text
REAL_PROVISION_LOCAL_CONFIG_ENV
```

## Default Mode

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

## Apply Mode

Apply mode requires:

```bash
bash scripts/provision-local-profile-config-env.sh \
  --apply \
  --confirm REAL_PROVISION_LOCAL_CONFIG_ENV
```

Apply mode is allowed to create only files that are missing:

```text
.env
config.yaml
```

from repo-owned templates:

```text
.env.template
config.yaml.template
```

## Strict Create-only Rule

The script must not overwrite existing local files.

Protected existing files:

```text
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/config.yaml
```

If either exists, the script reports it as protected and skips it.

## Secret Policy

`.env` created by this script is a placeholder/template-derived local file only.

It must not contain real tokens committed to the repo. Real secrets must still be manually edited locally after provisioning.

## Runtime Non-actions

Phase 3K-FIX.20 does not:

- start gateway
- run chat
- run model calls
- run `hermes setup`
- clone default profile secrets
- write repo files from local execution
- overwrite local `.env`
- overwrite local `config.yaml`

## Expected Pre-apply Dry-run Evidence

Before local apply, expected dry-run markers are:

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

## Expected Apply Evidence

After guarded apply on the current clean profile state, expected markers are:

```text
Mode: apply
Real provisioning: GUARDED_APPLY_REQUESTED
ENV_CREATED_COUNT=6
CONFIG_CREATED_COUNT=6
LOCAL_PROVISIONING_CREATED_COUNT=12
REAL_PROFILE_WRITE=true
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=true
ENV_WRITE=true
GATEWAY_START=false
CHAT_SMOKE=false
PASS: local-only config/env guarded provisioning completed
```

## Post-apply Expected State

After apply:

```text
MISSING_ENV_COUNT=0
MISSING_CONFIG_COUNT=0
MISSING_PROFILE_YAML_COUNT=0
READINESS_STATUS=READY
```

The `SECRET_WRITE=false` marker remains true because no real secret is written; only placeholder/template-derived `.env` files are created.

## Final Lock

Current lock before local apply:

```text
Phase 3K-FIX.20 local-only config/env provisioning guarded execution implementation
PREPARED / guarded provisioning script implemented / dry-run available / local guarded apply pending / no remote real write / no secret write
```

After user-local apply succeeds, this file should be updated to final execution PASS.

## Next Step

Phase 3K-FIX.20 local guarded apply execution evidence lock
