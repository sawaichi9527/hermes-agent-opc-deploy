# M8 roadmap status sync

This document records the M8.7 roadmap status sync for the Hermes-native OPC profile set.

M8.7 exists because the main `docs/implementation-roadmap.md` is a long cumulative roadmap. The M8 real apply result is already locked in `docs/verification-m8-secretary-apply.md`; this document provides a compact roadmap-facing status sync without copying runtime backups, secrets, or private runtime contents into the repository.

## Synced status

```text
M8 Real Profile Backup + Controlled Secretary-first SOUL.md Apply
PASS / frozen / backup completed / secretary SOUL applied / secretary MATCH verified / gateway remained stopped / no other profile applied
```

## Source verification lock

```text
docs/verification-m8-secretary-apply.md
```

## Synced M8 scope

```text
M8.1 Backup all six real profiles outside git
M8.2 Secretary-first apply target decision
M8.3 Guarded secretary SOUL.md apply
M8.4 Post-apply secretary verification
M8.5 Rollback procedure documented
M8.6 Secretary Apply Verification Lock
M8.7 Roadmap Status Sync
```

## Synced result summary

```text
external backup: /home/eye/hermes-backups/preprod-profile-deploy-20260614-025143
real apply target: /home/eye/.hermes/profiles/secretary/SOUL.md
source template: profiles/secretary/SOUL.md.template
post-apply secretary dry-run: Comparison: MATCH
gateway state: stopped
other profiles applied: no
Lark cutover: no
runtime cleanup: no
```

## Synced boundaries

M8.7 does not perform any runtime operation.

Not performed by M8.7:

```text
real profile overwrite
runtime backup creation
gateway start/restart
Lark production cutover
native memory deletion
session deletion
Kanban deletion
cache/log cleanup
Runes Wiki mutation
all-profile overwrite
```

## Next work

```text
M9 Secretary-only behavior smoke without Lark cutover
```

M9 should validate the updated `secretary` profile through local Hermes profile invocation first. Gateway restart and Lark production cutover remain separate explicit maintainer-approved stages.
