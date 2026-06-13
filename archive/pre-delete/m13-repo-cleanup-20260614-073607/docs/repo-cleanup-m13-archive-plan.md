# M13 Repository Archive Staging Plan

Status: DRAFT / archive staging only / no deletion

## Purpose

Reduce mainline repository noise after the M12 Hermes-native OPC runtime baseline lock.

This cleanup does not delete files. It moves older planning, pre-production, and superseded verification material into `archive/pre-delete/` so the maintainer can review before final deletion.

## Cleanup Rule

Keep mainline focused on the current baseline:

- Hermes-native profile creation by `hermes profile create <profile> --clone`
- profile-specific doc overlay scripts
- M12 runtime baseline verification
- current profile templates under `profiles/`

Move older or superseded material to archive.

## Protected Mainline Content

Do not move:

- `README.md`
- `profiles/**`
- `docs/verification-m12-native-opc-runtime-baseline.md`
- `scripts/verify-m12-native-opc-runtime-baseline.sh`
- `scripts/create-*-profile-clone.sh`
- `scripts/apply-*-runtime-doc-overlay.sh`
- `.gitignore`
- current archive README files

## Archive Candidate Rationale

### Historical verification docs

Older M4-M9 verification files are preserved as history but no longer represent the active baseline after M12.

### Pre-production / dry-run docs

Earlier pre-production deployment planning docs were superseded by the M12 runtime rule:

```text
Hermes creates the profile.
Repo only overlays SOUL.md / NOTES.md / profile.yaml / README.md.
.env and config.yaml are protected.
```

### Superseded scripts

Older scripts that can touch native templates, provisioning, or pre-M12 dry-run deployment are moved out of mainline to reduce accidental use.

## Important Follow-up

After applying this archive staging, `scripts/verify-repo-layout.sh` may still reference older files. Update the layout verifier in the next cleanup step before treating repository layout verification as final.
