# coordinator hung-worker — 本地解碼後端零輸出 stall（`local_stream_stale_timeout`）

**適用 hermes-agent v0.23.2**（commit `ae2a81ccc00e`）｜記錄日期：2026-11-18
**背景**：coordinator 分派給 researcher/writer 的 kanban 任務在本機發生第 4 次 hung-worker。本文記錄從「orchestration 層」到**實測證實的本地解碼後端 stall** 的根因，以及已套用的修復（**待觀察，未標定完全解決**）。

---

## 1. 問題

coordinator（`local-e769f47c…`）分派的 kanban 任務（例 `t_ee930e8e`：light research + write）卡在 `running`：
- events 只剩 heartbeat，**無新 comment/spawn、無 deliverable**。
- 早期懷疑是 orchestration 層（dispatcher stale reap 抓不到「活著但卡死」的 worker + coordinator completion-deferral + 本地小模型慢），詳 `coordinator-hung-worker` skill。

---

## 2. 診斷（實測證實：主因在本地解碼後端層）

SSH 到本地後端機 `192.168.23.217`，讀 coordinator worker 的 agent log：
```
~/.hermes/profiles/coordinator/logs/agent.log   (session local-e769f47c…, 任務 t_ee930e8e)
```

**關鍵線索（agent.log 實測）**：
- 17:41 coordinator 做完 tool listing、發出第一個請求後 → **HTTP 200 但 ~900s 零輸出**：
  `Stream stale for 900s — no chunks received`、`http_status=200 bytes=0 chunks=0 ttfb=-`。
- context **凍在 ~32,569 tokens** 全程沒長（**從未派 researcher**）；重試 3 次每次仍卡 900s；18:45「Model unloaded」。
- worker 心跳一直跳 → kanban stale 偵測（需 3600s 無心跳）漏掉它。

**推翻了「tool-call 重複迴圈」假說**：實際是**零輸出 stall**（非產生垃圾），但與 LM Studio `token-counter-frozen` case 同類漏洞——**後端活著卻不產出，心跳讓 kanban 偵測漏掉**。

⚠️ **未 100% 證實 engine 層具體卡點**（prefill stall vs decode stall）：LM Studio server-log 拿不到（`.217` 當時沒跑 LM Studio、log 找不到）。但 agent.log 確證是**後端輸出 stall，非分派缺陷**。

---

## 3. 解法：`agent.local_stream_stale_timeout` 900 → 300

本地端点的 stale-stream 天花板（base 180s，本地預設拉高到 900s）降到 **300s（5min）**。每次 stall 從 15min 縮到 5min，重試損傷成比例下降。

**⚠️ 寫錯檔會靜默失效（與 concurrency fix 同坑）**：
- 每個 **named profile 只讀自己的 `~/.hermes/profiles/<name>/config.yaml`（不併合併全域 `~/.hermes/config.yaml`）**。
- 改全域無效——實測 `hermes -p coordinator config get agent.local_stream_stale_timeout` 仍是 900。
- **判準**：只有**打到本地 ornith 後端（`192.168.23.217:1234/v1`）**的 profile 才需要。已逐檔寫入：

| profile | 端點 | 改前 | 改後 |
|---|---|---|---|
| secretary | local ornith @.217 | 900 | **300** |
| coordinator | local ornith @.217 | 900 | **300** |
| researcher | local ornith @.217 | 900 | **300** |
| writer | local ornith @.217 | 900 | **300** |
| runes-holder | local ornith @.217 | 900 | **300** |
| builder | local ornith @.217 | 900 | **300** |
| aeon-builder | remote `aeon` @ **192.168.23.215** | — | 未改（遠端 DGX vLLM） |
| opencode-researcher | cloud deepseek (opencode-go) | — | 未改（雲端） |

每檔把 `agent: {}` 改成：
```yaml
agent:
  local_stream_stale_timeout: 300
```

**無需重啟**：`load_config_readonly()` 依檔案 mtime 快取、**每次串流請求重新讀取**，改完下次請求即生效（與 concurrency fix 的 `max_in_progress_per_profile` 不同——後者需重啟）。

---

## 4. 驗證

```bash
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
for p in secretary coordinator researcher writer runes-holder builder; do
  $HM -p $p config get agent.local_stream_stale_timeout   # 全 = 300 ✅
done
```

6 個本地後端 profile 皆解析到 300；aeon-builder / opencode-researcher 保持 900（不打本地端點，正確未動）。

---

## 5. 待觀察（未標定完全解決）

接下來真實 `coordinator → researcher → writer` 全鏈若再卡：
- **正常**：應在 **~5min** 內由 stale 偵測觸發（而非拖到 15min）。
- **仍卡死 / 出现「一直吐 chunk 永不結束」**（runaway / trickling——stale 偵測每收到 chunk 就重置、抓不到）→ 再考慮加 `agent.stream_max_lifetime`（單次串流總牆鐘上限，見官方 configuration.md §API Timeouts）。

備用 backstop：kanban `enforce_max_runtime`（per-task `max_runtime_seconds`）仍是任務層柵桿，尚未設，待觀察是否需雙重防護。

---

## 6. 重灌 / 接手檢查點

```bash
# 1. 6 個本地後端 profile 皆應 = 300（非全域、非預設 900）
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
for p in secretary coordinator researcher writer runes-holder builder; do
  $HM -p $p config get agent.local_stream_stale_timeout
done

# 2. 全鏈實測：派一個真實 research+write 任務走 board，觀察卡住時長
#    應 ~5min 內由 stale 觸發；若仍拖 ~15min = 設定未生效（寫錯檔或寫到全域）
```

> ⚠️ `hermes update` 不會動這些 profile config（是 repo/config 設定，非 source patch）。但若哪天改到 source（如 stale 偵測邏輯），仍需依對應 fix doc 重放。

---

*來源：本機實測（SSH `.217` 讀 coordinator agent.log、`hermes -p <profile> config get`）+ 官方 configuration.md §API Timeouts + repo `hermes-upgrade-v0232-concurrency.md` / `kanban-dispatch.md` / `handoff.md`。*
