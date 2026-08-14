# Profile Interaction Loop

Status: draft  
Scope: maintainer personal-use baseline  

This document records how OPC profiles should interact horizontally and vertically without turning this repository into a parallel runtime.

The design goal is to get closer to an office-like stateful loop while staying aligned with Hermes Agent official primitives.

## Problem statement

Profiles alone provide role separation, but role separation is not the same as collaboration.

A practical OPC flow needs to answer:

- How does the user submit work?
- Who receives the work first?
- How is work routed?
- How does each role report progress?
- What happens when a role is blocked?
- How does another role review or continue the work?
- Where is durable state kept?
- What is learned after completion?

Without a durable interaction loop, the system becomes mostly stateless prompt chaining.

## Maintainer baseline flow

```text
User
  -> Lark bot
  -> secretary
  -> coordinator
  -> researcher / writer / builder / runes-holder
  -> consult subagent when needed
```

### Lark bot

Channel adapter only.

Responsibilities:

- Receive Lark messages.
- Verify/normalize incoming requests.
- Forward to Hermes entry profile.
- Return replies to Lark.

Non-responsibilities:

- It is not the coordinator.
- It is not a worker profile.
- It should not own long-term role memory.

### Secretary

User-facing intake profile and preference adapter.

Responsibilities:

- Convert informal user instructions into a clean task brief.
- Preserve the user's preferred answer format and interaction style.
- Filter jokes, shorthand, and personal quirks away from worker roles.
- Decide whether the request can be answered directly or should go to coordinator.

Non-responsibilities:

- Does not replace coordinator.
- Does not own technical execution.
- Does not directly mutate runes.

### Coordinator

Project-manager profile.

Responsibilities:

- Plan.
- Route.
- Merge.
- Boundary check.
- Ask for clarification when required.
- Decide whether work should use direct response, delegation, or durable Kanban tasking.

Non-responsibilities:

- Does not absorb personal user style.
- Does not do deep research or implementation by default.
- Does not write runes directly.

## Interaction primitives

### Direct profile response

Use for short, low-risk work that can be completed in one turn.

Example:

```text
secretary -> coordinator -> direct answer
```

### `delegate_task`

Use for temporary isolated subtasks.

Recommended for:

- consult-* second opinion
- short parallel research
- isolated file review
- context-heavy work that should not flood the parent profile context

Not recommended for:

- durable cross-profile handoff
- long-running work that must survive interruption
- work requiring human unblock or later pickup

### Kanban

Use for durable stateful cross-profile work.

Recommended for:

- tasks that cross profile boundaries
- work that should survive restarts or interrupts
- work that needs progress comments, blocking, retry, handoff, and audit trail
- office-like work loops

Kanban should be evaluated as the preferred official Hermes primitive for the full OPC loop.

## Worker progress contract

When a role is executing assigned work, it should eventually produce one of these outcomes:

```text
complete
blocked
needs-review
needs-consult
handoff
```

For a durable Kanban task, the desired contract is:

```text
start: read task context
progress: heartbeat or comment when work is long
blocked: block with reason and required input
handoff: comment or complete with structured summary
complete: summary + metadata
```

For non-Kanban direct work, the profile should still structure the response with:

```text
status
summary
what was checked
open questions
next action
```

## Blocked role handling

A role is considered blocked when:

- required input is missing
- source material is unavailable
- tool/API access fails
- model uncertainty is too high
- task boundary is unclear
- local model appears insufficient for the decision

Preferred handling:

```text
worker -> mark blocked / report reason
coordinator -> decide clarify / reroute / consult / split task
secretary -> ask user if human decision is needed
```

## Consult subagent handling

External model consults should be treated as temporary second opinion calls, not long-lived profiles by default.

A consult result should return:

- opinion summary
- disagreement or risk notes
- confidence level
- evidence gaps
- recommended follow-up

Coordinator remains responsible for deciding whether to accept or reject consult advice.

## Runes-holder interaction

Runes-holder is only called when a result may deserve portable long-term sedimentation.

Runes-holder should answer:

- Should this be remembered outside profile-local memory?
- Is it stable enough?
- Is it project-specific or reusable?
- Is it free from secrets and short-term noise?
- What runes workspace/path may be appropriate?

Runes-holder should not directly bypass the shield or mutate runes.

## State locations

| State type | Preferred location |
|---|---|
| One-agent native identity/memory | `~/.hermes` |
| Profile identity/memory | `~/.hermes/profiles/<profile>/` |
| Actual project work | `~/workspace/<project>/` |
| Durable task queue / handoff | Hermes Kanban, if adopted |
| Portable selected knowledge sedimentation | `hermes-runes-md-wiki/wiki/<slug>/` |
| Simulation-only development | `simulate_env/.hermes/` |

## Minimal personal-use policy

Do not introduce enterprise complexity unless repeated usage proves it is needed.

Start with:

1. secretary intake
2. coordinator routing
3. researcher/writer/builder execution
4. runes-holder optional sedimentation advice
5. consult subagent only when needed
6. Kanban evaluation before custom queue logic

Do not start with:

- custom distributed workflow engine
- parallel profile runtime
- database beyond official Hermes primitives
- mandatory runes dependency
- automatic cross-profile memory injection

## Open questions

These must be reviewed later:

1. Should the maintainer baseline adopt Hermes Kanban as the official stateful OPC loop?
2. What Kanban board naming should map to personal projects?
3. Should `secretary` or `coordinator` own Kanban task creation from Lark?
4. What progress comment frequency is enough without being noisy?
5. How should `runes-holder` learn from completed Kanban tasks without polluting runes?
