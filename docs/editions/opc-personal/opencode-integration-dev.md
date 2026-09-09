# OpenCode integration development track

> Branch: `dev/opencode-integration`
> Version baseline: `0.21.0-dev.0`
> Status: design / discussion only; no live Freelancer/k6 change is implied by this document.

## 1. Purpose

This development track records the current design discussion for adding OpenCode as an optional capability to the existing Freelancer/k6 Hermes Agent deployment.

The primary architectural rule remains unchanged:

- **Hermes Agent is the runtime owner and primary agent harness.**
- The existing 8 Hermes profile rules remain the main organization and execution model.
- OpenCode must not become a mandatory second orchestration layer unless later evidence shows a clear benefit.
- This branch is the working specification. Later design decisions and direction changes should be updated here before remote implementation begins.

## 2. Current Freelancer/k6 profile baseline

Observed profile set on 2026-09-09:

| Profile | Current model | Observed state | Current role in this design |
|---|---|---|---|
| `aeon-builder` | `aeon` | stopped | specialized builder / execution role |
| `builder` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | normal build / code / test execution |
| `coordinator` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | orchestration, task decomposition, validation |
| `nim-researcher` | `ornith-1.5-35b-a3b` | stopped | NIM / external technical research |
| `researcher` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | general research and analysis |
| `runes-holder` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | rules / knowledge / governance role |
| `secretary` | `ornith-1.5-35b-a3b@q4_k_m` | running | Lark/Feishu user-facing entry point |
| `writer` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | documentation and writing |

The 8-profile organization is the system to preserve. OpenCode is an optional capability underneath or beside selected profiles, not a ninth Hermes profile.

## 3. Two possible OpenCode integration paths

### A. OpenCode Go API as an additional model/provider

Concept:

```text
Hermes profile
    -> OpenCode Go API
    -> selected model
    -> result returns to Hermes
```

Role:

- additional reasoning / second opinion
- architecture review
- difficult diagnosis
- optional research or writing assistance

Characteristics:

- Hermes remains the only agent harness.
- No local OpenCode CLI is required.
- Existing Hermes tools, profile rules, memory, governance and execution flow remain authoritative.
- OpenCode Go should be treated as a model/provider capability, not a replacement runtime.

### B. Local OpenCode CLI as a coding sub-agent

Concept:

```text
Hermes builder / aeon-builder
    -> terminal
    -> local `opencode run ...`
    -> OpenCode agent loop
    -> repo read/edit/test/build
```

Role:

- repo traversal
- code editing
- test/build/debug loops
- coding-agent execution

Characteristics:

- introduces a second agent harness below Hermes
- is useful mainly to `builder` and `aeon-builder`
- can dilute the meaning of the existing Hermes builder profiles if overused
- adds another session/config/tool-policy layer that must be debugged and governed

## 4. Current direction: do not mix A and B by default

Because Freelancer/k6 is intended to remain a **Hermes-Agent-first** machine, the current preferred direction is:

> **Start with A only: OpenCode Go API as an optional reasoning provider. Do not install or depend on local OpenCode CLI in the first implementation phase.**

Reasoning:

1. The existing Hermes deployment already has dedicated `builder` and `aeon-builder` profiles.
2. Adding local OpenCode CLI immediately would create an Agent-Harness-under-Agent-Harness arrangement.
3. A-only preserves the current profile organization, tool ownership, session model and governance boundaries.
4. OpenCode can remain a consultant / reasoning source instead of becoming the worker that actually owns coding execution.
5. B can still be evaluated later if measured Hermes-native coding performance reveals a real bottleneck.

This is a **current design decision, not a permanent ban** on path B.

## 5. Intended use of path A across the 8 profiles

Initial policy direction:

| Profile | OpenCode Go usage direction |
|---|---|
| `secretary` | normally avoid; keep Lark entry/routing cheap and predictable |
| `coordinator` | suitable for difficult planning, arbitration, second-opinion reasoning |
| `researcher` | suitable for difficult technical analysis or cross-checking |
| `nim-researcher` | suitable when an additional reasoning source is useful |
| `writer` | optional for difficult refinement; not a default dependency |
| `runes-holder` | local-first; only use external reasoning for difficult rule conflicts if explicitly allowed |
| `builder` | local-first; OpenCode Go may assist diagnosis, but execution remains Hermes-owned |
| `aeon-builder` | local-first; same principle as builder |

The exact provider/model routing mechanism is intentionally **not hard-coded yet**. The remote implementer must first inspect the live Hermes v0.20.x configuration and supported provider/profile configuration schema before changing anything.

## 6. Path B remains a deferred option

Path B should be reconsidered only if one or more measurable conditions appear, for example:

- repeated large-repository traversal is inefficient under Hermes-native builder flow
- edit/test/debug loops are materially less reliable than OpenCode on the same task class
- coding tasks consume disproportionate model context or tool-loop budget
- builder profiles become the observed bottleneck in real workloads

If B is later approved, the intended scope is narrow:

- primary direct users: `builder`, `aeon-builder`
- `coordinator` may dispatch the task but should not normally become a direct repo editor
- other profiles should not receive unrestricted OpenCode CLI access

## 7. Observed Node/npm environment for possible future path B

Observed on Freelancer/k6 on 2026-09-09:

```text
Node.js: v22.22.3
npm:     10.9.8
nvm:     0.40.3
node:    /home/eye/.nvm/versions/node/v22.22.3/bin/node
npm:     /home/eye/.nvm/versions/node/v22.22.3/bin/npm
prefix:  /home/eye/.nvm/versions/node/v22.22.3
```

If local OpenCode CLI is eventually approved, the current preferred installation design is a user-owned dedicated npm prefix rather than a system-wide install:

```bash
mkdir -p "$HOME/.local/opencode-cli"
npm install -g \
  --prefix "$HOME/.local/opencode-cli" \
  opencode-ai

"$HOME/.local/opencode-cli/bin/opencode" --version
```

Reasons:

- no `sudo`
- fixed path independent from NVM's currently active global package tree
- easy removal / rollback
- easy for Hermes/systemd to invoke by absolute path
- does not require OpenCode Desktop

This is **reference-only in `0.21.0-dev.0`**. Do not install it during the A-only pilot.

## 8. Development stages

### DEV-0 — documentation baseline

Current stage.

- record A/B alternatives
- record 8-profile impact
- record current preferred A-only direction
- keep stable `main` untouched
- no live configuration changes on Freelancer/k6

### DEV-1 — inspect actual Hermes provider capability

Before implementation:

- verify live Hermes version
- inspect the actual provider/model configuration schema used by the deployment
- verify whether OpenCode Go can be configured per profile, through delegation, or only at another scope
- verify fallback behavior to the current Ornith/AEON models
- verify where API credentials are expected to live
- do not commit any real API key or secret

Output: update this document with the confirmed integration method.

### DEV-2 — smallest A-only pilot

Target:

- introduce OpenCode Go to the smallest practical subset of profiles
- prefer a non-user-facing reasoning profile first, subject to DEV-1 findings
- preserve current local model as fallback
- do not modify all 8 profiles at once
- do not introduce OpenCode CLI

Validation should cover:

- profile starts normally
- local/default path still works
- explicit OpenCode Go reasoning call works
- failure / quota exhaustion does not break the Hermes profile organization
- no secret is exposed in repo, logs or generated artifacts

### DEV-3 — controlled profile expansion

Only after DEV-2 succeeds:

- evaluate `coordinator`
- evaluate `researcher` / `nim-researcher`
- optionally evaluate `writer`
- keep `secretary` local-first
- keep builder execution Hermes-owned

Record quality, latency, quota consumption and operational complexity.

### DEV-4 — decision gate for local OpenCode CLI

After enough real Hermes usage exists, decide one of:

1. **A-only remains final** — OpenCode is a reasoning provider only.
2. **Replace A with B for coding use cases** — keep local reasoning primarily Hermes-native and add CLI only to builders.
3. **Allow a tightly controlled A+B hybrid** — only if measured benefit justifies the extra complexity.

The current preference is option 1 unless evidence supports another choice.

## 9. Success criteria

The OpenCode integration is successful only if it improves capability without weakening the Hermes-first architecture.

Minimum criteria:

- Hermes remains runtime owner.
- 8-profile rules remain authoritative.
- existing local Ornith/AEON path remains usable.
- OpenCode failure or quota exhaustion does not collapse normal Hermes operation.
- no secret is stored in Git.
- operational/debug complexity remains acceptable.
- any new dependency has a documented rollback procedure.

## 10. Non-goals for the current dev track

Not part of `0.21.0-dev.0` unless later explicitly approved:

- replacing Hermes profiles with OpenCode agents
- making OpenCode CLI the default builder backend
- installing OpenCode Desktop on Freelancer/k6
- giving all profiles direct shell access to OpenCode CLI
- auto-fallback from a free/local OpenCode worker into paid Go usage
- storing OpenCode Go credentials in this repository
- introducing a new queue/router/daemon/orchestration layer outside Hermes

## 11. Change-control rule for this dev branch

Until implementation begins:

1. Discuss target/direction changes first.
2. Update this dev document to reflect the latest decision.
3. Keep uncertain items explicitly marked as unresolved instead of silently assuming implementation details.
4. Only after the design is accepted should a remote OpenCode workstation modify the live Freelancer/k6 Hermes Agent PC.

This document is therefore both a design record and the primary pre-implementation specification for the `0.21.0` development track.
