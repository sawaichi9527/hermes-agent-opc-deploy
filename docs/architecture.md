# Architecture

## Core stance

This repository does not create a parallel OPC runtime.

Hermes OPC is defined here as a **usage pattern over official Hermes Agent profiles**.

```text
Hermes Agent official profile mechanism
        ↓
OPC-style role division
        ↓
Coordinator / Researcher / Writer / Builder / Runes Holder
```

## Layers

### 1. Hermes native layer

```text
~/.hermes/
```

Owns:

- default Hermes Agent identity
- native memory
- native configuration
- default one-agent operation

This layer must continue working without OPC and without runes.

### 2. Hermes official profile layer

```text
~/.hermes/profiles/<profile>/
```

Owns profile-scoped:

- `SOUL.md`
- memory
- skills
- config
- sessions
- state

OPC roles are implemented as official Hermes profiles, not as a separate runtime tree.

Recommended initial profiles:

```text
coordinator
researcher
writer
builder
runes-holder
```

### 3. Project working tree

```text
~/workspace/<project>/
```

Owns actual project material:

- source code
- documentation
- tests
- project artifacts
- project-specific rules
- project outputs

Do not move real project work into this repository or into a parallel global OPC project folder.

### 4. Optional runes sedimentation layer

```text
~/workspace/hermes-runes-md-wiki/wiki/<slug>/
```

Owns optional durable Markdown knowledge sedimentation.

It does not replace Hermes native memory or profile memory. It exists so important knowledge can be picked up again after machine migration or profile rebuild.

## Default SOUL vs profile SOUL

```text
~/.hermes/SOUL.md
```

is the default one-agent identity.

```text
~/.hermes/profiles/coordinator/SOUL.md
```

is the Coordinator profile identity.

They may be cloned from the same starting point, but after creation they should be treated as separate profile identity files. Do not assume automatic inheritance or synchronization.

## Runes Holder

`runes-holder` is an optional Hermes profile that advises whether runtime knowledge should be sedimented into `hermes-runes-md-wiki`.

It should not directly mutate runes content outside the approved runes shield workflow.

## Non-goals

This repository does not:

- fork Hermes Agent
- replace official profiles
- define `~/.hermes/opc/profiles` as a runtime
- store project workspaces
- store secrets
- store Hermes runtime sessions or state databases
- change `hermes-runes-md-wiki` shield behavior
