# Profile Templates

These files are templates for official Hermes Agent profiles.

They are not a replacement for Hermes Agent profile homes.

Recommended mapping:

```text
profiles/coordinator/     -> ~/.hermes/profiles/coordinator/
profiles/researcher/      -> ~/.hermes/profiles/researcher/
profiles/writer/          -> ~/.hermes/profiles/writer/
profiles/builder/         -> ~/.hermes/profiles/builder/
profiles/runes-holder/    -> ~/.hermes/profiles/runes-holder/
```

## Default SOUL vs profile SOUL

```text
~/.hermes/SOUL.md
```

is the default one-agent identity.

```text
~/.hermes/profiles/<profile>/SOUL.md
```

is the identity for one official profile.

They may share an initial template, but should be treated as separate role files after profile creation.

## Initial OPC roles

- `coordinator`: plan, route, merge, boundary check.
- `researcher`: evidence, verification, uncertainty marking.
- `writer`: structure, clarity, audience fit.
- `builder`: implementation, debug, test, ship.
- `runes-holder`: optional long-term knowledge sedimentation advisor.
