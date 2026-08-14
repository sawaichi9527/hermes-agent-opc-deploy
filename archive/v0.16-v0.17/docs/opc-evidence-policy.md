# OPC evidence policy

This policy defines the lightweight evidence rules for the manual OPC loop.

The goal is local maintenance traceability, not telemetry.

## Keep evidence small

Useful records are short and decision-oriented:

```text
phase name
operation goal
PASS / PARTIAL / BLOCKED status
short result summary
command names
follow-up actions
```

## Keep private material out

Do not record real local secret values, private credentials, or unreviewed sensitive transcripts.

Prefer summaries over raw dumps.

## Prefer high-level command results

Safe records should look like:

```text
layout check: PASS
runtime readiness: PASS
oneshot marker: PASS
follow-up: update documentation
```

Avoid copying large raw logs unless they have been reviewed and are useful.

## No telemetry system

This policy does not authorize:

```text
telemetry database
central log collector
background uploader
trace daemon
analytics pipeline
```

## Documentation-first

For Phase 4, evidence belongs in small documentation updates when it changes a decision or proves a baseline.

Do not add evidence just because a command produced output.
