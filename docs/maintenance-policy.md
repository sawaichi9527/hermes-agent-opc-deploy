# Maintenance Policy

This repository is maintained as a lightweight personal-use companion around upstream Hermes Agent.

## Operating model

Default contribution flow:

1. Update this GitHub repository directly when the connector can perform the change safely.
2. The user pulls the repository locally into `~/workspace/hermes-agent-opc-deploy` and validates the result.
3. Only ask the user to run patch scripts when GitHub connector limitations prevent direct edits.
4. For unusually large files where chat code blocks may be unreliable, generate the full file as a downloadable artifact and provide the target repository path for manual upload/overwrite.

## Local working copy

The expected local checkout path is:

```text
~/workspace/hermes-agent-opc-deploy
```

Normal validation flow after direct GitHub updates:

```bash
cd ~/workspace/hermes-agent-opc-deploy
git pull
./scripts/verify-layout.sh
git status --short
```

If the local clone does not exist yet:

```bash
mkdir -p ~/workspace
cd ~/workspace
git clone git@github.com:sawaichi9527/hermes-agent-opc-deploy.git
cd hermes-agent-opc-deploy
./scripts/verify-layout.sh
```

HTTPS clone may be used instead when SSH is not configured.

## Artifact handoff fallback

Use this only when direct GitHub edits or chat patch blocks are not reliable, such as very large files or connector limits.

Fallback convention:

1. Generate a complete replacement file as a downloadable artifact.
2. The user downloads it to `~/Downloads`.
3. The assistant provides the exact target path under `~/workspace/hermes-agent-opc-deploy`.
4. The user copies the file into place, verifies, commits, and pushes.

Example copy and commit flow:

```bash
cd ~/workspace/hermes-agent-opc-deploy

cp ~/Downloads/<downloaded-file> <target/path/in/repo>

./scripts/verify-layout.sh
git status --short
git diff -- <target/path/in/repo>

git add <target/path/in/repo>
git commit -m "Update <target description>"
git push
```

The assistant should avoid asking the user to manually copy many small files when direct GitHub updates are available.

## Scope control

Keep the system simple and useful for one-person or small personal lab usage.

Do not introduce enterprise-scale features such as:

- multi-tenant control planes
- distributed job queues
- complex service meshes
- centralized policy engines
- production deployment gates
- database-backed orchestration layers
- heavy observability stacks

Prefer:

- official Hermes Agent behavior
- official Hermes profiles
- small Markdown templates
- simple shell helpers
- local verification scripts
- clear migration notes

## Upstream-first rule

Hermes Agent is the runtime owner. This repository should adapt to Hermes Agent, not compete with it.

When upstream Hermes Agent changes profile behavior, prefer small template and documentation updates here instead of building a compatibility layer that hides upstream behavior.

## Burden rule

This repository must not become a burden for Hermes Agent.

Hermes Agent must continue to work in both modes even if this repository is absent:

- default one-agent usage
- official-profile OPC-style usage

The optional runes-holder and hermes-runes-md-wiki path are extra knowledge sedimentation aids only.

## Secrets rule

Never commit real secrets or live runtime state.

Do not commit:

- `.env`
- API keys
- tokens
- passwords
- state databases
- sessions
- logs
- caches
- large artifacts

Use template files with safe placeholder values only.
