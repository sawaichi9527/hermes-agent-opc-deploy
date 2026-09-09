# OpenCode integration development track

> Branch: `dev/opencode-integration`  
> Version baseline: `0.21.0-dev.2`  
> Status: live OPC-PERSONAL incremental migration design.

## 1. Purpose

Freelancer/k6 already runs the OPC-PERSONAL eight-profile Hermes Agent deployment. `0.21.0` is an **incremental migration/refactor**, not a greenfield deployment.

Primary rules:

- **Hermes Agent remains runtime owner and primary agent harness.**
- The existing OPC-PERSONAL organization remains the baseline.
- OpenCode Go is introduced selectively as a model/provider capability.
- Local OpenCode CLI remains deferred unless later evidence justifies a second coding-agent harness.
- Live implementation is performed later from a separate OpenCode workstation after this dev specification is accepted.

## 2. Current live baseline

Observed on 2026-09-09:

| Profile | Current model | Observed state | Role |
|---|---|---|---|
| `aeon-builder` | `aeon` | stopped | specialized builder/execution |
| `builder` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | normal build/code/test |
| `coordinator` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | orchestration/decomposition/validation |
| `nim-researcher` | `ornith-1.5-35b-a3b` | stopped | external/NIM research path |
| `researcher` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | general research |
| `runes-holder` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | rules/knowledge/governance |
| `secretary` | `ornith-1.5-35b-a3b@q4_k_m` | running | Lark/Feishu entry point |
| `writer` | `ornith-1.5-35b-a3b@q4_k_m` | stopped | documentation/writing |

The remote implementation must re-inspect the live host before any write.

## 3. OpenCode integration paths

### A. OpenCode Go API — current implementation direction

```text
Hermes profile
    -> OpenCode Go API
    -> selected model
    -> result returns to Hermes
```

Use cases:

- external reasoning / second opinion
- deeper research
- architecture review
- difficult diagnosis
- alternative model family when local Ornith/AEON is insufficient

This preserves Hermes tools, profile rules, memory, governance and session ownership.

### B. Local OpenCode CLI — deferred

```text
Hermes builder / aeon-builder
    -> terminal
    -> opencode run ...
    -> OpenCode coding-agent loop
```

Potential benefit is repo traversal/edit/test/debug, but it introduces a second agent harness under Hermes and mainly benefits two of eight profiles. It is not part of the current Go/researcher migration.

## 4. Approved maintainer direction: replace `nim-researcher`

For the **maintainer's live Freelancer/k6 deployment**, the design decision is now:

> `nim-researcher` will be replaced one-for-one by `opencode-researcher` if the OpenCode Go proof-of-capability succeeds.

Reason: NVIDIA NIM model service has not been sufficiently stable in the maintainer environment to justify a dedicated live profile dependency.

Target live organization remains eight profiles:

```text
aeon-builder
builder
coordinator
opencode-researcher
researcher
runes-holder
secretary
writer
```

This is a replacement, not a ninth profile.

## 5. Repository flexibility: external-researcher slot

The repo must remain useful to fork users whose NVIDIA NIM environment is stable. Therefore the repository policy is **not** to remove `nim-researcher` support.

Instead, the fourth research-oriented specialist position is treated as one configurable **external-researcher slot** with mutually exclusive variants:

| Deployment | External-researcher variant | Status |
|---|---|---|
| Maintainer / Freelancer-k6 | `opencode-researcher` | new default target for 0.21.0 |
| Optional fork deployment | `nim-researcher` | retained supported option |

Detailed policy: `docs/editions/opc-personal/external-researcher-variants.md`.

Important distinction:

- **Live Freelancer cleanup:** NIM-specific runtime dependencies can be removed from the maintainer host when no longer needed.
- **Repository cleanup:** valid NIM templates/docs/scripts must not be deleted merely because the maintainer switched provider.

A fork user should still be able to deploy an eight-profile OPC-PERSONAL layout using `nim-researcher` without recovering files from Git history.

## 6. Responsibility split

### `researcher`

- default/general research
- local/Hermes-native path first
- lower operational dependency and cost

### `opencode-researcher` — maintainer default external variant

- explicit external second opinion
- deeper/alternative-model reasoning through OpenCode Go
- cross-check difficult technical conclusions
- not a generic replacement for every profile

### `nim-researcher` — optional fork variant

- same organizational external-researcher slot
- NVIDIA NIM-backed research path
- may retain NIM-specific MoA behavior for users who want it
- must not be a dependency of the OpenCode variant

### `coordinator`

- remains orchestration owner
- decides when escalation/cross-check is worthwhile
- should not silently route all work to paid external reasoning

## 7. Migration impact surface

The remote implementer must inventory all current references to `nim-researcher`, including at minimum:

```text
- live profile definition / SOUL / AGENTS data
- editions/opc-personal templates
- docs/editions/opc-personal/nim-researcher-moa-profile.md
- scripts/setup-nim-moa-profile.sh
- skill allocation
- degradation/fallback matrices
- coordinator routing/delegation
- cron/jobs
- Runes governance/approval references
- exact profile-list validation scripts
- README/setup/reinstall documentation
- profile-name keyed live state
```

Every artifact must be classified along **two axes**:

### Live Freelancer/k6 action

```text
KEEP
RENAME
REFACTOR
REMOVE
```

### Repository support action

```text
SHARED          provider-agnostic, reuse in both variants
OPENCODE        belongs only to opencode-researcher
NIM-OPTIONAL    retain for fork users choosing nim-researcher
OBSOLETE        genuinely no longer useful to any supported variant
```

Do not confuse removing a NIM dependency from the live maintainer host with removing NIM support from the repository.

## 8. Provider and fallback questions to confirm remotely

Before live migration:

- exact Hermes version and provider schema
- whether OpenCode Go can bind per profile or via delegation
- OpenCode Go model identifier and authentication mechanism
- credential placement and permissions
- quota/rate-limit failure behavior
- reload/restart semantics
- whether `opencode-researcher` should have a local fallback or fail visibly back to coordinator
- how coordinator selects the external-researcher slot
- how variant choice should be represented in repo deploy/verify scripts

Secrets must never be committed.

## 9. Current OpenCode Go usage direction across profiles

| Profile | Direction |
|---|---|
| `secretary` | local/default; avoid routine paid external reasoning |
| `coordinator` | possible later for difficult arbitration, not first rollout |
| `researcher` | general local/default research |
| `opencode-researcher` | **dedicated OpenCode Go external research role** |
| `nim-researcher` | optional repo/fork variant, not maintainer live target |
| `writer` | optional later; not default dependency |
| `runes-holder` | local-first |
| `builder` | Hermes-native execution first |
| `aeon-builder` | Hermes-native execution first |

Only one of `opencode-researcher` or `nim-researcher` is active in an eight-profile OPC-PERSONAL deployment.

## 10. Deferred local OpenCode CLI reference

Observed Freelancer environment:

```text
Node.js: v22.22.3
npm:     10.9.8
nvm:     0.40.3
node:    /home/eye/.nvm/versions/node/v22.22.3/bin/node
npm:     /home/eye/.nvm/versions/node/v22.22.3/bin/npm
prefix:  /home/eye/.nvm/versions/node/v22.22.3
```

If path B is separately approved in the future, preferred installation layout remains:

```bash
mkdir -p "$HOME/.local/opencode-cli"
npm install -g \
  --prefix "$HOME/.local/opencode-cli" \
  opencode-ai

"$HOME/.local/opencode-cli/bin/opencode" --version
```

This is reference-only for the current migration.

## 11. Development stages

### DEV-0 — design baseline

Completed: A/B alternatives, Hermes-first rule, remote handoff.

### DEV-0.1 — live-baseline correction

Completed in `0.21.0-dev.1`: OPC-PERSONAL already deployed; migration/refactor framing; initial replacement proposal.

### DEV-0.2 — external-researcher variant decision

Current stage, `0.21.0-dev.2`:

- maintainer live target approves `nim-researcher -> opencode-researcher` replacement subject to provider proof
- maintain eight active profiles
- retain `nim-researcher` as optional repo/fork deployment variant
- define the mutually exclusive external-researcher slot
- prohibit accidental deletion of valid NIM deployment assets during maintainer migration

### DEV-1 — inspect live migration surface

Remote workstation must:

- verify Hermes/config/provider facts
- inventory every live/repo `nim-researcher` dependency
- classify artifacts by live action and repo support action
- confirm OpenCode Go integration mechanism
- propose exact migration diff, validation and rollback

### DEV-2 — OpenCode Go proof of capability

Before renaming the live role, prove:

- authentication
- intended model selection
- intended profile/delegation scope
- credential isolation
- quota/provider failure behavior
- preservation of unaffected local paths
- rollback

### DEV-3 — maintainer role migration

After DEV-2 and maintainer approval:

- back up live `nim-researcher`
- create/migrate `opencode-researcher`
- update coordinator routing and relevant policies
- remove/refactor NIM-specific dependencies from the **live maintainer deployment**
- keep NIM variant assets in the repo
- update exact-name validation to support the selected external-researcher variant
- validate total active profile count = 8

### DEV-4 — repository variant hardening

- make OpenCode the OPC-PERSONAL maintainer default
- keep NIM as an explicit optional variant for fork users
- separate provider-specific setup/docs cleanly
- update reinstall/deploy/verify behavior so variant selection is intentional
- ensure the unselected provider is not a runtime dependency

### DEV-5 — controlled expansion

Only after the researcher migration stabilizes:

- decide whether coordinator benefits from direct OpenCode Go reasoning
- optionally evaluate writer/builder diagnosis
- measure quality, latency, quota consumption and operational complexity

### DEV-6 — local OpenCode CLI gate

Only then decide whether local CLI adds enough coding value to justify a second agent harness.

## 12. Success criteria

For maintainer Freelancer/k6:

- Hermes remains runtime owner
- active profile count remains eight
- `opencode-researcher` replaces `nim-researcher`
- live OpenCode researcher does not depend on NVIDIA NIM
- `researcher` and `opencode-researcher` have clear non-overlapping responsibilities
- secretary/Lark remains stable
- local Ornith/AEON paths remain available where intended
- provider/quota failure does not corrupt Hermes state
- rollback is documented and usable

For repository/fork flexibility:

- `nim-researcher` deployment assets remain available and coherent
- OpenCode and NIM variants are mutually exclusive, not additive ninth profiles
- selecting OpenCode does not require NIM
- selecting NIM does not require OpenCode Go
- validation/reinstall can eventually express the selected variant
- no secrets are stored in Git

## 13. Non-goals

Unless later approved:

- removing NIM support from the repository solely because the maintainer does not use it
- running both `nim-researcher` and `opencode-researcher` in the same default eight-profile deployment
- adding a ninth profile for provider redundancy
- replacing Hermes orchestration with OpenCode
- installing OpenCode Desktop
- making local OpenCode CLI the default builder backend
- giving every profile OpenCode Go by default
- storing provider credentials in this repo

## 14. Change control

1. Treat live Freelancer/k6 as the starting point.
2. Discuss design changes first.
3. Update this dev branch before implementation.
4. Remote implementation must inspect before edit and preserve rollback.
5. Maintain a strict distinction between **maintainer live defaults** and **repo-supported optional variants**.
6. Implementation findings that contradict this design must be written back into the branch before continuing.

This file is the primary migration design record for `0.21.0`.
