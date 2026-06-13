# Phase 3N profile-specific invocation behavior

This phase investigates whether Hermes Agent can run a single request against a specific profile without mutating the sticky default profile.

Phase 3N keeps the same personal-use boundary:

```text
single request at a time
no parallel profile probing
no daemon/process startup
no load test
no throughput benchmark
no router or queue introduction
no external API fallback
no sticky default profile mutation unless explicitly approved by the maintainer
```

## Purpose

Phase 3M proved the minimal Hermes runtime path:

```text
Hermes CLI -> lmstudio provider alias -> local OpenAI-compatible /v1 backend -> configured local model -> response returned to CLI
```

Phase 3N checks whether that runtime path can be attached to a specific Hermes profile, especially `secretary`, without changing the user's sticky default profile.

## Phase 3N.1 command help probe lock

```text
Phase 3N.1 Profile Invocation Help Probe
Status: PASS
Result: CLI profile-related syntax checked; no non-mutating --profile flag found
Boundary: help-only / no model request / no profile mutation / no daemon / no concurrency / no load test
```

Maintainer verification ran:

```bash
hermes profile use --help
hermes profile show --help
hermes chat --help
hermes --help | grep -E "profile|-p|--profile" || true
```

Observed syntax:

```text
hermes profile use profile_name
hermes profile show profile_name
hermes chat -q QUERY
hermes chat --provider PROVIDER
hermes chat --model MODEL
```

Important findings:

```text
hermes profile use is sticky-default mutation behavior and must not be used casually.
hermes profile show is read-only profile inspection.
hermes chat supports one-shot query mode via -q / --query.
hermes chat supports --provider and --model overrides.
hermes chat help did not show --profile or -p.
Top-level hermes help did not show --profile or -p.
```

Therefore, Phase 3N.1 did not find a safe non-mutating CLI flag for selecting `secretary` directly. Future work must not assume a `--profile` or `-p` flag exists.

## Follow-up

The next step is Phase 3N.2 profile alias / wrapper discovery.

Phase 3N.2 should inspect whether `hermes profile alias` can create or reveal profile-specific wrapper scripts, and whether those wrappers can run a single request without mutating the sticky default profile.

Suggested read-only probes:

```bash
hermes profile alias --help
hermes profile info secretary || true
hermes profile show secretary
```

Do not run `hermes profile use secretary` unless explicitly approved, because it changes the sticky default profile.
