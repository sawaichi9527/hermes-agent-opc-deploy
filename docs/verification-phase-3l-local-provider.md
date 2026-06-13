# Phase 3L local provider verification lock

This file records the maintainer verification result for the local OpenAI-compatible provider baseline.

## Scope

The local backend is LM Studio / llama.cpp server for personal use. It is not treated as a vLLM-style concurrent serving backend.

Validation boundaries:

```text
single request at a time
sequential checks only
no parallel profile probing
no background-job fanout
no load test
no throughput benchmark
```

## Phase 3L.3a endpoint smoke

```text
Phase 3L.3a /models Parser Compatibility Hardening
Status: PASS
Result: parser fixed / six profiles verified / model_count=8
Boundary: sequential / no-concurrency
```

Verified profiles:

```text
secretary     model_count=8
coordinator   model_count=8
researcher    model_count=8
writer        model_count=8
builder       model_count=8
runes-holder  model_count=8
```

## Phase 3L.4 single-profile chat smoke

```text
Phase 3L.4 Single-profile Chat Runtime Smoke
Status: PASS
Result: secretary only / one request / no-concurrency / non-empty chat response extracted
Instruction-following marker: warning only, not a runtime blocker
```

The runtime smoke used one selected profile and one chat request. The smoke helper extracted non-empty response text and therefore proved the local chat endpoint path. The exact marker did not match because the selected reasoning-style Qwen model returned thinking text; this is treated as an instruction-following signal, not an endpoint/runtime failure.

## Follow-up

Later cleanup should set explicit model names in the real local profile config files instead of relying on smoke-time fallback to the first model id returned by the backend.

This follow-up should remain local/profile configuration work and should not introduce model routing, queues, concurrency, load testing, or external API fallback.
