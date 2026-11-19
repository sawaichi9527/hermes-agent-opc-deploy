# Kanban Board Dispatch（多 profile 分派機制）

**適用 hermes-agent **v0.23.2**（2026.9.24）。** 取代舊版「直接 spawn wrapper」（`/usr/local/bin/<profile> -z ...`）的任務分派做法。

## 1. 為什麼改走 board（根因）

Freelancer 環境有 **8 個 OPC worker profile**（coordinator / researcher / opencode-researcher / writer / builder / aeon-builder / runes-holder…）全部統一連線**同一台單執行緒本地後端** `192.168.23.217:1234/v1`（ornith-1.5-35b-a3b）。

**chain 斷裂根因**：多個 profile agent 同時直 spawn 連後端 → 併發擠爆單執行緒 → researcher 階段 timeout → chain 崩。

官方無內建「呼叫前讀佇列狀態」機制。**解法是 Kanban `max_in_progress` + dispatcher 限流**，而非自建 gatekeeper proxy。

## 2. 關鍵前提（先驗證再動手）

1. **dispatcher 必須正常 tick**：`hermes kanban diagnostics` 無警報；建一個會 running 的測試 task 看是否派工。
2. **`max_in_progress` 必須真的 enforce**：不同版本 behavior 不同（見版本陷阱）。更新後務必重跑併發測試確認，不要假設設定已生效。
3. **coordinator-as-worker 必須有 kanban 工具**：`kanban_*` 工具只在 dispatcher 派工時自動注入（透過 `HERMES_KANBAN_TASK` env）。正常 chat profile（被 terminal 直叫）**沒有**。驗證：建 assignee=coordinator 的 task，看它回報是否有 kanban_create/show/complete。

## 3. 版本陷阱（重要）

**v0.23.2 重測通過（2026-11-19）**：`max_in_progress_per_profile=1` **已驗證真正 enforce**。建 5 個 researcher ready 任務，dispatcher 維持 running=1（未 enforce 則 running=5）。

歷史版本敘述（僅作版本史參考）：
- **v0.21.1**：`max_in_progress` **不 enforce**。4 個 researcher 同時 running。即使改走 board 也擋不住併發。（歷史敘述，未重測）
- **v0.21.3（2026-09-14）**：`max_in_progress` **真正 enforce**。4 個 researcher → 只剩 1 running + 3 ready。巢狀 spawn 也受 `max_in_progress_per_profile` 限制（coordinator 派 3 個 researcher → 1 running + 2 ready）。（歷史敘述；v0.23.2 已重測通過，見首行）
- 官方文件比本機版本新。**查文獻前先確認本機版本**：`hermes --version`。

## 4. 正式運作流程（secretary 為 board 入口，v0.21.3 落地）

> **設定驗證（2026-11-19）**：以下 knob 仍在 `config.yaml` 的 `kanban:` 區段且已驗證，確認仍適用：
> - `dispatch_interval_seconds: 60`（§4 tick 間隔）
> - `max_in_progress_per_profile: 1`（§3/§5 併發上限）
> - `dispatch_in_gateway: true`
> - `dispatch_stale_timeout_seconds: 14400`（stale reap 閾值，4h）

### 入口指令
```bash
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
$HM kanban create "<任務 brief>" --assignee coordinator \
  --idempotency-key "<描述>-$(date +%s)"
```
dispatcher 預設 **60s tick** 唤醒 coordinator-as-worker（帶 `kanban_*` 工具）。coordinator 在 board 內用 `kanban_create` 派 researcher/writer，每層受 `max_in_progress_per_profile=1` 限流 → 後端同時只接一個 worker。

### 觀察
建立後等 ~70s；`hermes kanban list/stats` 看 running/ready。coordinator 完成後子任務 todo→ready，dispatcher 應顯示 **1 running + N ready**（限流生效）。tick 比直 spawn 慢約 60s。

### 為什麼只有 board 入口可行
coordinator 被 terminal 直叫時是「正常 chat profile」，**沒有 `kanban_*` 工具**（只有 dispatcher 派工才注入）。故 coordinator 自行改走 board 不通——**secretary 必須當入口**。

## 5. 觀察與驗證方法（決定性）
建 N 個會「停留 running」的任務（用 sleep），观察 dispatcher 是否把併發卡在 max_in_progress：
```bash
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
for i in a b c d; do
  $HM kanban create "CONC-TEST: run 'sleep 90' then complete" \
    --assignee researcher --idempotency-key "conc-$i-$(date +%s)"
done
sleep 70
$HM kanban stats | grep -E "running|ready"
# max_in_progress_per_profile=1 應 running=1；若 running=N 全跑 = 未 enforce，需更新。
```
注意：tick 預設 60s（`dispatch_interval_seconds`）。建任務後等一個 tick 才派工。用 `sleep 90` 比 `sleep 30` 更穩。

## 5b. kanban_link 死鎖（實測教訓，2026-09-15）

**陷阱**：coordinator-as-worker 用 `kanban_link` 把自己設為子任務的 parent → 子任務卡在 `todo`（要等 parent `done` 才 promotion），但 parent 要等子任務結果才能完成 → **無限迴圈死鎖**（實測卡 ~11 分鐘）。

**正確模式**：
- `kanban_create` 派單一 worker 時**不帶 parents** → 子任務直接 `ready` → dispatcher 立即派工。
- 完成 parent 時用 `created_cards=[child_id...]` 記錄，**不要**回頭 `kanban_link`。
- `kanban_link` 只用於 fan-in（多個 parent 都完成後 child 才開始）。

> 詳 `editions/opc-personal/profiles/coordinator/SOUL.md.template`「⚠️ kanban_link 死鎖警告」。

## 6. 還原指令（更新出問題時）
```bash
BK=/home/eye/Downloads/hermes_upgrade_backup_*/
cp $BK/config.yaml ~/.hermes/config.yaml
rm -rf ~/.hermes/profiles && cp -r $BK/profiles ~/.hermes/profiles
```

## 7. Cron 與 board 的關係（2026-09-15 實作）

**cron job 是單 profile 自包含任務，不走 board。** 這三類 job 不 spawn LLM chain，所以不消耗 kanban 的 per-profile 配額，也不會觸發 dispatcher 派工：

- **定向情報推送**（job `91d908e7d563`，every 90m）— scan → filter → push 一件
- **Forge Guardrails 專案追蹤**（job `8dc524193079`，every 1440m）
- **繁中後置過濾器**（job `4e1a92d56868`，every 90m）— 純腳本檢查

### 爭用預檢（消除 board × cron 撞車窗口）
情報員掃描前先查 board：
```bash
/home/eye/.hermes/hermes-agent/venv/bin/hermes kanban stats 2>&1 | grep -E "running"
```
- `running > 0` → 本次掃描**直接回 `[SILENT]`**，把後端讓給 kanban chain。
- `running = 0` → 正常執行掃描。

此預檢已加入 job `91d908e7d563` prompt。它是輕量 terminal 呼叫，不消耗 kanban 配額、也不觸發 dispatcher。

### 話題關注清單比對（情報員端）
情報員掃描到候選項目時跑 `/home/eye/workspace/daily/watchlist_match.py --file /tmp/candidates.jsonl`：
- **命中任一 topic keywords** → 直接深度研究並推送（優先於既有判定），寫 signal 檔給 secretary 走 board。
- **未命中** → 走既有判定（major release / breaking change / security risk / real test result / version launch，或 hn_score ≥ 300）。
- watchlist 缺損 → 跳過比對，用既有判定（不中斷掃描）。

## 8. 繁中閘門（補現行過濾器漏洞）

現行「繁中後置過濾器」（cron job `4e1a92d56868`）**只盯情報推送輸出檔**，管不到互動式自動路由（researcher/writer 走 board、不同 profile、不掛 `cron-shared-rules`）。

**secretary 是與使用者之間的唯一交付點**：交付任何自動路由產物給使用者**之前**，先用 `/home/eye/workspace/daily/zh_check.py <file>` 跑一次繁中檢查。FAIL → 不送出，改寫成繁中再送；PASS → 正常交付。

## 9. 取捨記錄（使用者裁決）

- **interval**：情報推送 job `91d908e7d563` 已改為 **every 90m**（與自動路由定時觸發 30m 節拍錯開，撞車機率幾乎為零）。取捨：情報更新慢半拍，但後端更順。
- **鬆動 trigger**：secretary 用自然語言識別意圖——「深入查一下 / 研究一下」→ 完整 chain（board 分派）；「關注一下 / 留意這個 / 這個有意思」→ 只加入關注清單 + 一句快速評估，不拉完整 chain（省本地算力）。

## 10. 記憶層整合（Plur + Runes 在分派中的應用）

kanban board 分派只解決「誰來做、併發控制」，不直接處理「記憶」。兩層記憶堆疊在分派流程中的定位：

### Plur（短/中期跨角色共享記憶）
- **自動注入**：`plur-hermes` plugin 的 `pre_llm_call` hook 已在每次 LLM 前 inject 相關 engram（hybrid search: BM25 + embeddings）。這是現行主要機制，不需要手動調 tool。
- **主動 recall（deliberate recall）**：coordinator 對**高價值/跨領域任務**在產出 handoff packet 前跑 `plur_recall --scope project:freelancer --query "<任務主題>"`，把自動注入可能漏掉的跨領域經驗（既有選型、失敗教訓、workflow 定案）帶進每個 worker 的 handoff。這是對自動注入的**補充**，不是取代。
- **成本取捨**：deliberate recall 增加一次 prefill（你已接受為地端約束）。chain 已長時可只在高價值任務才主動 recall，一般任務靠自動注入即可。
- **Scope 紀律**：新 shared learns 一律 `project:freelancer`（不要散落 `global`）；關鍵長期規則用 `plur promote`（retrieval_strength 0.7）避免衰減。

### Runes MD Wiki（長期受治理證據）
- **唯讀 retrieval**：只有當任務明確需要 Runes context（如 OPC 架構決策、既有治理規則）才路由 runes-holder（coordinator §Runes 唯一路由 hard rule）。一般任務不碰 wiki。
- **沉澱觸發**：任務完成後，coordinator 判斷本次是否有「值得受治理的長期知識」（選型決策、失敗教訓、workflow 定案），若有則產出 wiki candidate 經 secretary 審批（runes-holder Governed Write Flow）。這是把「每次任務的經驗」系統化轉成 governed knowledge 的機制。
- **Downsink**：Runes 可用 + 已批准 → candidate 經 forge native wrapper 下沉；未批准 → 不硬寫 wiki，回 coordinator 標「無 Runes 治理佐證」，PLUR / native memory 扛責。

### 邊界（何時不碰）
- Plur：不把 raw conversation / secrets / full logs 寫進 engram（scope 紀律 + safety boundary）。
- Runes：未批准提案不當 trusted memory；raw conversation / secrets 不複製進 wiki candidate。

## 11. Reporting 邊界缺口（2026-11-19）

**現象**：external cron worker process（如 job `91d908e7d563`）在調用 `kanban_complete` 之前就 exit → 對應 board 任務卡 `blocked`/`unknown`，**永遠不回收**（實測 t_a4b530c8 / t_ae0dc034 / t_f4ebbef7 卡 ~1179h，diagnostics 報 `stuck_in_blocked: age_hours≈1179`）。

**根因（兩層狀態脫鉤）**：
- **Cron 層**：`cron/scheduler_worker_failure.py::record_unknown_worker_outcome()` 把 execution 記 `unknown` + `_deliver_crash_failure()` + `mark_job_run()`，但**不 retire claim、不通知 kanban owner**。
- **Kanban 層**：`hermes_cli/kanban_db_dispatch.py` 的 reap / heartbeat / `enforce_max_runtime()` 皆限 `status='running'` → `blocked`/`unknown` 任務沒有自動 reap 路徑。

**結論**：external worker exit → cron 記 `unknown`、kanban 掉進 `blocked`，兩邊都沒有機制把它推到 terminal 狀態。

**完整修復規格（Option A/B/C）**：見 `/home/eye/Downloads/opc-align-1-reporting-boundary-fix.md`。
- **Option A（最小，推薦先做）**：Kanban reap loop 順道掃描 `blocked`/`unknown` 且 attach 的 external worker PID 已消失的任務，自動標 terminal（或回退 `ready`）——新增 `reap_orphaned_external_tasks()`，不碰 cron ledger。
- **Option B（backstop）**：cron external worker 任務建檔時帶 `max_runtime_seconds`（如 1800），讓 `enforce_max_runtime()` 在預算內 kill 並推到 terminal。
- **Option C（cron 層）**：`record_unknown_worker_outcome()` 記 `unknown` 後順帶把對應 kanban 任務標 `blocked→completed(superseded)` 或通知 creator（需 execution_id → task_id 映射）。

**實作現況（2026-11-19，Option A 已落地）**：
- 改 `hermes_cli/kanban_db_dispatch.py`：新增 `reap_abandoned_tasks()`，reclaim phase 在 `recompute_ready` 之後掃 `blocked`/`unknown` **且** `current_run_id IS NULL` **且**心跳老於 `ABANDONED_AFTER_SECONDS`（預設 3600s=1hr，或降到 45–50min）的任務 → 標 terminal `abandoned`（非 `done`）、關 run、寫 event。不計 `_record_task_failure`。
- 判 hang vs 背景完成仍走本 skill「心跳 ≠ 卡死」段；活著但卡死（有 heartbeat）走 `enforce_max_runtime`，兩者不同柵桿。
- host-specific 重打腳本 + 還原見 hermes-workspace `docs/kanban-abandoned-reap-patch.md`。
- ⚠️ **改的是核心碼非 config，`hermes update` 會蓋掉** → 每次更新後照 `post-upgrade-checklist.md` 檢查此函式是否仍在。

**邊界**：改 dispatcher/cron runtime 原始碼需使用者批准；本檔只记缺口與規格/現況，不實作。

## 12. Hung-worker backstop：`enforce_max_runtime`（2026-11-19 已驗證）

**為什麼需要**：dispatcher stale reap 抓不到「活著但卡死」的 coordinator（它一直 heartbeat，`hb_age < _STALE_HEARTBEAT_GAP=3600`）。唯一能抓 hung worker 的柵桿是 per-task `max_runtime_seconds`（與心跳無關，按總時長 kill）。

**實測驗證（2026-11-19）**：建 researcher 任務 `--max-runtime 25` + body `sleep 90`。結果：
```
timed_out {'elapsed_seconds': 60, 'limit_seconds': 25}
gave_up {'failures': 2, 'error': 'elapsed 60s > limit 25s', 'trigger_outcome': 'timed_out'}
```
worker 在超過 budget 後**一個 dispatcher tick 內被 kill**（status running→blocked），不再掛到 4h stale。機制確定管用。

**Policy（生效中）**：coordinator-as-worker 用 `kanban_create` 派子任務時，一律帶 `--max-runtime`：
- **單層子任務（single researcher/writer）**：`--max-runtime 1800`（30 min，約 normal p95 ~10min 的 3× 安全裕度）。
- **多跳 chain（researcher→writer 等）**：`--max-runtime 3600`（1 hr）。
- 值依 `measured_p95 × 1.5`，夾到 `[1800s, 18000s]`；若誤殺正常長任務再上调。

**耐用層（待實作，需批准）**：目前 `max_runtime_seconds` 無全域 config 預設（`config_defaults.py` 為 None），靠 coordinator 每次手帶。若要「coordinator 忘記也照套」的備層，需在 source（`config_defaults.py` kanban 段）加 seeded default，走 repo `docs/editions/opc-personal/` patch 層（避免 `hermes update` 蓋掉）——此為 source 改動，需 builder + 使用者批准。

---

*本文件為 v0.23.2 的 kanban board dispatch 單一事實來源。核心守則：secretary 是 board 入口、dispatcher enforce per_profile=1（v0.23.2 已重測通過）、cron 不走 board、繁中由 secretary 當閘門、Plur 自動注入 + deliberate recall 補充、Runes 按需 retrieval + 沉澱觸發。*
