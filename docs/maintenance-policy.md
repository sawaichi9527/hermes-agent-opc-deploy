# Maintenance Policy

This repository is maintained as a lightweight personal-use companion around upstream Hermes Agent.

## Operating model

Default contribution flow:

1. Update this GitHub repository directly when the connector can perform the change safely.
2. The user pulls the repository locally and validates the result.
3. Only ask the user to run patch scripts when GitHub connector limitations prevent direct edits.
4. For unusually large files where chat code blocks may be unreliable, generate the full file as a downloadable artifact and provide the target repository path for manual upload/overwrite.

## Scope control

Keep the system simple and useful for one-person or small personal lab usage.

Do not introduce enterprise-scale features such as:

- multi-tenant control planes
- distributed job queues
- complex service meshes
- centralized policy engines
- production deployment gates
- database-backed orchestration layers
- heavy observability stacks

Prefer:

- official Hermes Agent behavior
- official Hermes profiles
- small Markdown templates
- simple shell helpers
- local verification scripts
- clear migration notes

## Upstream-first rule

Hermes Agent is the runtime owner. This repository should adapt to Hermes Agent, not compete with it.

When upstream Hermes Agent changes profile behavior, prefer small template and documentation updates here instead of building a compatibility layer that hides upstream behavior.

## Burden rule

This repository must not become a burden for Hermes Agent.

Hermes Agent must continue to work in both modes even if this repository is absent:

- default one-agent usage
- official-profile OPC-style usage

The optional runes-holder and hermes-runes-md-wiki path are extra knowledge sedimentation aids only.

## Secrets rule

Never commit real secrets or live runtime state.

Do not commit:

- `.env`
- API keys
- tokens
- passwords
- state databases
- sessions
- logs
- caches
- large artifacts

Use template files with safe placeholder values only.
