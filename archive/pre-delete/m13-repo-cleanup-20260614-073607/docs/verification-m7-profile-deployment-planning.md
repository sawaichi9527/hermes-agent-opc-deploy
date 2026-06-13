# M7 profile deployment planning lock

This document locks the M7 pre-production profile deployment decision planning result for the Hermes-native OPC profile set.

M7 is a decision, backup, dry-run diff, and manual-apply planning stage. It does not authorize real profile overwrite by itself.

## Purpose

M7 verifies that the repository now contains a safe decision path for applying repository `SOUL.md.template` files to real Hermes runtime profile `SOUL.md` files.

It also records the maintainer-run dry-run result showing that all six real runtime profile `SOUL.md` files are currently different from the repository templates.

## Verified scope

```text
M7.1 Deployment decision matrix
M7.2 Backup requirement
M7.3 Template-vs-runtime dry-run diff
M7.4 Manual apply plan
M7.5 Post-apply verification plan
M7.6 Deployment dry-run result lock
```

## M7 deliverables

```text
docs/pre-production-profile-deployment.md
docs/profile-deployment-dry-run.md
scripts/dry-run-profile-deployment.sh
docs/verification-m7-profile-deployment-planning.md
```

## Verification commands

The maintainer ran these repository checks from the repository root:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
bash -n scripts/dry-run-profile-deployment.sh
git status --short
```

The maintainer also ran read-only deployment dry-run commands:

```bash
bash scripts/dry-run-profile-deployment.sh
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
SHOW_DIFF=1 PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

## Result

```text
verify-repo-layout.sh: PASS / repository layout is valid
verify-profile-templates.sh: PASS / profile templates satisfy baseline static checks
dry-run-profile-deployment.sh syntax: PASS
dry-run-profile-deployment.sh full dry-run: PASS / all six profiles inspected read-only
PROFILE=secretary dry-run: PASS / secretary inspected read-only
SHOW_DIFF=1 PROFILE=secretary: PASS / secretary unified diff displayed read-only
git status --short: clean working tree
```

## Confirmed repository-side M7 behavior

```text
pre-production-profile-deployment.md:
  Documents deployment decision matrix, backup requirement, dry-run diff, manual apply plan, and post-apply verification plan.

profile-deployment-dry-run.md:
  Provides dry-run report guidance only.
  Does not approve or generate real overwrite commands.

dry-run-profile-deployment.sh:
  Compares repository templates against runtime SOUL.md files.
  Prints metadata and MATCH/DIFFERENT status by default.
  Shows unified diff only when SHOW_DIFF=1 is explicitly set.
  Supports PROFILE=<profile> filtering.
  Does not copy, overwrite, delete, edit, start, stop, restart, backup, or clean anything.
```

## Confirmed dry-run result

The full dry-run compared the six repository templates against real runtime profile `SOUL.md` files under:

```text
/home/eye/.hermes/profiles/<profile>/SOUL.md
```

All six profiles were reported as different from the repository templates:

```text
secretary: DIFFERENT
coordinator: DIFFERENT
researcher: DIFFERENT
writer: DIFFERENT
builder: DIFFERENT
runes-holder: DIFFERENT
```

The secretary single-profile dry-run also reported:

```text
secretary: DIFFERENT
```

The secretary unified diff showed that the repository template is the newer expanded OPC convention form, while the runtime `SOUL.md` is an older minimal runtime file headed:

```text
# Secretary Profile Soul
Status: Phase 3K-FIX.13 native profile template source alignment
```

This means runtime profiles are not yet aligned with M5/M6 repository templates.

## Deployment decision implication

The M7 result does not mean profiles should be overwritten immediately.

It means the next real deployment stage must use a controlled apply process:

```text
backup first
review diff
choose exact target profile list
approve target list explicitly
apply manually or through a separately reviewed guarded command
verify each affected profile
keep rollback path
```

Recommended first apply target for the next stage is `secretary`, because it is the Lark-facing user entry profile and contains the largest user-facing M5 behavior update.

Applying all six profiles at once is not recommended as the first real deployment action.

## Confirmed boundaries

The M7 verification did not execute real runtime mutation.

Not included in M7:

```text
real profile SOUL.md overwrite
profile install/update
runtime backup creation
apply script execution
gateway start/restart
native memory deletion
session deletion
Kanban deletion
Lark production cutover
automatic cleanup apply
parallel multi-agent execution
```

The dry-run output listed metadata and comparison state only by default. `SHOW_DIFF=1` was explicitly used only for secretary inspection and still did not modify files.

## Manual apply requirement

A future real profile deployment still requires a separate maintainer-approved apply step.

Required before any apply:

```text
read-only runtime inventory reviewed
backup exists outside git
template-vs-runtime diff reviewed
exact target profile list prepared
maintainer explicitly approves each target profile
commands are reviewed before execution
rollback path is known
post-apply verification command is ready
```

Unclear profiles must remain deferred or use partial/manual-merge.

## Final lock

```text
M7 Pre-production Profile Deployment Decision Planning
PASS / deployment decision plan documented / dry-run diff tooling verified / all six runtime SOUL files differ from repo templates / no runtime mutation executed
```

## Next work

After this lock, the next stage is:

```text
M8 Real profile backup + controlled SOUL.md apply
```

M8 requires explicit maintainer approval before any real profile overwrite, backup command, gateway action, native memory/session/Kanban maintenance, or Lark cutover is executed.
