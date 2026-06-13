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

## Expected Phase 3M.1 result

After Phase 3L.5, the expected non-strict result is:

```text
PASS Hermes runtime readiness preflight completed
```

Warnings may still be acceptable if they only represent non-blocking local facts, such as a missing command discovery result before the exact Hermes CLI invocation is confirmed.

## Follow-up

If Phase 3M.1 passes, the next step should be Phase 3M.2 minimal Hermes command probe.

Phase 3M.2 must first identify the installed Hermes command and supported syntax without assuming command names. It should remain read-only or single-request only until the maintainer explicitly approves any runtime mutation.

Do not expand this phase into routing, queues, concurrency, daemon management, load testing, or external API fallback.
