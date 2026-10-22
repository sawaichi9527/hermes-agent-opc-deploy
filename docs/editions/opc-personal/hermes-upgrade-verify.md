# Hermes Agent 升級驗證記錄（OPC-PERSONAL）

- **日期**：2026-10-22
- **升級前 baseline**：v0.22.0+119.canary（git checkout，2026-09-24）；deploy repo 鎖定 v0.21.5
- **升級後**：**v0.22.4 · stable**（git release commit `4d04303818b6`）
- **方式**：`hermes update --yes`（git pull + 重裝 venv + 重啟 gateway），重啟 PC
- **健康狀態**：✅ 全部通過（版本/gateway/9 profile/schema/v32/Lark/cron）
- **可重複檢查 skill**：`hermes-upgrade-verify`（devops 分類）

---

## 1. v0.22.1→v0.22.4 對 OPC 架構的影響評估

deploy repo 定義的 8-profile 架構（SOUL / routing / kanban / plur / Runes）**活在 repo 自己的 `config/`、`editions/`、`scripts/`**，不是 hermes-agent 核心碼。更新核心不會覆寫你的 profile 定義。真正的風險在於 **v0.22.3 是一個未文件化的大滾動（~620 PR / 2,911 commits）**，直接動到架構依賴的領域。

### 三項最實質的變動

| 變動 | 影響領域 | 對你們架構的意義 |
|---|---|---|
| **State schema v31→v32**（`hermes_state_common.py`） | session store | 新增 `runtime_epoch`、`session_admissions`、`worker_executions`、`worker_receipts`。官方註解為 **additive、開檔自動 catch-up**，舊版本「永遠不會拒絕 newer schema」。→ 自動補表，先備份 state.db |
| **Multiplex in-place switch 重構**（`gateway/`，整批 commit） | default multiplexer（你們的核心） | 「serialize the in-place multiplex switch with reconcile」、「honour `gateway.auto_multiplex_migration=false`」。這些是把不穩機制修好，代表尚未 settle。**更新後要實際測多 profile 切換** |
| **Kanban worker delegation + cron authority** | dispatch / governance | `delegate_task` works in Kanban workers through owner-reserved children；cron 加 `scheduler_authority`/`scheduler_gateway_gate`。→ 直接影響 kanban-dispatch 與 cron-governance |

### 各版本風險分佈

| 版本 | 對架構影響 |
|---|---|
| v0.22.1 | **低**（多為 plugin catalog + gateway 內部 canonical authority 重構） |
| v0.22.2 | **中**（model seed 重構 + gateway boot 修復 + state 開變） |
| **v0.22.3** | **高（實質）**（schema v32 + multiplex switch 重構 + worker/cron authority） |
| v0.22.4 | **低**（Desktop UX 修補，不碰核心） |

### 結論

v0.22.2→v0.22.3 是狀態層 + gateway + worker 的大重構（4206 檔），變動砸在你們的 multiplex / session state / kanban dispatch / cron governance 四個領域，但多描述為 **additive/bugfix**。真正的未知數是 v0.22.3 未文件化滾動——需實際比對 deploy 依賴才能 100% 確定。

---

## 2. 升級 procedure（editable 安裝，已實測通過）

**安裝方式確認**：git checkout 原始碼 + `pip install -e .` editable 裝進獨立 venv（`/home/eye/.hermes/hermes-agent/venv`，Python 3.11）。不是純 git 跑源碼，也不是普通 pip 安裝。

### 一般使用者一行（推薦）
```bash
hermes update --yes      # 自己 pull git + 重裝 venv + 重啟 gateway
```
想鎖定 stable tag：`hermes update --channel stable --yes`

### 完整手動序列（開發者式，了解每步用）
```bash
# 0. 備份 state.db（schema v31→v32）
cp ~/.hermes/state.db ~/.hermes/state.db.bak-$(date +%Y%m%d)
# 1. 讀取檢查（不改東西）
hermes update --check
hermes update --plan
# 2. git 拉到目標版本
cd /home/eye/.hermes/hermes-agent && git fetch origin && git checkout main   # 或 git checkout v0.22.4
# 3. 重裝 editable（關鍵：讓 metadata+依賴跟 code 同步）
/home/eye/.hermes/hermes-agent/venv/bin/pip install -e . --no-deps
/home/eye/.hermes/hermes-agent/venv/bin/pip install -e .
# 4. 重啟 gateway（會中斷 secretary Lark 連線幾秒）
systemctl --user restart hermes-gateway
# 5. 驗證
hermes --version && hermes gateway status
```

> ⚠️ `hermes update` 會重啟 `hermes-gateway.service`，過程中 Lark 中斷幾秒。想延後重啟加 `--no-gateway-restart`，完再手動 restart。

---

## 3. 升級後驗證結果（2026-10-22 實測）

| 項目 | 結果 |
|---|---|
| **版本** | v0.22.4 · stable，git 在官方發布點 `4d04303818b6` ✓ |
| **Gateway** | default multiplexer running（PID 2027），重啟後自動起來、enabled ✓ |
| **9 Profile serve** | default + aeon-builder / builder / coordinator / opencode-researcher / researcher / runes-holder / secretary / writer ✓ |
| **Parked profiles** | `{}` 空，沒有被 park 的 ✓ |
| **Schema v32** | `session_admissions`/`worker_executions`/`worker_receipts` 三表都在（遷移成功）✓ |
| **Feishu/Lark** | `state: connected, error_code: null, needs_attention: false` ✓ |
| **Cron scheduler** | ticker 心跳正常、`doctor found no issues`、5 job active ✓ |

### Cron 冒煙測試（v0.22.3 authority/gating 路徑）
觸發 agent job `定向情報推送`（91d908e7d563）：直接觸發 → 派工 → **completed** → 產出 ~9KB 真實情報報告（`2026-10-22_17-07-05.md`）。no-agent 過濾器 job 17:00 completed。無新 incident（只有 10-14 舊 resolved）。

> **Gotcha**：手動 `hermes cron run` 若用 foreground CLI 且超時/提前退出，owner 丟失 → 執行標 `failed: Fire claim ownership lost` / `unknown`。**這不是 v0.22.3 regression，是觸發方式 artifact**。乾淨做法：`terminal(background=true, notify_on_complete=true)` 讓 owner 活到跑完，或直接看定時跑（`source=builtin`）history。

### 無害 cosmetic note
`pip show` / `importlib.metadata` 可能回報 `0.0.0` 或舊版（本 repo pyproject `version="0.0.0"`，實際版本由 git tag 動態推導）。**執行碼以 `hermes --version` + git describe 為準**，metadata 落後不影響運行。

---

## 4. 快速驗證序列（未來更新後跑這組，全部讀取）

```bash
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
$HM --version | head -1                                   # 版本
cd /home/eye/.hermes/hermes-agent && git describe --tags  # 發布點
$HM gateway status                                        # multiplex
grep -oE '"served_profiles"[^]]*|"parked_profiles"[^}]*}' ~/.hermes/gateway_state.json
$HM cron status | head -6; $HM cron doctor | head -3     # cron 健康
```

完整指令、每項預期結果、cron 冒煙細節見 skill **`hermes-upgrade-verify`**（devops 分類）。

---

## 5. 更新前檢查清單（下次升級直接用）

- [ ] 備份 state.db：`cp ~/.hermes/state.db ~/.hermes/state.db.bak-$(date +%Y%m%d)`
- [ ] 確認 `multiplex_profiles: true` 仍在 `~/.hermes/config.yaml`
- [ ] 跑 `hermes update --check` + `--plan`（read-only）
- [ ] 升級後用 §4 序列驗證；agent job 冒煙建議 background 觸發
- [ ] 有任何 profile 被 park = 該 profile state.db 打不開，需排查
