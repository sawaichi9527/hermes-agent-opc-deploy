# Session 機制（gateway 持久 vs oneshot 每任務新 session）

**確認日期**：2026-08-18。適用 hermes-agent **v0.20.1**。資料來源：K6（eye@192.168.23.214）hermes-agent 原始碼 + 各 profile `state.db` 實機資料交叉驗證。

## 結論（TL;DR）

OPC 8-profile 系統存在**兩種截然不同的 session 生命週期**：

| | Secretary | Coordinator / 6 個 worker |
|---|---|---|
| 執行形態 | 常駐 gateway process（Lark websocket） | 每次任務一個獨立 hermes process（`-z` oneshot） |
| Session | **持久**，per Lark chat | **每次全新**，一任務一 session |
| 跨任務對話記憶 | 有（同一 chat 沿用） | 無（每次空 session 起手） |

**全系統只有 secretary 是持久 session**（跟使用者的 Lark 聊天綁定）。只要被 coordinator 指派，其他 agent（researcher / nim-researcher / writer / builder / aeon-builder / runes-holder）就是全新 oneshot process + 全新 session；**coordinator 自己也是**（被 secretary 用同樣方式呼叫）。

## 1. Secretary ＝ 持久 session per Lark chat（gateway）

Secretary 以常駐 gateway 執行（`hermes-gateway-secretary.service`，Lark websocket）。

### 機制（`gateway/session.py`）

- **Session key 依 chat 決定性產生**：`build_session_key()` 用 chat 來源（平台 + chat_id + thread）組出固定字串，例如
  `agent:main:feishu:dm:oc_477b680002fee10f22674dd37da5ebd6`
  - 註：單 profile gateway 用 `agent:main` namespace；multiplexing gateway 才傳 profile 進 namespace。
- **找到即沿用、沒有才建立**：`get_or_create_session()` 依 session_key 查詢既有 session，存在就回傳同一 session → **同一個 Lark DM 的所有訊息共用一個 session**（message_count 一路累積）。
- **`/new` ＝ `force_new`**：在同一 chat 開**新的 session_id**（session_key 不變），新舊 session 以 `prev_session_id` 記錄連續性。這正是 session 10「cwd record 固化在舊值、`/new` 重置」的根因。
- **key → session_id 對應持久化**：`state.db` 的 `gateway_routing` table（`scope + session_key → entry_json`，內含現行 session_id）。

### 實證（secretary `state.db`）

同一 session_key 累積出多個 session（即 `/new` 歷史）：

```
20260818_122157_60dd90b7|feishu|agent:main:feishu:dm:oc_477b...|135
20260818_111945_a0c48d6d|feishu|agent:main:feishu:dm:oc_477b...|41
20260815_032511_c0963027|feishu|agent:main:feishu:dm:oc_477b...|84   ← handoff 提到的長對話 session
```

### cron 入口

cron 任務也從 secretary 執行，每次 run 一個獨立 session（source=`cron`）：

```
cron_91d908e7d563_20260818_171414|cron|secretary
cron_91d908e7d563_20260818_161214|cron|secretary
```

## 2. Coordinator / workers ＝ 每次指派全新 session（`-z` oneshot）

SOUL 的實際呼叫方式 `/usr/local/bin/<profile> -z '<brief>' chat -Q` 是 **oneshot mode**（`hermes_cli/oneshot.py`：*"send a prompt, get the final content block, exit"*）。

### 機制

- 每次呼叫 **spawn 一個全新 hermes process**（session `source=cli`），bypass 互動 CLI：無 banner / 無 spinner / 無 session_id 行，只把 agent 最終文字寫到 stdout 後 exit。
- **無 session_id 傳入** → `agent/agent_init.py:1565` 自動產生
  `{YYYYMMDD_HHMMSS}_{6hex}`（如 `20260818_122611_58bbf4`）。
- `run_agent.py:_ensure_db_session()` 在**第一次 turn 惰性建立** session row（含 profile_name、cwd、source），並把 messages 寫入 `state.db`。
- 跑完單一 conversation → stdout 回傳 → exit → 該 session 結束。

### 實證（researcher / coordinator `state.db`）

```
20260818_122611_58bbf4|cli|researcher|14     ← coordinator 指派的調研
20260818_122342_28fd3e|cli|researcher|36
20260818_122549_a48dde|cli|coordinator|2     ← secretary 指派的協調
```

每次 coordinator 路由 = worker 一任務一新 session row。

## 3. 資料存放

- 每個 profile 有**獨立的 `state.db`**（`~/.hermes/profiles/<role>/state.db`），`sessions` table 記錄所有 session（source 分 `cli` / `feishu` / `cron`）。
- 另有 `messages`（含 FTS）、`gateway_routing`、`session_turn_leases` 等 table。
- 來源分類判讀：`cli`＝oneshot/CLI；`feishu`＝Lark gateway；`cron_<jobid>_<ts>`＝cron。

## 4. 設計後果（重要）

- **Worker 的對話 context 不跨任務延續**——每次都是空 session 起手，只重新載入：
  SOUL.md 身份、profile 記憶（`MEMORY.md` / `USER.md`）、skills、toolsets、Plur 共享記憶（`project:freelancer`）。
- **跨任務狀態完全靠記憶層扛**：MEMORY.md / Plur / Runes / 檔案產物（`/home/eye/Downloads/`），而非 session。
- 與 D3 序列化設計一致：一次一個 process、無 parallel、無 context 膨脹（每次乾淨）。
- 副作用：worker「記不住」上次任務的對話細節；若要延續，需透過 handoff packet 或寫檔傳遞，並由 secretary 的持久 session 承接整體脈絡。

## 5. 實務註記

- **`/new` 只影響 secretary 的 Lark session**；worker 因每次全新，無需（也無法）重置。
- 既有長對話 secretary session 的 `cwd` record 固化在建立當下的值；`/new` 開新 session 即用新設定（session 10 已實測）。
- 觀察 session 現況：`sqlite3 ~/.hermes/profiles/<role>/state.db "SELECT id, source, message_count FROM sessions ORDER BY started_at DESC LIMIT 10;"`
- 此機制為 hermes 原生行為，**不需任何 config / SOUL 變更**；SOUL 只是「如何呼叫」的紀律層（複合任務硬規則、Delivery Check Chain 均建立在此之上）。
