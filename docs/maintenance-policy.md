# Maintenance Policy

This repository is maintained as a lightweight personal-use companion around upstream Hermes Agent.

## Operating model

Default maintenance flow:

1. Update this GitHub repository directly when the connector can perform the change safely.
2. The maintainer pulls the repository locally into `~/workspace/hermes-agent-opc-deploy` and validates the result.
3. Only ask the maintainer to run patch scripts when GitHub connector limitations prevent direct edits.
4. For unusually large files where chat code blocks may be unreliable, generate the full file as a downloadable artifact and provide the target repository path for manual upload or overwrite.

This flow is for the repository maintainer's development and debugging workflow. It is not a requirement for general users who only want to fork or study the repository.

## Local working copy

The expected maintainer checkout path is:

```text
~/workspace/hermes-agent-opc-deploy
```

Normal validation flow after direct GitHub updates:

```bash
cd ~/workspace/hermes-agent-opc-deploy
git pull
bash scripts/verify-layout.sh
git status --short
```

Use `bash scripts/verify-layout.sh` instead of direct execution because files created through GitHub's contents API may not preserve the executable bit.

If the local clone does not exist yet:

```bash
mkdir -p ~/workspace
cd ~/workspace
git clone git@github.com:sawaichi9527/hermes-agent-opc-deploy.git
cd hermes-agent-opc-deploy
bash scripts/verify-layout.sh
```

HTTPS clone may be used instead when SSH is not configured.

## Artifact handoff fallback

Use this only when direct GitHub edits or chat patch blocks are not reliable, such as very large files or connector limits.

Fallback convention:

1. Generate a complete replacement file as a downloadable artifact.
2. The maintainer downloads it to `~/Downloads`.
3. The assistant provides the exact target path under `~/workspace/hermes-agent-opc-deploy`.
4. The maintainer copies the file into place, verifies, commits, and pushes.

Example copy and commit flow:

```bash
cd ~/workspace/hermes-agent-opc-deploy

cp ~/Downloads/<downloaded-file> <target/path/in/repo>

bash scripts/verify-layout.sh
git status --short
git diff -- <target/path/in/repo>

git add <target/path/in/repo>
git commit -m "Update <target description>"
git push
```

The assistant should avoid asking the maintainer to manually copy many small files when direct GitHub updates are available.

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

## Sensitive local data rule

Never commit live local runtime state or machine-specific private material.

Do not commit real local credentials, profile session databases, cache dumps, logs, or large artifacts. Use template files with safe placeholder values only.
