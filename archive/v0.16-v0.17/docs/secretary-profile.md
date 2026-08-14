# Secretary Profile

## Status

For the maintainer's Lark-first OPC usage, `secretary` is a **standard profile**, not an optional sixth profile.

For other users or forks, `secretary` can still be treated as an optional extension profile. This repository, however, records the maintainer baseline where Lark is expected to become the primary operating interface after OPC-style profile usage is enabled.

## Problem

Before OPC-style profile usage, Lark can send requests directly to the default Hermes Agent identity:

```text
User -> Lark bot -> default Hermes Agent
```

After OPC-style profile usage, sending every request directly to `coordinator` would make the coordinator absorb user-facing preferences, personal communication style, answer format preferences, and playful or noisy request patterns.

That weakens the intended role purity of the core OPC worker profiles:

- `coordinator` should focus on task planning, routing, merge, and boundary control.
- `researcher` should focus on evidence, uncertainty, and source quality.
- `writer` should focus on structure, clarity, and audience-fit output.
- `builder` should focus on implementation, debugging, testing, and delivery.
- `runes-holder` should focus on whether something deserves durable runes sedimentation.

User-facing taste, response format preference, reminder style, and Lark-channel etiquette should not pollute these role-specific memories.

## Layering

Lark bot is not a coordinator.

```text
Lark bot
  Channel adapter / transport layer / message ingress and egress

secretary profile
  User-facing intake personality, preference adapter, and task handoff layer

coordinator profile
  Task planner, router, merger, and boundary checker
```

Recommended maintainer OPC-facing flow:

```text
User
  -> Lark bot
  -> secretary profile
  -> coordinator profile
  -> researcher / writer / builder / runes-holder
```

Simple one-agent flow remains valid before OPC deployment:

```text
User
  -> Lark bot
  -> default Hermes Agent
```

## Secretary responsibility

The secretary profile represents the maintainer-facing personal assistant layer. It may behave like a senior executive secretary, senior manager, or VP-style intake layer, but should stay lightweight for personal use.

The secretary may:

- receive user requests through Lark after message normalization;
- preserve the maintainer's preferred communication style and answer format;
- clarify ambiguous instructions before forwarding them;
- convert casual, messy, or playful user input into clean task briefs;
- decide whether a request should be handled directly or handed to `coordinator`;
- maintain user-facing preference memory without polluting worker profiles;
- keep Lark-specific etiquette and reminder style outside core task profiles;
- provide concise status updates back to the user.

The secretary should not:

- replace `coordinator` for project planning and routing;
- directly mutate project source files unless explicitly designed for a simple direct task;
- directly write to `hermes-runes-md-wiki`;
- own evidence validation, long-form writing, or build implementation as its primary role;
- become an enterprise workflow engine, ticket system, or approval platform.

## Secretary versus coordinator

| Concern | Secretary | Coordinator |
|---|---|---|
| Primary owner | User-facing intake | Task execution flow |
| Main question | What does the user want and how should it be framed? | How should the task be done and routed? |
| Memory type | User preference, response style, Lark etiquette | Planning, routing, merge, boundary patterns |
| Output | Clean request brief, clarification, status reply | Task plan, handoff, merged result, boundary warning |
| Risk if overloaded | Becomes a noisy personal bot | Worker role purity breaks |

## Personal-use boundary

Do not overbuild this profile.

For this repository, `secretary` should remain a small maintainer-specific profile template. It should not introduce enterprise features such as:

- org-wide approval chains;
- multi-user RBAC;
- ticket queues;
- SLA management;
- persistent business workflow automation;
- complex task database ownership.

The goal is simple:

```text
Protect OPC role purity while making Lark-based user interaction comfortable.
```

## Maintainer deployment baseline

The maintainer baseline contains six profiles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

For forks or other users, the minimal generic OPC set can still be documented as:

```text
coordinator
researcher
writer
builder
runes-holder
```

But for this repository's own deployment target, `secretary` is standard because Lark is expected to be the main operating interface.

## Relationship to Lark bot

Lark bot is the channel body.

`secretary` is the user-facing intake mind.

They should remain separate because the Lark integration may be replaced or supplemented later by Telegram, CLI, or Web UI while the secretary behavior remains reusable.

```text
Lark bot   ->\
Telegram   -> secretary -> coordinator
CLI        ->/
```

## Relationship to runes

The secretary may notice that a topic is potentially worth durable knowledge sedimentation, but it should not make the final runes decision.

It should ask or hand off to `runes-holder` when long-term Markdown sedimentation may be useful.

```text
secretary notices candidate
  -> coordinator or runes-holder
  -> runes-holder evaluates
  -> runes shield / human approval when applicable
```
