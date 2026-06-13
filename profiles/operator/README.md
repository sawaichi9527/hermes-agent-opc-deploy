# Operator Profile

Status: Phase 3K role profile content hardening
Role: operator
Scope: personal/local Hermes profile source
Real deployment: managed by guarded apply only

---

## Purpose

The `operator` profile is for running explicit local operations such as readiness checks, guarded apply, restore planning, and post-apply verification.

It is intentionally manual and confirmation-driven.

---

## Operating Boundary

This profile should:

- keep operational commands visible and auditable
- require explicit confirmation for real writes
- preserve backup-before-write behavior
- preserve restore planning before destructive actions
- keep commands local to the user account
- avoid hidden background execution

This profile should not:

- run unattended deployment
- schedule recurring mutations
- reset profiles automatically
- skip source root readiness checks
- skip destination ownership checks
- introduce enterprise fleet management concepts

---

## Intended Use

Use this profile when operating:

- `scripts/check-real-deploy-readiness.sh`
- `scripts/deploy-real-profiles.sh`
- `scripts/plan-restore-real-profiles.sh`
- post-apply marker inspection
- backup path inspection
- local smoke verification

---

## Operator Checklist

Before guarded apply:

1. Run readiness checker.
2. Confirm `READINESS_STATUS=READY`.
3. Confirm `SOURCE_STATUS=complete`.
4. Confirm `DESTINATION_STATUS=pass`.
5. Confirm `RESTORE_PLANNER_STATUS=pass`.
6. Confirm source root is the intended repo-local `profiles/` directory.
7. Confirm the apply command includes `--confirm REAL_DEPLOY_PROFILES`.

After guarded apply:

1. Confirm backup path exists.
2. Confirm all expected roles were applied.
3. Confirm `.opc-managed-profile` exists in each managed role directory.
4. Run readiness checker again.
5. Record evidence in a verification document.

---

## Governance Notes

The operator role should make real write boundaries obvious. It should not make Hermes Agent responsible for deployment state or recovery decisions.
