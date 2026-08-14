# Phase 3K-FIX.16 Native Profile Runtime Smoke Plan

Status: Phase 3K-FIX.16 runtime smoke planning implemented  
Scope: read-only runtime smoke / no chat / no gateway start / no real secret write / no config write  
Date: 2026-06-13

## Purpose

Phase 3K-FIX.16 verifies that the six canonical Hermes profiles are usable by
Hermes native profile discovery after the Phase 3K-FIX.15 guarded template
apply.

This phase does not attempt a full agent conversation.  It only checks that
Hermes can resolve each profile through native CLI surfaces and that each role
has the expected identity files on disk.

## Inputs

Canonical roles are read from:

```text
config/profile-roles.txt
```

Expected roles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Real profile root:

```text
~/.hermes/profiles
```

## Read-only Smoke Commands

The checker uses these non-destructive Hermes commands:

```bash
hermes profile show <role>
hermes -p <role> doctor
```

The checker does not run:

```bash
hermes -p <role> chat
hermes -p <role> gateway start
hermes setup
hermes doctor --fix
```

## Smoke Criteria

For each role, the checker expects:

- `hermes profile show <role>` resolves the profile name.
- `hermes profile show <role>` reports the real profile path.
- `hermes -p <role> doctor` executes in the role context.
- `doctor` sees the profile directory.
- `doctor` reports `SOUL.md exists (persona configured)`.
- `profile.yaml` exists in the real profile directory.
- gateway remains stopped.

Known expected gaps remain outside this phase:

- `.env` may be missing.
- `config.yaml` may be missing and defaults may be used.
- alias may be missing.
- skills may be uninitialized.
- model/provider may be unset.

These gaps are not treated as Phase 3K-FIX.16 failure unless they block native
profile discovery or doctor execution.

## Safety Boundary

The checker must report:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
```

This phase must not create or overwrite:

```text
.env
config.yaml
auth.json
state.db*
gateway_state.json
processes.json
memories/
sessions/
logs/
skills/
cron/
```

## Checker

Implemented script:

```bash
scripts/check-native-profile-runtime-smoke.sh
```

Expected successful summary after Phase 3K-FIX.15:

```text
ROLE_COUNT=6
PROFILE_SHOW_PASS_COUNT=6
PROFILE_SHOW_FAIL_COUNT=0
DOCTOR_PASS_COUNT=6
DOCTOR_FAIL_COUNT=0
SOUL_CONFIGURED_COUNT=6
PROFILE_YAML_PRESENT_COUNT=6
BLOCKED_COUNT=0
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
CONFIG_WRITE=false
GATEWAY_START=false
CHAT_SMOKE=false
PASS: native profile runtime smoke completed in read-only mode
```

If `.env`, `config.yaml`, alias, or skills remain missing, they should be
recorded as expected runtime readiness gaps for a later phase, not silently
fixed here.

## Out of Scope

Phase 3K-FIX.16 does not perform:

- real secret provisioning
- config provisioning
- alias creation
- gateway startup
- Telegram gateway binding
- model/provider selection
- chat or oneshot execution
- memory writes
- skills installation

## Final Lock Target

```text
Phase 3K-FIX.16 native profile runtime smoke planning
PASS / read-only runtime smoke checker added / native profile show and doctor smoke defined / no gateway start / no chat / no secret write / no config write
```

## Next Step

Phase 3K-FIX.17 native profile runtime smoke execution
