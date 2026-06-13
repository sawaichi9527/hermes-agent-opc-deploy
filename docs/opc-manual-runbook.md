# Manual OPC runbook

This runbook describes the maintainer's manual observe-plan-check-act-record loop for the personal Hermes Agent OPC deployment.

It does not introduce a daemon, queue, router, scheduler, or custom orchestrator.

## Baseline command

Use the Phase 3 accepted non-mutating runtime path:

```bash
hermes -z "..." \
  --provider lmstudio \
  --model qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m
```

This command is not claimed to be profile-bound to `secretary`.

## Observe

Capture the current request and current state.

Allowed inputs:

```text
user request
relevant repo files
recent verification output
runtime baseline status
```

Do not paste secrets or `.env` values.

## Plan

Ask for a small plan only.

Recommended prompt shape:

```text
Given the current local runtime baseline, propose the next one or two safe manual actions. Do not edit files. Do not propose daemon, queue, router, or profile mutation.
```

## Check

The maintainer reviews the plan before any action.

Check:

```text
Is the action personal-use scoped?
Does it avoid Hermes profile mutation?
Does it avoid custom orchestration?
Does it use existing scripts/docs when possible?
Does it avoid secrets?
```

## Act

Perform one approved action.

Preferred action types:

```text
run an existing verification script
read a document
update documentation with verified state
run one bounded Hermes one-shot prompt
```

Avoid by default:

```text
hermes profile use secretary
hermes profile alias secretary
kanban mutation
memory mutation
new scripts unless a clear repeated need exists
```

## Record

Record only useful evidence.

Recommended record shape:

```text
status: PASS / PARTIAL / BLOCKED
scope: one request / documentation / verification
result: concise summary
boundary: no daemon / no queue / no profile mutation / no secrets
```

Documentation updates should be small and tied to verified state.

## Exit criteria for a manual OPC cycle

A manual OPC cycle is complete when:

```text
the action result is known
the maintainer has reviewed the result
any useful evidence is recorded
no unintended runtime mutation remains
```

## Safety reminder

Phase 4 remains a usage discipline, not a new runtime subsystem.
