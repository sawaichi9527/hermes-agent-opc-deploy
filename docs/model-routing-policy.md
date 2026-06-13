# Model Routing Policy

## Current baseline

The maintainer's Hermes Agent currently uses local LAN inference:

```text
LM Studio on the LAN
  -> Qwen3.6-35B-A3B
  -> Hermes Agent official profiles
```

This repository should keep the baseline local-first and personal-use oriented.

External model APIs may be added later, but they should not force a large redesign or make local profile usage harder.

## Principle

Keep role identity separate from model provider.

```text
profile role
  = what the agent is responsible for

model provider
  = which inference backend the profile uses
```

Do not create duplicate profiles only because a different model provider is available.

## Preferred default

The first choice is to let the original worker profiles call the configured model backend when the task is within their normal responsibility:

```text
researcher
writer
builder
```

These profiles may use local LM Studio by default. If Hermes Agent official profile configuration supports switching provider/model cleanly, use official configuration rather than introducing a parallel routing layer.

## When not to create consult-* profiles

Avoid creating these too early:

```text
consult-researcher
consult-writer
consult-builder
senior-researcher
senior-writer
senior-builder
```

Do not add them only because an external API exists.

Too many provider-specific profiles can create maintenance burden:

- duplicated SOUL.md files;
- duplicated memory rules;
- unclear authority between base and consult profiles;
- higher chance of role drift;
- more migration work when Hermes Agent changes upstream profile behavior.

## When consult-* profiles may make sense

A separate consult profile may be useful when the role is not just a different model backend, but a different decision function.

Examples:

```text
consult-researcher
  External second-opinion reviewer for disputed facts, weak evidence, or high-uncertainty topics.

consult-writer
  External style or audience-fit reviewer for important drafts, not the normal first writer.

consult-builder
  External design/code-review advisor for risky implementation plans, not the normal implementer.
```

In this pattern, `consult-*` profiles are advisors. They should not own the primary task flow.

## Preferred escalation pattern

Start simple:

```text
secretary
  -> coordinator
  -> researcher / writer / builder
```

Escalate only when needed:

```text
secretary
  -> coordinator
  -> researcher / writer / builder
  -> consult-researcher / consult-writer / consult-builder when risk or uncertainty justifies it
```

The coordinator should decide when to ask for external consultation, based on a small set of criteria.

## Suggested escalation criteria

Use external consult profiles only for cases such as:

- high uncertainty after local reasoning;
- important decision with high cost of being wrong;
- suspected local-model weakness;
- need for broader world knowledge;
- user explicitly asks for second opinion;
- final review before a risky project action.

For normal personal tasks, local profiles are enough.

## Naming preference

Use `consult-*` before `senior-*`.

Reason:

```text
consult-*
  Means second opinion / advisory role.
  It does not imply permanent higher authority.

senior-*
  Can imply hierarchy and may accidentally weaken the base profile's role clarity.
```

If a future profile truly becomes the main authority for a role, revisit the naming then.

## Relationship to secrets

External API keys and credentials must never be stored in this repository.

Use the official Hermes Agent configuration and `.env` handling for the deployed profile environment.

This repository may only store templates or documentation with placeholder values.

## Personal-use boundary

Do not build an enterprise model-router.

No multi-tenant provider policy, no complex cost optimizer, no enterprise audit routing, and no large rules engine.

The goal is simple:

```text
Use local models by default.
Ask external models only when the task needs a second opinion or stronger outside capability.
```
