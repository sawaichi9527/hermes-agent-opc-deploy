# Phase 4.12 logs read-only probe preparation

This document prepares the Phase 4.12 bounded logs read-only probe for the maintainer's personal Hermes Agent OPC deployment.

Phase 4.12 follows the Phase 4 official-primitive-first rule. It uses Hermes logs only as a bounded evidence/reference primitive.

## Selected commands

```bash
hermes logs list
hermes logs -n 20
```

## Expected result

```text
Hermes lists available log files.
Hermes prints a small bounded view of the default agent log.
The command completes locally.
No follow/tail mode is used.
No runtime mutation is expected.
```

## Current status

```text
Phase 4.12 Bounded Logs Read-only Probe
PENDING / prepared / awaiting maintainer local verification
```

## Scope

This preparation does not add a script, start follow mode, create telemetry, mutate profiles, create task state, or introduce custom orchestration.

## Manual verification command

Run from any shell where `hermes` is available:

```bash
hermes logs list
hermes logs -n 20
```

Then run the repository layout check from the repo root:

```bash
cd ~/workspace/hermes-agent-opc-deploy
bash scripts/verify-repo-layout.sh
git status --short
```

## Follow-up

After local verification, this document can be updated to a PASS lock with the observed bounded output summary.
