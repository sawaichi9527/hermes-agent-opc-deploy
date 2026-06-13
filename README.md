# hermes-agent-opc-deploy

Private deployment companion for using **Hermes Agent official profiles** as an OPC-style role workflow.

This repository is **not** a fork of Hermes Agent and does **not** define a new runtime. It records deployment notes, profile templates, small usage-layer customizations, and migration guidance for a specific upstream Hermes Agent version.

## Current compatibility target

- Upstream project: `NousResearch/hermes-agent`
- Upstream version observed from `pyproject.toml`: `0.16.0`
- Local validation status: `pending`

Tags in this repository should follow upstream compatibility naming, for example:

```text
compat-hermes-v0.16.0
```

The tag means: "this deployment baseline is intended for Hermes Agent v0.16.0". It is not an independent product release version.

## Design position

Hermes Agent remains the runtime owner.

```text
~/.hermes/
  Hermes native runtime, native memory, default one-agent profile

~/.hermes/profiles/<profile>/
  Official Hermes profile state, memory, SOUL.md, skills, sessions, config

~/workspace/<project>/
  Actual project working tree: code, docs, tests, project artifacts

~/workspace/hermes-runes-md-wiki/wiki/<slug>/
  Optional durable Markdown knowledge sedimentation layer
```

OPC is treated as a **usage pattern** over official Hermes profiles:

- `coordinator`
- `researcher`
- `writer`
- `builder`
- `runes-holder`

`hermes-runes-md-wiki` is optional. If it is absent or not called by `runes-holder`, Hermes Agent one-agent or multi-profile operation must continue normally.

## Repository scope

This repository may contain:

- profile `SOUL.md` templates
- profile memory templates
- deployment notes for the current Hermes version
- migration checklists
- project rule templates such as `HERMES.md`
- small helper scripts that do not replace Hermes Agent

This repository must not contain:

- real `.env` files
- API keys, tokens, passwords, or credentials
- Hermes runtime session databases
- profile cache/log dumps
- large project artifacts
- copied Hermes Agent source code
- `hermes-runes-md-wiki` content itself

## First baseline

Start from the official Hermes profile mechanism. Do not introduce a parallel `~/.hermes/opc/profiles` runtime.

Use this repository as the deployment memory for how to create, configure, and migrate official Hermes profiles for OPC-style work.
