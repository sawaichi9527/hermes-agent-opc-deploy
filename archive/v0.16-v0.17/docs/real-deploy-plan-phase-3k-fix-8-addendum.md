# Real Deploy Plan Addendum: Phase 3K-FIX.8

Status: Phase 3K-FIX.8 canonical role content hardening implemented  
Scope: repo source content only  
Real profile write: not executed  
Real profile delete: not executed

## Summary

Phase 3K-FIX.8 adds minimal source README content for the corrected canonical Hermes profile taxonomy.

This follows:

- Phase 3K-FIX.1 canonical taxonomy selection
- Phase 3K-FIX.2 config-driven role readiness rewrite
- Phase 3K-FIX.5 real drift cleanup execution
- Phase 3K-FIX.7 repo drift source cleanup execution

## Added Canonical Profile Content

Added source files:

```text
profiles/secretary/README.md
profiles/coordinator/README.md
profiles/researcher/README.md
profiles/writer/README.md
profiles/builder/README.md
profiles/runes-holder/README.md
```

These files are source content only.

They are not deployed to real `~/.hermes/profiles/` until a guarded apply is executed.

## Current Source Taxonomy

Canonical role list remains config-driven:

```text
config/profile-roles.txt
```

Expected roles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Current Drift Status

Repo drift source artifacts should remain absent:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

Real drift profiles should remain absent:

```text
~/.hermes/profiles/default/
~/.hermes/profiles/developer/
~/.hermes/profiles/reviewer/
~/.hermes/profiles/operator/
~/.hermes/profiles/trial/
```

## Verification Lock

Primary verification file:

```text
docs/verification-phase-3k-fix-8.md
```

Expected lock result:

```text
Phase 3K-FIX.8 canonical role content hardening
PASS / six canonical README profiles added / readiness READY / repo drift absent / real drift absent / no real write / no real delete
```

## Next Phase

Recommended next phase:

```text
Phase 3K-FIX.9 canonical content guarded apply planning
```

Phase 3K-FIX.9 should plan canonical content deployment to real `~/.hermes/profiles/` without applying it automatically.
