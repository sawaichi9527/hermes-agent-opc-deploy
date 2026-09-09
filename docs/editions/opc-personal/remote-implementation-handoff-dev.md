# Remote implementation handoff — OpenCode workstation -> Freelancer/k6

> Development branch: `dev/opencode-integration`
> Version baseline: `0.21.0-dev.1`
> Status: pre-implementation handoff for an **already deployed** OPC-PERSONAL 8-profile Hermes system.

## 1. Purpose

This file is the handoff contract for a later implementation phase in which a separate workstation running OpenCode remotely inspects and modifies the live Freelancer/k6 Hermes Agent PC.

Important baseline correction:

- OPC-PERSONAL is **already deployed** on Freelancer/k6.
- The remote task is an incremental migration/refactor, not an initial 8-profile deployment.
- The external OpenCode workstation is an implementation console only.
- Hermes Agent on Freelancer/k6 remains the runtime owner.

## 2. Source-of-truth order

Before touching the live host, read in order:

1. repository `README.md`
2. `VERSION`
3. `docs/editions/opc-personal/opencode-integration-dev.md`
4. this file
5. existing OPC-PERSONAL deployment/safety documents and scripts relevant to affected profiles

If this handoff conflicts with a later decision in `opencode-integration-dev.md`, the design file wins.

## 3. Current migration target

Current direction for `0.21.0-dev.1`:

- preserve Hermes-first architecture
- evaluate OpenCode Go as a selective Hermes model/provider capability
- keep local OpenCode CLI deferred
- inspect whether `nim-researcher` should be replaced by `opencode-researcher`
- do not add a ninth profile merely to avoid deciding the fate of `nim-researcher`
- preserve the live eight-profile organization unless a later explicit decision changes it

Candidate target organization if the replacement is approved:

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

This candidate is **not yet approval to rename the live profile**.

## 4. Remote implementation principles

The remote OpenCode workstation must:

- inspect before edit
- treat live Freelancer/k6 state as authoritative
- create backups before every live configuration/profile change
- make the smallest reversible change first
- avoid changing all profiles together
- prove OpenCode Go provider behavior before making a role migration depend on it
- keep secretary/Lark user-facing flow stable
- never expose API keys in Git, committed transcripts, screenshots, generated docs or test artifacts
- not replace Hermes orchestration with OpenCode orchestration
- not introduce another daemon/router/queue without a later explicit design decision
- document implementation reality back into the dev branch

## 5. Required live-host discovery before writes

Collect and report at minimum:

```text
- OS / hostname / active user
- Hermes Agent version
- Hermes executable / installation path
- complete current profile list and exact model mapping
- running profile(s)
- profile definition / SOUL / AGENTS locations
- relevant Hermes config paths
- actual provider/model configuration schema supported by installed Hermes
- whether provider/model selection is global, per-profile, delegated-task scoped, or another mechanism
- current systemd/user-service units, if any
- current secret-loading mechanism and permissions
- current backup/restore mechanism
- current Git checkout state
```

Also specifically inventory all references to `nim-researcher` on the live host and in the repo checkout.

## 6. Expected live baseline to verify

Current expected eight profiles:

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

Model mapping observed on 2026-09-09:

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

## 7. Required `nim-researcher` dependency scan

Do not implement the candidate rename as a single file/directory rename.

Inspect at least:

```text
- live nim-researcher profile definition
- profile SOUL / AGENTS content
- editions/opc-personal templates
- docs/editions/opc-personal/nim-researcher-moa-profile.md
- scripts/setup-nim-moa-profile.sh
- skill allocation
- degradation/fallback rules
- coordinator routing/delegation
- cron/jobs references
- Runes governance/approval references
- validation scripts that enumerate exact profile names
- README/setup/reinstall documentation
- any session/state keyed by profile name
```

For every NIM-specific artifact, classify it as:

```text
KEEP     useful and provider-agnostic
RENAME   useful but role name must change
REFACTOR useful behavior belongs in a generic/OpenCode design
REMOVE   obsolete because dedicated NIM dependency is being retired
```

Return this inventory to the dev branch before destructive cleanup.

## 8. DEV-1 deliverable: migration discovery report

The first remote session should preferably make no role rename.

Expected report:

- confirmed live Hermes/version/config facts
- exact OpenCode Go integration mechanism supported by the installed Hermes version
- credential placement method
- fallback/reload/restart behavior
- full `nim-researcher` impact inventory
- which NIM-specific functions are still worth preserving
- proposed responsibility boundary between `researcher` and candidate `opencode-researcher`
- smallest OpenCode Go proof-of-capability diff
- complete rollback commands

Update `opencode-integration-dev.md` with confirmed facts before progressing.

## 9. DEV-2: prove OpenCode Go before role replacement

The provider path must work independently before the profile migration is tied to it.

Validate:

```text
[ ] OpenCode Go provider authenticates successfully
[ ] intended model is selectable in the required Hermes scope
[ ] an explicit test invocation returns normally
[ ] local/default model path remains usable
[ ] provider failure is observable
[ ] quota/rate-limit behavior is understood
[ ] secret is not exposed in repo/log artifacts
[ ] restart/reload semantics are understood
[ ] rollback restores original behavior
```

Avoid changing `secretary` during this proof unless strictly necessary.

## 10. DEV-3: candidate `nim-researcher -> opencode-researcher` migration

Only proceed after DEV-2 succeeds and the maintainer approves the role design.

Required order:

1. back up all affected live profile/config files
2. record the old `nim-researcher` model/provider/routing state
3. migrate the role definition deliberately
4. update coordinator routing/delegation references
5. update relevant skills/policies/validation rules
6. retire/refactor NIM-specific MoA pieces according to the dependency inventory
7. preserve useful provider-agnostic behavior
8. verify profile count and profile discovery
9. verify `researcher` and `opencode-researcher` have distinct responsibilities
10. verify secretary/Lark and unrelated profiles are unchanged

Do not leave stale `nim-researcher` references that make reinstall/validation disagree with the live host.

## 11. Post-change validation checklist

After each live change:

```text
[ ] affected profile starts successfully
[ ] secretary/Lark path still works
[ ] unrelated profiles retain their prior mapping
[ ] profile list matches the intended eight-role organization
[ ] local/default model path still works where intended
[ ] OpenCode Go path works where explicitly configured
[ ] provider failure does not corrupt Hermes profile state
[ ] coordinator routing still behaves as designed
[ ] researcher/opencode-researcher responsibilities are distinguishable
[ ] no stale NIM-only dependency breaks validation or reinstall scripts
[ ] secrets are absent from Git diff
[ ] backup exists
[ ] rollback is tested or directly executable
```

## 12. Rollback expectation

Every applied migration step must have same-session rollback.

Preferred pattern:

1. stop/reload only affected Hermes component if required
2. restore backed-up profile/config state
3. restore the original profile name/routing if a rename was attempted
4. restart/reload
5. verify original Ornith/AEON/NIM mapping as appropriate
6. verify secretary/Lark
7. record rollback result

Do not rely only on `git revert` for live files outside the repository.

## 13. Deferred path B: local OpenCode CLI

Do not install local OpenCode CLI merely as part of the OpenCode Go / researcher migration.

Current observed Node environment is retained for a possible later decision:

```text
Node.js v22.22.3
npm 10.9.8
nvm 0.40.3
```

If path B is separately approved later, preferred installation layout remains:

```bash
mkdir -p "$HOME/.local/opencode-cli"
npm install -g --prefix "$HOME/.local/opencode-cli" opencode-ai
"$HOME/.local/opencode-cli/bin/opencode" --version
```

Intended CLI scope remains primarily `builder` / `aeon-builder`.

This section is reference-only for the current migration.

## 14. Commit discipline

When the remote OpenCode workstation makes repo changes:

- use `dev/opencode-integration`
- keep commits small and purpose-specific
- never commit credentials/live-host private data
- update design docs when implementation reality differs from assumptions
- distinguish provider proof, role migration, cleanup and validation commits

Suggested categories:

```text
docs(dev): ...
chore(dev): ...
feat(opencode-go): ...
refactor(profile): ...
fix(opencode-go): ...
test(opencode-go): ...
```

## 15. Promotion gate to stable

Do not merge into `main` merely because OpenCode Go can connect.

Promotion requires:

- successful controlled provider proof
- approved final role organization
- successful role migration if `opencode-researcher` is adopted
- no stale NIM-specific deployment references
- validated rollback
- no secretary/Lark regression
- acceptable quota/cost, latency and reliability
- repo documentation/scripts matching the actual live deployment
- explicit maintainer decision that `0.21.0` is ready

Until then, `main` / `0.20.1` remains the stable source and this branch remains the evolving migration specification.
