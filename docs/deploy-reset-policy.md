# Deploy reset policy

This document records how future OPC deployment scripts should handle existing Hermes Agent state.

The policy applies to both the repository-local simulation environment and, later, the real Hermes home after the maintainer explicitly approves deployment.

```text
real Hermes home, do not mutate during design
  ~/.hermes/

simulation Hermes home, safe for development
  ~/workspace/hermes-agent-opc-deploy/simulate_env/.hermes/
```

## Current stance

Real deployment is not active yet.

During current repository development:

1. Scripts may create and reset `simulate_env/.hermes/`.
2. Scripts must not mutate real `~/.hermes/`.
3. Scripts may inspect real `~/.hermes/` only when explicitly requested and only for safe read-only checks.
4. Scripts must not copy `.env`, secrets, runtime SQLite databases, logs, caches, sessions, or profile runtime state into the repository.

## Hermes persistence files to treat carefully

Hermes Agent uses local persistence files under the Hermes home. Future deploy/reset scripts must treat at least these artifacts as runtime state:

```text
state.db
state.db-wal
state.db-shm
kanban.db
kanban.db-wal
kanban.db-shm
memory_store.db
memory_store.db-wal
memory_store.db-shm
sessions/
logs/
cache/
state/
```

The exact list should be re-verified against the installed Hermes Agent version before real deployment.

## Default behavior for real deployment

Future real deployment should preserve existing Hermes state unless the maintainer explicitly asks for a clean install style reset.

Default behavior:

```text
preserve existing state.db
preserve existing kanban.db
preserve existing memory_store.db
preserve sessions/logs/cache unless an explicit reset flag is passed
create missing official profiles through official Hermes commands
apply OPC customizations only after official profile initialization
never silently overwrite profile-local files
```

This is the safest behavior for a non-empty Hermes installation.

## Clean install style deployment

The maintainer may want OPC deployment to behave like a clean Hermes install, especially when validating the first baseline.

Future real deploy scripts should support an explicit clean mode, for example:

```bash
./scripts/deploy-profiles.sh --clean-install
```

A clean install style deployment must:

1. Require an explicit flag.
2. Print the exact files/directories that would be reset.
3. Create a backup before moving/removing anything.
4. Avoid direct deletion when a timestamped backup can be used.
5. Keep `--reset-memory` separate from normal conversation/session reset unless the user explicitly asks for it.

Recommended backup path:

```text
~/.hermes/backups/opc-pre-reset-YYYYMMDD-HHMMSS/
```

## Reset flag semantics

Future scripts should keep reset scopes explicit.

```text
--reset-sessions
  reset session/message history artifacts such as state.db and session-related sidecars

--reset-kanban
  reset Kanban board state such as kanban.db and sidecars

--reset-memory
  reset long-term memory/fact-store artifacts such as memory_store.db and sidecars

--reset-history
  reset conversation/session history and Kanban work state;
  this should not automatically reset long-term memory unless the maintainer confirms that policy later

--reset-all
  reset sessions, Kanban, and memory artifacts

--clean-install
  clean OPC deployment mode;
  equivalent to a carefully backed-up reset followed by official profile initialization and OPC overlay
```

## Simulation reset behavior

Simulation scripts may implement these flags earlier than real deploy scripts, but only against:

```text
simulate_env/.hermes/
```

Simulation reset should be repeatable and safe:

```text
prepare-sim-env.sh
prepare-sim-env.sh --reset-history
prepare-sim-env.sh --reset-all
verify-sim-layout.sh
```

Simulation reset may remove or move files under `simulate_env/`, but must never touch real `~/.hermes/`.

## Official command first principle

When real deployment is eventually approved, profile creation should prefer official Hermes Agent commands first.

Conceptual future flow:

```text
1. backup or preserve existing state according to reset flags
2. run official Hermes profile create command for missing profiles
3. inspect generated official profile files
4. apply OPC template overlay only where safe
5. verify resulting layout
```

Do not manually invent profile runtime layout when an official Hermes command can initialize it.

## Non-goals for current phase

Current Phase 1 scripts must not:

```text
mutate ~/.hermes/
create real ~/.hermes/profiles/*
clear real Hermes history
clear real Hermes memory
copy real secrets into this repository
commit simulation runtime files
```

Real deployment belongs to a later maintainer-approved phase.
