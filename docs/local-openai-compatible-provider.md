# Phase 3L local OpenAI-compatible provider baseline

This document records the maintainer baseline for running Hermes Agent official profiles against a personal local LLM backend.

## Status

```text
Phase 3L.2 Local OpenAI-compatible Provider Baseline
Status: USER PATCHED / six real profiles updated / pending sequential smoke verification
```

The real profile files live outside this repository:

```text
~/.hermes/profiles/<profile>/.env
~/.hermes/profiles/<profile>/config.yaml
```

Those files may contain local endpoint configuration or secrets and must not be copied into git.

## Target profiles

The maintainer baseline contains six official Hermes profile folders:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Each profile should have its own local `.env` and `config.yaml` under `~/.hermes/profiles/<profile>/`.

## Provider baseline

Use the OpenAI-compatible provider path for LM Studio or llama.cpp server.

For LM Studio default local serving:

```env
OPENAI_API_BASE=http://127.0.0.1:1234/v1
OPENAI_API_KEY=lm-studio
```

For llama.cpp server default local serving:

```env
OPENAI_API_BASE=http://127.0.0.1:8080/v1
OPENAI_API_KEY=llama-cpp
```

For a LAN host, keep the `/v1` suffix:

```env
OPENAI_API_BASE=http://<host-or-ip>:1234/v1
OPENAI_API_KEY=lm-studio
```

Do not use `LM_API_KEY` or `LM_BASE_URL` as the baseline unless Hermes Agent provider discovery later proves that an `lm` or `lmstudio` provider consumes those variables directly.

## Config direction

Each profile `config.yaml` should use the OpenAI-compatible provider conceptually like this:

```yaml
model:
  provider: openai
  name: <model-id-returned-by-/v1/models>
```

The model name should match the id exposed by the local backend. Do not hard-code a guessed model id in repo documentation as a universal default.

## Local backend boundary

The local backend is treated as a personal-use LM Studio / llama.cpp server backend, not as a vLLM-style concurrent serving backend.

Validation rules:

```text
single request at a time
sequential profile checks only
no parallel profile probing
no xargs -P
no GNU parallel
no background-job fanout
no load test
no throughput benchmark
small delay between profile checks
```

The goal is to prove that the profile can reach the endpoint, not to test capacity.

## Recommended smoke

The repository provides a read-only helper:

```bash
./scripts/smoke-local-provider-sequential.sh
```

Default behavior:

- checks the six profile folders under `~/.hermes/profiles/`
- checks `.env` and `config.yaml` presence
- reads only `OPENAI_API_BASE` and `OPENAI_API_KEY` from `.env`
- confirms the base URL ends with `/v1`
- calls `/models` once per profile, sequentially
- waits between profiles
- does not trigger text generation

Optional chat smoke:

```bash
./scripts/smoke-local-provider-sequential.sh --chat
```

`--chat` sends one minimal chat completion per profile, sequentially. Use it only when LM Studio / llama.cpp is already loaded and idle.

For an endpoint-only check with a longer gap:

```bash
SMOKE_DELAY_SEC=5 ./scripts/smoke-local-provider-sequential.sh
```

For a single profile:

```bash
./scripts/smoke-local-provider-sequential.sh --profile builder
```

## Verification lock wording

Use this wording after successful local verification:

```text
Phase 3L.3 Local Provider Runtime Smoke
PASS / sequential / no-concurrency / local OpenAI-compatible endpoint verified
```

If endpoint-only smoke passes but `--chat` is not run yet:

```text
Phase 3L.3 Local Provider Endpoint Smoke
PASS / sequential / no-concurrency / /v1/models verified / chat smoke pending
```

## Non-goals

This phase does not introduce:

- a model router
- a queue
- concurrent serving
- vLLM assumptions
- load testing
- external API fallback
- duplicated profile sets for every provider
- committed local `.env` files

Keep this layer simple so Hermes Agent remains the runtime owner and does not carry an enterprise serving burden.
