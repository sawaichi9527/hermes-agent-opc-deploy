# Validation history archive

This directory holds historical validation material from the earlier simulation/runtime-heavy direction.

The current project direction is Hermes-native OPC profile set customization, not a custom deployment or validation framework.

## Archive policy

```text
Phase 3 / Phase 4 / Phase 5 validation material
  = historical safety evidence
  = useful for reference
  = not the main workflow
  = not required by repository layout checks
```

The mainline now focuses on:

```text
README.md
docs/implementation-roadmap.md
docs/phase-6-hermes-native-profile-alignment.md
profiles/*/SOUL.md.template
profiles/*/NOTES.md
scripts/verify-repo-layout.sh
scripts/verify-profile-templates.sh
```

## Historical groups

```text
phase-3-runtime/
  Local provider, Hermes runtime readiness, invocation behavior, runtime baseline.

phase-4-readonly-primitives/
  Manual OPC loop design and official read-only primitive probes.

phase-5-simulation/
  Repository-local simulation trial and no-real-profile-mutation evidence.
```

## Status

```text
M1 Hermes-native OPC Scope Reset
IN PROGRESS / historical validation no longer drives the mainline
```

Earlier documents may remain in Git history or be moved here when exact file-level archival is needed. The important policy change is that these validation artifacts no longer define the active implementation route.
