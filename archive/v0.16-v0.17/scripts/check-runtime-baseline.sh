#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

printf '== Repository layout ==\n'
bash scripts/verify-repo-layout.sh

printf '\n== Hermes readiness ==\n'
bash scripts/check-hermes-runtime-readiness.sh

printf '\n== Local provider ==\n'
bash scripts/smoke-local-provider-sequential.sh

printf '\n== Hermes oneshot ==\n'
bash scripts/smoke-hermes-runtime-oneshot.sh

printf '\nPASS runtime baseline check completed\n'
