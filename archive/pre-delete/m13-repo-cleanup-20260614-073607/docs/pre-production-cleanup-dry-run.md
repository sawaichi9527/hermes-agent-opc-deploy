# M6 Pre-production cleanup dry-run plan

This document is a dry-run report template for future pre-production Hermes runtime maintenance.

It is not an approval to clean anything.

## Required inputs

```text
runtime root:
profile name:
inspector output reviewed: yes/no
backup exists outside git: yes/no
maintainer approval for apply: yes/no
```

## Dry-run report template

```text
Profile:
Runtime root:

Preserve:
- path:
  reason:

Cleanup candidates after backup:
- path:
  type:
  reason:
  risk:
  required approval:

Defer / unknown:
- path:
  reason:
  needed follow-up:

Secrets/private-data risk:
- yes/no
- notes:

Apply decision:
- do not apply yet / approved exact targets only

Verification after future apply:
- command:
- expected result:

Rollback note:
- backup location:
- restore owner:
```

## Classification guide

### Preserve

```text
SOUL.md
NOTES.md
.env
config.yaml
identity / metadata
provider/model config
Lark token/config
gateway config
required tool/skill config
```

### Candidate after backup

```text
old sessions
old chat history
temporary caches
old logs
test-generated state
obsolete smoke output
explicitly approved Kanban/task reset targets
explicitly approved native memory pollution targets
```

### Defer

```text
unknown databases
unknown state directories
native memory with unclear value
profile-specific files not documented yet
secret-bearing or private runtime data
anything whose deletion impact is unknown
```

## Manual apply guard

No cleanup command should be generated or executed from this document unless the maintainer later fills the exact target list and explicitly approves manual application.

The preferred default is:

```text
Defer uncertain items.
Preserve identity/config/secrets.
Clean only backed-up, reviewed, explicitly approved runtime history.
```
