#!/usr/bin/env bash
set -euo pipefail

# M0 capability checklist（骨架模式，階段一）
#
# 驗證項目在 M0（K6 實機）執行，確認端點/套件/CLI 可達。目前為骨架，
# 每個檢查點為「待 M0 填入實際指令」的佔位（TODO）。
#
# 對應藍圖 §10 M0：
#   - hermes --help / hermes profile --help
#   - pip show plur-hermes
#   - curl agent-a1 / Spark vLLM /v1/models / NIM 端點可達
#   - hermes doctor PASS

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ISSUES=0
PENDING=0

check_pending() {
  local name="$1"
  echo "PENDING ${name} — 待 M0 填入實際指令"
  PENDING=$((PENDING + 1))
}

echo "== m0-capability-check.sh (skeleton) =="
echo "Repo root: ${REPO_ROOT}"
echo

check_pending "hermes CLI reachability"
check_pending "hermes profile --help"
check_pending "pip show plur-hermes"
check_pending "agent-a1 endpoint reachable"
check_pending "Spark vLLM /v1/models reachable"
check_pending "NIM endpoint reachable"
check_pending "hermes doctor PASS"

echo
echo "== Summary =="
echo "PENDING_CHECKS=${PENDING}"
echo "FAILED_CHECKS=${ISSUES}"
if [ "${ISSUES}" -eq 0 ]; then
  echo "PASS m0-capability-check skeleton loaded; all checks pending M0."
else
  echo "FAIL m0-capability-check has ${ISSUES} issue(s)."
  exit 1
fi
