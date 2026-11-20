# Post-Upgrade Checklist（`hermes update` 後必查）

> 每次 `hermes update` 會重寫 hermes-agent 核心原始碼與部分 config seeded 值。
> 本機對 OPC 部署做的自訂改動會被蓋掉或重置。更新後照此清單逐一檢查/重打，
> 否則「活著但卡死」worker 的 safety net、per-profile stale timeout 等會悄悄消失。
> 架構層可复用；host-specific 重打腳本見 hermes-workspace `docs/kanban-abandoned-reap-patch.md`。

## 0. 更新前先做
- [ ] `git stash` / commit 本機未推送的自訂（config、patch 副本）。
- [ ] 備份 `~/.hermes/`（至少 config.yaml、各 profile config.yaml、kanban.db）。
- [ ] 記下本次 version tag，更新後 `hermes --version` 確認落點。

## 1. Dispatcher / kanban runtime（⭐ 最關鍵）
- [ ] **abandoned-reap 函式仍在？**
  ```bash
  grep -c "def reap_abandoned_tasks(" \
    /home/eye/.hermes/hermes-agent/hermes_cli/kanban_db_dispatch.py
  # 應 = 1；=0 表示被蓋掉，照 hermes-workspace docs/kanban-abandoned-reap-patch.md §4 重打。
  ```
- [ ] `ABANDONED_AFTER_SECONDS` 常數仍在（預設 3600）。
- [ ] `enforce_max_runtime()` 仍在、簽名沒變。
- [ ] dispatcher 重啟：`systemctl --user restart hermes-gateway.service`。
- [ ] 重啟後確認 board 正常分派（建一支 short sleep researcher task 看 running=1）。

## 2. kanban config section（config.yaml `kanban:`）
更新若重置 config，逐項核對仍在：
- [ ] `dispatch_interval_seconds: 60`
- [ ] `max_in_progress_per_profile: 1`（限流保護單執行緒後端）
- [ ] `dispatch_in_gateway: true`
- [ ] `dispatch_stale_timeout_seconds: 14400`

## 3. Per-profile local_stream_stale_timeout（本地小模型專用）
> 每個 named profile 只讀**自己的** `~/.hermes/profiles/<name>/config.yaml`（不合併全域）。
> 改全域無效，必須逐檔。
- [ ] 凡打到本地 ornith 後端（`192.168.23.217:1234`）的 profile，`agent.local_stream_stale_timeout`
     應 = **900**（⚠️ **11-20 由 300 改回 900**；11-18 曾設 300，已被實測反轉——單槽後端排隊 TTFT 實測 400.8 s > 300 会误杀健康请求）。涉及：secretary、coordinator、researcher、writer、runes-holder、builder。
- [ ] `load_config_readonly()` 依 mtime 快取、每次串流重讀 → **無需重啟**，下次請求即生效。

## 4. config_defaults.py seeded defaults（若曾實作）
- [ ] 若曾往 `config_defaults.py` 灌 `max_runtime_seconds` 全域預設 → `hermes update` 會蓋掉，
     需重灌或改走 per-task `--max-runtime`。
- [ ] 核對 `config_defaults.py` 未被更新無意重置其他預設值。

## 5. 驗證收尾
- [ ] 跑一次真實 `secretary → coordinator → researcher/writer` 全鏈，確認分派/heartbeat 正常。
- [ ] 故意派一支會空轉的 coordinator task，確認它在 `--max-runtime` 預算內被 kill（backstop 還活）。
- [ ] board 上舊 abandoned 卡確認沒被重派。

## 6. 還原（更新出問題）
- [ ] config：從更新前備份蓋回各 `config.yaml`。
- [ ] core patch：`cp` 對應 `.bak.<timestamp>` 蓋回，重啟 gateway。
- [ ] kanban.db：若異常，從備份還原後重啟。

---
維護註記：本清單隨 OPC 部署自訂項增減而更新。每次新增一處會更新被蓋掉的自訂，就補進相對 section。
