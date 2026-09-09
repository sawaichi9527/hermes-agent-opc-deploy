# OpenCode integration development track

> Branch: `dev/opencode-integration`
> Version baseline: `0.21.0-dev.1`
> Status: live OPC-PERSONAL migration design; design decisions are recorded here before remote implementation changes Freelancer/k6.

## 1. Purpose

This development track records the incremental design for introducing OpenCode capabilities into the **already deployed** OPC-PERSONAL Hermes Agent environment on Freelancer/k6.

This is **not** a greenfield 8-profile deployment plan. The OPC-PERSONAL 8-profile system is already implemented on the live Freelancer/k6 Hermes-Agent PC. The purpose of `0.21.0` is to evolve that existing deployment without weakening its Hermes-first architecture.

Primary architectural rules:

- **Hermes Agent remains the runtime owner and primary agent harness.**
- The existing OPC-PERSONAL 8-profile organization is the current live baseline.
- `0.21.0` is an incremental migration/refactor track, not a redeployment from zero.
- OpenCode may provide models or selected auxiliary capabilities, but must not silently replace Hermes orchestration.
- Any role rename/replacement must preserve the intended organizational function or explicitly document the new function.
- Later target/direction changes are updated on this branch before a separate OpenCode workstation remotely modifies Freelancer/k6.

## 2. Live Freelancer/k6 baseline

The OPC-PERSONAL deployment is already in use. Profile state observed during the 2026-09-09 discussion:

| Profile | Current model | Observed state | Current role |
|---|---|---|---|
| `aeon-builder` | `aeon` | stopped | specialized builder / execution role |
| `builder` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | normal build / code / test execution |
| `coordinator` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | orchestration, task decomposition, validation |
| `nim-researcher` | `ornith-1.5-35b-a3b` | stopped | NIM-oriented external/model research path |
| `researcher` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | general research and analysis |
| `runes-holder` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | rules / knowledge / governance role |
| `secretary` | `ornith-1.5-35b-a3b@q4_k_m` | running | Lark/Feishu user-facing entry point |
| `writer` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | documentation and writing |

This table is a live-state snapshot, not a guarantee of future state. Remote implementation must re-inspect the host before writes.

## 3. Why OpenCode is being considered now

The goal is not to make Freelancer/k6 an OpenCode-first machine. The goal is to improve selected Hermes roles while keeping the existing multi-profile Hermes organization authoritative.

Two candidate OpenCode capabilities were discussed:

### A. OpenCode Go API as an additional Hermes model/provider

Concept:

```text
Hermes profile
    -> OpenCode Go API
    -> selected model
    -> result returns to Hermes
```

Potential use:

- higher-quality or alternative reasoning
- second opinion / arbitration
- architecture review
- difficult diagnosis
- research tasks that benefit from a different model family

Characteristics:

- Hermes remains the agent harness.
- No local OpenCode CLI is required.
- Existing Hermes tools, profile rules, memory, governance and execution flow stay authoritative.
- OpenCode Go is a model/provider capability, not a worker framework.

### B. Local OpenCode CLI as a coding sub-agent

Concept:

```text
Hermes builder / aeon-builder
    -> terminal
    -> local `opencode run ...`
    -> OpenCode agent loop
    -> repo read/edit/test/build
```

Potential use:

- large-repository traversal
- code editing
- test/build/debug loops
- coding-agent execution

Characteristics:

- introduces a second agent harness beneath Hermes
- mainly benefits `builder` / `aeon-builder`
- can dilute the meaning of those Hermes profiles if it becomes the actual worker for most coding tasks
- adds another session/config/tool-policy layer to operate and debug

## 4. Current direction: Hermes-first, A before B

Because Freelancer/k6 remains a Hermes-Agent-first system, current preference is:

> **Evaluate OpenCode Go API first as a selective provider/role capability. Do not introduce local OpenCode CLI merely because it is available.**

Path B remains deferred unless real Hermes-native builder workloads show a measurable reason to add it.

Reasons:

1. OPC-PERSONAL already has dedicated `builder` and `aeon-builder` roles.
2. The current need is selective capability improvement, not replacement of the Hermes execution layer.
3. A provider-level integration preserves the existing runtime, tools, profile governance and session ownership.
4. A local OpenCode CLI would create Agent-Harness-under-Agent-Harness complexity for a relatively narrow subset of the eight roles.
5. The migration should change only the roles that gain clear operational value.

This is a current design preference, not a permanent ban on path B.

## 5. New candidate role migration: `nim-researcher` -> `opencode-researcher`

### 5.1 Motivation

The live OPC-PERSONAL blueprint includes `nim-researcher`, originally intended to exploit NVIDIA NIM as an external research/model path. In current operation, the maintainer has observed that the NVIDIA NIM model service is not sufficiently stable for the role to remain an attractive dedicated dependency.

Therefore `0.21.0-dev.1` introduces this candidate migration:

```text
current:
    nim-researcher
        -> NIM-oriented specialist path

candidate:
    opencode-researcher
        -> OpenCode Go-backed specialist research / second-opinion path
```

This is **not yet an approved live rename**. It is the main role-level design question for the next discussion/inspection phase.

### 5.2 Why replacement may be cleaner than adding a ninth profile

If `nim-researcher` is no longer operationally justified, adding `opencode-researcher` while keeping the old role would create profile sprawl:

```text
researcher
nim-researcher
opencode-researcher
```

Instead, a one-for-one replacement can keep OPC-PERSONAL at eight profiles:

```text
aeon-builder
builder
coordinator
opencode-researcher   # candidate replacement for nim-researcher
researcher
runes-holder
secretary
writer
```

This preserves the overall organization size while replacing an unreliable external model dependency with a more useful external reasoning role.

### 5.3 Candidate responsibility split

If approved, the intended distinction should remain clear:

| Role | Primary responsibility |
|---|---|
| `researcher` | general/default research using the normal Hermes/local path |
| `opencode-researcher` | explicit external second opinion, deeper reasoning, alternative-model research via OpenCode Go |
| `coordinator` | decides when escalation/cross-check is worthwhile; remains orchestration owner |

`opencode-researcher` should not become a generic substitute for every profile merely because its model is stronger or paid.

### 5.4 Questions that must be resolved before rename

- Does Hermes v0.20.x permit the desired OpenCode Go provider/model binding at profile scope?
- Should `opencode-researcher` always use OpenCode Go, or retain a local fallback path?
- What is the failure behavior under quota exhaustion / provider outage?
- Does coordinator explicitly dispatch to it, or can profiles invoke it through delegation?
- What spending/quota policy is acceptable?
- Which existing NIM-specific MoA behavior should be retired, retained elsewhere, or redesigned?
- Are any skills, cron jobs, Runes policies or degradation rules keyed to the literal `nim-researcher` name?

## 6. Migration impact surface for `nim-researcher`

A profile rename/replacement must not be implemented as a single directory rename. The remote implementer must scan all OPC-PERSONAL artifacts that can reference the old role.

At minimum inspect:

```text
- live Hermes profile definition / SOUL / AGENTS data
- editions/opc-personal profile templates
- docs/editions/opc-personal/nim-researcher-moa-profile.md
- scripts/setup-nim-moa-profile.sh
- skill allocation rules
- degradation / fallback matrices
- coordinator delegation/routing rules
- cron/jobs definitions
- Runes approval/governance references
- validation scripts that expect an exact 8-profile list
- README / setup documentation
- any session or profile-name keyed state on the live host
```

The migration design must decide for each dependency whether to:

1. rename it,
2. delete it,
3. preserve it under a more generic name, or
4. move its useful behavior to another role.

Do not preserve NIM-specific complexity by default if the reason for the role replacement is to reduce dependency on NIM.

## 7. OpenCode Go usage direction across the profile organization

Current working direction, subject to provider-capability inspection:

| Profile | OpenCode Go direction |
|---|---|
| `secretary` | avoid as a default; keep Lark entry/routing predictable |
| `coordinator` | possible for difficult arbitration/planning, but preserve orchestration independence |
| `researcher` | local/default general research path |
| `nim-researcher` | candidate for retirement |
| `opencode-researcher` | candidate dedicated OpenCode Go research/reasoning role |
| `writer` | optional; not a default dependency |
| `runes-holder` | local-first; external reasoning only for explicitly permitted difficult cases |
| `builder` | local/Hermes execution first; optional diagnosis only if later justified |
| `aeon-builder` | same principle as builder |

If `nim-researcher -> opencode-researcher` is approved, the total live profile count should remain eight unless a later decision explicitly changes the organization size.

## 8. Path B remains deferred

Local OpenCode CLI should be reconsidered only if measurable conditions appear, for example:

- repeated large-repository traversal is inefficient under Hermes-native builder flow
- edit/test/debug loops are materially less reliable than OpenCode on the same task class
- coding tasks consume disproportionate model context or tool-loop budget
- builder profiles become an observed operational bottleneck

If B is later approved, intended scope remains narrow:

- primary direct users: `builder`, `aeon-builder`
- `coordinator` may dispatch but should not normally become a repo editor
- other profiles should not receive unrestricted CLI access

## 9. Observed Node/npm environment for possible future path B

Observed on Freelancer/k6 on 2026-09-09:

```text
Node.js: v22.22.3
npm:     10.9.8
nvm:     0.40.3
node:    /home/eye/.nvm/versions/node/v22.22.3/bin/node
npm:     /home/eye/.nvm/versions/node/v22.22.3/bin/npm
prefix:  /home/eye/.nvm/versions/node/v22.22.3
```

If local OpenCode CLI is eventually approved, current preferred installation design is a user-owned dedicated npm prefix:

```bash
mkdir -p "$HOME/.local/opencode-cli"
npm install -g \
  --prefix "$HOME/.local/opencode-cli" \
  opencode-ai

"$HOME/.local/opencode-cli/bin/opencode" --version
```

Reasons:

- no `sudo`
- fixed path independent from the active NVM global package tree
- easy rollback/removal
- predictable absolute path for Hermes/systemd
- no need for OpenCode Desktop

This is reference-only. Do not install it as part of the current Go-provider/role migration unless path B is separately approved.

## 10. Development stages

### DEV-0 — design baseline (completed)

- recorded A/B alternatives
- recorded Hermes-first constraint
- created remote implementation handoff

### DEV-0.1 — live-baseline correction (`0.21.0-dev.1`)

Current stage.

- record that OPC-PERSONAL 8-profile is already deployed on Freelancer/k6
- reframe work as an incremental migration/refactor
- add `nim-researcher -> opencode-researcher` as a candidate role replacement
- keep local OpenCode CLI deferred

### DEV-1 — inspect live migration surface

Before functional change:

- verify live Hermes version and exact profile/config locations
- inspect the actual provider/model configuration schema
- verify OpenCode Go compatibility and profile/delegation scope
- inventory every live/repo reference to `nim-researcher`
- identify NIM-specific behavior that is still useful vs obsolete
- verify current fallback, restart and secret-loading mechanisms
- produce a concrete migration diff and rollback plan

Output: update this document with confirmed implementation facts.

### DEV-2 — OpenCode Go proof of capability

Before renaming the live profile, prove that the intended OpenCode Go path works in Hermes with the smallest reversible test.

Validation should cover:

- provider connection
- intended model selection
- scoped invocation semantics
- credential isolation
- failure / quota exhaustion behavior
- preservation of current local/default paths

Do not make a role rename depend on an unproven provider integration.

### DEV-3 — candidate `opencode-researcher` migration

If DEV-2 succeeds and the role design is approved:

- back up current `nim-researcher` live state
- migrate profile definition and routing deliberately
- retire or refactor NIM-specific MoA artifacts
- update exact-name validation/scripts/docs
- validate `researcher` vs `opencode-researcher` responsibility split
- verify coordinator routing and fallback
- verify secretary/Lark is unaffected

### DEV-4 — controlled expansion / optimization

After the role migration stabilizes:

- decide whether coordinator should also have direct OpenCode Go reasoning capability
- evaluate optional writer/builder diagnosis use only if justified
- measure quality, latency, quota consumption and operational complexity

### DEV-5 — decision gate for local OpenCode CLI

Only after enough live Hermes usage exists, decide one of:

1. **Go-provider integration is sufficient** — no local CLI.
2. **Add CLI only to builder-class roles** because measured coding execution benefits justify it.
3. **Use a tightly controlled hybrid** only if additional complexity has measurable value.

Current preference remains option 1 unless evidence supports another choice.

## 11. Success criteria

The `0.21.0` migration is successful only if capability improves without weakening the Hermes-first architecture.

Minimum criteria:

- Hermes remains runtime owner.
- the live OPC-PERSONAL organization remains coherent.
- if `nim-researcher` is replaced, total profile count remains eight unless explicitly redesigned.
- `researcher` and any `opencode-researcher` have non-overlapping, understandable responsibilities.
- existing local Ornith/AEON paths remain usable where intended.
- OpenCode failure/quota exhaustion does not collapse normal Hermes operation.
- NIM-specific artifacts are not left as broken/stale references after a rename.
- no secrets are committed to Git.
- every live migration step has a documented rollback.

## 12. Non-goals for the current dev track

Unless later explicitly approved:

- redeploying OPC-PERSONAL from scratch
- replacing Hermes profiles with OpenCode agents
- making local OpenCode CLI the default builder backend
- installing OpenCode Desktop on Freelancer/k6
- adding a ninth profile merely to keep a deprecated `nim-researcher`
- giving all profiles OpenCode Go by default
- storing OpenCode Go credentials in this repository
- introducing a new queue/router/daemon/orchestration layer outside Hermes

## 13. Change-control rule

1. Treat the live Freelancer/k6 OPC-PERSONAL system as the starting point.
2. Discuss target/direction changes first.
3. Update this dev document before implementation.
4. Keep candidate decisions explicitly marked unresolved until approved.
5. A separate OpenCode workstation performs the eventual remote inspection/change according to the handoff document.
6. Implementation reality that differs from this design must be written back into the dev branch instead of silently diverging.

This file is the primary migration design record for the `0.21.0` development track.
