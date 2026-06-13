# Phase 3M Hermes runtime readiness check

This phase verifies that the real local Hermes profile baseline is ready for a minimal Hermes runtime probe after Phase 3L.

Phase 3M keeps the same personal-use boundary:

```text
read-only by default
single request at a time
no parallel profile probing
no daemon/process startup
no load test
no throughput benchmark
no router or queue introduction
no external API fallback
```

## Purpose

Phase 3L proved the local OpenAI-compatible provider path:

```text
/models endpoint smoke: PASS for six profiles
single-profile chat smoke: PASS for secretary
explicit model.name cleanup: PASS for six real local profiles
```

Phase 3M moves one layer closer to Hermes runtime readiness by checking whether the real local Hermes home and profiles contain the expected runtime prerequisites.

This phase does not attempt to prove full Lark integration or multi-profile task orchestration.

## Script

```text
scripts/check-hermes-runtime-readiness.sh
```

The script is read-only. It does not mutate `~/.hermes`, does not edit profile config, does not print secrets, and does not send a chat request.

It checks:

```text
Hermes root exists
Hermes root SOUL.md exists, warning only if missing
profile root exists
Hermes command discovery, warning only by default
profile directory exists
profile SOUL.md exists, warning only if missing
profile config.yaml exists
profile .env exists
profile .env permission is 600, warning only if different
OPENAI_API_BASE present
OPENAI_API_BASE ends with /v1
OPENAI_API_KEY present
model.provider exists under model
model.name exists under model
```

The default profile list is:

```text
secretary coordinator researcher writer builder runes-holder
```

## Usage

Run the default read-only preflight:

```bash
cd ~/workspace/hermes-agent-opc-deploy
bash scripts/check-hermes-runtime-readiness.sh
```

Run only one profile:

```bash
PROFILE_LIST=secretary \
  bash scripts/check-hermes-runtime-readiness.sh
```

Require a detectable Hermes command:

```bash
bash scripts/check-hermes-runtime-readiness.sh --require-hermes-command
```

Treat warnings as failures:

```bash
bash scripts/check-hermes-runtime-readiness.sh --strict
```

## Phase 3M.1 verification lock

```text
Phase 3M.1 Hermes Runtime Readiness Preflight
Status: PASS
Result: read-only / six profiles checked / local provider config present / Hermes command discovered / warnings=0
Boundary: no runtime mutation / no chat request / no daemon / no concurrency / no load test
```

Maintainer verification confirmed:

```text
repository layout check: PASS
Hermes root exists: PASS
Hermes root SOUL.md exists: PASS
profile root exists: PASS
Hermes command found: hermes
secretary readiness: PASS
coordinator readiness: PASS
researcher readiness: PASS
writer readiness: PASS
builder readiness: PASS
runes-holder readiness: PASS
summary: PASS Hermes runtime readiness preflight completed; warnings=0
```

All six real local profiles had the expected runtime prerequisites:

```text
profile directory exists
SOUL.md exists
config.yaml exists
.env exists
.env permission 600
OPENAI_API_BASE present and ends with /v1
OPENAI_API_KEY present
model.provider present
model.name present
```

No secrets were printed or tracked. The check remained read-only and did not send any model request.

## Follow-up

The next step is Phase 3M.2 minimal Hermes command probe.

Phase 3M.2 must use the discovered `hermes` command and first identify supported command/help/profile syntax before attempting any model-backed request. It should remain read-only where possible, or single-request only after explicit maintainer approval.

Do not expand this phase into routing, queues, concurrency, daemon management, load testing, or external API fallback.
