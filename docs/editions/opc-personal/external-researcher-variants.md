# External researcher profile variants

> Development branch: `dev/opencode-integration`  
> Version baseline: `0.21.0-dev.2`

## Purpose

OPC-PERSONAL keeps an eight-profile organization, but the dedicated external-model research role is treated as one configurable **external-researcher slot** rather than a permanently fixed provider-specific role.

The slot has two supported design variants:

| Variant | Profile name | Provider direction | Intended use |
|---|---|---|---|
| Maintainer default | `opencode-researcher` | OpenCode Go API | stable external reasoning, second opinion, deeper research |
| Optional fork variant | `nim-researcher` | NVIDIA NIM | users who have a reliable NIM service and want NIM/MoA behavior |

The variants are **mutually exclusive in one OPC-PERSONAL deployment**. Selecting one does not create a ninth profile.

## Maintainer deployment decision

For the live Freelancer/k6 deployment, `0.21.0` targets:

```text
nim-researcher
    -> replaced by opencode-researcher
```

Reason: NVIDIA NIM model service has not been sufficiently stable in the maintainer's actual environment. The live migration therefore removes the NIM dependency from this dedicated role rather than retaining it as a fallback requirement.

Target live profile set:

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

## Repository policy

The repository must **not delete NIM support merely because the maintainer no longer uses it**.

Instead:

- keep NIM-specific documentation, profile templates, setup logic and MoA guidance that remain valid;
- clearly mark them as an optional deployment variant rather than the maintainer default;
- avoid making NIM artifacts mandatory for the OpenCode variant;
- avoid making OpenCode Go artifacts mandatory for the NIM variant;
- keep shared/provider-agnostic research behavior reusable by both variants where practical;
- ensure validation/reinstall tooling can distinguish the selected variant.

A fork user should be able to choose either:

```text
OPC-PERSONAL + opencode-researcher
```

or:

```text
OPC-PERSONAL + nim-researcher
```

without manually resurrecting deleted files from repository history.

## Responsibility boundary

Both variants occupy the same organizational function:

- `researcher`: normal/default research path, generally local/Hermes-native;
- external-researcher slot: explicit external-model specialist, cross-check, second opinion, deeper or alternative-model research;
- `coordinator`: decides when use of the external specialist is worthwhile and remains orchestration owner.

Provider-specific features may differ. For example, NIM-specific MoA behavior can remain part of the NIM variant without being copied into the OpenCode variant unless there is a provider-agnostic reason to do so.

## Migration rule for Freelancer/k6

When the remote implementation begins:

1. inventory all live `nim-researcher` dependencies;
2. classify each dependency as shared, NIM-specific, or obsolete;
3. remove/replace NIM-specific dependencies **from the live Freelancer/k6 OpenCode deployment** where they are no longer needed;
4. preserve equivalent NIM assets in the repository under the optional NIM variant;
5. implement `opencode-researcher` as the maintainer-default external-researcher variant;
6. update validation so the live deployment expects exactly one external-researcher variant, not both.

A live cleanup and a repository deletion are therefore different decisions.

## Validation direction

Future tooling should ideally validate a selected variant explicitly, for example conceptually:

```text
EXTERNAL_RESEARCHER_VARIANT=opencode
```

or:

```text
EXTERNAL_RESEARCHER_VARIANT=nim
```

The exact configuration mechanism must be chosen only after inspecting the existing scripts/profile layout. `0.21.0-dev.2` defines the policy, not the final implementation syntax.

Minimum invariants:

- exactly eight active OPC-PERSONAL profiles;
- exactly one external-researcher profile selected;
- `researcher` remains present as the general research role;
- selected variant has all required provider/config/skills;
- unselected variant does not become a runtime dependency;
- secrets are never committed to the repository.

## Promotion requirement

Before `0.21.0` becomes stable, the maintainer OpenCode variant must be validated on Freelancer/k6. NIM variant files may remain as a supported optional path even if no NIM service is active on the maintainer host; however, repository checks must ensure those assets are internally coherent and not broken by the OpenCode migration.
