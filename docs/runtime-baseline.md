# Local Hermes runtime baseline

This document consolidates the Phase 3L through Phase 3T local runtime baseline for the maintainer's personal Hermes Agent OPC deployment.

It intentionally stays small:

```text
personal-use local runtime
single request at a time
no daemon ownership
no router or queue
no concurrency or load testing
no external fallback
no sticky default profile mutation
no alias wrapper creation by default
```

## Phase 3O runtime baseline consolidation

Phase 3O consolidates the already-proven runtime facts instead of adding new runtime behavior.

Locked inputs:

```text
Phase 3L Local OpenAI-compatible Provider
PASS / six profiles configured / /models reachable / secretary chat smoke verified

Phase 3M Hermes Runtime Readiness
PASS / Hermes command discovered / lmstudio provider alias identified / hermes -z exact marker returned

Phase 3N Profile-specific Invocation Behavior
PASS / no built-in non-mutating --profile selector found / explicit provider-model override accepted
```

Current safe invocation baseline:

```bash
hermes -z "..." \
  --provider lmstudio \
  --model qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m
```

This is not claimed to be profile-bound to `secretary`. It is the safest currently proven non-mutating Hermes runtime invocation path.

## Phase 3P safe runtime smoke script

Phase 3P adds a small script wrapper around the already-proven command:

```text
scripts/smoke-hermes-runtime-oneshot.sh
```

Purpose:

```text
check that hermes exists
run exactly one hermes -z request
use explicit provider/model override
validate exact marker by default
avoid profile mutation
avoid daemon/process management
avoid concurrency and load testing
```

Default expected marker:

```text
hermes-runtime-ok
```

## Phase 3Q secretary-like operational prompt smoke

Phase 3Q allows the same script to run a bounded non-empty response check for a secretary-like prompt.

This remains a behavior smoke only:

```text
not profile-bound to secretary
no tool use required
no file write expected
no daemon
no concurrency
no external fallback
```

Recommended prompt shape:

```text
Summarize Phase 3L, 3M, and 3N in three short bullet lines. Do not edit files.
```

Use `--non-empty` for this mode because it validates bounded response generation, not exact instruction-following.

## Phase 3R local runtime runbook

Phase 3R documents routine usage in:

```text
docs/local-runtime-runbook.md
```

The runbook is the maintainer-facing reference for safe local use.

## Phase 3S runtime regression bundle

Phase 3S adds:

```text
scripts/check-runtime-baseline.sh
```

It runs checks sequentially only:

```text
repo layout
real Hermes runtime readiness preflight
local provider /models smoke
Hermes CLI oneshot smoke
```

It deliberately does not run the optional local provider `--chat` smoke by default because that would add additional model requests. Use the dedicated script when a generation smoke is needed.

## Phase 3T documentation lock

Phase 3T locks this baseline in documentation and makes the repository layout check track the new docs/scripts.

Tracked files:

```text
docs/runtime-baseline.md
docs/local-runtime-runbook.md
scripts/smoke-hermes-runtime-oneshot.sh
scripts/check-runtime-baseline.sh
```

Locked result:

```text
Phase 3O-3T Local Runtime Baseline
PASS / consolidated / documented / sequential smoke available / no enterprise complexity introduced
```

## Non-goals

Do not use this phase to introduce:

```text
multi-agent orchestration
queueing
routing middleware
parallel profile probing
load or throughput benchmarks
daemon ownership
external model fallback
profile alias wrapper creation
sticky default profile mutation
custom Hermes runtime replacement
```
