# M6 Pre-production profile maintenance plan

This document defines the pre-production maintenance procedure for the Hermes-native OPC profile set.

M6 is planning and read-only inspection first. It does not authorize real runtime cleanup by itself.

## Purpose

Before real long-term Lark-facing use, the maintainer should understand the current local Hermes runtime state and decide what to preserve, backup, clean, or defer.

This is needed because the repository has already locked the profile-template baseline, but the real `~/.hermes` runtime may still contain historical test sessions, native memory, Kanban/task state, caches, or old logs.

## Scope

```text
M6.1 Pre-production Runtime Inventory
M6.2 Backup Policy
M6.3 Cleanup Classification
M6.4 Dry-run Cleanup Plan
M6.5 Manual Apply Procedure
```

## Non-goals

M6 does not do the following by default:

```text
real ~/.hermes cleanup
real profile SOUL.md overwrite
profile install/update
native memory deletion
session deletion
Kanban deletion
gateway start/restart
Lark cutover
secret/token inspection
parallel multi-agent execution
```

## M6.1 Pre-production Runtime Inventory

Use the read-only inspector:

```bash
bash scripts/inspect-profile-runtime-state.sh
```

The inspector must only list metadata such as paths, file names, sizes, timestamps, and candidate classifications.

It must not:

```text
print .env contents
print token values
print database contents
print session contents
print native memory contents
print cache contents
modify files
move files
delete files
start or restart services
```

Inventory should cover these profile names when present:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Runtime root default:

```text
/home/eye/.hermes
```

The inspector may also be pointed at another root by setting:

```bash
HERMES_HOME=/path/to/hermes bash scripts/inspect-profile-runtime-state.sh
```

## M6.2 Backup Policy

Before any real cleanup, the maintainer must create a backup outside this repository.

Backup target must not be committed to git.

Backup should preserve at least:

```text
~/.hermes/profiles/<profile>/SOUL.md
~/.hermes/profiles/<profile>/NOTES.md
~/.hermes/profiles/<profile>/.env
~/.hermes/profiles/<profile>/config.yaml
profile identity / metadata
provider configuration
Lark token/config
runtime profile directories needed for rollback
```

Backup must not be copied into:

```text
this repository
Hermes Runes MD Wiki candidates
docs/
profiles/
archive/validation-history/
```

Do not paste secrets, `.env` values, runtime databases, session dumps, or private logs into GitHub issues, Markdown docs, prompt context, or Runes Wiki proposals.

## M6.3 Cleanup Classification

Classify runtime items into three groups.

### Preserve

Do not remove without a separate explicit deployment decision:

```text
.env
config.yaml
SOUL.md
NOTES.md
profile identity / metadata
provider/model configuration
Lark token/config
gateway configuration
profile distribution metadata
tool/skill configuration that is required for operation
```

### Cleanup candidate after backup

Can be considered for cleanup only after inventory review and backup:

```text
old sessions
old chat history
temporary caches
old logs
test-generated state
obsolete smoke-test output
Kanban/task state that the maintainer explicitly decides to reset
native memory that is confirmed to be test pollution
```

### Defer

Do not touch in M6 if unclear:

```text
unknown databases
unknown state directories
native memory with unclear value
profile-specific files not documented yet
any file whose deletion impact is unknown
anything containing secrets or private runtime data
```

## M6.4 Dry-run Cleanup Plan

The dry-run cleanup plan is a report, not an executable cleanup.

Recommended dry-run report shape:

```text
Profile:
Runtime root:
Preserve:
Cleanup candidates after backup:
Defer / unknown:
Potential risk:
Required approval before apply:
```

The dry-run report should be generated manually from the read-only inspector output and reviewed by the maintainer.

Do not add an automatic apply mode to the inspector.

## M6.5 Manual Apply Procedure

Manual apply is intentionally not implemented as a script in M6.

A real cleanup may happen only when all of the following are true:

```text
read-only inventory was reviewed
backup exists outside git
cleanup candidates were classified
maintainer explicitly approves the exact target list
commands are reviewed before execution
rollback path is known
```

For every real cleanup action, the maintainer should record:

```text
profile:
target path:
reason:
backup location:
approval note:
command used:
verification after cleanup:
rollback note:
```

If any item is uncertain, defer it.

## Recommended M6 verification

After adding or modifying M6 planning artifacts, run:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
bash -n scripts/inspect-profile-runtime-state.sh
git status --short
```

The runtime inspector may be run separately when the maintainer is ready:

```bash
bash scripts/inspect-profile-runtime-state.sh
```

## Final M6 planning rule

```text
M6 creates the safety procedure.
M6 does not clean the runtime by itself.
Real cleanup is a later explicit maintainer-approved action.
```
