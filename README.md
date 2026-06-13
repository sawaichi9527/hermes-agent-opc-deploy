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

## Development safety rule

Do not deploy templates into the real Hermes profile directory until the maintainer explicitly approves deployment.

During repository development, use documentation and templates first. When file-level testing is needed, use the repository-local simulation path:

```text
~/workspace/hermes-agent-opc-deploy/simulate_env/.hermes/
```

The real Hermes home remains untouched during design work:

```text
~/.hermes/
~/.hermes/profiles/
```

Future deployment scripts must support both states:

- OPC profiles are not deployed yet.
- OPC profiles already exist and may contain local changes.

Profile initialization should prefer official Hermes Agent commands first, then apply small customizations after the official files are created.

See: [`docs/simulation-and-deploy-policy.md`](docs/simulation-and-deploy-policy.md)

## Local checkout

Expected local path:

```text
~/workspace/hermes-agent-opc-deploy
```

After repository updates, validate locally with:

```bash
cd ~/workspace/hermes-agent-opc-deploy
git pull
./scripts/verify-layout.sh
git status --short
```

If the repository is not cloned yet:

```bash
mkdir -p ~/workspace
cd ~/workspace
git clone git@github.com:sawaichi9527/hermes-agent-opc-deploy.git
cd hermes-agent-opc-deploy
./scripts/verify-layout.sh
```

## Maintenance policy

Default update flow:

1. Update this GitHub repository directly when possible.
2. The user pulls the repository locally at `~/workspace/hermes-agent-opc-deploy` and validates.
3. Ask the user to run patch scripts only when GitHub connector limitations prevent direct edits.
4. For unusually large files, generate complete downloadable files, have the user save them to `~/Downloads`, and provide exact copy / commit / push commands.

Keep the repository personal-use oriented. Avoid enterprise-scale features that make the system harder to operate than Hermes Agent itself.

See: [`docs/maintenance-policy.md`](docs/maintenance-policy.md)

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
