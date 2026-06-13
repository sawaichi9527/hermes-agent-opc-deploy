# Phase 3L.5 local model name cleanup

This step removes the smoke-time fallback to the first `/v1/models` result by setting an explicit `model.name` in each real local Hermes profile config.

## Scope

This is local profile configuration cleanup only.

It must remain within the personal-use boundary:

```text
no model router
no queue
no concurrency
no load test
no external API fallback
no daemon
no enterprise serving layer
```

Real profile files live outside this repository:

```text
~/.hermes/profiles/<profile>/config.yaml
```

Those real files must not be committed to git.

## Current verified local model id

The Phase 3L.4 smoke used the first model id returned by the local OpenAI-compatible backend:

```text
qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m
```

Use this model id for the initial cleanup unless the local LM Studio / llama.cpp loaded model intentionally changes.

## Helper

Use the repo helper:

```bash
scripts/set-local-model-name.sh
```

Default mode is dry-run. It only reports what would change.

Example for one profile first:

```bash
PROFILE_LIST=secretary \
MODEL_NAME=qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m \
bash scripts/set-local-model-name.sh
```

Apply only after the dry-run looks correct:

```bash
PROFILE_LIST=secretary \
MODEL_NAME=qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m \
bash scripts/set-local-model-name.sh --apply
```

Then verify with a single-profile smoke:

```bash
PROFILE_LIST=secretary \
SMOKE_DELAY_SEC=5 \
bash scripts/smoke-local-provider-sequential.sh --chat
```

If secretary passes, apply to the six profile baseline:

```bash
MODEL_NAME=qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m \
bash scripts/set-local-model-name.sh --apply
```

Then run endpoint-only sequential smoke:

```bash
bash scripts/smoke-local-provider-sequential.sh
```

## Expected result

After cleanup, `smoke-local-provider-sequential.sh --chat` should no longer need to print this warning:

```text
model.name missing in config.yaml; using first /models id for chat smoke
```

The exact marker can remain a warning for reasoning-style Qwen models. Runtime validation is based on a successful single request and non-empty extracted text, not exact marker compliance.
