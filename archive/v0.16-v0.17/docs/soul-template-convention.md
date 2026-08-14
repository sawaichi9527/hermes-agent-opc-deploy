# Hermes OPC SOUL Template Convention v1

This document defines the repository-local convention for `profiles/*/SOUL.md.template` files.

This is not an official Hermes Agent standard and not an external industry standard. It is a local convention for keeping the Hermes-native OPC profile set readable, maintainable, and testable.

## Purpose

```text
Keep profile instructions consistent.
Make role boundaries easy to inspect.
Keep runtime handoff compact and Traditional Chinese-first.
Prevent profile separation from becoming parallel multi-agent execution.
Keep real Hermes runtime state protected until the maintainer explicitly approves changes.
```

## Standard section order

Each `SOUL.md.template` should use this order where practical:

```text
# SOUL: <profile>

## Role / 角色定位
## Mission / 任務
## Not Your Role / 不是你的角色
## Runtime Behavior / 執行規則
## OPC Handoff / OPC 交接規則
## Context / Compression Policy
## Memory / Kanban / Runes Boundary
## Safety Boundary / 安全邊界
## Language Policy / 語言政策
## Output Contract / 輸出格式
## Maintenance Notes / 維護備註
```

Profile-specific sections may be inserted when useful, but they should not hide the core boundaries.

## Language convention

```text
secretary
  Main body should be Traditional Chinese-first because this is the user-facing profile.
  English should be kept for profile names, technical terms, commands, paths, file names, model names, source identifiers, and project names.

coordinator / researcher / writer / builder
  Role definition may remain English-first for precision.
  Runtime handoff and secretary-facing summaries should be Traditional Chinese-first.

runes-holder
  Traditional Chinese / English mixed is allowed because this role bridges user-facing workflow, Runes governance terms, commands, paths, and wiki headings.
```

## Naming convention

Templates should avoid hard-coding a personal name.

Use neutral terms by default:

```text
使用者
the user
maintainer
```

Use `maintainer` only for repository, approval, review, or runtime-authority context.

The user's preferred name, nickname, role name, or secretary-specific address style should be configured in the real deployed profile or native memory, not hard-coded into the template.

## Context / Compression Policy

Context compression is part of profile behavior, not only runtime background behavior.

The profile set should avoid transcript multiplication:

```text
secretary should not forward complete Lark threads by default.
coordinator should not forward complete secretary context to workers.
workers should return compact results, not repeat all source context.
runes-holder should return compact Runes Wiki-derived summaries, not large wiki dumps.
```

The preferred handoff style is:

```text
目的:
必要背景:
需要處理的問題:
可用來源:
輸出格式:
限制:
```

Each profile should include a short context/compression rule appropriate to its role.

## Agentic behavior convention

Borrow common multi-agent design ideas only when they reinforce this repository's constraints:

```text
clear role identity
explicit non-role boundary
one next handoff at a time
compact handoff packet
source and uncertainty labeling
tool/runtime mutation guardrails
output contract
```

Do not import generic agentic AI hype into the templates.

Do not introduce:

```text
parallel worker swarm
background autonomous execution
unapproved cron creation
unapproved gateway changes
unapproved real profile mutation
unapproved native memory/session/Kanban cleanup
```

## Runes boundary convention

Hermes native memory, Hermes native Kanban, and Hermes Runes MD Wiki must stay separate.

```text
Hermes native memory
  Profile-local Hermes Agent capability.

Hermes native Kanban
  Hermes Agent task/workflow primitive.

Hermes Runes MD Wiki
  External governed Markdown knowledge layer accessed through runes-holder and runes shield.
```

Only runes-holder should operate the Runes Wiki governed path, and only after secretary-mediated user approval.

## Maintenance notes convention

A template may include a maintenance note section at the bottom.

Maintenance notes are for repository maintainers and should be marked so the profile can ignore them at runtime.

Recommended shape:

```text
## Maintenance Notes: <version> / <date>

This section is for maintainer tracking only.
The profile runtime should ignore this section and should not treat it as conversation behavior.
```

Use maintenance notes for:

```text
source of a behavior patch
version/date of tuning
summary of meaningful changes
format-only note for semantic freeze
```

Do not put secrets, real runtime logs, `.env` values, session dumps, cache dumps, or private credentials into maintenance notes.

## Summary

```text
This convention is repo-local.
SOUL.md templates should be readable and role-bounded.
Runtime handoff should be Traditional Chinese-first and compact.
Real Hermes runtime mutation requires explicit maintainer approval.
```