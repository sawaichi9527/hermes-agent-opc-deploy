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

## Phase 3N.2 profile alias / wrapper discovery lock

```text
Phase 3N.2 Profile Alias Wrapper Discovery
Status: PASS
Result: alias command syntax identified / secretary is not a distribution / no non-mutating wrapper path proven yet
Boundary: read-only discovery / no model request / no profile mutation / no daemon / no concurrency / no load test
```

Maintainer verification ran:

```bash
hermes profile alias --help
hermes profile info secretary || true
hermes profile show secretary
```

Observed alias syntax:

```text
hermes profile alias [--remove] [--name NAME] profile_name
```

Important findings:

```text
hermes profile alias can manage wrapper scripts, but it is not a read-only profile selector.
Creating or removing an alias is a local filesystem mutation and should not be part of read-only smoke validation.
secretary is not a distribution: Profile 'secretary' is not a distribution (no distribution.yaml).
hermes profile show secretary remains a safe read-only inspection path.
```

Observed secretary profile remained valid:

```text
Profile: secretary
Path: /home/eye/.hermes/profiles/secretary
Model: qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m (lmstudio)
Gateway: stopped
.env: exists
SOUL.md: exists
```

Phase 3N.2 did not prove a built-in non-mutating CLI selector for `secretary`. At this point, the already verified Phase 3M path using explicit provider/model overrides is the safe single-request runtime path.

## Follow-up

Phase 3N should not use `hermes profile use secretary` unless the maintainer explicitly approves sticky default mutation.

Possible future options:

```text
A. Accept explicit --provider lmstudio + --model MODEL override as the safe non-mutating runtime path.
B. Explicitly approve a one-time alias wrapper creation test, then inspect the generated wrapper before using it.
C. Defer profile-bound single-request execution until Hermes exposes a non-mutating --profile-like selector.
```

Recommended next step is Phase 3N.3 decision lock: either accept explicit provider/model override as sufficient for this personal deployment stage, or intentionally test alias wrapper creation as a local mutation with maintainer approval.
