# Consult Subagent Upgrade Policy

This document records the maintainer baseline for future external model API usage.

The current default is local-first:

```text
LAN LM Studio -> Qwen3.6-35B-A3B -> official Hermes profiles
```

External model APIs are expected to be rare escalation tools, not the default execution path.

## Baseline decision

Use **consult subagents first**.

Do not create permanent official Hermes profiles such as `consult-researcher`, `consult-writer`, or `consult-builder` at the beginning.

The normal operating model remains:

```text
secretary
  -> coordinator
  -> researcher / writer / builder / runes-holder
  -> local LM Studio / Qwen3.6-35B-A3B
```

When a second opinion is needed:

```text
base profile
  -> temporary consult subagent using external model API
  -> advisory result returned to base profile or coordinator
  -> coordinator merges or rejects the advice
```

## Why subagent first

Most tasks should use local profiles and local compute.

A consult role should not become a long-lived profile unless real usage proves that it needs persistent state, memory, and a dedicated SOUL.md.

Keeping consult work temporary avoids:

- duplicating the base worker profiles
- weakening the role purity of `researcher`, `writer`, and `builder`
- creating extra profile memory to maintain
- making external API usage feel like part of the default path
- adding cost and operational burden before it is needed

## Consult subagent scope

A consult subagent may provide:

- second opinion
- risk review
- counterexamples
- external reasoning contrast
- external model weakness/strength comparison
- final sanity check before high-risk action

A consult subagent must not own:

- project direction
- long-term role memory
- final delivery responsibility
- direct project file mutation
- direct runes mutation
- direct user-facing final answer unless coordinator explicitly routes it that way

## Escalation triggers

Use consult subagents only when one or more of the following is true:

- the local model shows uncertainty or weak reasoning
- the task has high cost or high risk
- the user explicitly asks for external second opinion
- the coordinator wants an independent challenge before final merge
- the researcher needs outside validation for important evidence
- the writer needs an external style or clarity critique
- the builder wants a final safety review before a risky implementation step

## Upgrade criteria

Only consider a permanent official Hermes consult profile after repeated practical use shows that the consult role needs persistence.

Possible upgrade signs:

- the same consult task is used frequently
- consult outputs need their own memory or skills
- consult behavior requires a stable SOUL.md
- consult routing rules become stable and repeatable
- external API use becomes a normal workflow stage rather than rare escalation
- maintaining prompt templates is no longer enough

If upgraded, prefer names such as:

```text
consult-researcher
consult-writer
consult-builder
```

Avoid `senior-*` naming for this use case. `senior-*` implies hierarchy and may accidentally weaken the base profile roles. `consult-*` better expresses second-opinion advisory usage.

## Non-goals

This policy does not introduce external model APIs as a default dependency.

It does not require external APIs for daily usage.

It does not change the maintainer baseline profiles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

It does not deploy anything into `~/.hermes/profiles/`.

It is a planning policy only until the maintainer explicitly approves real deployment.
