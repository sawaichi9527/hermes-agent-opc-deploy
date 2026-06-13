# Real Deploy Plan Addendum — Phase 3K-FIX.16

Status: Phase 3K-FIX.16 native profile runtime smoke planning implemented  
Date: 2026-06-13

## Summary

Phase 3K-FIX.16 adds read-only runtime smoke planning for the six canonical
Hermes native profiles.

This phase introduces a checker that verifies safe Hermes CLI runtime surfaces:

```bash
hermes profile show <role>
hermes -p <role> doctor
```

The phase does not start gateways, does not run chat, and does not provision
secrets or local configuration.

## New Read-only Checker

```text
scripts/check-native-profile-runtime-smoke.sh
```

The checker reports these safety markers:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

## Runtime Smoke Boundary

Allowed checks:

```text
profile show
profile path resolution
doctor profile context resolution
SOUL.md persona confirmation
profile.yaml presence
readiness stays READY
```

Forbidden checks in this phase:

```text
chat / oneshot
gateway start
hermes setup
hermes doctor --fix
.env creation
config.yaml creation
secret copy
state/session/memory writes
```

## Expected Runtime Result

After Phase 3K-FIX.15, a successful read-only smoke should report:

```text
ROLE_COUNT=6
PROFILE_SHOW_PASS_COUNT=6
PROFILE_SHOW_FAIL_COUNT=0
DOCTOR_PASS_COUNT=6
DOCTOR_FAIL_COUNT=0
SOUL_CONFIGURED_COUNT=6
PROFILE_YAML_PRESENT_COUNT=6
BLOCKED_COUNT=0
PASS: native profile runtime smoke completed in read-only mode
```

Expected remaining gaps:

```text
.env missing
config.yaml missing / defaults used
alias missing
skills uninitialized
model/provider unset
```

These are intentionally deferred to a later provisioning phase.

## Verification

Run:

```bash
cd ~/workspace/hermes-agent-opc-deploy

bash -n scripts/check-native-profile-runtime-smoke.sh

bash scripts/check-native-profile-runtime-smoke.sh | grep -E \
  "PHASE 3K-FIX.16|Mode: read-only|ROLE_COUNT=6|PROFILE_SHOW_PASS_COUNT=6|PROFILE_SHOW_FAIL_COUNT=0|DOCTOR_PASS_COUNT=6|DOCTOR_FAIL_COUNT=0|SOUL_CONFIGURED_COUNT=6|PROFILE_YAML_PRESENT_COUNT=6|BLOCKED_COUNT=0|REAL_PROFILE_WRITE=false|REAL_PROFILE_DELETE=false|SECRET_WRITE=false|CONFIG_WRITE=false|GATEWAY_START=false|CHAT_SMOKE=false|PASS: native profile runtime smoke completed in read-only mode"
```

Readiness must remain:

```text
READINESS_STATUS=READY
REAL_PROFILE_WRITE=false
REAL_RESTORE_WRITE=false
```

## Final Lock

```text
Phase 3K-FIX.16 native profile runtime smoke planning
PASS / read-only runtime smoke checker added / native profile show and doctor smoke defined / no gateway start / no chat / no secret write / no config write
```

## Next Step

Phase 3K-FIX.17 native profile runtime smoke execution
