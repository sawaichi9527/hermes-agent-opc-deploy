# Local runtime runbook

This runbook describes the current safe way to validate and use the maintainer's local Hermes Agent runtime baseline.

It is intentionally personal-use oriented and does not replace Hermes Agent.

## Safe baseline

Current validated runtime path:

```text
Hermes CLI
  -> provider alias: lmstudio
  -> local OpenAI-compatible /v1 backend
  -> qwen3.6-35b-a3b model
  -> response returned to CLI
```

Use the explicit provider/model pattern:

```bash
hermes -z "Reply with exactly: hermes-runtime-ok" \
  --provider lmstudio \
  --model qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m
```

## One-shot smoke

Use the repository helper for the default exact marker smoke:

```bash
cd ~/workspace/hermes-agent-opc-deploy
bash scripts/smoke-hermes-runtime-oneshot.sh
```

Expected result:

```text
PASS Hermes runtime oneshot smoke completed
```

## Secretary-like bounded prompt smoke

This checks behavior without claiming the request is profile-bound to `secretary`:

```bash
cd ~/workspace/hermes-agent-opc-deploy
bash scripts/smoke-hermes-runtime-oneshot.sh \
  --prompt "Summarize Phase 3L, 3M, and 3N in three short bullet lines. Do not edit files." \
  --non-empty
```

This should be treated as a generation smoke only.

## Sequential baseline check

Run the small runtime baseline check:

```bash
cd ~/workspace/hermes-agent-opc-deploy
bash scripts/check-runtime-baseline.sh
```

The bundle is sequential and personal-use only. It does not use parallel workers.

## Do not do by default

Do not run these unless explicitly approved:

```text
hermes profile use secretary
hermes profile alias secretary
```

Reason:

```text
hermes profile use secretary mutates sticky default profile state.
hermes profile alias secretary creates or manages local wrapper scripts.
```

Do not assume these commands exist:

```text
hermes run
hermes profiles
hermes --profile
hermes -p
```

They were not available or not proven in the validated Hermes Agent v0.16.0 runtime.

## Troubleshooting

If `--provider openai` fails, use `--provider lmstudio`.

The local backend may still be OpenAI-compatible at the HTTP protocol level, but the Hermes Agent CLI provider alias is `lmstudio` for this runtime.

If the exact marker smoke fails, first check:

```bash
hermes config show
hermes profile show secretary
bash scripts/check-hermes-runtime-readiness.sh
bash scripts/smoke-local-provider-sequential.sh --profile secretary
```

Do not print or commit real `.env` values.
