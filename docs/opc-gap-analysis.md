# OPC Gap Analysis Against Current Hermes Agent Official Capabilities

Status: draft  
Scope: maintainer personal-use baseline  
Hermes compatibility baseline: follow repo compatibility matrix  

This document records the gap between the original OPC concept documents and the current plan for using Hermes Agent official profiles as the implementation base.

The goal is not to reject Hermes Agent official design. The goal is to clearly mark what is already covered by upstream Hermes, what remains a usage convention in this repository, and what may need light customization later after the main baseline is stable.

## Current baseline decision

This repository does not create a parallel OPC runtime.

The baseline is:

```text
Hermes official profiles
  = runtime isolation, profile identity, per-profile memory/config/sessions/skills

OPC
  = a usage pattern over official Hermes profiles

hermes-agent-opc-deploy
  = deployment companion, profile templates, policy docs, simulation-first scripts
```

Maintainer standard profiles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

External model review is handled first by temporary consult subagents, not long-lived consult profiles.

## Gap summary

| Area | Original OPC expectation | Current Hermes-profile baseline | Gap / risk | Later customization candidate |
|---|---|---|---|---|
| Profile separation | Long-lived role members with SOUL / memory / config | Covered by official profiles | Mostly covered | Profile templates and deployment checks |
| Secretary intake | User-facing secretary / VP-like intake layer | Maintainer baseline adds `secretary` profile | Custom maintainer policy, not upstream default OPC role | Secretary SOUL / Lark handoff template |
| Coordinator routing | Coordinator routes, merges, checks boundaries | Partly covered by profile + possible Kanban/orchestrator usage | Needs local convention for when to use Kanban, delegate_task, or direct response | Coordinator routing playbook |
| Researcher / Writer / Builder roles | Stable worker roles | Covered structurally by profiles | Need role purity and handoff format rules | SOUL templates and worker checklist |
| Runes Holder | Memory sedimentation gate | Custom profile, external to upstream Hermes | Not upstream concept | Runes-holder SOUL and runes pickup checklist |
| Project workspace | Project work lives in project workspace | Covered by Hermes `terminal.cwd` concept, but must be configured | Profiles are not sandboxes; cwd is separate from profile identity | Deploy script should set/verify cwd intentionally |
| Shared task board | Durable team queue / task lifecycle | Hermes Kanban appears to cover much of this | Need adoption decision; not yet deployed | Kanban baseline after profile templates stabilize |
| Inter-agent comments | Agents report progress and handoff via shared thread | Kanban comments/complete/block/heartbeat can cover this | Need maintainer policy for required comments/heartbeat | Office-loop policy and templates |
| Stuck worker handling | Detect stuck role, escalate, resume | Kanban has block/heartbeat/dispatcher behavior; subagents have heartbeat/inactivity behavior | Need local escalation policy | Block reasons, retry budget, secretary notification |
| Long-running durability | Survive interrupts/restarts | Kanban supports durable task board; delegate_task is not durable | Need decision matrix | Use Kanban for cross-profile durable work; delegate_task for short consult |
| Cross-profile memory sharing | Team learns from results | Official profiles isolate memory; Kanban provides durable task history; runes provides optional sedimentation | Memory sharing is not automatic and should not be forced | Runes-holder review, selective sedimentation |
| Self-evolution feeling | Closed-loop learning and improvement | Partially possible through Kanban, memory, sessions, profile-specific memories, and runes pickup | Needs governance to avoid memory pollution | Weekly review / runes-holder summary later |
| Assets/raw/archive/inbox | Original OPC workspace layers | Not part of runes wiki baseline | Avoid moving runtime workspace into runes | Keep these in project workspace or Hermes/Kanban attachments, not runes |

## What is already covered well by Hermes official capabilities

### Official profiles

Official profiles provide the correct base for long-lived roles. Each profile can have its own identity, config, API keys, memory, sessions, skills, cron jobs, and state. This maps well to the OPC concept of long-lived role members.

This means the repository should not implement its own profile runtime.

### `delegate_task` for temporary subagents

Temporary consult or scoped subtasks should start as delegated subagents rather than official profiles. This matches the maintainer design for `consult-*` second opinions.

Use this for:

```text
consult-researcher style second opinion
consult-writer style alternate wording review
consult-builder style high-risk implementation review
```

Do not give these long-term identity unless repeated usage proves it is needed.

### Kanban for durable cross-profile work

The Hermes Kanban feature is much closer to the original OPC team workflow than plain profile commands alone. It provides a durable task board, task state, comments, assignees, blocking, heartbeat, parent-child dependencies, and worker spawning by profile.

This means future OPC enhancement should evaluate Kanban before building custom queue/state logic.

## What remains not fully satisfied

### 1. Original OPC has stronger team-office semantics than profiles alone

Profiles alone provide identity isolation, but not necessarily a full office loop.

A full office loop needs:

```text
intake
triage
assignment
progress update
blocking / escalation
handoff
review
closure
learning / sedimentation
```

Hermes profiles are the role containers. They are not by themselves a complete team process.

### 2. Lark bot is not the secretary profile

Lark bot is only the channel adapter. The maintainer baseline requires a `secretary` profile as the user-facing intake and preference adapter.

```text
User -> Lark bot -> secretary -> coordinator
```

This avoids polluting coordinator/researcher/writer/builder with personal formatting preferences or joke style.

### 3. Runes-holder is outside upstream Hermes concepts

`runes-holder` is a maintainer-specific profile that decides whether knowledge should be solidified into hermes-runes-md-wiki. This is intentionally outside Hermes Agent core and must remain optional to Hermes runtime.

### 4. Memory sharing should be governed, not automatic

Profiles have their own memory. That is good for role purity.

The missing piece is not “make all profiles share memory.” The desired policy is:

```text
profile memory = role-local learning
Kanban task history = operational handoff/history
runes = selected portable long-term sedimentation
```

## Later customization candidates

These are not immediate implementation goals. They are marked for future consideration after the main profile baseline is stable.

1. Coordinator routing playbook: when to answer directly, when to create Kanban tasks, when to delegate a consult subagent.
2. Secretary intake template for Lark messages.
3. Required worker progress contract: heartbeat/comment/block/complete expectations.
4. Runes-holder sedimentation checklist.
5. Simulation scripts for Kanban-like workflow without touching real `~/.hermes`.
6. Deployment scripts that use official Hermes commands first, then apply small customizations.

## Non-goals

This repository should not:

- Fork Hermes Agent.
- Reimplement official profiles.
- Create `~/.hermes/opc/profiles` as a parallel runtime.
- Move project work into this repository.
- Make hermes-runes-md-wiki required for Hermes Agent or OPC operation.
- Treat consult subagents as official profiles before repeated usage justifies it.
