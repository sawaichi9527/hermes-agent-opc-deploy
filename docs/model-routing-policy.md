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

Do not create duplicate official profiles only because a different model provider is available.

## Preferred default

The first choice is to let the normal maintainer baseline profiles use the local model backend:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

These profiles may use local LM Studio by default. If Hermes Agent official profile configuration supports switching provider/model cleanly, use official configuration rather than introducing a parallel routing layer.

For normal personal tasks, the local profile set plus local Qwen3.6-35B-A3B should be enough.

## Consult capability should start as subagent-like work

For the maintainer baseline, `consult-*` should not start as permanent official Hermes profiles.

Treat external model consultation as **subagent-like, ephemeral second opinion work** first:

```text
base profile owns the task
  -> coordinator decides consultation is justified
  -> external consult call runs as temporary second opinion
  -> result returns as advisory evidence
  -> base profile/coordinator remains responsible for final merge
```

This keeps the system simple because most work still uses local profiles and local compute.

The consult worker should not keep long-term role memory at first. It should receive a narrow task brief, return a structured advisory result, and end.

## Why subagent-like consult first

Using official profiles for every external consult role too early creates unnecessary maintenance burden:

- duplicated `SOUL.md` files;
- duplicated memory rules;
- duplicated provider-specific config;
- unclear authority between base and consult roles;
- higher chance of role drift;
- more migration work when Hermes Agent changes upstream profile behavior.

A temporary consult task is enough for most cases because external APIs are expected to be rare escalation paths, not the daily runtime.

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

Also avoid `senior-*` naming for this use case because it implies hierarchy. The goal is not to replace the base local profiles.

## When consult-* profiles may make sense later

A separate official `consult-*` profile may become useful only when the role is not just a different model backend, but a stable, repeated decision function.

Possible future examples:

```text
consult-researcher
  Repeated external second-opinion reviewer for disputed facts, weak evidence, or high-uncertainty topics.

consult-writer
  Repeated external style or audience-fit reviewer for important drafts, not the normal first writer.

consult-builder
  Repeated external design/code-review advisor for risky implementation plans, not the normal implementer.
```

Promote a consult capability to an official profile only if all of these are true:

- it is used often enough to justify maintaining profile files;
- it has stable responsibilities beyond one-off model access;
- it needs its own `SOUL.md`, memory rules, or skills;
- its authority remains advisory rather than primary;
- it does not make normal local-profile operation harder.

## Preferred escalation pattern

Start simple:

```text
secretary
  -> coordinator
  -> researcher / writer / builder / runes-holder
  -> local LM Studio / Qwen3.6-35B-A3B
```

Escalate only when needed:

```text
secretary
  -> coordinator
  -> base local profile
  -> temporary consult subagent / external model second opinion
  -> coordinator merges advisory result
```

Only after repeated use should the temporary consult path be promoted to a permanent official profile.

## Suggested escalation criteria

Use external consult only for cases such as:

- high uncertainty after local reasoning;
- important decision with high cost of being wrong;
- suspected local-model weakness;
- need for broader world knowledge;
- user explicitly asks for second opinion;
- final review before a risky project action.

For normal personal tasks, local profiles are enough.

## Naming preference

Use `consult-*` before `senior-*` if a permanent consult role is eventually needed.

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
Keep consult work temporary until repeated real use proves it deserves a profile.
```
