# Phase 6 Hermes-native profile alignment

This document records the scope correction after Phase 5.

The core goal of `hermes-agent-opc-deploy` is to align with Hermes Agent's native profile-agent capability first.

This repository should remain a small customization and validation layer for the maintainer's personal Hermes Agent profile setup.

## Corrected project purpose

```text
Hermes-native profile agents first.
Small customization only where useful.
SOUL.md and profile guidance optimization are the primary customization surface.
Repository checks and simulation remain safety/regression evidence, not the day-to-day usage path.
```

## What this repository is

```text
A profile guidance and template repository.
A place to curate maintainer-specific OPC profile behavior.
A safety check layer for profile templates.
A simulation/regression aid before optional real profile changes.
```

## What this repository is not

```text
Not a replacement for Hermes Agent profile support.
Not a standalone agent runtime.
Not an orchestration framework.
Not a queue, router, daemon, dispatcher, or background scheduler.
Not the default daily workflow for using Hermes Agent.
```

## Native-alignment rule

Future work should prefer Hermes Agent's own profile commands and profile semantics whenever possible.

Custom code or scripts should only be added when there is a proven gap that is not already covered by Hermes-native behavior.

## Customization boundary

Allowed by default:

```text
SOUL.md profile role guidance improvements
profile notes and documentation cleanup
small static validation checks
simulation-only regression checks
Hermes-native profile command documentation
```

Requires explicit maintainer approval:

```text
real ~/.hermes profile writes
profile use or alias changes
custom deployment workflows
Kanban task workflows
external memory activation
background services or schedulers
```

## Status of earlier phases

```text
Phase 3: PASS / local Hermes runtime baseline
Phase 4: PASS / official read-only primitive baseline
Phase 5: PASS / simulation-only profile deployment trial
```

These phases remain useful as safety evidence, but they should not expand into a separate deployment platform.

## Phase 6.0 lock

```text
Phase 6.0 Hermes-native Profile Alignment
PASS / scope corrected / Hermes-native profile agents first / custom deployment framework expansion stopped
```

## Practical next step

The next implementation step should verify Hermes-native profile targeting and profile distribution behavior before any real profile write.

Recommended next phase:

```text
Phase 6.1 Hermes-native Profile Command Verification
```

Candidate read-only or low-risk probes:

```bash
hermes profile --help
hermes profile show secretary
hermes profile install --help
hermes chat -p secretary -q "Reply exactly: secretary-ok"
```

The final command may send a model request, so it should only be run when the maintainer wants to validate native profile behavior.
