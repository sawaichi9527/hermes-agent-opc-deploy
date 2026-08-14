# M6 pre-production maintenance planning lock

This document locks the M6 pre-production profile maintenance planning result for the Hermes-native OPC profile set.

M6 is a planning, classification, and read-only inspection stage. It does not authorize real runtime cleanup by itself.

## Purpose

M6 verifies that the repository now contains a safe pre-production maintenance procedure before any real long-term Lark-facing profile deployment or runtime cleanup.

It records the result of the maintainer-run repository checks and the read-only Hermes runtime inventory.

## Verified scope

```text
M6.1 Pre-production Runtime Inventory
M6.2 Backup Policy
M6.3 Cleanup Classification
M6.4 Dry-run Cleanup Plan
M6.5 Manual Apply Procedure
M6.6 Maintenance Planning Verification Lock
```

## M6 deliverables

```text
docs/pre-production-profile-maintenance.md
docs/pre-production-cleanup-dry-run.md
scripts/inspect-profile-runtime-state.sh
docs/verification-m6-maintenance-planning.md
```

## Verification commands

The maintainer ran these checks from the repository root:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
bash -n scripts/inspect-profile-runtime-state.sh
git status --short
```

The maintainer also ran the read-only runtime inventory:

```bash
bash scripts/inspect-profile-runtime-state.sh
```

## Result

```text
verify-repo-layout.sh: PASS / repository layout is valid
verify-profile-templates.sh: PASS / profile templates satisfy baseline static checks
inspect-profile-runtime-state.sh syntax: PASS
inspect-profile-runtime-state.sh runtime inventory: PASS / read-only metadata inventory completed
git status --short: clean working tree
```

## Confirmed repository-side M6 behavior

```text
pre-production-profile-maintenance.md:
  Documents inventory, backup, classification, dry-run, and manual-apply procedure.

pre-production-cleanup-dry-run.md:
  Provides a dry-run report template only.
  Does not approve or generate cleanup commands.

inspect-profile-runtime-state.sh:
  Lists metadata only.
  Does not print file contents.
  Does not print .env values, token values, session contents, memory contents, database contents, or cache contents.
  Does not move, delete, edit, start, stop, or restart anything.
```

## Confirmed read-only runtime inventory result

The read-only inspector found the expected OPC profile directories under the local Hermes runtime root:

```text
/home/eye/.hermes/profiles/secretary
/home/eye/.hermes/profiles/coordinator
/home/eye/.hermes/profiles/researcher
/home/eye/.hermes/profiles/writer
/home/eye/.hermes/profiles/builder
/home/eye/.hermes/profiles/runes-holder
```

For all six profiles, the inspector found these core files present:

```text
SOUL.md
NOTES.md
.env
config.yaml
profile.yaml
```

For all six profiles, the inspector classified identity/config files as preserve candidates:

```text
SOUL.md
NOTES.md
.env
config.yaml
profile.yaml
```

For all six profiles, the inspector classified the following kinds of runtime/history paths as review-only cleanup candidates after backup:

```text
audio_cache
image_cache
logs
sessions
```

The inspector also reported global runtime metadata for these existing areas:

```text
/home/eye/.hermes/sessions
/home/eye/.hermes/logs
/home/eye/.hermes/cache
/home/eye/.hermes/skills
```

The inspector reported these global paths missing at inspection time:

```text
/home/eye/.hermes/state
/home/eye/.hermes/kanban
/home/eye/.hermes/memory
/home/eye/.hermes/gateways
/home/eye/.hermes/tools
```

## Confirmed boundaries

The M6 verification did not execute real cleanup.

Not included in M6:

```text
real ~/.hermes cleanup
real profile SOUL.md overwrite
profile install/update
gateway start/restart
native memory deletion
session deletion
Kanban deletion
Lark production cutover
automatic cleanup apply script
parallel multi-agent execution
```

The inspector output listed paths and metadata only. It did not print secret values or private runtime file contents.

## Manual apply requirement

A future real cleanup still requires a separate maintainer-approved apply step.

Required before any apply:

```text
read-only inventory reviewed
backup exists outside git
exact target list prepared
maintainer explicitly approves the exact target list
commands are reviewed before execution
rollback path is known
```

Unclear items must remain deferred.

## Final lock

```text
M6 Pre-production Profile Maintenance Planning
PASS / read-only inventory verified / cleanup policy documented / dry-run plan documented / no runtime cleanup executed
```

## Next work

After this lock, the next stage is:

```text
M7 Pre-production profile deployment decision / backup / manual apply planning
```

M7 requires explicit maintainer approval before any real profile overwrite, runtime cleanup, gateway action, native memory/session/Kanban maintenance, or Lark cutover is executed.
