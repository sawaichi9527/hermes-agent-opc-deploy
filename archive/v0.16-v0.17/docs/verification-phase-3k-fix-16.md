# Phase 3K-FIX.16 Native Profile Runtime Smoke Planning

Status: PASS  
Result: read-only runtime smoke checker added / native profile show and doctor smoke defined / no gateway start / no chat / no secret write / no config write  
Date: 2026-06-13

## Scope

Phase 3K-FIX.16 adds a read-only runtime smoke checker for the six canonical
Hermes native profiles.

The checker verifies native Hermes profile discovery through safe CLI paths:

```bash
hermes profile show <role>
hermes -p <role> doctor
```

It does not start the gateway, does not run chat, and does not write secrets or
configuration.

## Implemented Files

```text
scripts/check-native-profile-runtime-smoke.sh
docs/native-profile-runtime-smoke-plan.md
docs/verification-phase-3k-fix-16.md
docs/real-deploy-plan-phase-3k-fix-16-addendum.md
```

## Safety Boundary

The runtime smoke checker is read-only by design.

Expected safety markers:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

Forbidden in this phase:

```text
hermes setup
hermes doctor --fix
hermes -p <role> chat
hermes -p <role> gateway start
.env creation
config.yaml creation
auth/state/session/memory writes
```

## Smoke Expectations

The checker expects:

```text
ROLE_COUNT=6
PROFILE_SHOW_PASS_COUNT=6
PROFILE_SHOW_FAIL_COUNT=0
DOCTOR_PASS_COUNT=6
DOCTOR_FAIL_COUNT=0
SOUL_CONFIGURED_COUNT=6
PROFILE_YAML_PRESENT_COUNT=6
BLOCKED_COUNT=0
```

Expected remaining gaps after this phase:

```text
.env missing
config.yaml missing / defaults used
alias missing
skills uninitialized
model/provider unset
```

These are later provisioning concerns, not Phase 3K-FIX.16 blockers unless they
prevent `profile show` or `doctor` from running.

## Verification Commands

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull

git status
git log --oneline -8

bash -n scripts/check-native-profile-runtime-smoke.sh

bash scripts/check-native-profile-runtime-smoke.sh | grep -E \
  "PHASE 3K-FIX.16|Mode: read-only|ROLE_COUNT=6|PROFILE_SHOW_PASS_COUNT=6|PROFILE_SHOW_FAIL_COUNT=0|DOCTOR_PASS_COUNT=6|DOCTOR_FAIL_COUNT=0|SOUL_CONFIGURED_COUNT=6|PROFILE_YAML_PRESENT_COUNT=6|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|CONFIG_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS: native profile runtime smoke completed in read-only mode"

./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"

git status --short
```

## Expected Result

The runtime smoke checker should pass if Hermes can resolve every canonical role
and doctor can enter every profile context.

Expected result:

```text
PASS: native profile runtime smoke completed in read-only mode
```

## Final Lock

```text
Phase 3K-FIX.16 native profile runtime smoke planning
PASS / read-only runtime smoke checker added / native profile show and doctor smoke defined / no gateway start / no chat / no secret write / no config write
```

## Next Step

Phase 3K-FIX.17 native profile runtime smoke execution
