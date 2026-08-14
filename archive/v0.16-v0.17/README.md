# hermes-agent-opc-deploy

Hermes-native OPC profile set customization repository for the maintainer's personal Hermes Agent setup.

This repository does **not** define a new runtime, deployment framework, queue, router, daemon, dispatcher, or orchestration layer. Hermes Agent remains the runtime owner. This repository exists to curate a small set of `SOUL.md` / `NOTES.md` customizations and operating guidance around Hermes Agent's native profile capability.

## Current compatibility target

- Upstream project: `NousResearch/hermes-agent`
- Upstream version observed locally: `0.16.0`
- Local profile baseline: `secretary`, `coordinator`, `researcher`, `writer`, `builder`, `runes-holder`
- Local model baseline: LM Studio / llama.cpp serving `qwen3.6-35b-a3b` class models

## Correct project position

```text
Hermes Agent native profiles first.
OPC is a six-profile role set, not a parallel multi-agent swarm.
This repo customizes profile guidance; it does not replace Hermes Agent profile support.
```

The intended profile set is:

```text
secretary
  Lark-facing user interface, user-preference buffer, and OPC entrypoint.

coordinator
  Sequential task planner and one-profile-at-a-time router.

researcher
  Evidence comparison and factual verification worker.

writer
  Drafting, rewriting, report, and presentation worker.

builder
  Implementation, command, code, deployment, and verification worker.

runes-holder
  Hermes Runes MD Wiki access/governance specialist through runes shield.
```

## Runtime flow

```text
Lark bot
  -> profile/secretary
  -> profile/coordinator
  -> one selected worker profile at a time
  -> profile/secretary summarizes and replies to the user
```

Only `secretary` should be treated as the Lark-facing profile. Worker profiles should not run gateways by default.

## Local compute constraint

The local model backend is treated as a personal LM Studio / llama.cpp resource, not as a concurrent serving cluster.

```text
OPC policy:
- one active profile call at a time
- no parallel worker dispatch
- compact handoff packets
- avoid copying full transcripts across profiles
- summarize before long sessions force compression
```

The profile set may contain six roles, but role separation must not become concurrent model usage.

## Memory and Runes boundary

Hermes Agent native memory and Hermes Agent native Kanban are Hermes-native capabilities. They are not the same as the external `hermes-runes-md-wiki/wiki` governed Markdown knowledge layer.

```text
Hermes native memory
  profile-local continuity and assistant memory; each profile may use its own native memory.

Hermes native Kanban
  Hermes Agent task/workflow primitive; not equivalent to Runes Wiki.

Hermes Runes MD Wiki
  external governed Markdown source-of-truth; accessed through runes-holder and runes shield.
```

`runes-holder` is not the gatekeeper for other profiles' native memory. It may use its own native memory to learn `hermes-runes-md-wiki/wiki/_system/` guidance and runes shield procedures.

`runes-holder` may retrieve Runes Wiki derived context for other profiles, but it does not guarantee final truth. The requesting profile is responsible for validating data against appropriate sources such as Hermes native memory, Runes Wiki, third-party RAG, Obsidian notes, repository evidence, command output, official documentation, or web search.

Governed writes to `hermes-runes-md-wiki/wiki` require secretary-mediated user approval before `runes-holder` invokes runes shield.

## Profile language policy

```text
SOUL.md authoring:
- secretary: Traditional Chinese / English mixed; personal preference allowed.
- runes-holder: Traditional Chinese / English mixed; Runes governance context allowed.
- coordinator / researcher / writer / builder: English-first role definitions for precision.

Runtime inter-profile communication:
- Traditional Chinese first for handoff packets, summaries, user context, and next-action notes.
- Keep exact technical terms, commands, paths, filenames, API names, error messages, and source identifiers in their original language.
```

## Repository layout

Mainline content:

```text
README.md
docs/implementation-roadmap.md
docs/phase-6-hermes-native-profile-alignment.md
profiles/<profile>/SOUL.md.template
profiles/<profile>/NOTES.md
scripts/verify-repo-layout.sh
scripts/verify-profile-templates.sh
archive/validation-history/
```

Historical validation material from earlier simulation/runtime phases is being moved under `archive/validation-history/` and should not drive the main workflow anymore.

## Current implementation route

```text
M1 Hermes-native OPC Scope Reset
  Reframe the repository, archive old validation material, and simplify required checks.

M2 OPC profile set policy docs
  Add the focused design documents for profile flow, local compute, and runes-holder boundaries.

M3 Six-profile SOUL.md template rewrite
  Update all six profile templates with the corrected runtime, language, and Runes boundaries.

M4 Minimal verification
  Run only repository layout and profile template checks; no simulation-first workflow.

M5 SOUL.md behavior tuning
  Tune profile behavior after the mainline is clean.

M6 Pre-production profile cleanup
  Backup and selectively clear unneeded native memory/session history before real use.
```

## Minimal validation

After repository updates:

```bash
cd ~/workspace/hermes-agent-opc-deploy
git pull
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
git status --short
```

Optional Hermes-native profile existence check:

```bash
hermes profile show secretary
hermes profile show coordinator
hermes profile show researcher
hermes profile show writer
hermes profile show builder
hermes profile show runes-holder
```

Optional secretary gateway check, only when validating Lark-facing runtime behavior:

```bash
hermes -p secretary gateway status
```

## Safety rule

This repository must not contain real `.env` files, API keys, tokens, passwords, credentials, Hermes runtime session databases, profile cache/log dumps, copied Hermes Agent source code, or copied `hermes-runes-md-wiki` content.

Real profile mutation, profile cleanup, native memory reset, session reset, Kanban reset, and Lark cutover require explicit maintainer approval.
