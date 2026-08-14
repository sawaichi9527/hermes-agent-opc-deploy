# M9 secretary-only behavior smoke partial verification lock

This document locks the M9 secretary-only local behavior smoke result for the Hermes-native OPC profile set.

M9 validated the updated real `secretary` profile after M8 without starting the gateway and without Lark cutover. Repository and runtime preflight passed, but the local `hermes -p secretary -z` prompt invocation did not produce a final response.

The result is therefore PARTIAL, not PASS.

## Purpose

M9 exists to verify the updated real `secretary` profile locally before any gateway restart or Lark-facing production cutover.

This lock records that the profile installation, SOUL alignment, and gateway boundary are correct, while the local prompt smoke needs further runtime diagnosis.

## Verified scope

```text
M9.1 Secretary runtime preflight
M9.2 Secretary SOUL alignment check
M9.3 Gateway non-cutover check
M9.4 Local secretary prompt smoke
M9.5 Result capture guide
M9.6 Secretary Local Smoke Failure Diagnosis
```

## M9 deliverables

```text
docs/secretary-only-behavior-smoke.md
scripts/smoke-secretary-profile-local.sh
docs/verification-m9-secretary-smoke-partial.md
scripts/diagnose-secretary-local-smoke.sh
```

## Repository-side verification result

The maintainer verified M9 repo artifacts with:

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
bash -n scripts/smoke-secretary-profile-local.sh
```

Result:

```text
verify-repo-layout.sh: PASS / repository layout is valid
verify-profile-templates.sh: PASS / profile templates satisfy baseline static checks
smoke-secretary-profile-local.sh syntax: PASS
```

## Secretary preflight result

The guarded smoke script dry-run reported:

```text
PASS hermes profile show secretary
PASS profile name secretary
PASS secretary SOUL.md exists
PASS secretary .env exists
PASS secretary gateway remained stopped before smoke
PASS secretary SOUL alignment dry-run command
PASS secretary runtime SOUL matches repository template
```

Manual confirmation also showed:

```text
Profile: secretary
Path:    /home/eye/.hermes/profiles/secretary
Model:   qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m (lmstudio)
Gateway: stopped
Skills:  0
.env:    exists
SOUL.md: exists
```

## SOUL alignment result

The maintainer ran:

```bash
PROFILE=secretary bash scripts/dry-run-profile-deployment.sh
```

Result:

```text
Comparison: MATCH
Decision hint: skip / already aligned
```

This confirms the real runtime secretary `SOUL.md` still matches `profiles/secretary/SOUL.md.template` after M8.

## Local prompt smoke result

The maintainer ran:

```bash
RUN_SECRETARY_SMOKE=1 bash scripts/smoke-secretary-profile-local.sh
RUN_SECRETARY_SMOKE=1 SHOW_OUTPUT=1 bash scripts/smoke-secretary-profile-local.sh
```

Both attempts failed at local Hermes prompt invocation:

```text
hermes -z: no final response was produced; treating the run as failed.
FAIL hermes -p secretary -z prompt failed
```

Manual diagnosis repeated the same behavior:

```bash
hermes -p secretary -z "請只回覆 OK"
hermes -p secretary -z "請只回覆 OK" --dev
```

Both returned:

```text
hermes -z: no final response was produced; treating the run as failed.
```

A positional prompt test was also attempted:

```bash
hermes -p secretary "請只回覆 OK"
```

That is not valid for the current Hermes CLI shape. Hermes treated the prompt text as a command name and returned a usage error.

## Doctor result summary

The maintainer ran:

```bash
hermes doctor
```

Important PASS signals:

```text
Python environment OK
required packages mostly OK
~/.hermes/.env exists
API key or custom endpoint configured
~/.hermes/config.yaml exists
config version up to date
~/.hermes/state.db exists
systemd linger enabled
six profiles found
secretary profile found
built-in memory active
```

Doctor reported non-blocking or unrelated warnings such as optional auth providers not logged in, optional tool dependencies missing, and npm audit warnings in unrelated workspaces.

No doctor result in the provided evidence directly explains the `no final response` failure.

## Interpretation

M9 failure is currently classified as runtime invocation / model final-response handling, not as profile deployment failure.

Reasons:

```text
secretary profile exists
secretary .env exists
secretary SOUL.md exists
secretary runtime SOUL matches repo template
secretary gateway remained stopped
Hermes doctor sees the profile set
Hermes doctor reports API/custom endpoint configured
hermes -p secretary -z reaches Hermes but produces no final response
```

Possible causes to investigate later:

```text
model response emitted only reasoning_content or non-final content
Hermes CLI -z final-response extraction issue
profile-level provider/model behavior issue
secretary SOUL length or instruction structure interacting badly with selected model
local model endpoint returning an unexpected response shape
```

Do not assume the SOUL template is wrong until runtime final-response behavior is isolated.

## Confirmed boundaries

M9 did not perform:

```text
gateway start/restart
Lark production cutover
other profile apply
all-profile overwrite
native memory deletion
session deletion
Kanban deletion
cache/log cleanup
Runes Wiki mutation
parallel multi-agent execution
```

The local prompt attempts may create normal Hermes runtime session state, but no repo file, wiki candidate, gateway state, native memory cleanup, or Lark-facing state was intentionally changed.

## Final lock

```text
M9 Secretary-only Behavior Smoke without Lark Cutover
PARTIAL / repo verification PASS / secretary preflight PASS / SOUL MATCH / gateway remained stopped / local -z prompt failed with no final response / no Lark cutover
```

## Next work

The next stage should be:

```text
M10 Secretary final-response diagnosis / local model response handling
```

Recommended next direction:

```text
check Hermes CLI invocation modes
check whether model output appears in reasoning_content or non-final fields
run minimal baseline prompt with default profile and/or a simpler temporary profile
avoid gateway restart and Lark cutover until a local final response is produced
```
