# OPC-PERSONAL 完整治理架構（四層：多 profile + kanban + Plur + Runes）

**適用 hermes-agent v0.21.3 + hermes-runes-md-wiki v0.7.6-dev（2026-09-16 落地）**。
這是 OPC-PERSONAL 的**完整層級架構**：在通用多 profile + kanban + Plur 之上，疊加 runes-holder + hermes-runes-md-wiki 的長期受治理記憶層。

> 只想要「多 profile + kanban + Plur」（不含 Runes）的 forker，見 `architecture-overview.md`。
> 只想知道「board 怎麼分派」，見 `kanban-dispatch.md`。
> 只想知道「Runes 審批 UX / native wrapper / token」，見 `runes-approval-ux.md`。

---

## 0. 為什麼需要四層（根因）

Freelancer 環境有 **8 個 OPC worker profile**（secretary / coordinator / researcher / opencode-researcher / writer / builder / aeon-builder / runes-holder）全部統一連線**同一台單執行緒本地後端** `192.168.23.217:1234/v1`（ornith-1.5-35b-a3b）。

三層問題各自需要專門機制處理：

| 層 | 解決的問題 | 元件 |
|---|---|---|
| **L0 分派** | 多 profile 直 spawn 併發擠爆單執行緒後端 → chain 斷裂 | kanban board + `max_in_progress_per_profile=1` |
| **L1 短中期記憶** | 跨角色共享經驗（選型、失敗教訓、workflow 定案）會衰減、需紀律 | Plur（`project:freelancer` scope + deliberate recall）|
| **L2 長期受治理記憶** | 把「值得長期的知識」系統化轉成 governed evidence，且寫入需 human approval | runes-holder + hermes-runes-md-wiki（forge native wrapper + Lark 批准關鍵字）|

L1 / L2 不在調用拓撲軸內（worker 不直接呼叫），只在**記憶生命週期軸**上——可選時下沉、缺席時 PLUR / native memory 扛責。

---

## 1. L0 — kanban board 分派（入口與限流）

**secretary 是唯一 board 入口**。需要任務拆解 / routing 時建 board entry：

```bash
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
$HM kanban create "<簡短 brief>" --assignee coordinator \
  --idempotency-key "<描述>-$(date +%s)"
```

dispatcher 預設 **60s tick** 唤醒 coordinator-as-worker（注入 `kanban_*` 工具）。coordinator 在 board 內用 `kanban_create`（**不帶 parents**）派 researcher/writer/runes-holder，每層受 `max_in_progress_per_profile=1` 限流 → 單執行緒後端同時只接一個 worker。

**關鍵前提**：
- coordinator 被 terminal 直叫時是「正常 chat profile」，**沒有 `kanban_*` 工具**（只有 dispatcher 派工才注入）。故 coordinator 自行改走 board 不通——**secretary 必須當入口**。
- `max_in_progress` 必須真正 enforce（v0.21.3 實測：4 researcher → 1 running + 3 ready；巢狀 spawn 也受 `per_profile` 限制）。

詳 `kanban-dispatch.md`（含 §5b kanban_link 死鎖教訓、§7 cron × board 爭用預檢、§8 繁中閘門）。

---

## 2. L1 — Plur 記憶層（短/中期跨角色共享）

三層記憶堆疊的中層：跨角色共享、ACT-R 衰減、中期 lifecycle。

| 元件 | 版本 / 型態 | 角色 |
|---|---|---|
| `plur-hermes` | pip plugin（`plugins.enabled: plur`，8 profiles 全啟）| `pre_llm_call` / `post_llm_call` hooks 自動 learn / inject |
| `@plur-ai/cli` | npm global CLI bridge；`~/.plur/` 儲存 | engrams 本體 |

### 在分派中的應用
- **自動注入（現行主要機制）**：`pre_llm_call` hook 每次 LLM 前 inject 相關 engram（hybrid search: BM25 + embeddings）。不需要手動調 tool。
- **主動 recall（deliberate recall，補充）**：coordinator 對**高價值/跨領域任務**在產出 handoff packet 前跑 `plur_recall --scope project:freelancer --query "<主題>"`，把自動注入可能漏掉的跨領域經驗帶進 worker handoff。
- **成本取捨**：deliberate recall 增加一次 prefill（地端現實約束）。chain 已長時只在高價值任務主動 recall。

### Scope 紀律
- 新 shared learns 一律 `project:freelancer`（不要散落 `global`）。
- 關鍵長期規則用 `plur promote`（retrieval_strength 0.7）避免衰減。
- 中文 statement 帶英文關鍵字（BGE-small 英文 embedder），提高 recall 命中。

詳 `plur-memory-layer.md`。

---

## 3. L2 — Runes 治理層（長期受治理證據）

**runes-holder 對 `hermes-runes-md-wiki` 的所有操作一律透過 runes-shield 層提供的 native wrapper**（forge）。P0 approve/reject/promote = human-only；審批採「Lark 純文字關鍵字 + SOUL 層象徵 token」。

### Native Wrapper ONLY 原則
- **不得**直接讀/寫 `wiki/*.md`（禁止 `cat >` / `echo >>` / `sed -i` / python `write_text` 等 ad-hoc 方法）。
- 寫入僅在 secretary 審批 + handoff 攜帶 token 時執行（`--write`）。
- 白名單 wrapper 不足時，停下來回報，不繞過護盾。

### 唯一路由
secretary 與所有 worker **只能經 coordinator 到 runes-holder**（retrieve 亦同）。worker 不得直接呼叫 runes-holder。coordinator 在 board 內用 `kanban_create` 派 runes-holder child（與 researcher 同路徑）。

### 雙軌審批

| 軌道 | 對象 | 機制 |
|---|---|---|
| A | L2 破壞命令（apt upgrade / systemctl stop 核心 / reboot / 改 /etc/）| **Lark 互動卡片** [批准]/[拒絕]/[修改命令] |
| B | Runes governed write 候選 | **Lark 純文字關鍵字** `批准/拒絕/撤銷 <proposal_id>` + 一次性象徵 token + **forge native wrapper 執行狀態變更** |

### token 生命週期
```text
格式:  R-<ts>-<4hex>             例: R-20260815-3f9a
來源:  secretary（使用者「批准」後產生）
傳遞:  secretary -> coordinator handoff（approval_token 欄）-> runes-holder
使用:  單次；runes-holder 收到才視為 governed write 已核准
銷毀:  用後即棄；不 echo、不復用、不寫入 git/wiki/jobs.json
留存:  僅 operation manifest / audit jsonl 的 token_id 欄位
```

無 token 的 handoff = 寫入未核准 → runes-holder 回 coordinator「無 Runes 治理佐證」。

詳 `runes-approval-ux.md`（白名單工具全表、write_guard、審計、下沉/回退）。

---

## 4. 完整流程：一次 Runes 治理如何走通四層

以下為 2026-09-16 實測通過的實際流程（board task `t_6d69c735`）：

```text
1. secretary（board 入口）
   $HM kanban create "<完整 Runes 治理流程實測>" --assignee coordinator

2. dispatcher tick 唤醒 coordinator-as-worker（注入 kanban_* 工具）

3. coordinator 分派前 deliberate recall → plur_recall 召回 project:freelancer engrams

4. coordinator → researcher child（kanban_create，idempotency_key="t_<parent>:researcher:1"）
   - researcher 做 web research + 寫報告到 /home/eye/Downloads/
   - coordinator 走 kanban_show → done → merge（列出所有 conflict 點與選型建議）

5. coordinator flag Runes candidate（明確「未直接寫入 wiki」）
   → 路由 runes-holder，產生 approval token R-<ts>-<4hex>

6. coordinator → runes-holder child（kanban_create，idempotency_key="t_<parent>:runes-holder:1"）
   - runes-holder 經 forge native wrapper：forge.py create-flat --write 建 draft
   - status: draft（不 approve），寫入 wiki/freelancer/forge-inbox/

7. coordinator kanban_complete parent（created_cards=[researcher_id, runes-holder_id]）
   → 交付鏈完整，draft 待 human review
```

**human approval（軌道 B，之後的步驟）**：
```text
8. secretary 送出【Runes 治理寫入請求】（proposal_id / target / summary / 風險）
9. 使用者回覆「批准 <proposal_id>」
10. secretary 產生一次性 token R-<ts>-<4hex> → coordinator handoff → runes-holder
11. runes-holder：forge.py approve --path wiki/freelancer/forge-inbox/<file>.md
    → status: draft → approved + operation manifest 審計（真實寫入）
```

### 交付與邊界
- **本地產物**一律寫入 `/home/eye/Downloads/`。
- **Lark 雲端交付**：報告 → Drive；表格 → Base（指示 writer 用 lark-cli）。
- forge-inbox 內容是 draft / untrusted，不進 trusted memory；reviewed 才屬 wiki 其他位置。
- `write_guard.py`：P0 寫入只能落在 `wiki/<project>/forge-inbox/*.md`（實測 forge-inbox 外 → `WriteGuardError` 拒絕）。

---

## 5. coordinator SOUL lifecycle hardening（2026-09-16 實測修訂）

coordinator-as-worker 在 board 內派工時，三條 pattern-failure 修正（全部為 SOUL 內獨立警告段，研究來源 `opencode-researcher` t_40fad458 讀 hermes-agent v0.21.3 原始碼）：

| 規則 | 內容 | 驗證 |
|---|---|---|
| **1. idempotent spawning** | 派工帶決定性 `idempotency_key="<parent>:<role>:<seq>"`；同一 role 單一在途子卡；child registry 落 board comment；`created_cards` 不得重複 | ✅ t_6d69c735（同一 role 各只派一次，board idempotency 保護）|
| **2. hung-worker 判定 + 等待段两出口** | lease/heartbeat 四種組合判定；等待段只有兩個出口：A. done→merge complete / B. hung→block 自己的 parent + 留證據 | ✅ t_6d69c735（kanban_show → done → merge，無輪询死等）|
| **3. 串行派工 / 一次一 child** | 嚴格序列化；無並行同 role 派工、無 duplicate-spawn | ✅ t_6d69c735（researcher → merge → runes-holder）|

> **邊界知識（worker 沒有權限）**：coordinator-as-worker 只能 mutate **自己的** `HERMES_KANBAN_TASK`；對子卡只有 `kanban_show`（讀）+ `kanban_comment`（寫）。子卡回收（lease 過期、crash、heartbeat 停滯）是 **dispatcher 的職責**。故 hung worker 的唯一正確動作是「留證據、停止等待、交還決策」，**不得**重派同 role、**不得**標子卡 blocked/unblock、**不得**替它 complete。

> **未觸發分支**：hung-worker 的「block 自己 parent + 留證據」路徑在 t_6d69c735 未遇到（兩子卡均正常完成）。下次若有 worker 真正 hang 住時再驗證該路徑。

---

## 6. 記憶來源優先級（source priority）

```text
1. 當下使用者指令 / 當下對話
2. Hermes native memory（runtime/偏好/skill cache，非 canonical）
3. Runes MD Wiki（governed long-term evidence）
4. Plur（學得 conventions，可 decay；與 Runes 衝突時 Runes 為準，標該 engram 待手動 prune）
5. 第三方 RAG / Obsidian
6. Web 公開來源
```

Runes 與 Plur 衝突時 **Runes 為準**，並標該 engram 待手動 prune。

---

## 7. 下沉 / 回退（記憶生命週期軸）

```text
Runes 可用 + 已批准  -> 候選下沉：forge create-flat 建 draft -> approve/reject 狀態變更
                       -> operation manifest 審計（真實寫入，非意圖）
Runes 不可用/未同意  -> 不硬寫 wiki；回 coordinator 標「無 Runes 治理佐證」
                       -> 請求端 profile 以 PLUR / native memory 扛責
```

---

## 8. 驗證狀態（2026-09-16）

| 環節 | 實測結果 |
|---|---|
| deliberate recall | ✅ 觸發 10 engrams |
| researcher 派發 + 報告交付 | ✅ 單張子卡 + 決定性 idempotency_key + 145 行報告 |
| coordinator merge | ✅ 正確合併（列出所有 conflict 點）|
| Runes candidate flag（未寫入 wiki）| ✅ 路由 runes-holder + approval token |
| runes-holder forge draft | ✅ `forge.py create-flat --write`，status: draft |
| idempotent spawning / 串行派工 | ✅ 無 duplicate-spawn、無 fan-in 死鎖 |
| hung-worker 判定 | ⚠️ 本次未觸發（兩子卡均正常完成）|

完整流程四層連續走通，無死鎖、無重複派工、無輪询卡死。

---

## 9. 剩餘待辦

- **hung-worker「block 自己 parent + 留證據」路徑**待真正有 worker hang 住時驗證。
- `kanban_show` 是否回傳 lease/heartbeat 欄位未驗證（若無，tick 上限回退方案即唯一判準）。
- forge-inbox 現有一个 headroom draft（status: draft，pending human review）——等你決定要不要正式 adopt。

---

*本文件為 OPC-PERSONAL 完整四層治理架構單一事實來源。多 profile + kanban 分派見 `kanban-dispatch.md`；Plur 記憶層見 `plur-memory-layer.md`；Runes 審批 UX / native wrapper 見 `runes-approval-ux.md`；實測記錄見 `docs/planning/handoff.md` session 15/16。*
