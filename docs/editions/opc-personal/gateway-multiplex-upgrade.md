# Gateway 升級經驗：v0.21.3 → v0.21.5（2026-09-27）

**適用 hermes-agent v0.21.5+3435。** 記錄 2026-09-27 gateway migrate 前後遇到的問題、修正與教訓。
單一事實來源：`docs/editions/opc-personal/gateway-multiplex.md`（架構細節）。本檔專注「升級過程中踩到的坑 + 修正」。

## TL;DR

```text
hermes gateway migrate --multiplex  → default multiplexer 統一服務 9 profile
├─ 驗證發現 #1：worker spawn python-path bug（ModuleNotFoundError）
│    修：drop-in override.conf 加 HERMES_BIN=venv/bin/hermes
│    ⚠️ 不要手動改 .service 檔（restart 會蓋掉）；drop-in 才不被蓋
└─ 驗證發現 #2：native memory 2,200 chars 上限（程式碼預設，非官方文件明文）
     修：建立 memory-management skill + memory-diagnose.py 監控工具
     ⚠️ 不要盲目調高限制（增加 prefill 開銷，本地有限算力環境要接受的現實）
```

## 升級過程

```bash
hermes gateway migrate --multiplex
```

執行結果（已驗證）：
- ✓ `default: gateway.multiplex_profiles: true`（`~/.hermes/config.yaml`）
- ✓ secretary standalone gateway（pid 2045）stop + systemd user service uninstall
- ✓ default gateway 經 systemd restart，verify 服務 9 profiles
- ✓ 重啟 PC 後 `hermes-gateway.service` active，9 profile 全服務

## 問題 #1：Worker spawn python-path bug（已修）

**症狀**：multiplexer 跑 standalone `tools/python-3.14` shim，dispatcher spawn worker 用 `sys.executable -m hermes_cli.main` → worker 找不到 `hermes_cli`/`ruamel`（依賴在 venv）。Kanban board 分派 + cron 任務全部崩。

**根因**：spawn 用的 interpreter 是 standalone shim，不是 venv python。standalone shim 沒有 venv 的 hermes_cli/ruamel 依賴。

**修法**：drop-in override.conf 加 `Environment="HERMES_BIN=/home/eye/.hermes/hermes-agent/venv/bin/hermes"`，spawn 走 venv shim。
已驗證：新 multiplexer PID 含 HERMES_BIN；live kanban dispatch worker 正常 heartbeat，無 ModuleNotFoundError。

**完整細節**：見 `docs/editions/opc-personal/gateway-multiplex.md`「Worker spawn python-path bug 修正」段。

### ⚠️ 教訓 #1：systemd managed unit 不要手動改

`hermes gateway restart` 從 `generate_systemd_unit()` 模板（`hermes_cli/gateway.py`）重生成 unit，**會蓋掉手動改動的 `Environment`**。drop-in override.conf（`.service.d/override.conf`）是 systemd 疊在 managed unit 之上，restart 不改它——這是官方「不要 edit managed unit」的標準做法。

## 問題 #2：Native memory 上限發現（已建立監控）

**發現**：memory tool 回報 `2,177/2,200 chars (98%)`。查證後確認：
- **2,200 chars 是程式碼預設值**（`config_defaults.py:1296` `memory_char_limit: 2200`、`user_char_limit: 1375`），**不是官方文件明文規定**。
- 官方文件（llms.txt）**完全沒提這個數字**。
- memory **不會自動壓縮**——超限時 `memory` 工具直接回傳錯誤。

**社群討論**：GitHub Issue #5320（open, P3 cosmetic）提過調高預設值 + context-aware 自動縮放，但**尚未合併**。提案者論點：預設值為 ~800 tokens 小上下文窗口模型 sized；現代模型普遍 125k+ 上下文。

**修（監控而非改設定）**：建立 `memory-management` skill + `memory-diagnose.py` 診斷腳本。
- 當 memory ≥95% 時跑腳本 → 找出佔最多空間的條目（含大小/年齡/是否 ≥20% budget）→ 依建議收斂。
- 收斂策略：合併大條目 → 精簡舊條目（>14d）→ 移進 skill/repo → 刪除過時。

### ⚠️ 教訓 #2：不要盲目調高 memory_char_limit

調高 = 每次 session 把更多 memory 塞進 system prompt = prefill 開銷增大。本地有限算力環境（ornith-1.5-35b-a3b @ 192.168.23.217:1234），prefill 固定開銷約 1.1s/次，已明確是「要接受的現實約束」→ **保持預設、靠收斂維持**。

### ⚠️ 教訓 #3：記憶分層要對

memory 爆掉時，事實下沉的正確層級：
- **repo docs**（hermes-agent-opc-deploy）：部署/架構事實（git clone 後仍在，不佔 session prefill）——**最佳下沉層**。
- **skill**：當相關時才載入的程序/工作流。
- **plur**：跨角色共享經驗。**不適合**單 profile 部署事實（會 leak 進其他角色）。
- **native memory**：每次都要快速查的短事實，留一行指標即可。

## 收斂成果（2026-09-27）

| 項目 | 原本 | 精簡後 | 去向 |
|---|---|---|---|
| Gateway 現行架構條目 | 792 chars | 230 chars | 細節沉到 `gateway-multiplex.md`（含 spawn fix） |
| kanban enforcement 條目 | 707 chars | 移除 | 已在 `kanban-backend-concurrency` skill（版本陷阱段完整保留） |
| **memory 使用率** | 98%（2,168/2,200） | 51%（1,139/2,200） | 無事實丟失，只是沉到對應層 |

## 待辦

- 若需求強烈，才考慮 `hermes config set settings.memory_char_limit <數>`——先確認 prefill 成本可接受。
- 觀察 GitHub Issue #5320 是否合併（context-aware 自動縮放）。
- 選清 `~/.config/systemd/user/hermes-gateway-secretary.service.d/` drop-in 殘留目錄（無害，可選）。

---

*本檔記錄 v0.21.3 → v0.21.5 升級經驗。架構細節見 `gateway-multiplex.md`；kanban enforcement 見 `kanban-dispatch.md` + `kanban-backend-concurrency` skill。*
