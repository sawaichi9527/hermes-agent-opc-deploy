# Profile Language Policy

Status: planned for Phase 2 profile templates.
Scope: `SOUL.md.template` and future profile-facing prompt/config content in this repository.

## Decision

Use a single authoritative `SOUL.md.template` per profile.

Do not maintain full Chinese and English variants for each profile, and do not auto-select a profile SOUL template by OS locale.

The maintainer baseline is:

```text
secretary
  Traditional Chinese first, with English technical terms where useful

coordinator / researcher / writer / builder / runes-holder
  English-first canonical role instructions
  with explicit user-facing language policy
```

## Why

Profile SOUL files define durable role identity and behavioral boundaries. They should be stable, short, and easy to audit.

Maintaining full bilingual variants would create drift risk:

```text
SOUL.zh.md.template
SOUL.en.md.template
```

The two versions could diverge over time, and deployment/debugging would need to answer which version was actually installed.

Embedding full bilingual sections in one file is also discouraged because it spends context budget and may create duplicated or conflicting instructions.

## Canonical language model

The default implementation pattern is:

```text
role identity / safety / boundary / handoff rules
  -> one canonical source, usually English

user preference / tone / Lark interaction style
  -> secretary profile

final response language
  -> follow user/channel/task policy
```

## Secretary exception

`secretary` is the maintainer's Lark-first personal intake profile. It is allowed to be Traditional Chinese first because it directly handles:

- user preference adaptation
- Lark-facing interaction style
- informal user wording
- user-specific response format
- filtering user taste away from worker profiles

It may still use English for commands, filenames, code terms, tool names, role names, and protocol labels.

## Worker profile pattern

For `coordinator`, `researcher`, `writer`, `builder`, and `runes-holder`, use English-first role instructions.

Each worker template should include a short language policy similar to:

```markdown
## Language Policy

- Treat these role instructions as authoritative.
- Reply in the user's latest language unless the task explicitly requests another language.
- For Chehan's Lark-first workflow, Traditional Chinese is preferred for user-facing summaries.
- Keep commands, filenames, code, logs, API names, and protocol labels in their original language.
- Do not store user tone preferences in this role unless the preference is essential to the role's task.
```

## No locale auto-switch for now

Deployment scripts should not select different profile templates by locale.

Reason:

```text
locale auto-switch
  -> hidden deployment behavior
  -> harder debugging
  -> template drift
  -> inconsistent profile behavior across machines
```

A future override may be considered only after the maintainer baseline is stable.

## Forker guidance

Other users may translate templates for their own use, but should treat one version as canonical. If translated templates are added later, they should be generated from the canonical version and clearly marked as derived, not as independent authorities.
