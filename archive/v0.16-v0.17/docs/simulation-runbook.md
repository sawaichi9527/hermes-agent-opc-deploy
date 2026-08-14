# Simulation runbook

This runbook freezes the repository-local simulation workflow for the maintainer OPC profile baseline.

It is intentionally limited to the repository-local simulation Hermes home:

```text
~/workspace/hermes-agent-opc-deploy/simulate_env/.hermes/
```

It must not deploy, modify, reset, or inspect the real Hermes runtime as a mutation target:

```text
~/.hermes/
~/.hermes/profiles/
```

The real Hermes home may be read by verification scripts only when the script is explicitly designed as a read-only check.

## Goal

Use this runbook to answer one question before real deployment is considered:

```text
Do the repository templates, validation scripts, simulation deploy scripts, and inspection scripts agree on the exact OPC profile files that would be deployed?
```

The expected answer for a healthy Phase 2 baseline is:

```text
PASS repository layout is valid
PASS profile templates satisfy baseline static checks
PASS simulation profile inspection completed with 0 warning(s)
PASS simulation layout is valid with deployed OPC profiles
BASE PASS real ~/.hermes exists, but real OPC profiles are not deployed yet
```

## Profile baseline

The maintainer OPC simulation baseline contains six official-profile target names:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Simulation deployment maps repository-maintained templates into simulated profile runtime files:

```text
profiles/<role>/SOUL.md.template
  -> simulate_env/.hermes/profiles/<role>/SOUL.md

profiles/<role>/NOTES.md
  -> simulate_env/.hermes/profiles/<role>/OPC_NOTES.md
```

Each simulated profile also receives:

```text
simulate_env/.hermes/profiles/<role>/DEPLOYED_FROM.txt
```

The manifest records the source repository, source template paths, and target simulated profile directory.

## Full Phase 2 verification flow

Run this from the local checkout:

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

The preferred final `git status --short` result is empty.

If a newly added script appears as modified only because its executable bit was set locally, commit the mode change:

```bash
git add scripts/<script-name>.sh
git commit -m "Make <script purpose> executable"
git push
```

## Script responsibilities

### `scripts/verify-repo-layout.sh`

Purpose:

- Check required documentation files.
- Check profile template directories and files.
- Check required scripts.
- Run shell syntax validation with `bash -n`.
- Check that runtime, secret, database, cache, log, and simulation files are not tracked by git.

Success signal:

```text
PASS repository layout is valid.
```

### `scripts/verify-profile-templates.sh`

Purpose:

- Check every `profiles/<role>/SOUL.md.template` exists and is non-empty.
- Check common sections such as role definition, boundaries, handoff/escalation/reporting, language policy, and memory/runes awareness.
- Check role-specific boundaries for secretary, coordinator, researcher, writer, builder, and runes-holder.
- Check that templates do not contain obvious real secret values or dangerous runtime mutation instructions.

Success signal:

```text
PASS profile templates satisfy baseline static checks.
```

### `scripts/prepare-sim-env.sh`

Purpose:

- Create `simulate_env/.hermes/`.
- Create `simulate_env/.hermes/profiles/`.
- Create a simulated root `SOUL.md` placeholder.
- Create a simulated Hermes-home README.
- Optionally reset simulation state only when explicit flags are used.

It must not clear or mutate real `~/.hermes/`.

### `scripts/deploy-sim-profiles.sh`

Purpose:

- Copy each profile `SOUL.md.template` into the simulated profile runtime path as `SOUL.md`.
- Copy each profile `NOTES.md` into the simulated profile runtime path as `OPC_NOTES.md`.
- Write `DEPLOYED_FROM.txt` manifests.
- Refuse to operate if the computed simulation path is unsafe.

Default behavior is conservative. Existing files are preserved when possible.

Use `--force` when templates changed and simulation should be refreshed:

```bash
./scripts/deploy-sim-profiles.sh --force
```

Use `--clean --force` only when the simulated profiles should be recreated from scratch:

```bash
./scripts/deploy-sim-profiles.sh --clean --force
```

These flags must remain simulation-only.

### `scripts/inspect-sim-profiles.sh`

Purpose:

- List deployed simulated profiles.
- Show the source template and deployed target for each profile.
- Compute template and deployed `SOUL.md` SHA-256 hashes.
- Confirm deployed `SOUL.md` matches the repository template.
- Confirm `OPC_NOTES.md` matches the repository `NOTES.md`.
- Display a short `DEPLOYED_FROM.txt` manifest preview.
- Confirm `simulate_env` is not tracked by git.

Use strict mode for Phase 2 baseline verification:

```bash
./scripts/inspect-sim-profiles.sh --strict
```

Success signal:

```text
PASS simulation profile inspection completed with 0 warning(s).
```

### `scripts/verify-sim-layout.sh`

Purpose:

- Check the simulated Hermes root layout.
- Check simulated root files.
- In normal mode, allow profiles to be missing before simulation deploy.
- In `--require-profiles` mode, require all maintainer OPC profiles and generated simulation files.
- Confirm `simulate_env` is not tracked by git.

Use after simulation profile deployment:

```bash
./scripts/verify-sim-layout.sh --require-profiles
```

Success signal:

```text
PASS simulation layout is valid with deployed OPC profiles.
```

### `scripts/verify-layout.sh`

Purpose:

- Read-only check against the real Hermes home.
- Confirm the real Hermes root and default `SOUL.md` exist.
- Report official profile layout as optional before maintainer OPC deployment.

Expected pre-deployment signal:

```text
Summary: BASE PASS - Hermes native root exists; maintainer OPC profiles are not fully deployed yet.
```

This is expected until the maintainer explicitly approves real deployment.

## When to use `--force`

Use `--force` after repository templates changed and the simulation deployment should be refreshed.

Typical case:

```text
profiles/<role>/SOUL.md.template changed
  -> run deploy-sim-profiles.sh --force
  -> run inspect-sim-profiles.sh --strict
```

Do not use `--force` as a real deploy habit. It is currently a simulation refresh mechanism.

## When to use `--strict`

Use `--strict` for simulation inspection when the expectation is zero drift:

```text
repo template SHA == simulated deployed SOUL.md SHA
repo NOTES.md == simulated OPC_NOTES.md
DEPLOYED_FROM.txt exists
```

Strict inspection should be part of the normal Phase 2 verification path.

## Safety guarantees for Phase 2

The Phase 2 simulation workflow must keep these guarantees:

1. No script writes to real `~/.hermes/`.
2. No script deploys to real `~/.hermes/profiles/`.
3. No script deletes real Hermes state, sessions, memory, Kanban, logs, caches, or profile data.
4. `simulate_env/` remains ignored and untracked by git.
5. Real profile deployment remains blocked until the maintainer explicitly approves it.

## PASS checklist

Before marking Phase 2 simulation as healthy, all of these should pass:

```text
[ ] verify-repo-layout.sh
[ ] verify-profile-templates.sh
[ ] prepare-sim-env.sh
[ ] deploy-sim-profiles.sh --force
[ ] inspect-sim-profiles.sh --strict
[ ] verify-sim-layout.sh --require-profiles
[ ] verify-layout.sh
[ ] git status --short is clean or only expected executable-bit changes remain
```

## Pre-real-deploy checklist

Do not start real deployment yet. Before Phase 6 can begin, the repository should have at least:

```text
[ ] profile deployment design document
[ ] read-only plan-deploy-profiles.sh
[ ] explicit backup policy for any real profile file change
[ ] explicit preserve-state default
[ ] explicit reset and clean-install flags
[ ] verified Hermes Agent profile command syntax for the installed upstream version
[ ] maintainer approval to touch ~/.hermes/profiles/
```

Until then, the correct real Hermes result remains:

```text
BASE PASS - Hermes native root exists; maintainer OPC profiles are not fully deployed yet.
```
