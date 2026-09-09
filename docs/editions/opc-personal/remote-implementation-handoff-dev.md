# Remote implementation handoff — OpenCode workstation -> Freelancer/k6

> Development branch: `dev/opencode-integration`  
> Version baseline: `0.21.0-dev.2`  
> Status: pre-implementation handoff for an already deployed OPC-PERSONAL Hermes system.

## 1. Purpose

A separate workstation running OpenCode will later remotely inspect and modify the live Freelancer/k6 Hermes Agent PC.

Baseline:

- OPC-PERSONAL eight-profile is already deployed.
- This is an incremental migration/refactor.
- Hermes on Freelancer/k6 remains runtime owner.
- The remote OpenCode workstation is an implementation console, not a runtime replacement.

## 2. Source-of-truth order

Read before touching the host:

1. `README.md`
2. `VERSION`
3. `docs/editions/opc-personal/opencode-integration-dev.md`
4. `docs/editions/opc-personal/external-researcher-variants.md`
5. this handoff
6. existing affected OPC-PERSONAL safety/deployment documents and scripts

Later design decisions in the dev design file override older handoff wording.

## 3. Approved maintainer migration target

For Freelancer/k6, the intended live result is:

```text
nim-researcher
    -> opencode-researcher
```

subject to successful OpenCode Go proof-of-capability before the actual role replacement.

Target active profile set:

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

Total active profile count remains eight.

Local OpenCode CLI remains deferred and must not be installed merely as part of this migration.

## 4. Critical repo-vs-live distinction

The maintainer is retiring NIM from the **live Freelancer/k6 external-researcher role**, but the repo must retain `nim-researcher` as an optional fork-user deployment variant.

Therefore:

```text
Live Freelancer/k6:
    opencode-researcher = selected external-researcher variant
    nim-researcher      = removed from active runtime

Repository:
    opencode-researcher = maintainer/default variant
    nim-researcher      = retained optional variant
```

Do **not** delete valid NIM profile templates, setup logic, MoA documentation or supporting assets solely because they are removed from the maintainer host.

The two variants are mutually exclusive in a normal eight-profile deployment; they are not intended to create a ninth profile.

## 5. Remote implementation principles

The remote workstation must:

- inspect before edit
- treat live state as authoritative
- back up every affected live config/profile artifact
- make reversible changes
- prove OpenCode Go before making the live role depend on it
- keep secretary/Lark stable
- avoid changing unrelated profiles
- never expose API keys in Git/log artifacts/screenshots/docs
- preserve repo-level NIM optional support while removing unneeded live NIM dependencies
- document implementation findings back into the dev branch

## 6. Required live-host discovery

Collect at minimum:

```text
- OS / hostname / active user
- Hermes Agent version and executable path
- complete active profile list and exact model mapping
- profile/SOUL/AGENTS locations
- relevant Hermes config paths
- actual provider/model schema supported by the installed Hermes version
- provider scope: global / per-profile / delegation / other
- secret-loading mechanism and permissions
- systemd/user services
- backup/restore mechanism
- current Git checkout state
```

Also inventory all live and repo references to `nim-researcher`.

## 7. Expected current live baseline to verify

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

At discussion time only `secretary` was running. Re-verify.

## 8. Dependency inventory and classification

Inspect at least:

```text
- live nim-researcher definition
- SOUL / AGENTS content
- editions/opc-personal templates
- nim-researcher MoA documentation
- setup-nim-moa-profile.sh
- skill allocation
- degradation/fallback rules
- coordinator routing/delegation
- cron/jobs
- Runes governance references
- validation scripts with exact profile names
- README/setup/reinstall docs
- profile-name keyed state
```

Classify each item twice.

### A. Action on live Freelancer/k6

```text
KEEP
RENAME
REFACTOR
REMOVE
```

### B. Action in repository support

```text
SHARED          provider-neutral and reused
OPENCODE        OpenCode variant only
NIM-OPTIONAL    keep for fork users selecting NIM
OBSOLETE        safe to remove from all supported variants
```

An item marked `REMOVE` from live Freelancer can still be `NIM-OPTIONAL` in the repo.

## 9. DEV-1 deliverable

Before functional role migration, report back into the branch:

- confirmed live Hermes/config/provider facts
- exact OpenCode Go integration mechanism
- credential location and permissions
- reload/restart behavior
- quota/rate-limit/provider failure behavior
- complete NIM dependency inventory with dual classification
- exact proposed `opencode-researcher` responsibility and provider mapping
- coordinator routing change, if any
- exact validation/reinstall impact
- rollback commands

## 10. DEV-2 — prove OpenCode Go first

Validate before role replacement:

```text
[ ] OpenCode Go authenticates
[ ] intended model is selectable
[ ] invocation works at the required Hermes scope
[ ] credential is isolated from Git/artifacts
[ ] local/default paths remain available
[ ] provider failure is observable
[ ] quota/rate-limit behavior is understood
[ ] restart/reload semantics are known
[ ] rollback restores original behavior
```

Do not modify secretary for this proof unless strictly required.

## 11. DEV-3 — migrate live external-researcher slot

After DEV-2 succeeds:

1. back up all affected live files
2. record original `nim-researcher` state
3. create/migrate `opencode-researcher`
4. configure OpenCode Go provider/model according to confirmed Hermes semantics
5. update coordinator routing/delegation as required
6. update shared skills/policies/validation
7. remove/refactor NIM-only runtime dependencies from the maintainer host
8. **do not delete NIM-optional repo assets**
9. verify exactly eight active profiles
10. verify `researcher` vs `opencode-researcher` responsibility split
11. verify secretary/Lark and unrelated profiles remain unchanged

## 12. DEV-4 — harden repo variants

After live migration works, make the repository intentionally support both external-researcher choices:

```text
Maintainer/default:
    opencode-researcher

Optional fork variant:
    nim-researcher
```

Implementation should eventually make the selected variant explicit in deployment/verification rather than relying on manual file deletion.

Preferred properties:

- exactly one external-researcher variant selected
- both variants share provider-neutral logic where possible
- NIM-specific MoA stays isolated to NIM variant
- OpenCode credentials/config stay isolated to OpenCode variant
- unselected provider is not a runtime dependency
- fork user can reconstruct the NIM variant from the current repo, not Git history

The exact variant-selection syntax is not predetermined; inspect existing deploy scripts before designing it.

## 13. Post-change validation

```text
[ ] affected profile starts successfully
[ ] secretary/Lark still works
[ ] unrelated profiles retain prior mappings
[ ] active profile count = 8
[ ] exactly one external-researcher variant is active
[ ] researcher remains the general research role
[ ] opencode-researcher uses intended OpenCode Go path
[ ] live host no longer depends on NIM for the selected external role
[ ] provider failure does not corrupt profile state
[ ] coordinator routing works
[ ] no stale live nim-researcher reference breaks restart/validation
[ ] repo still contains coherent NIM optional deployment assets
[ ] secrets absent from Git diff
[ ] backup and rollback exist
```

## 14. Rollback expectation

Every migration step needs same-session rollback:

1. stop/reload only affected component if needed
2. restore backed-up profile/config
3. restore original `nim-researcher` name/routing/provider state
4. restart/reload
5. verify original Ornith/NIM behavior as appropriate
6. verify secretary/Lark
7. record rollback result

Do not rely only on Git revert for live files outside the repo.

## 15. Deferred local OpenCode CLI

Do not install it during this migration.

Known environment retained for a future decision:

```text
Node.js v22.22.3
npm 10.9.8
nvm 0.40.3
```

If separately approved later:

```bash
mkdir -p "$HOME/.local/opencode-cli"
npm install -g --prefix "$HOME/.local/opencode-cli" opencode-ai
"$HOME/.local/opencode-cli/bin/opencode" --version
```

Intended scope remains mainly builder-class roles.

## 16. Commit discipline

Use `dev/opencode-integration` and keep commits purpose-specific.

Suggested categories:

```text
docs(dev): ...
chore(dev): ...
feat(opencode-go): ...
refactor(profile): ...
feat(nim-variant): ...
test(opencode-go): ...
```

Never commit credentials or unnecessary live-host private data.

## 17. Promotion gate

Do not merge merely because OpenCode Go connects.

Promotion requires:

- successful provider proof
- successful maintainer `opencode-researcher` migration
- eight-profile organization preserved
- no secretary/Lark regression
- acceptable quota/cost/latency/reliability
- rollback validated
- repo docs/scripts match actual maintainer deployment
- NIM optional variant remains coherent for fork users
- explicit maintainer approval for stable `0.21.0`

Until then `main` / `0.20.1` remains stable.
