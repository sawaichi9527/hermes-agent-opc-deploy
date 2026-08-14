# M4 Minimal verification lock

This document locks the M4 minimal verification result for the Hermes-native OPC profile set reset.

## Purpose

M4 verifies only the repository mainline and profile template baseline after M1-M3.

It does not validate live Hermes runtime behavior and does not change real local profile state.

## Verified scope

```text
M1 Hermes-native OPC Scope Reset
M2 OPC profile set policy docs
M3 Six-profile SOUL.md template rewrite
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

## Confirmed boundaries

The verification did not include live runtime changes.

Not included in M4:

```text
real Hermes home changes
profile install or update
profile file overwrite
gateway start or restart
native memory maintenance
session maintenance
Kanban maintenance
Lark production cutover
simulation deploy
old Phase 3/4/5 full validation bundle
parallel multi-agent smoke
```

## Final lock

```text
M4 Minimal Verification
PASS / repo layout verified / profile templates verified / no runtime change / no profile change
```

## Next work

After this lock, the next stages are:

```text
M5 SOUL.md behavior tuning
M6 Pre-production profile maintenance planning
```

M6 requires explicit maintainer approval because it may touch native memory, sessions, Kanban state, or real profile runtime history.
