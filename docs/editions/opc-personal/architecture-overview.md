# OPC 通用架構：多 profile agents + kanban board dispatch + plur 記憶層

**適用 hermes-agent v0.21.3（2026-09-15）。** 本檔只講解「多 profile agent + kanban board 分派 + plur 記憶層」這三層**通用架構**，**不含** runes-holder / hermes-runes-md-wiki 治理層。

> **為什麼有這份檔？** 只想部署多 agent 協作的 forker 不需要 Runes 治理那層。本檔是自足的通用版；要加 Runes 治理見 `runes-approval-ux.md` 與 `kanban-dispatch.md` §10。

---

## 1. 為什麼需要三層架構

Freelancer 環境有 **8 個 OPC worker profile**（coordinator / researcher / opencode-researcher / writer / builder / aeon-builder / runes-holder…）全部統一連線**同一台單執行緒本地後端** `192.168.23.217:1234/v1`（ornith-1.5-35b-a3b）。

**chain 斷裂根因**：多個 profile agent 同時直 spawn 連後端 → 併發擠爆單執行緒 → researcher 階段 timeout → chain 崩。

**三層各自解決一個問題：**

| 層 | 解決的問題 |
|---|---|
| **多 profile agents** | 專業分工（coordinator 路由、researcher 蒐證、writer 產出…）|
| **kanban board dispatch** | 限流——確保單執行緒後端同時只接一個 worker，防 chain 崩 |
| **plur 記憶層** | 跨角色共享經驗，避免每次任務都從零開始 |

---

## 2. 多 profile agents（通用）

### 角色分工
```text
secretary      — 與使用者之間的唯一交付點、任務整理、繁中閘門
coordinator    — 路由與合併（board 內派工，不直 spawn）
researcher     — 例行證據/事實蒐集、單頁來源比對
opencode-researcher — 大規模文獻/多語系 (>10 來源)，內部 MoA
writer         — 結構/辭彙/終稿/報告/簡報
builder        — code/shell/debug/test/deploy
aeon-builder   — 重型算法死結/高併發/複雜除錯（遠端 DGX）
runes-holder   — Runes wiki 治理（**本檔不含**，見 runes-approval-ux.md）
```

### 路由規則（coordinator 決定）
```text
需要例行證據/事實/單頁來源比對        -> researcher
需要大規模文獻/多語系 (>10 來源)       -> opencode-researcher
researcher 回報 evidence_urls > 10     -> reroute opencode-researcher
需要結構/辭彙/終稿/報告/簡報           -> writer
需要 code/shell/debug/test/deploy      -> builder
需要重型算法死結/高併發/複雜除錯       -> aeon-builder
```

**複合任務硬規則**：當任務同時包含「調研/查證」與「產出/報告」兩個要素，必須走 `researcher/opencode-researcher → writer` 鏈，不得由單一 process 完成。

---

## 3. kanban board dispatch（限流核心）

### 為什麼只有 board 入口可行
coordinator 被 terminal 直叫時是「正常 chat profile」，**沒有 `kanban_*` 工具**（只有 dispatcher 派工才注入）。故 coordinator 自行改走 board 不通——**secretary 必須當入口**。

### 正式運作流程（v0.21.3）
```bash
# secretary 入口（board entry）
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
$HM kanban create "<任務 brief>" --assignee coordinator \
  --idempotency-key "<描述>-$(date +%s)"
```
dispatcher 預設 **60s tick** 唤醒 coordinator-as-worker（帶 `kanban_*` 工具）。coordinator 在 board 內用 `kanban_create` 派 researcher/writer，每層受 `max_in_progress_per_profile=1` 限流 → 單執行緒後端同時只接一個 worker。

### 關鍵前提（先驗證再動手）
1. **dispatcher 必須正常 tick**：`hermes kanban diagnostics` 無警報；建一個會 running 的測試 task 看是否派工。
2. **`max_in_progress` 必須真的 enforce**：不同版本 behavior 不同（見下方版本陷阱）。更新後務必重跑併發測試確認，不要假設設定已生效。
3. **coordinator-as-worker 必須有 kanban 工具**：`kanban_*` 工具只在 dispatcher 派工時自動注入。驗證：建 assignee=coordinator 的 task，看它回報是否有 kanban_create/show/complete。

### 版本陷阱
- **v0.21.1**：`max_in_progress` **不 enforce**。4 個 researcher 同時 running。即使改走 board 也擋不住併發。
- **v0.21.3（2026-09-14）**：`max_in_progress` **真正 enforce**。4 個 researcher → 只剩 1 running + 3 ready。巢狀 spawn 也受 `max_in_progress_per_profile` 限制。
- 官方文件比本機版本新。**查文獻前先確認本機版本**：`hermes --version`。

### ⚠️ kanban_link 死鎖（實測教訓）
**coordinator-as-worker 派單一子任務時，絕對不要用 `kanban_link` 把自己設為 parent。** `kanban_link` 建立 parent→child 依賴後，子任務會卡在 `todo`（要等所有 parent `done` 才 promotion），但你要等子任務結果才能完成 parent → **無限迴圈死鎖**。實測：一條 board 任務因此卡 ~11 分鐘。

**正確模式：**
- `kanban_create` 派單一 worker 時**不帶 parents** → 子任務直接 `ready` → dispatcher 立即派工 → 跑完完成。
- 完成 parent 時用 `created_cards=[child_id...]` 記錄，**不要**回頭 `kanban_link`。
- `kanban_link` 只用於 fan-in（多個 parent 都完成後 child 才開始）。

### 觀察與驗證方法
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
注意：tick 預設 60s。建任務後等一個 tick 才派工。用 `sleep 90` 比 `sleep 30` 更穩。

---

## 4. plur 記憶層（跨角色共享）

### 三層記憶堆疊的中層
| 元件 | 版本 / 型態 | 角色 |
|---|---|---|
| `plur-hermes` | pip plugin **0.17.2** | 註冊 `pre_llm_call` / `post_llm_call` hooks，自動 learn / inject |
| `@plur-ai/cli` | npm global **0.9.4** | CLI bridge；`~/.plur/` 儲存 |
| `~/.plur/` | engrams（約 120 engrams / 2300+ episodes） | 共享記憶本體 |

### 啟用
```bash
pip install plur-hermes            # 0.17.2；若已裝但缺 Hermes plugin 則重裝補齊
npm i -g @plur-ai/cli              # 既有

# 8 profiles 全部啟用 plugin
hermes -p <role> config set plugins.enabled plur    # 每個 profile

# 驗證：每個 profile 都看得到 plur 工具
hermes -p <role> tools list | grep plur
```

### 自動注入 vs 主動 recall
- **自動注入（現行主要機制）**：`pre_llm_call` hook 已在每次 LLM 前 inject 相關 engram（hybrid search: BM25 + embeddings）。不需要手動調 tool。
- **主動 recall（deliberate recall，補充）**：coordinator 對**高價值/跨領域任務**在產出 handoff packet 前跑 `plur_recall --scope project:freelancer --query "<任務主題>"`，把自動注入可能漏掉的跨領域經驗帶進每個 worker 的 handoff。這是對自動注入的**補充**，不是取代。

### Scope 紀律
- **新 shared learns 一律 `project:freelancer`**（不要散落一堆 `global`）。`global` 會 leak 進每個 project。
- **關鍵長期規則**：`plur promote`（設 retrieval_strength 0.7）或 feedback 強化，避免衰減退出注入範圍。
- **中文 statement 帶英文關鍵字**（BGE-small 英文 embedder），提高 recall 命中。

### 成本取捨
deliberate recall 增加一次 prefill（地端有限算力模型環境下的既定約束）。chain 已長時只在高價值任務才主動 recall，一般任務靠自動注入即可。

---

## 5. 完整概念驗證（實測記錄）

2026-09-15 我們用一條真實跨領域 board 任務驗證了「多 profile + kanban + plur」的完整架構：

**任務**：評估是否導入 context compression MCP tool（headroomlabs-ai/headroom）。

**結果：**
1. ✅ **deliberate recall 觸發**：coordinator 分派前調用 `plur_recall`，召回 10 則 engrams（含 headroom 本身、code-review-graph 等互補選型教訓）。
2. ✅ **kanban chain 完整走通**：`secretary → coordinator → researcher → coordinator → secretary`，27 分鐘、32 次 tool calls，無死鎖。
3. ✅ **研究交付物真實存在**：`/home/eye/Downloads/t_3c409a58_headroom-fit-assessment.md`（9KB）。

**意外發現並修正**：第一次實測觸發 kanban_link 死鎖（卡 ~11 分鐘），已修正 coordinator SOUL + kanban-dispatch.md §5b。

---

## 6. 與 Runes 治理層的關係

本檔是**通用版**，不含 runes-holder / hermes-runes-md-wiki。Runes 治理是**可選的第四層**：

- **一般 forker**：多 profile + kanban + plur 已足夠。
- **需要受治理長期知識**：加 runes-holder（經 secretary 中介的使用者同意 + approval token），把每次任務的經驗系統化轉成 governed wiki candidate。見 `runes-approval-ux.md`。

Runes 存取治理**僅能透過 profile agent runes-holder 執行**（經 coordinator 路由），不直接操作 wiki。

---

## 7. 快速部署檢查清單

```bash
# 1. 確認版本
hermes --version    # 應 ≥ v0.21.3

# 2. 確認 dispatcher 正常
hermes kanban diagnostics

# 3. 驗證 max_in_progress enforce（併發測試）
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
for i in a b c d; do
  $HM kanban create "CONC-TEST: sleep 90 then complete" \
    --assignee researcher --idempotency-key "conc-$i-$(date +%s)"
done
sleep 70
$HM kanban stats | grep -E "running|ready"   # 應 running=1

# 4. 啟用 plur（若未啟用）
for p in secretary coordinator researcher writer builder aeon-builder runes-holder opencode-researcher; do
  hermes -p $p config set plugins.enabled plur
done
hermes -p coordinator tools list | grep plur   # 應見 plur + plur-meta

# 5. populate project:freelancer engrams（首次）
PLUR=~/.nvm/versions/node/v22.22.3/bin/plur
$PLUR learn --scope project:freelancer "kanban board dispatch: secretary is board entry using 'hermes kanban create --assignee coordinator'; dispatcher enforces max_in_progress_per_profile=1"
```

---

*本檔為 OPC 通用架構（多 profile + kanban + plur）單一事實來源，不含 Runes 治理層。*
