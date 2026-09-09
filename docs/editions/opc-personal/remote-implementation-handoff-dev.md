# Remote implementation handoff — OpenCode workstation -> Freelancer/k6

> Development branch: `dev/opencode-integration`
> Version baseline: `0.21.0-dev.0`
> Status: pre-implementation handoff. Do not treat examples here as approval to modify the live host until the design track is accepted.

## 1. Purpose

This file is the handoff contract for the later implementation phase in which a separate workstation running OpenCode will remotely inspect and modify the Freelancer/k6 Hermes Agent PC.

The external OpenCode workstation is an **implementation console**, not the runtime owner. The live target remains Hermes Agent on Freelancer/k6.

## 2. Source-of-truth order

Before touching the live host, the remote implementer must read, in order:

1. repository `README.md`
2. `VERSION`
3. `docs/editions/opc-personal/opencode-integration-dev.md`
4. this file
5. relevant existing OPC-PERSONAL deployment/safety documents and scripts

If this handoff conflicts with `opencode-integration-dev.md`, the later design decision recorded in that design file wins.

## 3. Current implementation target

For `0.21.0-dev.0`, the current target is **A-only**:

- evaluate OpenCode Go as an optional Hermes reasoning/model provider
- keep Hermes Agent as the only agent harness/runtime owner
- retain the existing 8 profile rules
- retain Ornith/AEON as current local/default paths unless an explicitly approved profile-level change says otherwise
- do **not** install local OpenCode CLI on Freelancer/k6 during this phase
- do **not** install OpenCode Desktop

Path B (local OpenCode CLI as coding sub-agent) is deferred to a later decision gate.

## 4. Remote implementation principles

The remote OpenCode workstation must follow these rules:

- inspect before edit
- create backups before modifying live configuration
- make the smallest reversible change first
- do not roll out to all 8 profiles in one step
- do not expose API keys in Git, terminal transcripts committed to Git, screenshots, logs, generated docs or test artifacts
- do not replace Hermes orchestration with OpenCode orchestration
- do not introduce an extra daemon/router/queue unless a later design revision explicitly approves it
- preserve the existing rollback path

## 5. Required live-host discovery before any write

The remote implementer must first collect and report the live state of Freelancer/k6, including at minimum:

```text
- OS / hostname / active user
- Hermes Agent version
- Hermes executable / installation path
- current profile list and model mapping
- currently running profile(s)
- relevant Hermes config file paths
- provider/model configuration schema actually supported by the installed Hermes version
- systemd/user-service units involved, if any
- current secret-loading mechanism and file permissions
- current backup/restore mechanism
- Git checkout status if this repo already exists on the target
```

Known observations from the design discussion may be used as hints, but the live host is authoritative.

## 6. Known current profile baseline to verify

Expected 8 profiles:

```text
aeon-builder
builder
coordinator
nim-researcher
researcher
runes-holder
secretary
writer
```

Expected model mapping observed on 2026-09-09:

```text
aeon-builder    -> aeon
builder         -> ornith-1.5-35b-a3b@q4_k_m
coordinator     -> ornith-1.5-35b-a3b@q4_k_m
nim-researcher  -> ornith-1.5-35b-a3b
researcher      -> ornith-1.5-35b-a3b@q4_k_m
runes-holder    -> ornith-1.5-35b-a3b@q4_k_m
secretary       -> ornith-1.5-35b-a3b@q4_k_m
writer          -> ornith-1.5-35b-a3b@q4_k_m
```

Observed running state at discussion time: only `secretary` was running. Re-verify before implementation.

## 7. DEV-1 remote inspection deliverable

The first remote session should make **no functional provider change** unless the configuration mechanism is already unambiguous and explicitly approved.

Expected deliverable back to this repo:

- confirmed Hermes version
- exact config locations
- exact supported OpenCode/OpenAI-compatible provider mechanism, if any
- whether provider/model can be selected per profile, delegated task, or only globally
- credential placement method
- fallback behavior
- restart/reload requirement
- concrete diff proposed for the smallest pilot
- rollback commands

Update `opencode-integration-dev.md` with these confirmed facts before progressing to DEV-2.

## 8. DEV-2 smallest pilot rules

When the provider integration is confirmed, perform a minimal A-only pilot.

Preferred pilot characteristics:

- avoid changing `secretary` first because it is the Lark/Feishu user-facing gateway
- prefer a reasoning-oriented, non-user-facing profile if Hermes supports scoped model/provider configuration
- preserve the current local model path
- make paid/OpenCode Go usage explicit rather than silently automatic
- verify quota/failure behavior

The exact first profile is intentionally not fixed yet; it depends on the real Hermes configuration semantics discovered in DEV-1.

## 9. Validation checklist after each live change

At minimum:

```text
[ ] target profile starts successfully
[ ] secretary/Lark path still works
[ ] unchanged profiles retain prior model mapping
[ ] local/default model path still works
[ ] explicit OpenCode Go reasoning path works
[ ] provider failure is observable
[ ] quota/rate-limit failure does not corrupt profile state
[ ] restart/reload behavior is understood
[ ] secrets are absent from Git diff
[ ] backup exists and rollback is tested or clearly executable
```

Record evidence in a concise implementation note; do not commit secrets or large runtime logs.

## 10. Rollback expectation

Every applied change must have a same-session rollback method.

The preferred rollback pattern is:

1. stop/reload only the affected Hermes component if required
2. restore the backed-up config
3. restart/reload
4. verify original Ornith/AEON mapping
5. verify secretary gateway
6. record rollback result

Do not rely solely on `git revert` for files that live outside the repository.

## 11. Deferred path B: local OpenCode CLI

Do not implement this during the current A-only phase.

If a later design decision approves it, re-check the host first. The currently observed Node environment is:

```text
Node.js v22.22.3
npm 10.9.8
nvm 0.40.3
```

Current preferred future installation layout, if approved:

```bash
mkdir -p "$HOME/.local/opencode-cli"
npm install -g --prefix "$HOME/.local/opencode-cli" opencode-ai
"$HOME/.local/opencode-cli/bin/opencode" --version
```

Intended B scope would be limited primarily to `builder` and `aeon-builder`.

This section is reference-only and must not be interpreted as an installation instruction for `0.21.0-dev.0`.

## 12. Commit discipline during remote implementation

When the remote OpenCode workstation makes repo changes:

- work on `dev/opencode-integration`
- keep commits small and purpose-specific
- do not commit credentials or live-host private data
- update design docs when implementation reality differs from assumptions
- record implementation decisions rather than silently changing the target

Suggested commit categories:

```text
docs(dev): ...
chore(dev): ...
feat(opencode-go): ...
fix(opencode-go): ...
test(opencode-go): ...
```

## 13. Promotion gate to stable

Do not merge this development track into `main` merely because configuration can connect to OpenCode Go.

Promotion requires:

- successful controlled pilot
- validated rollback
- no regression to secretary/Lark operation
- acceptable quota/cost behavior
- acceptable latency and reliability
- documentation matching the actual deployed configuration
- explicit maintainer decision that `0.21.0` is ready

Until then, `main` / `0.20.1` remains the stable deployment source and this branch remains the evolving development specification.
