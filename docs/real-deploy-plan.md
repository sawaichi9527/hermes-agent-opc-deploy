# Real Deploy Plan

Status: Phase 3A read-only planning  
Scope: planning only  
Real profile write: disabled  
Target path: `~/.hermes/profiles/`  
Current guarantee: real `~/.hermes/profiles/` remains untouched

---

## Purpose

This plan defines the future real deployment path for OPC Hermes Agent
profiles.

Phase 3A is intentionally read-only. It documents and previews what a
future deployment would create, copy, back up, or reset, but it does not
touch the real Hermes profile directory.

The goal is to move from the frozen simulation baseline into a controlled
real deploy plan while keeping the system simple, personal-use friendly,
and lightweight for Hermes Agent.

---

## Current Baseline

| Phase | Result |
| --- | --- |
| Phase 1 repo + simulation foundation | PASS |
| Phase 2A SOUL templates | PASS |
| Phase 2B simulation profile deploy | PASS |
| Phase 2C simulation profile verification | PASS |
| Phase 2D profile template static hardening | PASS |
| Phase 2E simulation inspect / diff tooling | PASS |
| Phase 2F simulation runbook freeze | PASS |
| Phase 2 full simulation baseline | PASS |
| Real `~/.hermes/profiles/` untouched | PASS |

---

## Phase 3A Boundary

Phase 3A may add files inside the repo, such as documentation and a
read-only planning script.

Phase 3A must not:

- create directories under real `~/.hermes/profiles/`
- copy files into real `~/.hermes/profiles/`
- delete or reset real Hermes profile files
- modify real Hermes runtime state
- introduce daemon, service, database, queue, or enterprise orchestration
- make Hermes Agent depend on this planning layer at runtime

The planning layer should stay understandable from shell output and
Markdown documentation.

---

## Future Real Deploy Target

A future real deploy may create or update role-based profile directories
under:

- `~/.hermes/profiles/default/`
- `~/.hermes/profiles/developer/`
- `~/.hermes/profiles/reviewer/`
- `~/.hermes/profiles/operator/`
- `~/.hermes/profiles/trial/`

These role names follow the current simulation baseline and should not be
expanded unless there is a clear personal-use need.

---

## Planned Destination Layout

Future destination tree:

    ~/.hermes/profiles/
      default/
      developer/
      reviewer/
      operator/
      trial/

Each role directory may contain Hermes profile configuration files, SOUL
instructions, templates, or role-specific policy files, depending on the
validated profile format.

Phase 3A does not decide the final runtime profile format. It only records
the intended target layout.

---

## Planned Source Candidates

A future deploy script should inspect simple repo-local source candidates
before copying anything.

Candidate source roots:

- `profiles/`
- `templates/`
- `simulation/profiles/`
- `simulated-home/.hermes/profiles/`

The exact source root must be confirmed by the future dry-run output before
any real write is allowed.

A future copy map should be role-based:

| Role | Future destination |
| --- | --- |
| `default` | `~/.hermes/profiles/default/` |
| `developer` | `~/.hermes/profiles/developer/` |
| `reviewer` | `~/.hermes/profiles/reviewer/` |
| `operator` | `~/.hermes/profiles/operator/` |
| `trial` | `~/.hermes/profiles/trial/` |

The copy operation should remain a plain filesystem copy. No hidden
installer, background service, or profile registry should be introduced.

---

## Backup Policy

Before any future real deploy writes to `~/.hermes/profiles/`, it must
create a timestamped backup.

Planned backup root:

- `~/.hermes/backups/opc-profiles/`

Planned backup format:

- `~/.hermes/backups/opc-profiles/YYYYMMDD-HHMMSS/`

Required backup behavior:

1. If `~/.hermes/profiles/` exists, copy the existing tree into the
   timestamped backup directory.
2. If `~/.hermes/profiles/` does not exist, record that no existing profile
   tree was present.
3. Never overwrite an existing backup.
4. Print the exact backup path before a future write.
5. Keep restore instructions explicit and human-triggered.

The backup policy should stay file-based and local. No database-backed
backup index is needed for this personal-use scope.

---

## Reset Policy

Reset must be explicit and human-triggered.

Allowed future reset modes:

| Mode | Meaning |
| --- | --- |
| `preview` | Show what would be restored or removed. No writes. |
| `restore-backup` | Restore from a selected backup path. |
| `remove-opc-managed` | Remove only known OPC-managed files. |
| `full-reset` | Dangerous. Restore or remove the whole profile tree only with explicit confirmation. |

Phase 3A does not implement reset. It only records the intended policy.

A future reset command must not guess which backup to restore. The user
should provide or confirm the backup path.

---

## Risk Notes

Real profile deployment can affect Hermes Agent behavior.

Main risks:

1. Existing personal Hermes profiles may be overwritten.
2. Role-specific behavior may diverge from upstream Hermes defaults.
3. Incorrect profile layout may make Hermes fail to load a profile.
4. Future upstream Hermes changes may make local OPC templates stale.
5. Reset without backup could permanently lose local profile customization.

Required controls before Phase 3B:

1. Phase 2 full simulation baseline remains PASS.
2. Phase 3A read-only planning script passes.
3. Real `~/.hermes/profiles/` is inspected before any write.
4. The planned source root is printed.
5. The planned destination root is printed.
6. The planned backup path is printed.
7. Dry-run is the default behavior.
8. Real write requires explicit confirmation.

---

## Simplicity Policy

This project is for personal/local usage, not enterprise fleet management.

Do not add:

- central profile server
- orchestration daemon
- background reconciler
- database-backed deployment state
- remote telemetry
- multi-user RBAC
- automatic mutation of real profiles
- complex package manager behavior

Prefer:

- plain shell scripts
- readable Markdown
- local timestamped backups
- explicit dry-run output
- simple copy/restore semantics
- human-reviewed promotion from simulation to real deploy

The deployment layer should help the user operate Hermes Agent safely. It
should not become a second platform that Hermes Agent must depend on.

---

## Phase 3A Planning Script Expectations

`scripts/plan-real-deploy.sh` should be read-only.

It should print:

- repo root
- real profile root
- backup root
- current existence of real `~/.hermes/profiles/`
- candidate source roots
- planned role directories
- possible copy map
- backup policy
- reset policy
- explicit `REAL_PROFILE_WRITE=false`

It should not write into:

- `~/.hermes/profiles/`
- `~/.hermes/backups/opc-profiles/`

It may read the filesystem to inspect whether paths exist.

---

## Phase 3A Acceptance Criteria

Phase 3A is PASS only if:

1. `docs/real-deploy-plan.md` exists.
2. `scripts/plan-real-deploy.sh` exists.
3. `scripts/plan-real-deploy.sh` is executable.
4. The planning script performs no write into real `~/.hermes/profiles/`.
5. The planning script prints planned role directories.
6. The planning script prints backup policy.
7. The planning script prints reset policy.
8. The planning script clearly says real deployment is disabled.
9. The final output includes `REAL_PROFILE_WRITE=false`.
10. Git working tree can be reviewed before commit.

Recommended lock wording:

    Phase 3A real deploy read-only planning
    PASS / real ~/.hermes/profiles untouched / no real write

---

## Next Phase

After Phase 3A is locked, the next recommended phase is:

    Phase 3B real deploy dry-run implementation

Phase 3B may introduce a deploy script, but it should still default to
dry-run and require explicit write confirmation before touching real
`~/.hermes/profiles/`.

Phase 3B should not introduce enterprise-grade deployment complexity.
