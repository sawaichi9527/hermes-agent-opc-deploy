# OPC implementation roadmap

This roadmap replaces the earlier simulation/deployment-heavy plan with a Hermes-native OPC profile set plan.

The current objective is not to build a deployment framework. The objective is to curate a six-profile OPC role set on top of Hermes Agent native profiles.

## Scope reset

```text
Hermes Agent remains the runtime owner.
Hermes native profiles remain the profile container.
This repository customizes SOUL.md / NOTES.md and records small operating guidance.
Earlier Phase 3/4/5 validation is historical evidence, not the main workflow.
```

## Mainline profile set

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

Expected runtime flow:

```text
Lark bot
  -> secretary
  -> coordinator
  -> exactly one selected worker profile at a time
  -> secretary summarizes and replies to the user
```

The profile set is designed as a coherent OPC unit. It is not secretary-only, but it is also not a parallel multi-agent swarm.

## Hard constraints

### Hermes-native first

Use Hermes Agent native profile behavior wherever possible.

Custom code is allowed only for small template checks, documentation support, or explicitly approved glue that Hermes Agent does not already provide.

### Local compute is serialized

The maintainer's runtime uses a local LM Studio / llama.cpp backend. Even if the backend exposes multiple slots, the OPC policy is conservative:

```text
one active profile call at a time
no concurrent profile agent inference
no parallel worker dispatch
compact profile handoff packets
avoid copying full transcripts across profiles
```

### Lark ingress belongs to secretary

Only `secretary` should own Lark-facing user interaction by default. Other profile agents should not run gateways by default.

### Memory and Runes are separate

```text
Hermes native memory
  profile-local Hermes Agent capability; each profile may use its own native memory.

Hermes native Kanban
  Hermes Agent native task/workflow capability; not equivalent to Runes Wiki.

Hermes Runes MD Wiki
  external governed Markdown source-of-truth; accessed through runes-holder and runes shield.
```

`runes-holder` is the Runes Wiki access/governance specialist, not the gatekeeper for other profiles' Hermes native memory.

`runes-holder` may retrieve Runes Wiki context, but the requesting profile remains responsible for validation.

Governed writes to `hermes-runes-md-wiki/wiki` require secretary-mediated user consent before `runes-holder` invokes runes shield.

### Language policy

```text
SOUL.md templates:
- secretary: Traditional Chinese-first main body.
- runes-holder: Traditional Chinese / English mixed.
- coordinator / researcher / writer / builder: English-first role definitions.

Runtime inter-profile communication:
- Traditional Chinese first.
- Preserve exact technical terms, paths, commands, API names, filenames, errors, and source identifiers.
```

## M1 - Hermes-native OPC Scope Reset

Status: PASS / mainline reframed / old validation downgraded / archive index created / layout check simplified.

Goals:

- Reframe README and roadmap around Hermes-native OPC profile set.
- Archive older validation/simulation/runtime phase material under `archive/validation-history/`.
- Remove historical Phase 3/4/5 docs from the main required layout check.
- Keep only the minimal repository/profile template checks as the default validation path.
- Stop treating simulation deploy scripts as the main route.

Exit result:

```text
README reflects Hermes-native OPC profile set scope.
Roadmap reflects M1-M6 route.
Historical validation index exists under archive/validation-history/.
verify-repo-layout.sh no longer requires old Phase 3/4/5 docs.
No runtime or real profile mutation was introduced.
```

## M2 - OPC profile set policy docs

Status: PASS / four policy docs added / layout-tracked / no runtime mutation.

Deliverables:

```text
docs/opc-profile-set-design.md
docs/local-compute-policy.md
docs/runes-holder-boundary.md
docs/hermes-native-profile-usage.md
```

Coverage:

- Lark -> secretary -> coordinator -> worker profile flow.
- Six-profile OPC set as one coherent design.
- One active profile call at a time.
- Context budget and session-compression awareness.
- Hermes native memory / native Kanban / Runes Wiki separation.
- Runes-holder retrieval vs truth-verification responsibility.
- Traditional Chinese first runtime handoff policy.

Exit result:

```text
Four M2 policy docs exist.
verify-repo-layout.sh tracks the M2 policy docs.
No runtime or real profile mutation was introduced.
```

## M3 - Six-profile SOUL.md template rewrite

Status: PASS / six templates rewritten / M2 policy embedded / no runtime mutation.

Deliverables:

```text
profiles/secretary/SOUL.md.template
profiles/coordinator/SOUL.md.template
profiles/researcher/SOUL.md.template
profiles/writer/SOUL.md.template
profiles/builder/SOUL.md.template
profiles/runes-holder/SOUL.md.template
```

Profile-specific result:

```text
secretary
  Lark-facing entrypoint, personal-preference buffer, secretary-mediated user consent, serialized handoff owner.

coordinator
  Sequential router, one next profile at a time, compact Traditional Chinese-first handoff packets.

researcher
  Evidence comparison owner; validates Runes/native/RAG/Obsidian/web material.

writer
  Drafting and presentation owner; preserves source status, uncertainty, and verified-vs-retrieved distinction.

builder
  Implementation validation owner; validates against repo files, commands, official docs, and local state.

runes-holder
  Hermes Runes MD Wiki retrieval/governance specialist; retrieves Runes context and uses runes shield only after secretary/user consent.
```

Exit result:

```text
All six SOUL.md.template files reflect M2 policy docs.
Templates preserve no-real-secret and no-real-runtime-mutation boundaries.
verify-profile-templates.sh passed locally.
No real ~/.hermes profile file was mutated by this repository update.
```

## M4 - Minimal verification

Status: PASS / repo layout verified / profile templates verified / no runtime mutation / no profile mutation.

Verification lock:

```text
docs/verification-m4-minimal.md
```

Default validation:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
git status --short
```

Result:

```text
verify-repo-layout.sh: PASS / repository layout is valid
verify-profile-templates.sh: PASS / profile templates satisfy baseline static checks
git status --short: clean working tree
```

Optional Hermes-native profile checks remain available for future runtime inspection:

```bash
hermes profile show secretary
hermes profile show coordinator
hermes profile show researcher
hermes profile show writer
hermes profile show builder
hermes profile show runes-holder
```

Optional Lark-facing secretary check, only when validating runtime behavior:

```bash
hermes -p secretary gateway status
```

Not part of default M4:

```text
simulation deploy
old Phase 3/4/5 validation bundle
parallel multi-agent smoke
real profile mutation
native memory/session maintenance
Lark production cutover
```

## M5 - SOUL.md behavior tuning

Status: PASS / convention added / secretary tuned / worker profiles aligned / runes-holder format-only aligned / no runtime mutation.

Verification lock:

```text
docs/verification-m5-soul-convention.md
```

Deliverables:

```text
docs/soul-template-convention.md
profiles/secretary/SOUL.md.template
profiles/coordinator/SOUL.md.template
profiles/researcher/SOUL.md.template
profiles/writer/SOUL.md.template
profiles/builder/SOUL.md.template
profiles/runes-holder/SOUL.md.template
```

M5.1 SOUL Template Convention:

```text
Added docs/soul-template-convention.md.
Defined this repository's local SOUL.md section order, language convention, naming convention, context/compression policy, Runes boundary convention, and maintenance-notes convention.
```

M5.2 secretary tuning:

```text
Reworked secretary into Traditional Chinese-first main body.
Added neutral user naming policy.
Added intelligence secretary behavior.
Added context/compression policy for Lark-facing long conversations.
Added maintenance note M5-secretary-intelligence-v2 / 2026-06-14.
```

M5.3 coordinator / researcher / writer / builder tuning:

```text
Aligned templates with the SOUL convention.
Added role-specific context/compression policies.
Improved handoff clarity, evidence/source handling, source-aware writing, and bounded implementation behavior.
Kept runtime handoff Traditional Chinese-first.
```

M5.4 runes-holder format alignment:

```text
Aligned runes-holder template format with the SOUL convention.
Semantic meaning is intended to remain frozen.
Only hygiene adjustment: remove hard-coded personal naming from the language-policy description.
```

M5.5 verification result:

```text
verify-repo-layout.sh: PASS / repository layout is valid
verify-profile-templates.sh: PASS / profile templates satisfy baseline static checks
git status --short: clean working tree
```

Not part of M5:

```text
real ~/.hermes profile overwrite
profile install/update
gateway start/restart
native memory/session/Kanban cleanup
Lark cutover
parallel multi-agent execution
```

## M6 - Pre-production profile maintenance planning

Status: PASS / read-only inventory verified / cleanup policy documented / dry-run plan documented / no runtime cleanup executed.

Verification lock:

```text
docs/verification-m6-maintenance-planning.md
```

M6 is a pre-production maintenance planning stage. It creates the safety procedure and inspection tooling for future runtime cleanup, but it does not clean the real runtime by itself.

Deliverables:

```text
docs/pre-production-profile-maintenance.md
docs/pre-production-cleanup-dry-run.md
scripts/inspect-profile-runtime-state.sh
docs/verification-m6-maintenance-planning.md
```

M6.1 Pre-production Runtime Inventory:

```text
Added scripts/inspect-profile-runtime-state.sh.
The script is read-only and reports metadata only.
It does not print .env contents, token values, session contents, native memory contents, database contents, or cache contents.
The maintainer ran the inspector against /home/eye/.hermes and confirmed all six OPC profile directories exist.
```

M6.2 Backup Policy:

```text
Documented required pre-cleanup backup policy in docs/pre-production-profile-maintenance.md.
Backups must remain outside this repository and must not be copied into git, docs, profiles, or Runes Wiki candidates.
```

M6.3 Cleanup Classification:

```text
Documented preserve / cleanup-candidate-after-backup / defer classifications.
Preserve identity/config/secrets/profile files by default.
Defer unknown state, unclear native memory, unknown databases, and secret-bearing/private runtime data.
Read-only inventory classified profile caches/logs/sessions as review-only cleanup candidates after backup.
```

M6.4 Dry-run Cleanup Plan:

```text
Added docs/pre-production-cleanup-dry-run.md.
The dry-run plan is a report template, not an executable cleanup.
```

M6.5 Manual Apply Procedure:

```text
Manual apply remains deliberately non-scripted in M6.
Real cleanup requires reviewed inventory, external backup, exact target list, explicit maintainer approval, reviewed commands, and rollback path.
```

M6.6 verification result:

```text
verify-repo-layout.sh: PASS / repository layout is valid
verify-profile-templates.sh: PASS / profile templates satisfy baseline static checks
bash -n scripts/inspect-profile-runtime-state.sh: PASS
inspect-profile-runtime-state.sh: PASS / read-only runtime inventory completed
git status --short: clean working tree
```

Not part of M6 implementation:

```text
real ~/.hermes cleanup
real profile SOUL.md overwrite
profile install/update
gateway start/restart
native memory deletion
session deletion
Kanban deletion
Lark production cutover
automatic cleanup apply script
parallel multi-agent execution
```

## Archived material

Earlier Phase 3/4/5 validation and simulation documents are historical evidence only. They should live under:

```text
archive/validation-history/
```

They are not the operational mainline for future work.
