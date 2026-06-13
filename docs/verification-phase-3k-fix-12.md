# Phase 3K-FIX.12 Native Profile Schema Alignment Planning

Status: PASS  
Scope: native schema planning + read-only checker  
Real profile write: false  
Real profile delete: false  
Secret write: false  

---

## 1. Summary

Phase 3K-FIX.12 records the gap between OPC filesystem-level profile deployment and Hermes native profile completeness.

Phase 3K-FIX.11 showed that Hermes CLI can discover the six canonical profiles and `hermes -p <role> doctor` resolves each profile's runtime home.

However, native profile completeness is still partial because the profiles currently lack some Hermes-native artifacts such as `.env`, `config.yaml`, optional `profile.yaml` description metadata, aliases, and initialized skills.

This phase intentionally does not run `hermes setup`, does not create `.env`, does not copy secrets, and does not modify real profiles.

---

## 2. Files Added

```text
scripts/check-native-profile-schema.sh
docs/native-profile-schema-alignment-plan.md
docs/verification-phase-3k-fix-12.md
```

---

## 3. Checker Contract

The checker is:

```text
read-only
non-destructive
secret-safe
local-profile-inspection only
```

It reports:

```text
MISSING_PROFILE_DIR_COUNT
MISSING_SOUL_COUNT
MISSING_CONFIG_COUNT
MISSING_ENV_COUNT
MISSING_PROFILE_YAML_COUNT
MISSING_SKILLS_DIR_COUNT
MISSING_ALIAS_COUNT
PROFILE_SHOW_SOUL_NOT_CONFIGURED_COUNT
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
```

It must not:

```text
- run hermes setup
- create .env
- write config.yaml
- create aliases
- start gateways
- run chat
- modify ~/.hermes/profiles
- delete profiles
```

---

## 4. Expected Current Interpretation

Expected status after Phase 3K-FIX.11 evidence:

```text
Hermes CLI profile discovery: PASS
Per-profile doctor resolution: PASS
SOUL.md detected by doctor: PASS
Native schema completeness: PARTIAL
Secrets/config initialization: intentionally missing
Runtime chat smoke: pending
```

Known gaps:

```text
.env missing
config.yaml missing
profile.yaml likely missing
alias missing
skills count 0
profile show may report SOUL.md not configured while doctor sees SOUL.md exists
```

---

## 5. Verification Commands

```bash
cd ~/workspace/hermes-agent-opc-deploy

bash -n scripts/check-native-profile-schema.sh

bash scripts/check-native-profile-schema.sh | grep -E \
  "PHASE 3K-FIX.12 NATIVE PROFILE SCHEMA ALIGNMENT CHECK|Mode: read-only|ROLE_COUNT=6|MISSING_CONFIG_COUNT=6|MISSING_ENV_COUNT=6|MISSING_PROFILE_YAML_COUNT=6|MISSING_ALIAS_COUNT=6|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|PASS: native profile schema inspection completed|PARTIAL: native profile schema inspection completed"

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

git status --short
```

---

## 6. Expected Checker Shape

The exact `PROFILE_SHOW_SOUL_NOT_CONFIGURED_COUNT` may vary depending on Hermes CLI behavior.

A valid Phase 3K-FIX.12 result may be:

```text
MISSING_PROFILE_DIR_COUNT=0
MISSING_SOUL_COUNT=0
MISSING_CONFIG_COUNT=6
MISSING_ENV_COUNT=6
MISSING_PROFILE_YAML_COUNT=6
MISSING_SKILLS_DIR_COUNT=0
MISSING_ALIAS_COUNT=6
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
PASS: native profile schema inspection completed
```

This is still a Phase 3K-FIX.12 PASS because the phase goal is not to make native schema complete. The goal is to expose and document the gap safely.

---

## 7. Final Lock

```text
Phase 3K-FIX.12 native profile schema alignment planning
PASS / read-only checker added / native schema gaps documented / no real write / no real delete / no secret write
```

---

## 8. Next Action

```text
Phase 3K-FIX.13 native profile template source alignment
```

Recommended scope:

```text
- add repo-owned SOUL.md for each canonical role if missing from source
- add profile.yaml with role description metadata
- add config.yaml.template only
- add .env.template only
- update guarded deploy planning for native schema templates
- do not commit real .env
- do not run hermes setup automatically
```
