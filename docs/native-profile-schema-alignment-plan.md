# Phase 3K-FIX.12 Native Profile Schema Alignment Plan

Status: Phase 3K-FIX.12 native profile schema alignment planning documented  
Scope: planning + read-only inspection only  
Real profile write: false  
Real profile delete: false  
Secret write: false  

---

## 1. Purpose

Phase 3K-FIX.12 aligns the OPC canonical role profile layout with Hermes native profile expectations.

This phase exists because Phase 3K-FIX.10 successfully copied canonical profile content into:

```text
~/.hermes/profiles/secretary/
~/.hermes/profiles/coordinator/
~/.hermes/profiles/researcher/
~/.hermes/profiles/writer/
~/.hermes/profiles/builder/
~/.hermes/profiles/runes-holder/
```

Phase 3K-FIX.11 then confirmed that Hermes CLI can discover these profiles and `hermes -p <role> doctor` can resolve the per-profile `HERMES_HOME`.

However, the same inspection also showed native-profile gaps:

```text
.env: not configured
config.yaml not found
Skills: 0
alias: missing
profile show may report SOUL.md not configured while doctor sees SOUL.md exists
```

Therefore, Phase 3K-FIX.12 does not apply changes. It defines the native schema gap and adds a read-only checker.

---

## 2. Confirmed Native Profile Signals

Based on local inspection:

```text
hermes profile show <role>
hermes -p <role> doctor
```

confirmed:

```text
- Hermes primary CLI entrypoint is `hermes`.
- `hermes profile` is the native profile management command family.
- Six canonical profiles are discoverable by Hermes CLI.
- `hermes -p <role> doctor` resolves per-profile directories.
- `SOUL.md exists (persona configured)` is detected by doctor.
- Profile root runtime directories are present: cron/, sessions/, logs/, skills/, memories/.
```

Not yet complete:

```text
- .env initialization
- config.yaml initialization
- profile.yaml / description metadata
- wrapper alias creation
- skills hub initialization
- chat / oneshot runtime smoke
```

---

## 3. Native Schema Targets

The canonical role profiles should eventually align with these native Hermes profile artifacts:

```text
~/.hermes/profiles/<role>/SOUL.md
~/.hermes/profiles/<role>/config.yaml
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/profile.yaml
~/.hermes/profiles/<role>/skills/
~/.hermes/profiles/<role>/memories/
~/.hermes/profiles/<role>/sessions/
~/.hermes/profiles/<role>/logs/
~/.hermes/profiles/<role>/cron/
```

But not every artifact should be repository-managed.

---

## 4. Repository-owned vs Local-only Boundary

### Repository-owned candidates

These can be governed as source templates:

```text
profiles/<role>/README.md
profiles/<role>/SOUL.md
profiles/<role>/profile.yaml
profiles/<role>/config.yaml.template
profiles/<role>/.env.template
```

### Local-only artifacts

These must not be committed with real values:

```text
profiles/<role>/.env
~/.hermes/profiles/<role>/.env
~/.hermes/profiles/<role>/auth.json
~/.hermes/profiles/<role>/state.db
~/.hermes/profiles/<role>/sessions/
~/.hermes/profiles/<role>/logs/
~/.hermes/profiles/<role>/memories/MEMORY.md
~/.hermes/profiles/<role>/memories/USER.md
```

### Secrets rule

No real API keys, OAuth tokens, bot tokens, database credentials, or service credentials may be committed into this repo.

---

## 5. Why not run `hermes profile create` now?

Do not immediately recreate these profiles with `hermes profile create` because:

```text
- Hermes already discovers the six canonical role directories.
- Phase 3K-FIX.10 has already created managed profile directories and markers.
- Recreating profiles may overwrite or fork local state.
- The next change should be schema-aligned and reversible.
```

Preferred next step:

```text
1. inspect current real profile schema
2. define repo-owned template artifacts
3. dry-run a guarded schema apply
4. only then perform guarded apply if needed
```

---

## 6. Checker

Phase 3K-FIX.12 adds:

```text
scripts/check-native-profile-schema.sh
```

The checker is read-only and reports:

```text
MISSING_PROFILE_DIR_COUNT
MISSING_SOUL_COUNT
MISSING_CONFIG_COUNT
MISSING_ENV_COUNT
MISSING_PROFILE_YAML_COUNT
MISSING_SKILLS_DIR_COUNT
MISSING_ALIAS_COUNT
PROFILE_SHOW_SOUL_NOT_CONFIGURED_COUNT
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
SECRET_WRITE=false
```

Expected current result is not full PASS. A PARTIAL result is acceptable if it shows known native gaps without writing files.

---

## 7. Expected Current Interpretation

Given Phase 3K-FIX.11 evidence, expected current state is:

```text
profile directories: present
SOUL.md: present according to doctor
skills/: present but empty
.env: missing
config.yaml: missing
profile.yaml: likely missing
aliases: missing
Hermes CLI discovery: pass
runtime smoke: pending
```

This should be treated as:

```text
PASS / native schema inspection implemented
PARTIAL / native profile schema not fully aligned yet
```

---

## 8. Recommended Phase 3K-FIX.13

```text
Phase 3K-FIX.13 native profile template source alignment
```

Scope:

```text
- add repo-owned SOUL.md for each canonical role if missing from source
- add profile.yaml with role description metadata
- add config.yaml.template only, not real config.yaml
- add .env.template only, not real .env
- update guarded deploy script to handle native schema templates safely
- keep real secret writes disabled
```

Do not run `hermes setup` automatically.

---

## 9. Status Lock Candidate

If checker and docs verify:

```text
Phase 3K-FIX.12 native profile schema alignment planning
PASS / read-only checker added / native schema gaps documented / no real write / no real delete / no secret write
```
