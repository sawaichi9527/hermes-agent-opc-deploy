# Migration Checklist

Purpose: rebuild Hermes OPC-style usage on a new machine while staying close to official Hermes Agent profiles.

## Source machine

- [ ] Record Hermes Agent version.
- [ ] Record active profile names.
- [ ] Record project workspace paths under `~/workspace/<project>/`.
- [ ] Record optional runes path, if used.
- [ ] Export safe templates and decisions only.

## Target machine

- [ ] Install a compatible Hermes Agent version.
- [ ] Confirm default one-agent mode works.
- [ ] Recreate official profiles.
- [ ] Apply profile templates from this repository.
- [ ] Restore or recreate project workspaces under `~/workspace/<project>/`.
- [ ] Attach optional `hermes-runes-md-wiki` if available.
- [ ] Let `runes-holder` pick up durable knowledge from runes when needed.

## Principle

The target machine should not need the old machine's full runtime state to become useful.

Durable knowledge may be recovered from:

```text
~/workspace/hermes-runes-md-wiki/wiki/<slug>/
```

Profile behavior may be rebuilt from this repository's templates and deployment notes.
