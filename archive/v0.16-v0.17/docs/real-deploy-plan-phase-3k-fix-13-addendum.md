# Real Deploy Plan Addendum: Phase 3K-FIX.13 Native Profile Template Source Alignment

Status: Phase 3K-FIX.13 native profile template source alignment implemented  
Scope: repo source templates only  
Real profile write: false  
Real profile delete: false  
Secret write: false  

## Summary

Phase 3K-FIX.13 adds Hermes-native template source files for the six canonical OPC profiles.

This is a repo-side alignment step only. It does not mutate `~/.hermes/profiles/*` and does not create real `.env` files.

## Why this was needed

Phase 3K-FIX.11 confirmed Hermes CLI discovery and per-profile doctor execution.

Phase 3K-FIX.12 measured remaining native schema gaps:

- config missing
- `.env` missing
- `profile.yaml` missing
- alias missing

Phase 3K-FIX.13 resolves the repo source side for the non-secret artifacts and templates.

## Files added per role

For each canonical role:

```text
profiles/<role>/SOUL.md
profiles/<role>/profile.yaml
profiles/<role>/config.yaml.template
profiles/<role>/.env.template
```

Roles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Checker added

```text
scripts/check-native-profile-source-templates.sh
```

Read-only output markers:

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

## Security boundary

Phase 3K-FIX.13 intentionally does not add real credentials.

`.env.template` files contain only commented placeholders and local-only guidance.

Real `.env` remains local-only and must not be committed.

## Locked status

```text
Phase 3K-FIX.13 native profile template source alignment
PASS / six canonical roles include SOUL.md, profile.yaml, config.yaml.template, .env.template / source checker PASS / no real write / no real delete / no secret write
```

## Next action

```text
Phase 3K-FIX.14 native profile template guarded apply planning
```

Phase 3K-FIX.14 should plan guarded application of repo-owned template files to real profiles while preserving local-only secrets and runtime state.
