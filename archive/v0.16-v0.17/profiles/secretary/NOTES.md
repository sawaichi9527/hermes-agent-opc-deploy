# Secretary Profile Notes

`secretary` is part of the maintainer's standard OPC profile baseline.

For generic forks, this profile may be optional. For this repository's maintainer deployment, it is included because Lark is expected to be the main operating interface after OPC-style profile usage is enabled.

## Purpose

```text
Lark bot
  -> secretary
  -> coordinator
```

The secretary protects role purity by keeping user-facing preferences, Lark etiquette, response format, and casual request cleanup outside `coordinator`, `researcher`, `writer`, `builder`, and `runes-holder`.

## Primary duties

- receive normalized requests from the Lark channel adapter;
- preserve maintainer communication preferences;
- turn casual user input into clean task briefs;
- ask for clarification when needed;
- decide whether a request should be answered directly or handed to `coordinator`;
- keep playful or noisy user interaction from polluting worker profiles;
- return concise status updates to the maintainer.

## Non-goals

- Do not replace `coordinator` for task planning and routing.
- Do not own research, writing, building, or runes sedimentation as the primary role.
- Do not become a ticketing system or enterprise workflow engine.
- Do not write directly into `hermes-runes-md-wiki`.

## Deployment note

When real deployment is approved, initialize this as an official Hermes Agent profile first, then apply this repository's small customizations.

Do not manually construct a complete profile home from this repository alone.
