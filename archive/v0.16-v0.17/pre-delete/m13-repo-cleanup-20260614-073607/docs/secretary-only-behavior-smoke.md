# M9 Secretary-only behavior smoke without Lark cutover

This document defines the M9 local secretary behavior smoke for the Hermes-native OPC profile set.

M9 validates the updated real `secretary` profile after M8, but it must not start or restart the Lark gateway, cut over production traffic, mutate native memory, delete sessions, edit Kanban, or apply additional profile templates.

## Purpose

M8 applied the repository `profiles/secretary/SOUL.md.template` to the real runtime secretary profile and verified `Comparison: MATCH`.

M9 checks whether the updated `secretary` profile can be invoked locally and produce a basic safe response while preserving runtime boundaries.

## Scope

```text
M9.1 Secretary runtime preflight
M9.2 Secretary SOUL alignment check
M9.3 Gateway non-cutover check
M9.4 Optional local secretary prompt smoke
M9.5 Result capture guide
```

## Non-goals

M9 does not perform:

```text
gateway start/restart
Lark production cutover
coordinator/researcher/writer/builder/runes-holder apply
all-profile overwrite
native memory cleanup
session cleanup
Kanban cleanup
cache/log cleanup
Runes Wiki mutation
parallel multi-agent execution
long conversation evaluation
quality benchmark
```

## M9.1 Secretary runtime preflight

Required preflight checks:

```bash
hermes profile show secretary
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

Expected state:

```text
secretary profile exists
.env exists
SOUL.md exists
Gateway: stopped
PROFILE=secretary dry-run: Comparison: MATCH
```

## M9.2 Secretary SOUL alignment check

The local `secretary` runtime profile must remain aligned with the repository template before the behavior smoke runs.

Required check:

```bash
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

Expected result:

```text
Comparison: MATCH
```

If it is `DIFFERENT`, stop M9 and investigate before sending a prompt.

## M9.3 Gateway non-cutover check

M9 should keep the gateway stopped unless a later stage explicitly approves gateway activation.

M9 may read profile status:

```bash
hermes profile show secretary
```

M9 must not run:

```text
hermes -p secretary gateway start
hermes -p secretary gateway restart
any Lark production cutover command
```

## M9.4 Optional local secretary prompt smoke

Use the guarded smoke script.

Preflight / no prompt:

```bash
bash scripts/smoke-secretary-profile-local.sh
```

Real local secretary prompt smoke:

```bash
RUN_SECRETARY_SMOKE=1 bash scripts/smoke-secretary-profile-local.sh
```

The default prompt asks the secretary to return a short Traditional Chinese marker and avoid runtime mutation.

The smoke script validates:

```text
secretary profile show succeeds
secretary runtime SOUL.md matches repository template
secretary gateway is not started by the script
local secretary invocation returns non-empty output
```

The script does not persist the prompt or model output to repository files.

## M9.5 Result capture guide

When M9 is run, capture only the safe result summary.

Record:

```text
profile show result: PASS/FAIL
gateway state: stopped/other
SOUL alignment: MATCH/DIFFERENT
local secretary smoke: PASS/FAIL/SKIPPED
output non-empty: yes/no
runtime mutation performed: no
Lark cutover performed: no
```

Do not copy `.env`, token values, runtime databases, sessions, caches, full logs, or long model transcripts into repository docs, prompt context, GitHub issues, or Runes Wiki candidates.

## Required M9 repository verification

Before running real local secretary prompt smoke, verify repository artifacts:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
bash -n scripts/smoke-secretary-profile-local.sh
git status --short
```

## Final M9 safety rule

```text
Smoke secretary locally.
Keep gateway stopped.
Do not cut over Lark.
Do not mutate runtime state beyond the local prompt invocation.
Do not apply other profiles.
```
