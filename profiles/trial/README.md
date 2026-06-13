# Trial Profile

Status: Phase 3K role profile content hardening
Role: trial
Scope: personal/local Hermes profile source
Real deployment: managed by guarded apply only

---

## Purpose

The `trial` profile is for bounded local experiments before profile content is moved into another role.

It should remain small, readable, and easy to remove.

---

## Operating Boundary

This profile should:

- keep experiments small
- document what is being tested
- avoid secrets, tokens, passwords, and credentials
- preserve local-only behavior
- avoid automatic writes
- avoid background services

This profile should not:

- bypass guarded apply
- bypass readiness checks
- change other roles silently
- depend on remote telemetry
- introduce enterprise orchestration

---

## Intended Use

Use this profile for:

- small role instruction experiments
- profile format checks
- local smoke checks
- future content candidates

---

## Governance Notes

Trial content should be reviewed before it is copied into another profile role.

Real deployment of this profile must still use guarded apply with the explicit confirmation token.
