# Simulation and Deployment Policy

This repository is developed as a usage-layer companion for Hermes Agent official profiles.
It must not become a parallel Hermes runtime and must not modify the real Hermes home during design work.

## Current development rule

Do not sync or deploy profile templates into the real Hermes home until the maintainer explicitly approves deployment.

During repository design, documentation, and template refinement, the real paths remain untouched:

```text
~/.hermes/
~/.hermes/profiles/
```

The current expected local status is therefore:

```text
Hermes native root: present
Hermes native SOUL.md: present
Official OPC profiles: optional / not deployed yet
```

## Simulation rule

When file-level testing is needed before real deployment, simulate against a repository-local sandbox:

```text
~/workspace/hermes-agent-opc-deploy/simulate_env/.hermes/
```

The simulation directory may contain a minimal copied subset of the real Hermes layout, such as:

```text
simulate_env/.hermes/
  SOUL.md
  profiles/
    coordinator/
    researcher/
    writer/
    builder/
    runes-holder/
```

Simulation is for file-operation testing only. It is not a second Hermes runtime.

Do not copy secrets into the simulation directory.
Do not copy `.env`, tokens, API keys, state databases, sessions, logs, or cache files.

## Deployment script design

Future deployment scripts must support both states:

1. OPC profiles are not deployed yet.
2. OPC profiles already exist and may contain local changes.

Deployment scripts must be idempotent where practical and must avoid destructive overwrite by default.

Required behavior:

- Detect whether each target profile already exists.
- Prefer official Hermes Agent profile commands for profile initialization.
- Modify generated profile files only after the official initialization step.
- Never assume that a missing file can be safely invented unless the official command cannot create it and the maintainer approves the fallback.
- Back up or dry-run before changing existing profile files.
- Avoid touching `~/.hermes` unless the maintainer explicitly requests real deployment.

## Prefer official Hermes commands

When creating profiles, use the original Hermes Agent commands first, for example a future flow similar to:

```text
hermes profile create coordinator
hermes profile create researcher
hermes profile create writer
hermes profile create builder
hermes profile create runes-holder
```

The exact command syntax must be verified against the installed Hermes Agent version before writing the final deploy script.

The reason is simple: Hermes Agent may create additional files, metadata, directories, or state that this repository should not guess.

This repository may then apply small, explicit customizations to the files created by Hermes Agent, such as profile `SOUL.md` templates or notes.

## Non-goals

This repository must not:

- Reimplement Hermes Agent profile creation.
- Create a parallel `~/.hermes/opc/profiles/` runtime.
- Treat `simulate_env` as production state.
- Copy secrets or live session state into git.
- Force Hermes Agent one-agent mode or official profile mode to depend on this repository.
