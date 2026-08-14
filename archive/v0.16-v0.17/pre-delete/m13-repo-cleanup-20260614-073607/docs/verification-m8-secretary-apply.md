# M8 secretary-first real apply verification lock

This document locks the M8 real profile backup and controlled secretary-first `SOUL.md` apply result for the Hermes-native OPC profile set.

M8 is the first stage in this repo sequence that performed a real, target-specific runtime profile mutation. The mutation was limited to the real `secretary` profile `SOUL.md` file after an external backup was created.

## Purpose

M8 verifies that the repository `profiles/secretary/SOUL.md.template` can be safely applied to the real Hermes runtime secretary profile after backup and explicit maintainer approval.

It also records that gateway state, Lark production cutover, native memory, sessions, Kanban, caches, logs, `.env`, `config.yaml`, and all non-secretary profiles were not changed by the M8 apply script.

## Verified scope

```text
M8.1 Backup all six real profiles outside git
M8.2 Secretary-first apply target decision
M8.3 Guarded secretary SOUL.md apply
M8.4 Post-apply secretary verification
M8.5 Rollback procedure documented
M8.6 Secretary Apply Verification Lock
```

## M8 deliverables

```text
docs/real-profile-backup-and-secretary-apply.md
scripts/backup-hermes-profiles.sh
scripts/apply-secretary-soul-template.sh
docs/verification-m8-secretary-apply.md
```

## Repository-side verification before real apply

Before real backup/apply, the maintainer verified the repo-side M8 artifacts:

```text
verify-repo-layout.sh: PASS / repository layout is valid
verify-profile-templates.sh: PASS / profile templates satisfy baseline static checks
backup-hermes-profiles.sh syntax: PASS
apply-secretary-soul-template.sh syntax: PASS
backup-hermes-profiles.sh dry-run: PASS / no backup created
apply-secretary-soul-template.sh dry-run: PASS / no runtime file changed
```

## Real backup result

The maintainer created a real external backup with:

```bash
CREATE_BACKUP=1 bash scripts/backup-hermes-profiles.sh
```

Backup directory:

```text
/home/eye/hermes-backups/preprod-profile-deploy-20260614-025143
```

The backup script reported copy operations for all six runtime profile directories:

```text
/home/eye/.hermes/profiles/secretary
/home/eye/.hermes/profiles/coordinator
/home/eye/.hermes/profiles/researcher
/home/eye/.hermes/profiles/writer
/home/eye/.hermes/profiles/builder
/home/eye/.hermes/profiles/runes-holder
```

Backup manifest:

```text
/home/eye/hermes-backups/preprod-profile-deploy-20260614-025143/manifest.txt
```

Important boundary:

```text
The backup is outside this repository.
The backup may contain .env and private runtime files.
Do not commit it.
Do not copy it into docs, profiles, archive, GitHub issues, prompt context, or Runes Wiki candidates.
```

## Secretary apply command

The maintainer applied only the secretary `SOUL.md` using the guarded apply script:

```bash
BACKUP_DIR=/home/eye/hermes-backups/preprod-profile-deploy-20260614-025143 \
APPLY_SECRETARY_SOUL=1 \
bash scripts/apply-secretary-soul-template.sh
```

The script validated:

```text
repository secretary template exists
runtime secretary profile directory exists
runtime secretary SOUL.md exists
BACKUP_DIR exists
BACKUP_DIR contains profiles/secretary/SOUL.md
```

The script copied only:

```text
source: /home/eye/workspace/hermes-agent-opc-deploy/profiles/secretary/SOUL.md.template
target: /home/eye/.hermes/profiles/secretary/SOUL.md
```

## Secretary hash and metadata result

Before apply:

```text
repo secretary template size: 12039
runtime secretary SOUL.md size: 884
repo secretary template SHA256: 8d253718f91fd0293045af1fde1c019188828c152e789dfdc7b413969099fec9
runtime secretary SOUL.md SHA256: 764f9bf703449e37a9c28e959d223788723e22329f680eef1dd1f113daac0695
```

After apply:

```text
runtime secretary SOUL.md size: 12039
runtime secretary SOUL.md SHA256: 8d253718f91fd0293045af1fde1c019188828c152e789dfdc7b413969099fec9
```

Script result:

```text
PASS secretary runtime SOUL.md now matches repository template.
```

## Post-apply verification result

The maintainer ran:

```bash
hermes profile show secretary
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

`hermes profile show secretary` reported:

```text
Profile: secretary
Path:    /home/eye/.hermes/profiles/secretary
Model:   qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m (lmstudio)
Gateway: stopped
Skills:  0
.env:    exists
SOUL.md: exists
```

`PROFILE=secretary bash scripts/dry-run-profile-deployment.sh` reported:

```text
Comparison: MATCH
Decision hint: skip / already aligned
```

## Confirmed boundaries

The M8 real apply changed only:

```text
/home/eye/.hermes/profiles/secretary/SOUL.md
```

Not changed by M8:

```text
/home/eye/.hermes/profiles/secretary/.env
/home/eye/.hermes/profiles/secretary/config.yaml
/home/eye/.hermes/profiles/secretary/profile.yaml
/home/eye/.hermes/profiles/secretary/NOTES.md
/home/eye/.hermes/profiles/coordinator/SOUL.md
/home/eye/.hermes/profiles/researcher/SOUL.md
/home/eye/.hermes/profiles/writer/SOUL.md
/home/eye/.hermes/profiles/builder/SOUL.md
/home/eye/.hermes/profiles/runes-holder/SOUL.md
```

Also not performed:

```text
gateway start/restart
Lark production cutover
profile install/update through Hermes commands
native memory deletion
session deletion
Kanban deletion
cache/log cleanup
Runes Wiki mutation
parallel multi-agent execution
all-profile overwrite
```

## Rollback reference

If rollback is needed, restore only the backed-up secretary file:

```bash
cp /home/eye/hermes-backups/preprod-profile-deploy-20260614-025143/profiles/secretary/SOUL.md \
  /home/eye/.hermes/profiles/secretary/SOUL.md
```

Then verify:

```bash
hermes profile show secretary
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

Rollback should not touch `.env`, `config.yaml`, other profiles, native memory, sessions, Kanban, gateway, or Lark state unless explicitly approved.

## Final lock

```text
M8 Real Profile Backup + Controlled Secretary-first SOUL.md Apply
PASS / backup completed / secretary SOUL applied / secretary MATCH verified / gateway remained stopped / no other profile applied
```

## Next work

After this lock, the next stage is:

```text
M9 Secretary-only behavior smoke without Lark cutover
```

M9 should validate secretary behavior through local Hermes profile invocation first. Gateway restart and Lark production cutover remain separate explicit maintainer-approved stages.
