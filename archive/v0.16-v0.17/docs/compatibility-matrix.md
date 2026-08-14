# Compatibility Matrix

This repository follows **Hermes Agent upstream compatibility**, not an independent product version.

| Repo tag | Hermes Agent version | Source | Status | Notes |
|---|---:|---|---|---|
| `compat-hermes-v0.16.0` | `0.16.0` | upstream `pyproject.toml` | pending local validation | Initial OPC deployment baseline for official Hermes profiles. |

## Tagging rule

Use compatibility tags:

```text
compat-hermes-v<upstream-version>
```

Examples:

```text
compat-hermes-v0.16.0
compat-hermes-v0.16.1
compat-hermes-v0.17.0
```

Do not use plain `vX.Y.Z` unless this repository later becomes an independent tool with its own release lifecycle.

## Validation states

- `draft`: written but not installed or tested.
- `pending local validation`: intended for this upstream version but not fully verified on a machine.
- `validated`: installed and smoke-tested against the listed Hermes Agent version.
- `superseded`: retained for history; replaced by a newer compatibility baseline.
- `broken`: known not to work with the listed upstream version.

## Compatibility principle

Prefer upstream Hermes Agent behavior. This repository should only document thin usage-layer conventions and templates. If upstream Hermes changes profile behavior, adapt this repository instead of forcing Hermes to match this repository.
