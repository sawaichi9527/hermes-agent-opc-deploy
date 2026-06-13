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

OPC is treated as a **usage pattern** over official Hermes profiles.

For the maintainer's Lark-first OPC usage, the standard baseline profile set is:

- `secretary`
- `coordinator`
- `researcher`
- `writer`
- `builder`
- `runes-holder`

For other users or forks, `secretary` may be treated as an optional extension. For this repository's own deployment target, `secretary` is standard because it protects worker profile purity when Lark becomes the main operating interface.

`secretary` is a user-facing intake and preference-adapter profile. It is not the Lark bot itself and does not replace `coordinator`. See: [`docs/secretary-profile.md`](docs/secretary-profile.md)

Profile language policy is single-template and no locale auto-switch by default:

```text
secretary
  Traditional Chinese first

coordinator / researcher / writer / builder / runes-holder
  English-first canonical role instructions
  user-facing language follows channel/task policy
```

See: [`docs/profile-language-policy.md`](docs/profile-language-policy.md)

`hermes-runes-md-wiki` is optional. If it is absent or not called by `runes-holder`, Hermes Agent one-agent or multi-profile operation must continue normally.

## Implementation roadmap

The current implementation plan is tracked in:

- [`docs/implementation-roadmap.md`](docs/implementation-roadmap.md)

Immediate next implementation tasks:

```text
1. Add repository layout verification.       DONE
2. Add simulation environment preparation.  DONE
3. Add simulation layout verification.      DONE
4. Expand inert profile templates.          DONE
5. Add simulation deploy / inspect tooling. DONE
6. Freeze simulation operator runbook.      DONE
7. Design dry-run real profile plan.
8. Evaluate Kanban / delegation / goals for stateful OPC office-loop behavior.
```

Current Phase 1/2 commands:

```bash
./scripts/verify-repo-layout.sh
./scripts/verify-profile-templates.sh
./scripts/prepare-sim-env.sh
./scripts/deploy-sim-profiles.sh --force
./scripts/inspect-sim-profiles.sh --strict
./scripts/verify-sim-layout.sh --require-profiles
./scripts/verify-layout.sh
```

For the frozen simulation operator procedure, see:

- [`docs/simulation-runbook.md`](docs/simulation-runbook.md)

Real deployment into `~/.hermes/profiles/` is intentionally out of scope until the maintainer explicitly approves it.

## OPC gap tracking

This repository now explicitly tracks the gap between:

```text
original OPC concept documents
vs.
current Hermes official profiles + personal-use deployment baseline
```

See:

- [`docs/opc-gap-analysis.md`](docs/opc-gap-analysis.md)
- [`docs/profile-interaction-loop.md`](docs/profile-interaction-loop.md)

Current working assumption:

```text
profiles alone provide role separation;
Kanban/delegation/goals may provide the stateful office-loop primitives;
this repo should evaluate official Hermes primitives before adding custom workflow logic.
```

## Model routing position

The current inference baseline is local-first:

```text
LAN LM Studio -> Qwen3.6-35B-A3B -> Hermes Agent official profiles
```

Future external model APIs should be treated as optional consultation capability, not as a reason to duplicate every base profile.

The default future path is **consult subagent first, official consult profile later only if proven necessary**:

```text
normal work
  -> local official profiles
  -> local LM Studio / Qwen3.6-35B-A3B

rare escalation
  -> temporary consult subagent / external model second opinion
  -> advisory result returned to the base profile or coordinator

only after repeated real use
  -> consider official consult-researcher / consult-writer / consult-builder profiles
```

Avoid `senior-*` naming for this use case because it implies hierarchy. If a permanent advisory role is eventually needed, prefer `consult-*`.

See:

- [`docs/model-routing-policy.md`](docs/model-routing-policy.md)
- [`docs/consult-subagent-upgrade-policy.md`](docs/consult-subagent-upgrade-policy.md)

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

See:

- [`docs/simulation-and-deploy-policy.md`](docs/simulation-and-deploy-policy.md)
- [`docs/deploy-reset-policy.md`](docs/deploy-reset-policy.md)

## Reset and clean-install policy

Future real deploy scripts must preserve existing Hermes state by default, unless the maintainer explicitly selects a clean-install style reset.

The reset policy separates:

```text
--reset-sessions
--reset-kanban
--reset-memory
--reset-history
--reset-all
--clean-install
```

Current Phase 1/2 scripts only implement these ideas against the simulation path:

```text
simulate_env/.hermes/
```

They must not clear real `~/.hermes/` history, memory, Kanban, sessions, or profile files.

## Local checkout

Expected local path:

```text
~/workspace/hermes-agent-opc-deploy
```

After repository updates, validate locally with:

```bash
cd ~/workspace/hermes-agent-opc-deploy
git pull
./scripts/verify-repo-layout.sh
./scripts/verify-profile-templates.sh
./scripts/prepare-sim-env.sh
./scripts/deploy-sim-profiles.sh --force
./scripts/inspect-sim-profiles.sh --strict
./scripts/verify-sim-layout.sh --require-profiles
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
