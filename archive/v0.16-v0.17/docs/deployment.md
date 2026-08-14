# Deployment Guide

Status: draft for Hermes Agent `0.16.0` compatibility baseline.

## Goals

- Use official Hermes profiles.
- Avoid a parallel OPC runtime.
- Keep project work under `~/workspace/<project>/`.
- Keep runes as an optional external Markdown sedimentation layer.

## Suggested flow

1. Install or update Hermes Agent using the official method.
2. Confirm default one-agent operation with `~/.hermes/SOUL.md`.
3. Create official Hermes profiles for `coordinator`, `researcher`, `writer`, `builder`, and `runes-holder`.
4. Adapt the templates in `profiles/<profile>/` into the matching official Hermes profile home.
5. Keep actual project work in `~/workspace/<project>/`.
6. Treat `~/workspace/hermes-runes-md-wiki/wiki/<slug>/` as optional long-term Markdown sedimentation.

## Validation checklist

- [ ] Default Hermes one-agent mode works.
- [ ] Each official profile starts successfully.
- [ ] Each profile has the expected `SOUL.md`.
- [ ] Project work remains under `~/workspace/<project>/`.
- [ ] `runes-holder` treats runes as optional.
- [ ] Compatibility matrix records the actual Hermes Agent version.
