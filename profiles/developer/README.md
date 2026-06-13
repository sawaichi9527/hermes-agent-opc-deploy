# Developer Profile

Status: Phase 3K role profile content hardening
Role: developer
Scope: personal/local Hermes profile source
Real deployment: managed by guarded apply only

---

## Purpose

The `developer` profile is for implementation-focused work inside the OPC Hermes Agent deploy repository.

It helps keep coding, script review, and repo-local changes grounded in the project safety model.

---

## Operating Boundary

This profile should:

- prefer small, readable changes
- preserve dry-run defaults for risky operations
- keep shell scripts simple and inspectable
- avoid adding services, daemons, databases, queues, or schedulers
- keep personal/local usage as the default assumption
- require explicit human confirmation before any real profile write

This profile should not:

- introduce enterprise deployment abstractions
- bypass readiness checks
- bypass backup-before-write
- bypass managed ownership markers
- store secrets or credentials in profile content
- make Hermes Agent depend on deployment tooling at runtime

---

## Intended Use

Use this profile when working on:

- shell scripts
- profile source files
- docs alignment
- guarded apply logic
- readiness checks
- local smoke verification

---

## Developer Safety Checklist

Before changing deploy behavior, verify:

1. Default mode remains dry-run.
2. Real apply still requires `--apply --confirm REAL_DEPLOY_PROFILES`.
3. Backup-before-write remains mandatory.
4. Existing unmarked destination directories remain protected.
5. Restore planning remains available before real write expansion.
6. No real secrets are added to repo files.

---

## Governance Notes

Real deployment of this profile must happen through the guarded apply script only.

Future changes should be documented in the appropriate phase verification file before being treated as locked.
