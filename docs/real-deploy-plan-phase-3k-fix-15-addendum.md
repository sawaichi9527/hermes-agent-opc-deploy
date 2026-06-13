# Real Deploy Plan Addendum — Phase 3K-FIX.15

Status: Phase 3K-FIX.15 guarded apply script implemented  
Scope: local guarded execution pending / no remote real write / no secret write

## Summary

Phase 3K-FIX.15 introduces the guarded execution script for applying
repository-owned native profile templates into existing Hermes profiles.

This phase deliberately separates:

1. Script implementation in the repository.
2. Local dry-run verification.
3. Local guarded apply execution with explicit token.
4. Post-apply verification lock.

## Script

```text
scripts/apply-native-profile-templates.sh
```

## Apply Token

```text
REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

## Files Eligible for Apply

For each canonical role:

```text
SOUL.md
profile.yaml
config.yaml.template
.env.template
```

## Files and State Protected from Apply

The script must not write or remove:

```text
.env
config.yaml
auth.json
state.db*
gateway.pid
gateway_state.json
memories/
sessions/
logs/
skills/
cron/
workspace/
home/
plans/
backups/
cache/
```

## Local Verification Sequence

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull

git status

git log --oneline -8
```

Dry-run:

```bash
bash -n scripts/apply-native-profile-templates.sh

bash scripts/apply-native-profile-templates.sh | grep -E \
  "PHASE 3K-FIX.15|Mode: dry-run|ROLE_COUNT=6|APPLY_CANDIDATE_COUNT=24|APPLIED_TEMPLATE_COUNT=0|MISSING_SOURCE_COUNT=0|MISSING_DESTINATION_COUNT=0|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|CONFIG_WRITE=false|PASS: native profile template guarded apply dry-run completed"
```

Guarded apply:

```bash
bash scripts/apply-native-profile-templates.sh \
  --apply \
  --confirm REAL_APPLY_NATIVE_PROFILE_TEMPLATES
```

Expected guarded apply markers:

```text
Mode: apply
Real template apply: GUARDED_APPLY_REQUESTED
BACKUP_STATUS=created
ROLE_COUNT=6
MISSING_SOURCE_COUNT=0
MISSING_DESTINATION_COUNT=0
BLOCKED_COUNT=0
REAL_PROFILE_WRITE=true
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
PASS: native profile template guarded apply completed
```

Post-apply checks:

```bash
bash scripts/check-native-profile-schema.sh | grep -E \
  "ROLE_COUNT=6|MISSING_PROFILE_YAML_COUNT=0|MISSING_ENV_COUNT=6|MISSING_CONFIG_COUNT=6|MISSING_ALIAS_COUNT=6|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|PASS: native profile schema inspection completed"

bash scripts/check-native-profile-source-templates.sh | grep -E \
  "ROLE_COUNT=6|MISSING_SOURCE_TEMPLATE_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|PASS: native profile source templates complete"

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

## Expected Phase 3K-FIX.15 Final Lock

After local guarded apply evidence is captured, Phase 3K-FIX.15 should lock as:

```text
Phase 3K-FIX.15 native profile template guarded apply execution
PASS / guarded apply token accepted / repo-owned templates applied / backup created / local-only files protected / no secret write / no config write
```

## Next Planned Phase

```text
Phase 3K-FIX.16 native profile runtime smoke planning
```

Phase 3K-FIX.16 should validate Hermes runtime behavior after template apply,
including `hermes profile show`, `hermes -p <role> doctor`, and a minimal
non-destructive invocation strategy.
