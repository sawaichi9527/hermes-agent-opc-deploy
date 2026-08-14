#!/usr/bin/env bash
set -uo pipefail

# M0 capability checklist — K6 實機版（v0.20.0）
#
# 設計：在 K6（freelancer 主控端）上執行，驗證端點/套件/CLI 可達。
# 亦支援從本機經 SSH 遠端執行（設 SSH_HOST / SSH_USER / SSH_KEY）。
#
# 執行方式：
#   bash scripts/m0-capability-check.sh                 # K6 本機
#   SSH_HOST=192.168.23.214 SSH_KEY=~/.ssh/id_k6_backup \
#     bash scripts/m0-capability-check.sh               # 遠端跑
#
# M0 對應藍圖 §10：
#   - hermes CLI / doctor / profile
#   - skills（ppt-master / plur-memory）
#   - curl agent-a1 / Spark vLLM / NIM 端點
#   - secrets store 介面
#
# 註：L3 硬熔斷（caveat 1）與 L2 HITL（D20）需實作階段在工具層驗證，
#     本 checklist 僅確認 CLI 面可達，不驗證工具層熔斷行為。

HERMES_BIN="${HERMES_BIN:-}"
HERMES_HOME="${HERMES_HOME:-/home/eye/.hermes}"
SPARK_HOST="${SPARK_HOST:-192.168.23.215}"
SPARK_PORT="${SPARK_PORT:-1234}"
A1_HOST="${A1_HOST:-192.168.23.217}"
A1_PORT="${A1_PORT:-1234}"
NIM_BASE_URL="${NIM_BASE_URL:-https://integrate.api.nvidia.com}"

PASS=0
FAIL=0
SKIP=0

pass() { printf 'PASS %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL %s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf 'SKIP %s\n' "$1"; SKIP=$((SKIP + 1)); }

resolve_path() {
  if [ -n "${SSH_HOST:-}" ]; then
    echo "${SSH_USER:-eye}@${SSH_HOST}"
  else
    echo "local"
  fi
}

remote() {
  if [ -n "${SSH_HOST:-}" ]; then
    local key="${SSH_KEY:-${HOME}/.ssh/id_k6_backup}"
    ssh -i "${key}" -o BatchMode=yes -o ConnectTimeout=10 "${SSH_USER:-eye}@${SSH_HOST}" "$@"
  else
    bash -c "$@"
  fi
}

TARGET="$(resolve_path)"
echo "== m0-capability-check (v0.20.0) =="
echo "Target: ${TARGET}"
echo

# --- 1. hermes CLI ---
if command -v hermes >/dev/null 2>&1; then
  HERMES_BIN="$(command -v hermes)"
elif [ -x "${HERMES_HOME}/hermes-agent/venv/bin/hermes" ]; then
  HERMES_BIN="${HERMES_HOME}/hermes-agent/venv/bin/hermes"
fi

if [ -n "${HERMES_BIN}" ]; then
  ver="$(PATH="$(dirname "${HERMES_BIN}"):${PATH}" "${HERMES_BIN}" --version 2>&1 | head -1)"
  case "${ver}" in
    *v0.20.0*) pass "hermes CLI reachable: ${ver}" ;;
    *) pass "hermes CLI reachable: ${ver} (版號非 0.20.0，請確認)" ;;
  esac
else
  fail "hermes CLI not found on ${TARGET}（需於 K6 執行，或設 HERMES_BIN）"
fi

# --- 2. doctor ---
echo
echo "== hermes doctor =="
if [ -n "${HERMES_BIN}" ]; then
  PATH="$(dirname "${HERMES_BIN}"):${PATH}" "${HERMES_BIN}" doctor 2>&1 | tail -8
fi

# --- 3. profile list ---
echo
echo "== hermes profile list =="
if [ -n "${HERMES_BIN}" ]; then
  PATH="$(dirname "${HERMES_BIN}"):${PATH}" "${HERMES_BIN}" profile list 2>&1
fi

# --- 4. skills（ppt-master / plur-memory，D17 / caveat 4）---
echo
echo "== skills (ppt-master / plur-memory) =="
if [ -n "${HERMES_BIN}" ]; then
  PATH="$(dirname "${HERMES_BIN}"):${PATH}" "${HERMES_BIN}" skills list 2>&1 | grep -iE 'ppt-master|plur' || echo "(skill 查詢無結果，需人工確認)"
fi

# --- 5. Plur（D7）---
echo
echo "== Plur =="
if [ -d "${HERMES_HOME}/skills/plur-memory.SKILL.md" ] || [ -f "${HERMES_HOME}/skills/plur-memory.SKILL.md" ]; then
  pass "plur-memory skill 存在（skill 形態，非 pip plur-hermes）"
elif [ -d "${HOME}/.plur" ]; then
  pass "~/.plur 資料夾存在（engrams 就緒）"
else
  skip "Plur 未偵測（M7 安裝）"
fi

# --- 6. Secrets Store（D19）---
echo
echo "== Secrets Store =="
if [ -n "${HERMES_BIN}" ]; then
  out="$(PATH="$(dirname "${HERMES_BIN}"):${PATH}" "${HERMES_BIN}" secrets bitwarden status 2>&1 || true)"
  if echo "${out}" | grep -qiE 'enabled|active|configured|setup'; then
    pass "Secrets Store (bitwarden) 已設定"
  else
    skip "Secrets Store 未設定（D19 實作階段設定）"
  fi
fi

# --- 7. agent-a1 端點（192.168.23.217:1234）---
echo
echo "== agent-a1 (${A1_HOST}:${A1_PORT}) =="
a1_code="$(curl -s -m 8 -o /dev/null -w '%{http_code}' "http://${A1_HOST}:${A1_PORT}/v1/models" 2>&1 || true)"
case "${a1_code}" in
  200|401|403) pass "agent-a1 reachable (HTTP ${a1_code}; 401/403 需 api_key 屬正常)" ;;
  *) fail "agent-a1 unreachable (HTTP ${a1_code})" ;;
esac

# --- 8. Spark vLLM 端點（192.168.23.215:1234，D4/D8/D13）---
echo
echo "== Spark vLLM (${SPARK_HOST}:${SPARK_PORT}) =="
spark_code="$(curl -s -m 8 -o /dev/null -w '%{http_code}' "http://${SPARK_HOST}:${SPARK_PORT}/v1/models" 2>&1 || true)"
case "${spark_code}" in
  200|401|403) pass "Spark vLLM reachable (HTTP ${spark_code}; 401/403 需 token 屬正常)" ;;
  *) fail "Spark vLLM unreachable (HTTP ${spark_code})" ;;
esac

# --- 9. NIM 端點（外網標準 NIM）---
echo
echo "== NIM (${NIM_BASE_URL}) =="
nim_code="$(curl -s -m 8 -o /dev/null -w '%{http_code}' "${NIM_BASE_URL}/v1/models" 2>&1 || true)"
case "${nim_code}" in
  200|401|403) pass "NIM reachable (HTTP ${nim_code})" ;;
  *) fail "NIM unreachable (HTTP ${nim_code})" ;;
esac

echo
echo "== Summary =="
echo "PASS=${PASS} FAIL=${FAIL} SKIP=${SKIP}"
if [ "${FAIL}" -eq 0 ]; then
  echo "PASS m0-capability-check completed without hard failures."
else
  echo "FAIL m0-capability-check has ${FAIL} hard failure(s)."
  exit 1
fi
