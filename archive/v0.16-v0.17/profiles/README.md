# Profile Templates

These files are templates for official Hermes Agent profiles.

They are not a replacement for Hermes Agent profile homes.

Recommended mapping for the maintainer baseline:

```text
profiles/secretary/       -> ~/.hermes/profiles/secretary/
profiles/coordinator/     -> ~/.hermes/profiles/coordinator/
profiles/researcher/      -> ~/.hermes/profiles/researcher/
profiles/writer/          -> ~/.hermes/profiles/writer/
profiles/builder/         -> ~/.hermes/profiles/builder/
profiles/runes-holder/    -> ~/.hermes/profiles/runes-holder/
```

For other users or forks, `secretary` may be treated as optional. For the maintainer's Lark-first OPC usage, `secretary` is part of the standard profile set because it protects the role purity of the worker profiles.

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

## Maintainer OPC roles

- `secretary`: Lark-facing user intake, preference adapter, and request-brief formatter.
- `coordinator`: plan, route, merge, boundary check.
- `researcher`: evidence, verification, uncertainty marking.
- `writer`: structure, clarity, audience fit.
- `builder`: implementation, debug, test, ship.
- `runes-holder`: long-term knowledge sedimentation advisor for optional runes pickup.

## Phase 3H guarded deploy source roles

Phase 3H also completes the repo-local source root required by the real deploy readiness gate.

Required guarded deploy role directories:

```text
profiles/default/
profiles/developer/
profiles/reviewer/
profiles/operator/
profiles/trial/
```

These directories are intentionally minimal in Phase 3H. They exist so the read-only readiness checker can verify that a complete source root is present.

Phase 3H does not perform a real apply. A future real deploy must still use guarded apply with explicit confirmation.

Expected readiness result after Phase 3H, assuming destination ownership is safe:

```text
SOURCE_STATUS=complete
READINESS_STATUS=READY
```
