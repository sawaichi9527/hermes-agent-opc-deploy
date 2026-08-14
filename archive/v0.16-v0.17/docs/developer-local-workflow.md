# Developer Local Workflow

This document is for the repository maintainer's local development and debugging workflow.

It is not required for general users who only want to fork or read this repository.

## Maintainer local path

The maintainer keeps a working clone at:

```text
~/workspace/hermes-agent-opc-deploy
```

Normal sync and validation flow:

```bash
cd ~/workspace/hermes-agent-opc-deploy
git pull
bash scripts/verify-layout.sh
git status --short
```

`bash scripts/verify-layout.sh` is preferred over direct execution because files created through GitHub's contents API may not preserve the executable bit.

## Optional executable bit fix

If the maintainer wants direct execution to work locally:

```bash
cd ~/workspace/hermes-agent-opc-deploy
chmod +x scripts/verify-layout.sh
git status --short
```

If Git reports a mode change, it can be committed:

```bash
git add scripts/verify-layout.sh
git commit -m "Make verify-layout executable"
git push
```

This is optional. The repository should remain usable with:

```bash
bash scripts/verify-layout.sh
```

## Download handoff fallback

When direct GitHub edits are blocked by connector limits, or when a file is too large for reliable chat code-block patching:

1. The assistant generates a complete replacement file.
2. The maintainer downloads it to `~/Downloads`.
3. The assistant provides the exact copy command into `~/workspace/hermes-agent-opc-deploy`.
4. The maintainer verifies, commits, and pushes.

Template flow:

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

## Scope reminder

This workflow exists for maintainer convenience only.

The repository remains a lightweight deployment companion around upstream Hermes Agent official profiles. It must not become a parallel runtime, enterprise control plane, or operational burden for Hermes Agent.