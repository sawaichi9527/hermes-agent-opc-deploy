# Phase 3K-FIX.13 Native Profile Template Source Alignment

Status: PASS  
Scope: repo-owned native profile template source only  
Real profile write: false  
Real profile delete: false  
Secret write: false  

## Purpose

Phase 3K-FIX.13 aligns the canonical role source tree with Hermes native profile expectations without writing local secrets or mutating real `~/.hermes/profiles/*`.

This follows Phase 3K-FIX.12, which measured native schema gaps across six discovered Hermes profiles:

- missing `config.yaml`
- missing `.env`
- missing `profile.yaml`
- missing aliases

Phase 3K-FIX.13 does not fix local runtime state directly. It adds repo-owned template source that can later be guarded-applied.

## Canonical roles

- secretary
- coordinator
- researcher
- writer
- builder
- runes-holder

## Added source artifacts

For each canonical role, Phase 3K-FIX.13 adds:

```text
profiles/<role>/SOUL.md
profiles/<role>/profile.yaml
profiles/<role>/config.yaml.template
profiles/<role>/.env.template
```

Existing `profiles/<role>/README.md` remains in place as human-facing documentation.

## Safety boundary

This phase does not:

- run `hermes setup`
- run `hermes profile create`
- write `~/.hermes/profiles/*`
- create real `.env`
- copy default profile secrets
- configure API keys
- configure provider/model credentials
- create wrapper aliases
- start gateways

## Checker

New read-only checker:

```bash
bash scripts/check-native-profile-source-templates.sh
```

Expected markers:

```text
Status: PHASE 3K-FIX.13 NATIVE PROFILE TEMPLATE SOURCE ALIGNMENT CHECK
Mode: read-only
ROLE_COUNT=6
MISSING_SOURCE_TEMPLATE_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
PASS: native profile source templates complete
```

## Expected verification

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull

git status
git log --oneline -20

bash -n scripts/check-native-profile-source-templates.sh
bash scripts/check-native-profile-source-templates.sh | grep -E \
  "PHASE 3K-FIX.13|Mode: read-only|ROLE_COUNT=6|MISSING_SOURCE_TEMPLATE_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|PASS: native profile source templates complete"

for role in secretary coordinator researcher writer builder runes-holder; do
  test -f "profiles/$role/README.md" && echo "PASS README $role"
  test -f "profiles/$role/SOUL.md" && echo "PASS SOUL $role"
  test -f "profiles/$role/profile.yaml" && echo "PASS profile.yaml $role"
  test -f "profiles/$role/config.yaml.template" && echo "PASS config template $role"
  test -f "profiles/$role/.env.template" && echo "PASS env template $role"
done

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

git status --short
```

## Expected result

```text
Phase 3K-FIX.13 native profile template source alignment
PASS / six canonical roles include SOUL.md, profile.yaml, config.yaml.template, .env.template / source checker PASS / no real write / no real delete / no secret write
```

## Next action

Phase 3K-FIX.14 native profile template guarded apply planning

This should plan how to apply repo-owned native templates into real `~/.hermes/profiles/<role>/` without overwriting local secrets.
