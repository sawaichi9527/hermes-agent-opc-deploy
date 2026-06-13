# M7 Pre-production profile deployment decision plan

This document defines the pre-production deployment decision procedure for applying repository `SOUL.md.template` files to real Hermes profile `SOUL.md` files.

M7 is still decision, backup, diff, and manual-apply planning. It does not authorize automatic overwrite by itself.

## Purpose

M1-M6 established the repository-side OPC profile baseline and runtime maintenance safety procedure.

M7 prepares the maintainer to decide whether, when, and how the repository templates should be applied to the real Hermes runtime profile files under `~/.hermes/profiles/*/SOUL.md`.

The goal is safe deployment readiness, not immediate mutation.

## Scope

```text
M7.1 Deployment decision matrix
M7.2 Backup requirement
M7.3 Template-vs-runtime dry-run diff
M7.4 Manual apply plan
M7.5 Post-apply verification plan
```

## Non-goals

M7 does not do the following by default:

```text
real profile SOUL.md overwrite
profile install/update
gateway start/restart
native memory deletion
session deletion
Kanban deletion
Lark production cutover
automatic cleanup apply
parallel multi-agent execution
```

## M7.1 Deployment decision matrix

Before applying repository templates to real runtime profiles, classify each profile separately.

Recommended decision states:

```text
apply-now
  Maintainer has reviewed template diff, backup exists, and the profile is safe to overwrite manually.

defer
  Runtime profile appears active, unclear, or needs more review.

skip
  Profile should intentionally remain unchanged.

partial/manual-merge
  Runtime SOUL.md contains useful local customization that should be merged manually instead of overwritten.
```

Suggested per-profile matrix:

```text
Profile:
Runtime path:
Template path:
Decision: apply-now / defer / skip / partial/manual-merge
Reason:
Backup prepared: yes/no
Diff reviewed: yes/no
Manual command approved: yes/no
Rollback path known: yes/no
```

## M7.2 Backup requirement

Before any real overwrite, create a backup outside this repository.

Minimum backup scope for each target profile:

```text
~/.hermes/profiles/<profile>/SOUL.md
~/.hermes/profiles/<profile>/NOTES.md
~/.hermes/profiles/<profile>/.env
~/.hermes/profiles/<profile>/config.yaml
~/.hermes/profiles/<profile>/profile.yaml
```

The backup may include additional profile runtime files, but it must not be committed to git.

Do not paste `.env` values, token values, runtime databases, session contents, logs, caches, or memory contents into Markdown docs, GitHub issues, prompt context, or Runes Wiki proposals.

Recommended backup location pattern:

```text
~/hermes-backups/preprod-profile-deploy-YYYYMMDD-HHMMSS/
```

## M7.3 Template-vs-runtime dry-run diff

Use the read-only dry-run script:

```bash
bash scripts/dry-run-profile-deployment.sh
```

The script defaults to metadata and status only. It does not print full file diffs unless explicitly requested.

To show diffs:

```bash
SHOW_DIFF=1 bash scripts/dry-run-profile-deployment.sh
```

To inspect one profile:

```bash
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

The script must not:

```text
write files
overwrite SOUL.md
copy .env
print secrets
start or restart gateways
clean memory/session/Kanban state
```

## M7.4 Manual apply plan

M7 deliberately does not provide an automatic apply script.

A real manual apply may happen only when all of the following are true:

```text
read-only runtime inventory reviewed
backup exists outside git
template-vs-runtime diff reviewed
exact target profile list prepared
maintainer explicitly approves each target profile
manual commands are reviewed before execution
rollback path is known
```

Suggested manual apply pattern, to be reviewed before use:

```bash
cp profiles/<profile>/SOUL.md.template ~/.hermes/profiles/<profile>/SOUL.md
```

Do not run this command until the exact target profile is approved by the maintainer.

## M7.5 Post-apply verification plan

After any future real apply, verify each affected profile separately.

Recommended checks:

```bash
hermes profile show <profile>
```

If secretary is updated and Lark-facing behavior is being validated later:

```bash
hermes -p secretary gateway status
```

Gateway restart or production cutover must remain a separate explicit maintainer-approved step.

Post-apply result should record:

```text
profile:
backup location:
command used:
verification command:
verification result:
rollback available: yes/no
notes:
```

## Required M7 verification

Repository-side M7 verification should run:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
bash -n scripts/dry-run-profile-deployment.sh
git status --short
```

Optional read-only deployment dry-run:

```bash
bash scripts/dry-run-profile-deployment.sh
```

## Final M7 planning rule

```text
M7 prepares deployment decisions.
M7 does not overwrite real profiles by itself.
Real deployment requires backup, reviewed diff, exact target list, explicit maintainer approval, and rollback path.
```
