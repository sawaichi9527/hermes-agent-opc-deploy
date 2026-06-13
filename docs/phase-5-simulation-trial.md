# Phase 5 simulation trial

This document defines Phase 5.0 through Phase 5.6 for the maintainer's personal Hermes Agent OPC deployment.

Phase 5 is a repository-local simulation trial only.

It must not mutate the real Hermes home:

```text
~/.hermes/
~/.hermes/profiles/
```

The simulation target is limited to:

```text
simulate_env/.hermes/
```

## Phase 5.0 simulation trial entry criteria lock

Entry criteria:

```text
Phase 4 final consolidation is PASS.
Repository layout is PASS.
Profile templates pass static checks before simulated deploy.
Simulation commands target simulate_env only.
Real profile deployment remains blocked unless explicitly approved later.
```

Locked boundary:

```text
no real ~/.hermes profile mutation
no profile use or alias workflow
no Kanban task mutation
no external memory activation
no runtime daemon, queue, router, or scheduler
no deployment to real profiles in Phase 5
```

Current status:

```text
Phase 5.0 Simulation Trial Entry Criteria Lock
PENDING / prepared / awaiting maintainer local verification
```

## Phase 5.1 simulation environment layout re-check

Commands:

```bash
./scripts/verify-repo-layout.sh
./scripts/verify-profile-templates.sh
./scripts/prepare-sim-env.sh
./scripts/verify-sim-layout.sh
```

Expected result:

```text
repository layout: PASS
profile templates: PASS
simulation environment prepared
simulation layout valid before profile deployment
```

## Phase 5.2 profile template simulation dry-run

Command:

```bash
./scripts/deploy-sim-profiles.sh --force
```

Expected result:

```text
six simulated profiles are deployed under simulate_env/.hermes/profiles/
repository templates are copied to simulated runtime names
no real profile directory is changed
```

## Phase 5.3 simulated conflict / existing-profile check

Commands:

```bash
./scripts/deploy-sim-profiles.sh
./scripts/inspect-sim-profiles.sh --strict
```

Expected result:

```text
existing simulated profile state is handled conservatively
strict inspection confirms deployed files match repository templates
simulation manifests are present
```

## Phase 5.4 simulated deploy report verification

Command:

```bash
./scripts/verify-sim-layout.sh --require-profiles
```

Expected result:

```text
simulation layout is valid with all required profiles
simulate_env remains ignored and untracked
```

## Phase 5.5 simulation evidence lock

Commands:

```bash
./scripts/verify-layout.sh
bash scripts/verify-repo-layout.sh
git status --short
```

Expected result:

```text
real Hermes root read-only baseline remains safe
repository layout remains PASS
working tree is clean or only expected local executable-bit changes are present
```

## Phase 5.6 final simulation trial consolidation

Final Phase 5 result can only be marked PASS after Phase 5.1 through Phase 5.5 are locally verified.

Target final lock:

```text
Phase 5 Simulation Trial
PASS / simulation-only / repeatable / no real profile mutation / ready for Phase 6 decision
```

## Full maintainer verification command

Run from the repository root:

```bash
cd ~/workspace/hermes-agent-opc-deploy

git pull

./scripts/verify-repo-layout.sh
./scripts/verify-profile-templates.sh
./scripts/prepare-sim-env.sh
./scripts/verify-sim-layout.sh
./scripts/deploy-sim-profiles.sh --force
./scripts/deploy-sim-profiles.sh
./scripts/inspect-sim-profiles.sh --strict
./scripts/verify-sim-layout.sh --require-profiles
./scripts/verify-layout.sh
bash scripts/verify-repo-layout.sh
git status --short
```

## Result status

```text
Phase 5.0-5.6 Simulation Trial
PENDING / prepared / awaiting maintainer local verification
```

## Follow-up

After local verification, this file can be updated to a PASS lock with the observed result summary.

Phase 6 must not begin unless the maintainer explicitly approves real deployment.
