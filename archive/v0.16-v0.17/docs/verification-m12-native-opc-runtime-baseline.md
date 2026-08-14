# M12 Hermes Native OPC Runtime Baseline Lock

Status: PASS / runtime verified / GitHub synced baseline

## Purpose

Lock the clean Hermes-native OPC runtime baseline after the profile deployment reset.

This verification confirms that OPC profiles are created through official Hermes native profile lifecycle and that repository overlay is limited to documentation/persona metadata only.

## Scope

Profiles covered:

- secretary
- coordinator
- researcher
- writer
- builder
- runes-holder

## Final Deployment Rule

Runtime profiles must be created by Hermes native profile clone:

```bash
hermes profile use default
hermes profile create <profile> --clone
```

The repository must not be used to manually construct a full Hermes profile home.

## Allowed Repository Overlay

Only these files may be overlaid from this repository into a runtime profile:

```text
profiles/<profile>/SOUL.md.template -> ~/.hermes/profiles/<profile>/SOUL.md
profiles/<profile>/NOTES.md         -> ~/.hermes/profiles/<profile>/NOTES.md
profiles/<profile>/profile.yaml     -> ~/.hermes/profiles/<profile>/profile.yaml
profiles/<profile>/README.md        -> ~/.hermes/profiles/<profile>/README.md
```

## Protected Runtime Files

The following runtime files must not be overwritten by repository deployment scripts:

```text
~/.hermes/profiles/<profile>/.env
~/.hermes/profiles/<profile>/config.yaml
~/.hermes/profiles/<profile>/skills/
~/.hermes/profiles/<profile>/sessions/
~/.hermes/profiles/<profile>/logs/
~/.hermes/profiles/<profile>/memories/
~/.hermes/profiles/<profile>/workspace/
~/.hermes/profiles/<profile>/home/
```

Reason:

- `.env` contains runtime secrets and provider credentials.
- `config.yaml` contains inherited local model/provider configuration.
- runtime directories contain Hermes-managed state.

## Verified Runtime State

All profiles were verified with:

```bash
hermes profile show <profile>
sed -n '1,20p' ~/.hermes/profiles/<profile>/SOUL.md
```

Observed common state:

```text
Model:   qwen3.6-35b-a3b-uncensored-heretic-native-mtp-preserved@q5_k_m (custom)
Gateway: stopped
Skills:  73
.env:    exists
SOUL.md: exists
Alias:   exists
```

Observed profile SOUL headers:

```text
secretary      # SOUL: secretary
coordinator    # SOUL: coordinator
researcher     # SOUL: researcher
writer         # SOUL: writer
builder        # SOUL: builder
runes-holder   # SOUL: runes-holder
```

## Script Baseline

The following independent scripts were added and pushed:

```text
scripts/create-coordinator-profile-clone.sh
scripts/create-researcher-profile-clone.sh
scripts/create-writer-profile-clone.sh
scripts/create-builder-profile-clone.sh
scripts/create-runes-holder-profile-clone.sh

scripts/apply-secretary-runtime-doc-overlay.sh
scripts/apply-coordinator-runtime-doc-overlay.sh
scripts/apply-researcher-runtime-doc-overlay.sh
scripts/apply-writer-runtime-doc-overlay.sh
scripts/apply-builder-runtime-doc-overlay.sh
scripts/apply-runes-holder-runtime-doc-overlay.sh
```

Each overlay script is profile-specific and performs:

- dry-run by default;
- explicit apply via profile-specific environment variable;
- `.env` hash preservation check;
- `config.yaml` hash preservation check;
- post-apply document hash comparison.

## Git Baseline

Repository state at lock time:

```text
main == origin/main
latest commit:
8702103 Add independent OPC profile clone and doc overlay scripts
```

## Result

PASS.

Hermes native OPC profile baseline is locked.

No gateway startup was performed.
No Lark / Feishu setup was performed.
No default profile mutation was performed.
No `.env` or `config.yaml` repository overlay was performed.
