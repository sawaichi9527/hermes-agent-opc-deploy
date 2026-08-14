# Phase 3K-FIX.8 Canonical Role Content Hardening

Status: implemented / pending local verification  
Scope: repo source content only  
Real profile write: not executed  
Real profile delete: not executed

## Purpose

Phase 3K-FIX.8 adds minimal readable README content for the six canonical Hermes profile roles.

This phase follows the taxonomy correction work from Phase 3K-FIX.1 through Phase 3K-FIX.7.

It does not deploy the content to real `~/.hermes/profiles/`.

## Canonical Roles

The canonical profile roles are sourced from:

```text
config/profile-roles.txt
```

Expected roles:

```text
secretary
coordinator
researcher
writer
builder
runes-holder
```

## Added Source Files

Phase 3K-FIX.8 adds:

```text
profiles/secretary/README.md
profiles/coordinator/README.md
profiles/researcher/README.md
profiles/writer/README.md
profiles/builder/README.md
profiles/runes-holder/README.md
```

Each README documents:

- role purpose
- responsibilities
- operating boundary
- allowed behavior
- disallowed behavior
- governance notes

## Safety Boundary

This phase modifies repo source content only.

It does not run:

```text
scripts/deploy-real-profiles.sh --apply
scripts/cleanup-drift-profiles.sh --apply
```

Expected flags remain:

```text
REAL_PROFILE_WRITE=false
REAL_PROFILE_DELETE=false
```

## Expected Verification

Run from repo root:

```bash
for role in secretary coordinator researcher writer builder runes-holder; do
  test -f "profiles/$role/README.md" && echo "PASS canonical README exists $role"
done
```

Check content headings:

```bash
grep -n \
  "Status: Phase 3K-FIX.8 canonical role content hardening\|Operating Boundary\|Governance Notes\|Real deployment: guarded apply only" \
  profiles/secretary/README.md \
  profiles/coordinator/README.md \
  profiles/researcher/README.md \
  profiles/writer/README.md \
  profiles/builder/README.md \
  profiles/runes-holder/README.md
```

Check readiness remains READY:

```bash
./scripts/check-real-deploy-readiness.sh | grep -E \
  "ROLE_COUNT=6|SOURCE_STATUS=complete|DESTINATION_STATUS=pass|RESTORE_PLANNER_STATUS=pass|READINESS_STATUS=READY|REAL_PROFILE_WRITE=false|REAL_RESTORE_WRITE=false"
```

Check real drift profiles remain absent:

```bash
for role in default developer reviewer operator trial; do
  test ! -e "$HOME/.hermes/profiles/$role" && echo "PASS real drift profile absent $role"
done
```

Check repo drift sources remain absent:

```bash
for role in default developer reviewer operator trial; do
  test ! -e "profiles/$role" && echo "PASS repo drift source absent $role"
done
```

## Expected Lock Result

After local verification passes, Phase 3K-FIX.8 may be locked as:

```text
Phase 3K-FIX.8 canonical role content hardening
PASS / six canonical README profiles added / readiness READY / repo drift absent / real drift absent / no real write / no real delete
```

## Next Phase

Recommended next phase:

```text
Phase 3K-FIX.9 canonical content guarded apply planning
```

The next phase should plan a guarded deploy of canonical profile content to real `~/.hermes/profiles/`, but should not automatically apply it.
