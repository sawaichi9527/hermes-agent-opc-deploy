# Phase 4 OPC loop design review

This document records Phase 4.1 through Phase 4.10 for the maintainer's personal Hermes Agent OPC deployment.

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

## Phase 4.8 OPC design verification lock

Phase 4.8 records the maintainer's local verification of the Phase 4.1-4.7 documentation baseline.

Locked result:

```text
Phase 4.8 OPC Design Verification Lock
PASS / local verification completed / documents present / repository layout still valid / no runtime functionality introduced
```

Maintainer verification confirmed:

```text
git pull: PASS / latest Phase 4 documentation commits pulled
docs/phase-4-opc-loop-design.md: PASS / exists and reviewed
docs/opc-manual-runbook.md: PASS / exists and reviewed
docs/opc-evidence-policy.md: PASS / exists and reviewed
manual file existence checks: PASS
repository layout: PASS
forbidden tracked runtime/secrets check: PASS
working tree: clean implied
```

Scope clarification:

```text
This lock confirms that Phase 4.1-4.7 is locally documented and repository-safe.
It does not add new scripts.
It does not run Hermes runtime requests.
It does not mutate profiles.
It does not create alias wrappers.
It does not create Kanban, sessions, memory, telemetry, queue, router, or daemon behavior.
```

## Phase 4.9 layout tracking cleanup

Phase 4.9 removes the remaining documentation tracking gap from Phase 4.8.

Locked result:

```text
Phase 4.9 Layout Tracking Cleanup
PASS / Phase 4 documents added to repository layout check / no runtime functionality introduced
```

Tracked Phase 4 documents:

```text
docs/phase-4-opc-loop-design.md
docs/opc-manual-runbook.md
docs/opc-evidence-policy.md
```

Scope clarification:

```text
This cleanup only extends the required documentation list in scripts/verify-repo-layout.sh.
It does not change the forbidden tracked runtime/secrets check.
It does not add a runtime script.
It does not run Hermes.
It does not mutate profiles.
It does not create alias wrappers, Kanban items, sessions, memory records, telemetry, queue, router, or daemon behavior.
```

Phase 4 now has both manual verification and repository layout tracking for its documentation baseline.

## Phase 4.10 official primitive help probe lock

Phase 4.10 records the maintainer's read-only help probe for official Hermes CLI primitives.

Commands verified:

```bash
hermes kanban --help || true
hermes sessions --help || true
hermes logs --help || true
hermes memory --help || true
hermes prompt-size --help || true
hermes chat --help
```

Locked result:

```text
Phase 4.10 Official Primitive Help Probe Lock
PASS / read-only CLI help inventory completed / official primitive syntax captured / no runtime mutation
```

Observed primitive classification:

```text
kanban: available, but includes task mutation and dispatcher/gateway-oriented commands; documentation-only by default
sessions: available for viewing/managing SQLite session store; read-only list/stats/browse are candidates, delete/prune/repair/rename deferred
logs: available for viewing/tailing/filtering logs; tail/follow is interactive and not part of default smoke
memory: available, but setup/off/reset mutate memory provider or built-in memory; status only is candidate read-only check
prompt-size: available and offline; good candidate bounded-context preflight
chat: available with -q, --provider, --model, --quiet, resume/continue/worktree options; Phase 3 accepted explicit provider/model one-shot remains the safe baseline
```

Important caution:

```text
Hermes kanban exposes swarm, dispatch, daemon/watch-style, task mutation, and garbage collection operations.
Hermes sessions exposes delete, prune, repair, rename, optimize, and export operations.
Hermes memory exposes setup, off, and reset operations.
These must not be used by default in the personal Phase 4 baseline.
```

Allowed follow-up without extra approval:

```text
help probes
prompt-size offline report
logs list or small bounded view
sessions list/stats if needed for evidence review
memory status if needed for configuration awareness
```

Deferred unless explicitly approved:

```text
kanban init/create/dispatch/daemon/watch/swarm/gc
sessions delete/prune/repair/rename/export
memory setup/off/reset
chat --worktree, resume/continue session workflows, or tool-enabled operational runs
```

Scope clarification:

```text
This phase only records CLI help output and classification.
It does not create tasks.
It does not start gateway, dispatcher, daemon, watch, or background behavior.
It does not mutate sessions, memory, profiles, files, or aliases.
It does not introduce a custom orchestrator.
```
