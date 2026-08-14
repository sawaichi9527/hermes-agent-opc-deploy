#!/usr/bin/env bash
set -euo pipefail

# jobs-json-init.sh — 初始化 ~/.hermes/opc/jobs.json（v4.1 欄位，M4 實測）
#
# 設計：建立 OPC 任務可觀測性檔 jobs.json（若不存在）。
#   * 每任務欄位：task_id, profile, model_used, started_at, last_ping_at,
#     status, evidence_urls, approval_state, host
#   * 計數欄：moa_trigger_count（nim ≤3）、daily_token_used
#   * 空 array 即為合法初始狀態；本腳本只建骨架，不塞任務。
#
# dry-run 預設：--apply 才真的寫檔。
#
# 執行方式：
#   bash scripts/jobs-json-init.sh            # dry-run（顯示目標路徑與內容）
#   bash scripts/jobs-json-init.sh --apply    # 建立檔案
#   HERMES_HOME=... bash scripts/jobs-json-init.sh --apply

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
JOBS_DIR="$HERMES_HOME/opc"
JOBS_FILE="$JOBS_DIR/jobs.json"
APPLY=0

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/jobs-json-init.sh [--apply]

Default behavior:
  - Dry-run only: prints the target path and the initial skeleton content.

Options:
  --apply
      Create $HERMES_HOME/opc/jobs.json if it does not exist.
      If it already exists, the script leaves it untouched.

Environment:
  HERMES_HOME   Default: $HOME/.hermes

Boundary:
  Creates an empty jobs collection only. No secrets are written
  (G-B4: never log tokens/SSH keys/passwords).
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply)
      APPLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "FAIL unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

skeleton='{
  "version": "1",
  "schema": "opc-jobs-json-v4.1",
  "jobs": [],
  "note": "每任務欄位: task_id, profile, model_used, started_at, last_ping_at, status, evidence_urls, approval_state, host; 計數: moa_trigger_count (nim <=3), daily_token_used. 禁止記 secret (G-B4/D19)."
}'

printf 'jobs-json-init.sh (v0.20.0) — initialize jobs.json\n'
printf 'Target: %s\n' "$JOBS_FILE"
printf 'Apply: %s\n\n' "$APPLY"

if [ -f "$JOBS_FILE" ]; then
  printf 'PASS jobs.json already exists at %s (left untouched)\n' "$JOBS_FILE"
  exit 0
fi

if [ "$APPLY" -eq 1 ]; then
  mkdir -p "$JOBS_DIR"
  printf '%s\n' "$skeleton" > "$JOBS_FILE"
  printf 'PASS created %s\n' "$JOBS_FILE"
  printf 'Verify:\n  hermes config / cat %s\n' "$JOBS_FILE"
else
  printf 'INFO dry-run would create %s with:\n%s\n' "$JOBS_FILE" "$skeleton"
  printf 'Re-run with --apply to create it.\n'
fi
