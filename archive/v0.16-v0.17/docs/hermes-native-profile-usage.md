# Hermes-native profile usage

This document records the intended Hermes-native usage path for the OPC profile set.

The repository should not become the day-to-day runtime. Hermes Agent native profile commands remain the operating interface.

## Main rule

```text
Use Hermes Agent native profiles first.
Use this repository to curate profile guidance and small policy docs.
Do not replace Hermes Agent profile support with custom deployment scripts.
```

## Profile set

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Each profile should exist as a Hermes-native profile under the local Hermes profile home.

## Basic checks

Use native profile show commands to inspect profile state:

```bash
hermes profile show secretary
hermes profile show coordinator
hermes profile show researcher
hermes profile show writer
hermes profile show builder
hermes profile show runes-holder
```

These checks are read-only profile status checks.

## Targeting a profile

Use Hermes-native profile targeting when invoking a profile.

Examples:

```bash
hermes -p secretary chat -q "請用繁體中文簡短回覆：secretary-ok"
hermes -p coordinator chat -q "請用繁體中文簡短回覆：coordinator-ok"
```

For real work, only one profile call should be active at a time.

## Lark-facing runtime

Only `secretary` should be treated as the Lark-facing profile by default.

Expected ingress:

```text
Lark bot -> profile/secretary
```

Gateway check:

```bash
hermes -p secretary gateway status
```

Gateway start / restart / cutover is not part of default verification and requires explicit maintainer approval.

Worker profiles should not run gateways by default.

## Sequential handoff practice

When a task needs another profile, the current profile should produce a compact handoff packet rather than starting parallel work.

Recommended handoff packet:

```text
目的:
必要背景:
需要處理的問題:
可用來源:
輸出格式:
限制:
```

The next profile should return a compact result. Secretary or coordinator then decides the next step.

## Language use

SOUL.md authoring language and runtime handoff language are different concerns.

```text
SOUL.md authoring:
- secretary: Traditional Chinese / English mixed
- runes-holder: Traditional Chinese / English mixed
- coordinator / researcher / writer / builder: English-first role definitions

Runtime inter-profile communication:
- Traditional Chinese first
- preserve exact technical terms, commands, paths, filenames, API names, error messages, and source identifiers
```

## Native memory and Kanban

Hermes Agent native memory is available to profiles as a Hermes-native capability.

```text
Each profile may use its own native memory.
runes-holder does not control other profiles' native memory.
```

Hermes Agent native Kanban is also separate from Hermes Runes MD Wiki.

Do not describe Hermes native memory or native Kanban as `wiki` operations.

## Runes Wiki operations

`hermes-runes-md-wiki/wiki` is an external governed Markdown knowledge layer.

Only `runes-holder` should interact with that layer through runes shield in the OPC workflow.

Governed write flow:

```text
profile detects durable Runes Wiki candidate
  -> secretary asks user for approval
  -> user approves
  -> secretary instructs runes-holder
  -> runes-holder invokes runes shield
```

Runes Wiki retrieval flow:

```text
requesting profile asks runes-holder for Runes Wiki context
  -> runes-holder retrieves and summarizes wiki-derived context
  -> requesting profile validates against appropriate sources
```

## Commands that require approval

Do not run these as part of default verification:

```bash
hermes profile use <profile>
hermes profile alias <profile>
hermes profile install <source> --name <profile> --force
hermes profile update <profile>
hermes -p secretary gateway start
hermes -p secretary gateway restart
```

These commands can alter runtime behavior, sticky profile state, aliases, installed profile files, or live gateway behavior.

## Default repository validation

Default repo validation remains minimal:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
git status --short
```

No simulation deploy, profile install, gateway start, memory reset, session reset, Kanban reset, or Lark cutover should happen without explicit maintainer approval.

## Summary

```text
Hermes Agent native profiles are the operating layer.
secretary is the Lark-facing entrypoint.
worker profiles are called sequentially.
runes-holder is the Runes Wiki bridge, not a truth oracle.
this repository is guidance/template customization, not a runtime framework.
```
