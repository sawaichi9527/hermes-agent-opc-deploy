# M5 SOUL convention / profile tuning lock

This document locks the M5 SOUL convention and profile-template tuning result for the Hermes-native OPC profile set.

## Purpose

M5 verifies repository-side SOUL template convention work and profile-template tuning after the M1-M4 frozen baseline.

It does not validate live Hermes runtime behavior and does not change real local profile state.

## Verified scope

```text
M5.1 SOUL Template Convention
M5.2 secretary behavior tuning
M5.3 coordinator / researcher / writer / builder convention alignment
M5.4 runes-holder format-only alignment
```

## M5 deliverables

```text
docs/soul-template-convention.md
profiles/secretary/SOUL.md.template
profiles/coordinator/SOUL.md.template
profiles/researcher/SOUL.md.template
profiles/writer/SOUL.md.template
profiles/builder/SOUL.md.template
profiles/runes-holder/SOUL.md.template
```

## Verification commands

The maintainer ran the minimal repository checks from the repository root:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
git status --short
```

## Result

```text
verify-repo-layout.sh: PASS / repository layout is valid
verify-profile-templates.sh: PASS / profile templates satisfy baseline static checks
git status --short: clean working tree
```

## Confirmed M5 behavior changes

```text
SOUL Template Convention:
  Added repository-local Hermes OPC SOUL Template Convention v1.

secretary:
  Traditional Chinese-first main body.
  Neutral user naming policy.
  Intelligence secretary behavior.
  Context / compression policy for Lark-facing long conversations.
  Maintenance note M5-secretary-intelligence-v2 / 2026-06-14.

coordinator / researcher / writer / builder:
  Aligned with the SOUL convention.
  Added role-specific context / compression policies.
  Improved handoff clarity, source handling, source-aware writing, and bounded implementation behavior.

runes-holder:
  Format-only alignment with the SOUL convention.
  Semantic meaning intended to remain frozen.
  Hygiene adjustment only: removed hard-coded personal naming from the language-policy description.
```

## Confirmed boundaries

The verification did not include live runtime changes.

Not included in M5:

```text
real Hermes home changes
real profile SOUL.md overwrite
profile install or update
gateway start or restart
native memory maintenance
session maintenance
Kanban maintenance
Lark production cutover
simulation deploy
parallel multi-agent execution
```

## Final lock

```text
M5 SOUL Convention / Profile Tuning
PASS / convention added / secretary tuned / worker profiles aligned / runes-holder format-only aligned / no runtime change / no profile change
```

## Next work

After this lock, the next stage is:

```text
M6 Pre-production profile maintenance planning
```

M6 requires explicit maintainer approval before any real runtime maintenance action is executed.