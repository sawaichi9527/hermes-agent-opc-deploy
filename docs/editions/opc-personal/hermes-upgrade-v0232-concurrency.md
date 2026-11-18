# hermes upgrade v0.23.2 — kanban 併發限制對齊單執行緒本地後端

**適用 hermes-agent v0.23.2**（2026-11-16 stable，commit `ae2a81ccc00e`）｜記錄日期：2026-11-18
**背景**：本机 OPC 多 profile agent 跑在**單執行緒本地推理後端**，v0.23.2 預設的 kanban 併發行為會壓垮它。本文記錄問題→診斷→解法→驗證，作重灌與接手參考。

---

## 1. 問題

本機 OPC 架構：8 個 worker profile（secretary / coordinator / researcher / writer / builder / runes-holder / aeon-builder / opencode-researcher）統一連線**同一台單執行緒本地後端**：

```
Strix Halo 395 (gfx1151) + Ubuntu + LM Studio + ornith-1.5-35b-a3b（llama.cpp）
```

llama.cpp / LM Studio 在**不併發**下反應最好；多併發會嚴重拖垮單機推理品質。

**v0.23.2 預設行為（實測確認有 bug）**：
- `kanban.max_in_progress_per_profile` 預設 = `None`（**無 per-profile 上限**）
- 全域 `kanban.max_in_progress` 被記憶體推導：`clamp(MemTotal / 512MB, floor=2, ceiling=8)` → 本機 ~30GB RAM → **8**

實測：派 4 個 researcher「sleep 90 then complete」→ **4 個同時 running（running=7 含其他）**。這會直接壓垮本地單併發後端，正是 `kanban-dispatch.md` 警告的 chain 斷裂根因。

---

## 2. 診斷

1. **v0.23.2 沒有 per-assignee 粒度**。kanban 只有兩個 knob：
   - 全域 `max_in_progress`（記憶體推導預設 2–8）
   - uniform `max_in_progress_per_profile`（預設 None）
   
   原始碼：`hermes_cli/kanban_db_dispatch.py:2299`（`per_profile_cap` 對所有 assignee 用同一 cap）、`config_defaults.py:1870/1877`。`kanban_watchers_dispatcher.py:116` 從 `kanban_cfg` 讀取。
   
   「per-assignee」在程式碼中僅是統計 bucket（`kanban stats` per-assignee counts），**不是設定閘門**。

2. **設定寫錯檔會靜默失效**。首次把 `max_in_progress_per_profile: 1` 寫進 `profiles/secretary/config.yaml`（active profile），`hermes config get` 讀回 = 1，但 dispatcher 實測仍是 running=7。根因：**dispatcher 在 gateway multiplexer 裡讀全域 `~/.hermes/config.yaml`，不讀 secretary profile 檔**。

---

## 3. 解法

在全域 config 設 uniform per-profile cap = 1：

```yaml
# ~/.hermes/config.yaml  →  kanban:
kanban:
  dispatch_in_gateway: true
  dispatch_interval_seconds: 60
  max_in_progress_per_profile: 1      # ★新增（v0.23.2 對齊單執行緒後端）
  ...
```

- **必須寫全域** `~/.hermes/config.yaml`（dispatcher 讀全域）。寫 profile 檔無效。
- 改前已備份原檔：`~/.hermes/config.yaml.bak-*`。
- 此設定 **hot-reload 不生效**——gateway 啟動時快取 config，需**重啟 gateway** 才載入（整機重啟亦可）。

---

## 4. 兩層架構與限制影響

| 層 | Profiles | 算力 | 是否受單併發限制 |
|---|---|---|---|
| **薄** | secretary / coordinator / researcher / writer / builder / runes-holder | 本地 Strix Halo（llama.cpp） | ✅ 限單併發（per_profile=1）|
| **厚** | aeon-builder / opencode-researcher | DGX vLLM 遠端 / opencode-go 雲端 | 理論上也被限 1，但走其他算力、實際影響極小 |

- `aeon-builder`：`provider: custom`（DGX vLLM 遠端独立推理機）
- `opencode-researcher`：`provider: opencode-go`（reference_models = qwen3.8-max / glm-5.3，雲端）

uniform per_profile=1 會同時限厚 profile，但厚 profile 的 kanban 任務通常本就不併發跑；其**內部** MoA/reference 併發（在單一 agent workflow 內）不受 per-profile cap 影響。故實際損益比下，per_profile=1 是保護本地後端最簡單且正確的做法（恢復 v0.21.3 設計初衷）。

---

## 5. 驗證

重啟 gateway 後，派 4 個 researcher「sleep 90 then complete」：

```
kanban stats → running=1, researcher running=1 / ready=3   ✅ enforce 生效
```

（修前：running=7。修後：每 profile 最多 1 個 in-flight，本地單併發後端恢復序列化防護。）

Board 與 worker scope 已清理（running=0 / ready=0，無遺留 zombie scope）。

---

## 6. 重灌 / 接手檢查點

```bash
# 1. 確認 version 對齊
cat ~/.hermes/hermes-agent/...  # hermes --version → v0.23.2
grep max_in_progress_per_profile ~/.hermes/config.yaml   # 應 = 1

# 2. 併發實測（升後必跑，沿用 kanban-dispatch.md §5）
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
for i in a b c d; do
  $HM kanban create "CONC-TEST: run 'sleep 90' then complete" \
    --assignee researcher --idempotency-key "conc-v023-$i-$(date +%s)"
done
sleep 75
$HM kanban stats | grep -E "running|ready"
# per_profile=1 應 running=1；若 running=N 全跑 = 未 enforce，需重設全域 config + 重啟
```

> ⚠️ `hermes update` 不會動 `kanban.max_in_progress_per_profile`（這是 repo/config 設定，非 source patch）。但若哪天改到 `cron/scheduler.py` 的 ruamel interpreter patch，仍需依 `cron-ruamel-interpreter-fix.md` 重放。

---

*來源：本機實測（`hermes --version`、`kanban stats`、`config get`）+ 原始碼（`kanban_db_dispatch.py`、`config_defaults.py`、`kanban_watchers_dispatcher.py`）+ repo `kanban-dispatch.md` / `gateway-multiplex.md`。*
