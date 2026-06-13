# OPC implementation roadmap

This document defines the implementation plan for the maintainer's Lark-first OPC deployment baseline.

The plan intentionally keeps the real Hermes home untouched until the maintainer explicitly approves deployment.

```text
real runtime path, not touched during design
  ~/.hermes/
  ~/.hermes/profiles/

simulation path, safe for repository development
  ~/workspace/hermes-agent-opc-deploy/simulate_env/.hermes/
```

## Baseline principles

1. Use Hermes Agent official profiles as the role container.
2. Do not create a parallel `~/.hermes/opc/profiles` runtime.
3. Prefer official Hermes commands for profile initialization, then apply small customizations.
4. Treat `secretary` as a standard maintainer baseline profile, not optional for the maintainer's Lark-first usage.
5. Keep `consult-*` as temporary external second-opinion subagents until repeated real use proves that official consult profiles are needed.
6. Evaluate Hermes official Kanban / delegation / persistent-goal primitives before adding custom workflow logic.
7. Keep `hermes-runes-md-wiki` optional and agent-agnostic.
8. Do not store real secrets, runtime session databases, or profile cache/log dumps in this repository.
9. Preserve real Hermes state by default; clean-install style reset must be explicit and backed up.

## Current target baseline profiles

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Expected high-level flow:

```text
User
  -> Lark bot adapter
  -> secretary
  -> coordinator
  -> researcher / writer / builder
  -> runes-holder, when sedimentation should be considered
```

External model escalation remains advisory:

```text
base local profile
  -> temporary consult subagent / external second opinion
  -> advisory result returned to coordinator or the requesting base profile
```

## Phase 0 - Freeze design boundaries

Status: mostly complete.

Goals:

- Record the distinction between Hermes Agent runtime, official profiles, project workspaces, and runes wiki.
- Record the secretary baseline decision.
- Record consult-subagent-first policy.
- Record simulation-first deployment safety.
- Record deploy reset / clean-install policy.
- Record OPC gap analysis versus the original OPC concept documents.
- Record the profile interaction loop problem and likely Hermes official primitives to evaluate.

Deliverables:

- `docs/architecture.md`
- `docs/secretary-profile.md`
- `docs/model-routing-policy.md`
- `docs/consult-subagent-upgrade-policy.md`
- `docs/simulation-and-deploy-policy.md`
- `docs/deploy-reset-policy.md`
- `docs/opc-gap-analysis.md`
- `docs/profile-interaction-loop.md`

Exit criteria:

- The baseline roles and non-goals are clear.
- No one should confuse Lark bot, secretary, coordinator, Hermes runtime, or runes wiki.
- Future reset behavior is explicit before any real deploy script exists.

## Phase 1 - Repository structure and static validation

Status: started.

Goals:

- Make the repository self-checking before any real deployment.
- Separate repository-layout validation from real Hermes-home validation.
- Add a simulation environment scaffold that can be created and reset safely.

Implemented scripts:

```text
scripts/verify-repo-layout.sh
scripts/prepare-sim-env.sh
scripts/verify-sim-layout.sh
```

Responsibilities:

- `verify-repo-layout.sh`
  - Check required docs, profile notes, script files, and template directories.
  - Check shell syntax for repository scripts.
  - Check that no forbidden runtime files are accidentally committed.

- `prepare-sim-env.sh`
  - Create `simulate_env/.hermes/`.
  - Create a placeholder simulated `SOUL.md` by default.
  - Optionally copy only safe non-secret baseline files from the real `~/.hermes` after explicit command-line flags.
  - Never copy `.env`, runtime DBs, caches, logs, sessions, or secrets by default.
  - Support simulation reset flags such as `--reset-history` and `--reset-all` against the simulation path only.

- `verify-sim-layout.sh`
  - Check simulated Hermes root and simulated profile directory root.
  - Verify expected profile names as optional until simulation deploy is implemented.
  - Confirm `simulate_env/*` is not tracked by git.

Recommended Phase 1 validation flow:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/prepare-sim-env.sh
bash scripts/verify-sim-layout.sh
./scripts/verify-layout.sh
git status --short
```

Exit criteria:

- Running repo checks does not require real profile deployment.
- Simulation can be prepared and verified repeatedly.
- `git status --short` stays clean after verification.

## Phase 2 - Profile template content

Goals:

- Draft maintainer baseline profile templates without deploying them.
- Keep templates role-pure and minimal.
- Avoid overfitting to one project.

Planned template areas:

```text
profiles/secretary/
profiles/coordinator/
profiles/researcher/
profiles/writer/
profiles/builder/
profiles/runes-holder/
```

Likely files per profile template:

```text
NOTES.md
SOUL.template.md
memory.seed.template.md
config-notes.md
```

Content rules:

- `secretary` may hold maintainer preference and intake style.
- `coordinator` should own routing, planning, merging, and boundary checks.
- `researcher` should own evidence, uncertainty, and verification.
- `writer` should own structure, tone transformation, and audience fit.
- `builder` should own implementation, debugging, testing, and delivery notes.
- `runes-holder` should own sedimentation advice, not direct uncontrolled memory writes.

Exit criteria:

- Each profile has a clear role contract.
- Cross-profile contamination risks are explicitly documented.
- Templates are deployable later but remain inert in this phase.

## Phase 3 - Official-profile initialization design

Goals:

- Design deployment around official Hermes profile commands.
- Avoid manually inventing missing profile files.
- Support both undeployed and already-deployed states.
- Support preserve-state and clean-install style deployment choices.

Planned docs/scripts:

```text
docs/profile-deployment-design.md
scripts/plan-deploy-profiles.sh
scripts/deploy-profiles.sh   # later, after maintainer approval only
```

Policy:

- `plan-deploy-profiles.sh` should be read-only and report what would happen.
- `deploy-profiles.sh` must not be introduced as an active mutating script until the maintainer explicitly says real deployment may begin.
- Any real deployment script should:
  - detect existing profiles;
  - avoid overwriting local modifications silently;
  - create backups or diffs before changes;
  - preserve existing Hermes state by default;
  - support explicit reset flags for clean-install style deployment;
  - prefer official Hermes profile creation commands first;
  - apply templates only after official initialization.

Exit criteria:

- There is a clear dry-run plan before any mutation.
- Existing profile safety rules are documented before implementation.
- Reset/clean-install behavior is backed up and opt-in.

## Phase 4 - Stateful OPC loop design

Goals:

- Evaluate Hermes Kanban, delegation, and persistent goals as official stateful primitives.
- Define how profiles report progress, block, hand off, and close tasks.
- Avoid building custom workflow logic before the official primitives are understood.

Planned docs:

```text
docs/kanban-opc-evaluation.md
docs/task-lifecycle-policy.md
docs/handoff-format.md
docs/blocking-and-escalation-policy.md
```

Questions to answer:

- Who creates a task?
- When does secretary pass a request to coordinator?
- When does coordinator create/assign Kanban tasks?
- How often should a role heartbeat?
- What does `blocked` mean?
- Who can unblock a task?
- When does coordinator ask the user for clarification?
- When does consult-subagent second opinion run?
- When is runes-holder asked to consider sedimentation?

Exit criteria:

- The office-loop is no longer just stateless role prompting.
- There is a durable task lifecycle plan.
- Blocking and handoff are explicit.

## Phase 5 - Simulation trial

Goals:

- Exercise profile templates and task lifecycle against `simulate_env/.hermes/` only.
- Validate expected file operations before touching real `~/.hermes`.

Planned checks:

```text
prepare sim env
verify sim layout
simulate profile creation output
simulate template overlay
simulate existing-profile conflict
simulate dry-run deploy report
```

Exit criteria:

- The simulation flow is repeatable.
- No operation requires real profile mutation.
- Safety checks detect missing, existing, and conflicting profile states.

## Phase 6 - Maintainer-approved real deployment

This phase must not start until the maintainer explicitly approves real deployment.

Goals:

- Initialize official Hermes profiles through official Hermes commands.
- Apply profile templates carefully.
- Verify real profile layout.
- Keep backups or diffs for any modified files.
- Let the maintainer choose whether to preserve or reset existing Hermes history/memory state.

Planned command flow, subject to future verification:

```text
hermes profile create secretary
hermes profile create coordinator
hermes profile create researcher
hermes profile create writer
hermes profile create builder
hermes profile create runes-holder
```

The exact command syntax must be re-verified against the installed Hermes Agent version before use.

Exit criteria:

- Real `~/.hermes/profiles/<name>/` directories exist.
- Each expected `SOUL.md` exists.
- Role templates are applied only where safe.
- `verify-layout.sh` reports deployed baseline state.

## Phase 7 - Trial operation and tuning

Goals:

- Use the OPC baseline in real Lark-first operations.
- Record which assumptions work and which fail.
- Tune templates and routing policy based on actual use.

Observation targets:

- Secretary intake quality.
- Coordinator routing quality.
- Researcher evidence discipline.
- Writer structure quality.
- Builder implementation quality.
- Runes-holder sedimentation usefulness.
- Frequency of consult-subagent second opinions.
- Need, or lack of need, for permanent consult profiles.
- Kanban/task-loop usefulness.

Exit criteria:

- The first real baseline is usable without creating more burden than it removes.
- Any next customizations are based on observed friction, not hypothetical complexity.

## Immediate next tasks

Recommended implementation order:

1. Run Phase 1 validation locally.
2. Fix any shell or layout issues found by the new scripts.
3. Expand profile template directories with inert template files.
4. Add `docs/profile-deployment-design.md`.
5. Add Kanban/office-loop evaluation docs.

Do not start real profile deployment yet.
