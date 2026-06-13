# Phase 4.13 sessions read-only probe preparation

This document prepares the Phase 4.13 bounded sessions read-only probe for the maintainer's personal Hermes Agent OPC deployment.

Phase 4.13 uses Hermes sessions only as a local evidence/reference primitive.

## Selected commands

```bash
hermes sessions list
hermes sessions stats
```

## Expected result

```text
Hermes lists recent sessions or reports that none are available.
Hermes prints session store statistics.
The commands complete locally.
No runtime mutation is expected.
```

## Current status

```text
Phase 4.13 Sessions Read-only Probe
PENDING / prepared / awaiting maintainer local verification
```

## Scope

This preparation does not add a script, resume a conversation, change profile state, create task state, or introduce custom orchestration.

Session mutation commands remain deferred unless explicitly approved by the maintainer.

## Manual verification command

Run from any shell where `hermes` is available:

```bash
hermes sessions list
hermes sessions stats
```

Then run the repository layout check from the repo root:

```bash
cd ~/workspace/hermes-agent-opc-deploy
bash scripts/verify-repo-layout.sh
git status --short
```

## Follow-up

After local verification, this document can be updated to a PASS lock with the observed bounded output summary.
