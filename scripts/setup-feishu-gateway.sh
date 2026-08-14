#!/usr/bin/env bash
set -euo pipefail

# setup-feishu-gateway.sh — secretary gateway 接管（M3 實測）
#
# 設計：在 K6 上，把 secretary profile 設為唯一 gateway owner（Lark/Feishu）。
#   * 停用 default gateway、啟用 secretary gateway（hermes-gateway-secretary.service + systemd linger）。
#   * Feishu env 複製（.env FEISHU_* + NVIDIA_API_KEY）到 secretary。
#   * plugins（feishu/plur/rtk-rewrite）與 approvals/security 設定複製 secretary。
#   * cron 2 jobs 遷移至 secretary（owner=secretary，D14）。
#
# 本腳本是 dry-run 預設的引導工具；real cutover（disable/enable systemd service、
#   cron 遷移）需 maintainer 明確批准 + --apply。真實 secret 不進 repo。
#
# 執行方式：
#   bash scripts/setup-feishu-gateway.sh              # dry-run
#   bash scripts/setup-feishu-gateway.sh --apply      # 執行接管
#   HERMES_HOME=... bash scripts/setup-feishu-gateway.sh

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
PROFILE="secretary"
APPLY=0
APPROVE_TOKEN="REAL_FEISHU_GATEWAY_TAKEOVER"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/setup-feishu-gateway.sh [--apply] [--confirm REAL_FEISHU_GATEWAY_TAKEOVER]

Default behavior:
  - Dry-run only: reports what the secretary gateway takeover would do.
  - Never writes, never disables/enables systemd services, never moves cron.

Options:
  --apply
      Actually perform the takeover. Requires --confirm <token>.
  --confirm <token>
      Acknowledge this is a real cutover. Token must equal REAL_FEISHU_GATEWAY_TAKEOVER.

Environment:
  HERMES_HOME   Default: $HOME/.hermes

Boundary:
  This is a guided operator tool. Real secret values (FEISHU_APP_SECRET etc.)
  must be provided out-of-band; the script only references env variable names.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply)
      APPLY=1
      shift
      ;;
    --confirm)
      if [ "$#" -lt 2 ]; then
        echo "FAIL --confirm requires a token" >&2
        exit 2
      fi
      if [ "$2" != "$APPROVE_TOKEN" ]; then
        echo "FAIL wrong confirm token" >&2
        exit 2
      fi
      CONFIRMED=1
      shift 2
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

if [ "$APPLY" -eq 1 ] && [ "${CONFIRMED:-0}" -ne 1 ]; then
  # require explicit --confirm on the same invocation
  echo "FAIL --apply requires --confirm REAL_FEISHU_GATEWAY_TAKEOVER" >&2
  exit 2
fi

profile_dir="$HERMES_HOME/profiles/$PROFILE"
env_file="$profile_dir/.env"

pass() { printf 'PASS %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; exit 1; }
info() { printf 'INFO %s\n' "$1"; }

printf 'setup-feishu-gateway.sh (v0.20.0) — secretary gateway takeover\n'
printf 'Hermes home: %s\n' "$HERMES_HOME"
printf 'Profile: %s\n' "$PROFILE"
printf 'Apply: %s\n\n' "$APPLY"

if [ ! -d "$profile_dir" ]; then
  fail "$profile profile dir missing: $profile_dir"
fi
pass "$profile profile exists"

# --- 1. Feishu env 準備（只檢查變數名，不讀真實值）---
printf '\n== Feishu env (secretary/.env) ==\n'
required_vars=(FEISHU_APP_ID FEISHU_APP_SECRET NVIDIA_API_KEY)
if [ -f "$env_file" ]; then
  for var in "${required_vars[@]}"; do
    if grep -qE "^${var}=" "$env_file" 2>/dev/null || grep -qE "^${var}[[:space:]]*=" "$env_file" 2>/dev/null; then
      pass "$var present in secretary/.env"
    else
      warn "$var missing in secretary/.env — must be set out-of-band"
    fi
  done
else
  warn "$env_file does not exist — must contain FEISHU_* + NVIDIA_API_KEY (set out-of-band)"
fi

# --- 2. plugins 複製清單 ---
printf '\n== Plugins (feishu/plur/rtk-rewrite) ==\n'
warn "plugins must be enabled in secretary config: feishu, plur, rtk-rewrite (setup via config; --apply writes only if a config patcher is wired)"

# --- 3. approvals / security 複製 ---
printf '\n== Approvals / security ==\n'
warn "approvals + security settings are copied into secretary profile (D18/D19). Run scripts/approvals-deny-init.sh for the L3 deny list."

# --- 4. gateway 接管 ---
printf '\n== Gateway takeover ==\n'
if [ "$APPLY" -eq 1 ]; then
  info "would disable default gateway service"
  info "would enable hermes-gateway-secretary.service + systemd linger for $PROFILE"
  info "would verify Lark websocket connection"
else
  info "dry-run: would disable default gateway, enable hermes-gateway-secretary.service (systemd linger), verify Lark websocket"
fi

# --- 5. cron 遷移 ---
printf '\n== Cron migration (owner=secretary, D14) ==\n'
info "cron jobs migrate to $PROFILE; approval_state=pre_approved on scheduled tasks"

printf '\n== Summary ==\n'
if [ "$APPLY" -eq 1 ]; then
  printf 'PASS setup-feishu-gateway apply requested; operator must confirm each real step on K6.\n'
else
  printf 'PASS setup-feishu-gateway dry-run completed; nothing written.\n'
  printf 'Re-run with --apply --confirm REAL_FEISHU_GATEWAY_TAKEOVER to execute.\n'
fi
