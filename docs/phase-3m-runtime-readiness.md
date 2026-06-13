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

## Phase 3M.2 verification lock

```text
Phase 3M.2 Minimal Hermes Command Probe
Status: PASS
Result: CLI help/version/profile syntax identified / unsupported commands ruled out
Boundary: command discovery only / no model request / no profile mutation / no daemon / no concurrency / no load test
```

Maintainer verification confirmed:

```text
hermes --help: PASS
hermes --version: PASS
hermes version: PASS
hermes profile --help: PASS
hermes profiles --help: invalid command, confirmed unsupported
hermes run --help: invalid command, confirmed unsupported
```

Observed Hermes runtime version:

```text
Hermes Agent v0.16.0 (2026.6.5)
upstream 7d183f64
Project: /home/eye/.hermes/hermes-agent
Python: 3.11.15
OpenAI SDK: 2.24.0
```

Relevant command syntax discovered:

```text
hermes --oneshot PROMPT
hermes -z PROMPT
hermes --model MODEL
hermes --provider PROVIDER
hermes chat
hermes chat -q "Hello"
hermes profile {list,use,create,delete,describe,show,alias,rename,export,import,install,update,info}
```

The singular `hermes profile` command is supported. The plural `hermes profiles` command is not supported. There is no `hermes run` command in this runtime. Future runtime probes must not assume either `hermes profiles` or `hermes run`.

## Phase 3M.3a provider alias discovery lock

```text
Phase 3M.3a Provider Alias Discovery
Status: PASS
Result: Hermes runtime provider alias identified as lmstudio; openai override confirmed unsupported
Boundary: command/config discovery only / no successful model request / no profile mutation / no daemon / no concurrency / no load test
```

Maintainer verification confirmed:

```text
hermes -z with --provider openai: BLOCKED / Unknown provider 'openai'
hermes model --help: PASS
hermes config --help: PASS
hermes config show: PASS
hermes profile show secretary: PASS
hermes profile list: PASS
```

Observed Hermes model configuration:

```text
provider: lmstudio
model.default: qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m
base_url: http://192.168.23.217:1234/v1
```

Observed secretary profile:

```text
profile: secretary
model: qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m
provider: lmstudio
.env: exists
SOUL.md: exists
```

The local API remains OpenAI-compatible at the HTTP protocol level, but the Hermes Agent runtime provider alias is `lmstudio`, not `openai`. Future Hermes runtime probes must use `--provider lmstudio` or the active Hermes profile/default configuration rather than `--provider openai`.

## Phase 3M.3b Hermes runtime request probe lock

```text
Phase 3M.3b Single-profile Hermes Runtime Request Probe
Status: PASS
Result: Hermes CLI oneshot reached lmstudio provider and returned exact marker
Boundary: one request / no daemon / no concurrency / no load test / no profile mutation / no external fallback
```

Maintainer verification ran:

```bash
hermes -z "Reply with exactly: hermes-runtime-ok" \
  --provider lmstudio \
  --model qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m
```

Observed result:

```text
hermes-runtime-ok
```

This proves the minimal Hermes CLI runtime path:

```text
Hermes CLI -> lmstudio provider alias -> local OpenAI-compatible /v1 backend -> configured local model -> response returned to CLI
```

The request used an explicit provider/model override and did not mutate the sticky default profile. It did not start a daemon, did not run concurrent requests, did not load test the backend, and did not use external fallback.

## Follow-up

Phase 3M is now locked for minimal Hermes runtime readiness purposes.

A later phase may validate profile-specific invocation behavior, such as whether `hermes profile use secretary` or another non-mutating profile invocation path is appropriate. Do not mutate the sticky default profile unless the maintainer explicitly approves it.

Do not expand this phase into routing, queues, concurrency, daemon management, load testing, throughput benchmarking, or external API fallback.