# M7 profile deployment dry-run guide

This document is the dry-run report guide for comparing repository profile templates against real Hermes runtime profile files.

It is not an approval to overwrite anything.

## Required inputs

```text
runtime root:
profile name:
repo template path:
runtime SOUL.md path:
backup exists outside git: yes/no
diff reviewed: yes/no
maintainer approval for apply: yes/no
```

## Read-only dry-run command

Default summary mode:

```bash
bash scripts/dry-run-profile-deployment.sh
```

Single-profile summary:

```bash
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

Show unified diffs explicitly:

```bash
SHOW_DIFF=1 bash scripts/dry-run-profile-deployment.sh
```

Use another Hermes root:

```bash
HERMES_HOME=/path/to/hermes bash scripts/dry-run-profile-deployment.sh
```

## Dry-run report template

```text
Profile:
Repository template:
Runtime SOUL.md:
Template present: yes/no
Runtime present: yes/no
Files match: yes/no
Diff reviewed: yes/no
Decision: apply-now / defer / skip / partial/manual-merge
Reason:
Backup location:
Required approval:
Rollback note:
```

## Decision guide

### apply-now

Use only when:

```text
diff was reviewed
runtime customization is not needed
backup exists outside git
maintainer approved exact target profile
rollback path is known
```

### partial/manual-merge

Use when:

```text
runtime SOUL.md has local customization worth preserving
repo template is newer but should not fully replace runtime content
manual merge is safer than overwrite
```

### defer

Use when:

```text
runtime file purpose is unclear
profile has active production behavior
backup is missing
reviewer has not approved exact target
```

### skip

Use when:

```text
profile intentionally remains unchanged
repo template does not apply to this runtime
current runtime profile is known-good and should stay untouched
```

## Manual apply guard

Do not run copy commands until the maintainer explicitly approves each exact target profile.

A future manual command may look like this, but it is not approved by this document:

```bash
cp profiles/<profile>/SOUL.md.template ~/.hermes/profiles/<profile>/SOUL.md
```

## Safety rule

```text
Dry-run can compare and classify.
Dry-run must not mutate runtime files.
Apply requires a separate explicit maintainer-approved step.
```
