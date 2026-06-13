# Phase 4 OPC loop design review

This document records Phase 4.1 through Phase 4.7 for the maintainer's personal Hermes Agent OPC deployment.

Phase 4 starts from the Phase 3 local runtime baseline and deliberately avoids building a separate orchestration system.

```text
personal-use only
manual / guided OPC loop
official Hermes primitives first
single request at a time by default
no custom daemon
no queue or router
no background scheduler
no parallel profile probing
no sticky default profile mutation by default
no alias wrapper creation by default
no external model fallback
```

## Phase 4.1 official Hermes primitive inventory

Purpose: inventory the official Hermes CLI primitives before designing any custom workflow.

Suggested read-only probes:

```bash
hermes kanban --help || true
hermes sessions --help || true
hermes logs --help || true
hermes memory --help || true
hermes prompt-size --help || true
hermes chat --help
```

Expected classification:

```text
chat / -z / --provider / --model: already validated runtime invocation path
sessions: candidate evidence/reference primitive
logs: candidate evidence/reference primitive
prompt-size: candidate preflight / bounded-context primitive
kanban: candidate task-state primitive, documentation-only until proven safe
memory: defer until a specific personal-use need is proven
profile: inspection only by default; mutation deferred
```

Phase 4.1 is discovery only. It must not create tasks, mutate profile state, start services, or run background processes.

## Phase 4.2 minimal OPC state model

Phase 4 uses a simple manual state model:

```text
observe -> plan -> check -> act -> record
```

State meaning:

```text
observe: capture the user's request and current runtime/repo state
plan: produce a small bounded plan using official Hermes runtime path
check: maintainer reviews the plan and approves one next action
act: execute one approved action manually or with an existing repo script
record: summarize result and update documentation only when useful
```

This is a working discipline, not a new state machine implementation.

Non-goals:

```text
no automated scheduler
no agent dispatcher
no queue state
no websocket bridge
no long-running controller
no automatic file mutation
```

## Phase 4.3 manual OPC runbook

The manual runbook is documented in:

```text
docs/opc-manual-runbook.md
```

The runbook explains how the maintainer should perform a small OPC loop using the already validated runtime invocation path and human review.

## Phase 4.4 single-task OPC dry-run policy

A Phase 4 dry-run should use one bounded task only.

Recommended dry-run task shape:

```text
Given docs/runtime-baseline.md, summarize the current runtime baseline status in three short bullets. Do not edit files.
```

Recommended invocation pattern:

```bash
hermes -z "Given docs/runtime-baseline.md, summarize the current runtime baseline status in three short bullets. Do not edit files." \
  --provider lmstudio \
  --model qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m
```

Success criteria:

```text
one request only
non-empty bounded answer
no file mutation
no profile mutation
no daemon
no queue
no router
```

This phase does not require a new script because Phase 3 already provides the safe runtime smoke helper.

## Phase 4.5 evidence / session capture policy

Evidence policy is documented in:

```text
docs/opc-evidence-policy.md
```

Default evidence stance:

```text
record summaries, decisions, and PASS/FAIL status
record command names and high-level outputs when useful
do not record real secrets
do not record full .env values
do not create telemetry infrastructure
do not retain unnecessary full prompts or full responses by default
```

## Phase 4.6 OPC safety boundary lock

Locked boundary:

```text
Phase 4 OPC loop is manual / guided.
It is not an autonomous daemon.
It is not a workflow engine.
It is not a multi-agent dispatcher.
It is not a background worker.
It is not a queue or router.
It is not an automatic writer.
```

Allowed by default:

```text
read-only help probes
manual runtime one-shot prompt
manual review before action
existing repo verification scripts
documentation updates for verified state
```

Deferred unless explicitly approved:

```text
hermes profile use secretary
hermes profile alias secretary
kanban task creation
memory mutation
custom automation helpers
long-running processes
```

## Phase 4.7 roadmap decision

Decision:

```text
Phase 4 remains a manual, official-primitive-first OPC loop baseline.
No custom orchestration is introduced.
No new runtime feature is added.
The next implementation work should be documentation, dry-run evidence, or maintainer-approved official primitive evaluation only.
```

Recommended result:

```text
Phase 4.1-4.7 OPC Loop Design Review
PASS / documented / manual-first / official-primitives-first / no enterprise complexity introduced
```

Future work may evaluate official Hermes Kanban or sessions only after a clear personal-use need is proven.
