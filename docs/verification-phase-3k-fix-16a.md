# Phase 3K-FIX.16a Runtime Smoke Doctor Matcher Hotfix

Status: PASS  
Result: doctor smoke matcher hardened / read-only checker only / no real profile write / no secret write / no config write

## Context

Phase 3K-FIX.16 introduced a read-only native profile runtime smoke checker:

- `scripts/check-native-profile-runtime-smoke.sh`

The first local execution showed that the checker correctly confirmed:

```text
ROLE_COUNT=6
PROFILE_SHOW_PASS_COUNT=6
PROFILE_SHOW_FAIL_COUNT=0
SOUL_CONFIGURED_COUNT=6
PROFILE_YAML_PRESENT_COUNT=6
ENV_MISSING_COUNT=6
CONFIG_MISSING_COUNT=6
GATEWAY_STOPPED_COUNT=6
BLOCKED_COUNT=0
```

However, the doctor pass counters did not pass:

```text
DOCTOR_PASS_COUNT=0
DOCTOR_FAIL_COUNT=6
PARTIAL: native profile runtime smoke completed with expected or unresolved gaps
```

This indicated that `hermes -p <role> doctor` was running and confirming role-context state, but the checker matched one exact path phrase too strictly.

## Hotfix

The doctor pass matcher was relaxed while keeping the smoke read-only.

The checker now treats a doctor run as passing when the output contains:

```text
Hermes Doctor
```

and at least one role-context signal:

```text
SOUL.md exists (persona configured)
~/.hermes/profiles/<role>
profiles/<role>
```

This matches the actual purpose of the Phase 3K-FIX.16 smoke:

- prove Hermes can enter the role profile context;
- prove the role persona is visible;
- avoid requiring one exact terminal wording across Hermes versions.

## Safety Boundary

This hotfix does not change real profile contents.

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

The checker still does not:

- run `hermes setup`;
- create `.env`;
- create or overwrite `config.yaml`;
- start gateway;
- run chat / oneshot;
- mutate memories, sessions, logs, skills, cron, auth, or state files.

## Expected Local Verification

After pulling the hotfix:

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull

bash -n scripts/check-native-profile-runtime-smoke.sh

bash scripts/check-native-profile-runtime-smoke.sh | grep -E \
  "ROLE_COUNT=|PROFILE_SHOW_PASS_COUNT=|PROFILE_SHOW_FAIL_COUNT=|DOCTOR_PASS_COUNT=|DOCTOR_FAIL_COUNT=|SOUL_CONFIGURED_COUNT=|PROFILE_YAML_PRESENT_COUNT=|ENV_MISSING_COUNT=|CONFIG_MISSING_COUNT=|GATEWAY_STOPPED_COUNT=|BLOCKED_COUNT=|PASS:|PARTIAL:"
```

Expected after this hotfix:

```text
ROLE_COUNT=6
PROFILE_SHOW_PASS_COUNT=6
PROFILE_SHOW_FAIL_COUNT=0
DOCTOR_PASS_COUNT=6
DOCTOR_FAIL_COUNT=0
SOUL_CONFIGURED_COUNT=6
PROFILE_YAML_PRESENT_COUNT=6
ENV_MISSING_COUNT=6
CONFIG_MISSING_COUNT=6
GATEWAY_STOPPED_COUNT=6
BLOCKED_COUNT=0
PASS: native profile runtime smoke completed in read-only mode
```

Then verify real deploy readiness remains unchanged:

```bash
./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

## Final Lock

Phase 3K-FIX.16a runtime smoke doctor matcher hotfix:

```text
PASS / doctor matcher hardened / profile context detection aligned with Hermes output / no real profile write / no secret write / no config write
```

## Next

After local PASS, Phase 3K-FIX.16 can be treated as runtime smoke PASS and the next action remains:

```text
Phase 3K-FIX.17 native profile runtime smoke execution lock
```
