# M8 Real profile backup + controlled secretary-first SOUL.md apply

This document defines the M8 controlled deployment procedure for applying the repository `secretary` SOUL template to the real Hermes runtime profile.

M8 is the first stage that prepares real runtime mutation, but mutation must still be guarded, backed up, target-specific, and explicitly approved.

## Purpose

M7 confirmed that all six real runtime `SOUL.md` files differ from the repository templates. M8 starts controlled deployment by backing up all real profiles and applying only `secretary` first.

The goal is to update the Lark-facing user entry profile first, verify it, and avoid a risky all-profile overwrite.

## Scope

```text
M8.1 Backup all six real profiles outside git
M8.2 Secretary-first apply target decision
M8.3 Guarded secretary SOUL.md apply
M8.4 Post-apply secretary verification
M8.5 Rollback procedure
```

## Non-goals

M8 does not do these by default:

```text
apply all six profiles at once
apply coordinator / researcher / writer / builder / runes-holder
profile install/update through Hermes commands
gateway start/restart
Lark production cutover
native memory cleanup
session cleanup
Kanban cleanup
cache/log cleanup
Runes Wiki mutation
parallel multi-agent execution
```

## M8.1 Backup all six real profiles outside git

Use the guarded backup script.

Dry-run preview:

```bash
bash scripts/backup-hermes-profiles.sh
```

Real backup creation:

```bash
CREATE_BACKUP=1 bash scripts/backup-hermes-profiles.sh
```

Default backup root:

```text
~/hermes-backups/
```

Default backup directory pattern:

```text
~/hermes-backups/preprod-profile-deploy-YYYYMMDD-HHMMSS/
```

The backup is intentionally outside this repository and may contain `.env` and private runtime files. Do not commit it.

Minimum expected backup content:

```text
profiles/secretary/
profiles/coordinator/
profiles/researcher/
profiles/writer/
profiles/builder/
profiles/runes-holder/
manifest.txt
```

## M8.2 Secretary-first apply target decision

M8 applies only this target first:

```text
/home/eye/.hermes/profiles/secretary/SOUL.md
```

Source template:

```text
profiles/secretary/SOUL.md.template
```

Reason:

```text
secretary is the Lark-facing user entry profile.
secretary contains the largest M5 user-facing behavior update.
secretary can be verified before worker profiles are changed.
```

The remaining five profiles must remain unchanged in M8 unless a later explicit stage approves them.

## M8.3 Guarded secretary SOUL.md apply

The apply script is locked by default.

Preview without mutation:

```bash
bash scripts/apply-secretary-soul-template.sh
```

Real apply requires both:

```text
APPLY_SECRETARY_SOUL=1
BACKUP_DIR=<existing backup directory containing profiles/secretary/SOUL.md>
```

Example:

```bash
BACKUP_DIR=~/hermes-backups/preprod-profile-deploy-YYYYMMDD-HHMMSS \
APPLY_SECRETARY_SOUL=1 \
bash scripts/apply-secretary-soul-template.sh
```

The apply script must:

```text
verify the repo template exists
verify the runtime secretary profile exists
verify backup directory exists
verify backup contains profiles/secretary/SOUL.md
copy only profiles/secretary/SOUL.md.template to ~/.hermes/profiles/secretary/SOUL.md
not modify .env
not modify config.yaml
not modify other profiles
not restart gateway
not clean memory/session/Kanban/cache/log state
```

## M8.4 Post-apply secretary verification

After future real apply, verify:

```bash
hermes profile show secretary
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

Expected dry-run result after successful apply:

```text
secretary: MATCH
```

If `hermes profile show secretary` fails, do not restart gateway. Investigate first or rollback.

Gateway validation remains separate:

```bash
hermes -p secretary gateway status
```

Do not run gateway restart or Lark cutover in M8 unless a later explicit stage approves it.

## M8.5 Rollback procedure

If secretary behavior is wrong after apply, restore the backed-up file:

```bash
cp "$BACKUP_DIR/profiles/secretary/SOUL.md" ~/.hermes/profiles/secretary/SOUL.md
```

Then verify:

```bash
hermes profile show secretary
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

Rollback should not touch `.env`, `config.yaml`, native memory, sessions, Kanban, gateway state, or Lark state unless explicitly approved.

## Required M8 repository verification

Before running real backup/apply commands, verify repository artifacts:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
bash -n scripts/backup-hermes-profiles.sh
bash -n scripts/apply-secretary-soul-template.sh
git status --short
```

## Required M8 runtime sequence

Recommended execution order:

```bash
bash scripts/dry-run-profile-deployment.sh
CREATE_BACKUP=1 bash scripts/backup-hermes-profiles.sh
BACKUP_DIR=<printed backup directory> APPLY_SECRETARY_SOUL=1 bash scripts/apply-secretary-soul-template.sh
hermes profile show secretary
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

## Final M8 safety rule

```text
Backup first.
Apply secretary only.
Verify before any gateway action.
Do not apply all six profiles at once.
Do not clean runtime state in M8.
```
