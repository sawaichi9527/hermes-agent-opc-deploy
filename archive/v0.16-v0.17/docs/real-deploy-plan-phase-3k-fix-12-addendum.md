# Real Deploy Plan Addendum - Phase 3K-FIX.12

Status: Phase 3K-FIX.12 native profile schema alignment planning implemented  
Date: 2026-06-13  
Scope: planning + read-only checker only  
Real profile write: false  
Real profile delete: false  
Secret write: false  

---

## 1. Result

Phase 3K-FIX.12 adds a native profile schema alignment plan and a read-only checker.

It does not modify real profiles and does not run Hermes native setup commands.

---

## 2. Added Artifacts

```text
scripts/check-native-profile-schema.sh
docs/native-profile-schema-alignment-plan.md
docs/verification-phase-3k-fix-12.md
docs/real-deploy-plan-phase-3k-fix-12-addendum.md
```

---

## 3. Why this phase exists

Phase 3K-FIX.10 proved guarded filesystem deploy.

Phase 3K-FIX.11 proved Hermes CLI profile discovery and per-profile doctor resolution.

However, Phase 3K-FIX.11 also showed the profiles are not fully native-schema aligned:

```text
.env missing
config.yaml missing
profile.yaml not established
aliases missing
skills count 0
chat smoke pending
```

Phase 3K-FIX.12 converts that runtime uncertainty into a repeatable read-only inspection.

---

## 4. Safety Boundary

This phase explicitly avoids:

```text
hermes setup
hermes profile create
.env writes
config.yaml writes
secret copying
alias creation
gateway start
profile delete
profile overwrite
```

---

## 5. Verification

Run:

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull

bash -n scripts/check-native-profile-schema.sh

bash scripts/check-native-profile-schema.sh | grep -E \
  "PHASE 3K-FIX.12 NATIVE PROFILE SCHEMA ALIGNMENT CHECK|Mode: read-only|ROLE_COUNT=6|MISSING_CONFIG_COUNT=6|MISSING_ENV_COUNT=6|MISSING_PROFILE_YAML_COUNT=6|MISSING_ALIAS_COUNT=6|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|PASS: native profile schema inspection completed|PARTIAL: native profile schema inspection completed"

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

git status --short
```

---

## 6. Status Lock

```text
Phase 3K-FIX.12 native profile schema alignment planning
PASS / read-only checker added / native schema gaps documented / no real write / no real delete / no secret write
```

---

## 7. Next Action

```text
Phase 3K-FIX.13 native profile template source alignment
```

Recommended next scope:

```text
repo-owned SOUL.md
repo-owned profile.yaml
repo-owned config.yaml.template
repo-owned .env.template
no real .env
no secrets
no automatic setup
```
