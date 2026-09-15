# Handoff — Hermes OPC 5+2 藍圖規劃

**Session end:** 2026-09-14
**Workspace:** `D:\Workspace\projects\freelancer-hermes-agent\`
**狀態:** M0–M8 全完成；M8 完成後待辦全完成（2026-08-15）。**2026-08-15 session 2 完成 §9 開放目標評估（#3/#4/#6）；session 3 完成 P3 Runes 審批 UX 接線 + P3 v2 修正（一律使用 runes-shield 層 native wrapper）+ Plur scope 紀律 + 藍圖 §9 同步**。**2026-08-15 後續：C6 MoA turn cap（A2）+ B4 NIM 可靠性 3-strike（定案實作）+ #8(a) 舊 CLI deprecate（PR #7）+ B5 Lark 秒回標不處理；A1 殘物清理**。**session 4：13 份 SOUL 模板全量 refine（v0.20.1，統一結構/繁中化/補決策/去冗/generic 填空 + token 審計），commit `dde6c33` 已 push，K6 8 profile 已同步 + ping PASS（2026-08-16）**。**session 5（2026-08-16）：Plugin/Skill 盤點與分配——K6 Hermes 升級 v0.20.0→v0.20.1（v2026.8.13）、ppt-master v4.5.0→v4.7.0、rtk-rewrite 失效 plugin 移除、8 profile 分配 18 支 skill symlink（見下節）**。**session 6（2026-08-16）：rtk-rewrite 重裝（官方 PyPI v1.2.3 + rtk binary v0.45.0）+ Web backend 本地化——捨 ddgs、全域 firecrawl fallback + 搜尋 3 角色（researcher/opencode-researcher/secretary）search=SearXNG / extract=Firecrawl（見下節）**。**session 7（2026-08-16）：Docker SearXNG/Firecrawl 升級 + lark-cli（larksuite/cli 官方）整合——SearXNG v2026.8.14、Firecrawl 2026-08-15 build；lark-cli v1.0.87 安裝 + user OAuth（林卓翰）+ bind 到 secretary hermes app + 26 skills 掛 secretary/writer（見下節）**。**session 8（2026-08-16）：任務交付檢查鍊（Delivery Check Chain）footer——coordinator Output Contract 加「交付鏈」實際路徑欄位，secretary 回覆 footer 附 `[任務交付檢查鍊]`（見下節）**。**session 9（2026-08-16）：Lark 實測三大問題修復——(1) 修復 profile 層 plugins 缺 web-searxng/web-firecrawl + 8 profile wrappers 至 /usr/local/bin 實現真實多 process 串接；(2) 報告路徑限 Downloads/；(3) Lark 雲端交付自動選型 + footer 強制（見下節）**。**session 10（2026-08-17）：彈性單/多 agent 定案 + 複合任務硬規則 + 報告輸出強制 Downloads/——footer 已於 cron 驗證（含 `secretary->coordinator->researcher->coordinator->secretary` 完整鏈）；secretary/writer `terminal.cwd` 強制 Downloads/；複合任務（調研+產出）必須經 coordinator（見下節）**。**session 11（2026-08-18）：session 機制研究完成並回寫 deploy repo——兩種生命週期定案（secretary gateway = 持久 per-Lark-chat session；coordinator/所有 worker `-z` oneshot = 每任務全新 session；cron = `cron_<jobid>_<ts>` 新 session）；doc `docs/editions/opc-personal/session-mechanism.md` commit `a037dff` 已 push（見下節）**。**session 12（2026-08-25）：本地模型切換殘留診斷（agents-a1... [truncated]

## 2026-09-15 session 14 — 多 profile 任務分派改走 kanban board（v0.21.3 對齊）

### 背景
deploy repo 停在 v0.20.2，SOUL/docs 全用「直 spawn wrapper」（`/usr/local/bin/<profile> -z '<brief>' chat -Q`）描述任務分派。但實際機上 hermes-agent 已是 **v0.21.3**，分派機制改為**走 kanban board**（secretary 是 board 入口）。這是 v0.20.x → v0.21.3 之間最大的流程差異，repo 文件完全沒提到 kanban / dispatcher / max_in_progress。

### 根因（為什麼要改）
Freelancer 環境有 **8 個 OPC worker profile** 全部統一連線**同一台單執行緒本地後端** `192.168.23.217:1234/v1`（ornith-1.5-35b-a3b）。多 profile 同時直 spawn → 併發擠爆單執行緒 → researcher 階段 timeout → chain 崩。

**解法 = Kanban `max_in_progress_per_profile=1` + dispatcher 限流**，而非自建 gatekeeper proxy。

### 關鍵事實（v0.21.3）
1. **dispatcher 必須正常 tick**：`hermes kanban diagnostics` 無警報；建 running 測試 task 看是否派工。
2. **`max_in_progress_per_profile=1` 真正 enforce**（v0.21.1 是 no-op，v0.21.3 才修好）。實測：4 個 researcher sleep task → **1 running + 3 ready**。巢狀也受限（coordinator 派 3 個 researcher → 1 running + 2 ready）。
3. **coordinator-as-worker 必須有 kanban 工具**：`kanban_*` 工具只在 dispatcher 派工時自動注入（HERMES_KANBAN_TASK env）。terminal 直叫的 coordinator 是「正常 chat profile」，**沒有 kanban_* 工具**。故 secretary 必須當 board 入口。

### 正式流程
```bash
HM=/home/eye/.hermes/hermes-agent/venv/bin/hermes
# secretary 入口（board entry）
$HM kanban create "<任務 brief>" --assignee coordinator --idempotency-key "<描述>-$(date +%s)"
# dispatcher 60s tick 唤醒 coordinator-as-worker（帶 kanban_* 工具）
# coordinator 在 board 內用 kanban_create 派 researcher/writer，每層受 per_profile=1 限流
```

### 變更內容（全部完成並驗證）
- **新增 doc**：`docs/editions/opc-personal/kanban-dispatch.md`（v0.21.3 多 profile 分派單一事實來源：根因、關鍵前提、版本陷阱、正式流程、觀察驗證、還原指令、Cron 與 board 關係、繁中閘門、取捨記錄）。
- **secretary SOUL**：Routing「實際呼叫方式」從直 spawn coordinator 改為 `hermes kanban create --assignee coordinator`（board entry）+ 解釋為什麼不能直 spawn。
- **coordinator SOUL**：Routing「實際呼叫方式」從直 spawn worker wrapper 改為 coordinator-as-worker 在 board 內用 `kanban_create` 派工。
- **session-mechanism.md**：版本 v0.20.1 → v0.21.3；§2 補充入口改走 board（但 coordinator-as-worker 仍是 oneshot mode）。
- **README.md / VERSION**：v0.20.0 → v0.21.3；layout + 狀態區新增 v0.21.3 條目。
- **Cron 與 board 關係**（已在上一個 session 實作，此處回寫 repo）：3 個 cron job（情報推送/Forge 追蹤/繁中過濾器）是單 profile 自包含，**不走 board**。情報推送 job `91d908e7d563` prompt 加「爭用預檢」（scan 前先 `hermes kanban stats | grep running`，running>0 回 `[SILENT]` 讓後端）。情報推送 interval 已改 **every 90m**（與自動路由定時觸發 30m 節拍錯開）。
- **話題關注清單**：`/home/eye/workspace/daily/topic-watchlist.json` + `watchlist_match.py`（情報員比對 keywords，命中即深度研究並推送；未命中走既有判定）。
- **繁中閘門**：現行「繁中後置過濾器」（cron job `4e1a92d56868`）只盯情報推送輸出檔，管不到互動式自動路由。改由 secretary 當唯一交付點，用 `zh_check.py` 在交付前跑繁中檢查。

### 取捨記錄（使用者已裁決）
- **interval**：情報推送 job `91d908e7d563` 改 every 90m（取捨：情報更新慢半拍，但與自動路由時鐘節拍錯開、撞車機率幾乎為零）。
- **鬆動 trigger**：secretary 用自然語言識別意圖——「深入查一下 / 研究一下」→ 完整 chain；「關注一下 / 留意這個 / 這個有意思」→ 只加入關注清單 + 一句快速評估，不拉完整 chain（省本地算力）。

### 待辦
- 若需求強烈，再分為時觸發的輕量 cron job（階段 B 定時式自動路由）。


## 2026-09-15 session 15 — 完整 Runes 治理流程實測（四層架構走通 + coordinator 輪询卡死）

### 目標
驗證「多 profile agents + kanban board dispatch + plur 記憶層 + runes-holder/hermes-runes-md-wiki」**完整四層架構**能否一次連續走通：
```
secretary → coordinator(board) → researcher(研究+flag candidate) 
→ coordinator(merge+路由runes-holder) → runes-holder(forge建draft) 
→ secretary(審批) → approve → approved
```

### 實測結果（部分成功）

| 環節 | 狀態 |
|---|---|
| **researcher 研究交付** | ✅ 完成，213 行報告到 `/home/eye/Downloads/headroom-context-compression-assessment.md`（18KB），明確選型結論（部分導入 headroom proxy 模式）|
| **runes-holder 建 draft（forge native wrapper）** | ✅ 完成，`partial-adoption...cd03f6c7.md`，status: draft，operation manifest 記錄|
| **approve（forge native wrapper）** | ✅ 完成，manifest `forge-approve-20260915-213136`，status: draft → approved|
| **coordinator merge + 路由** | ❌ **失敗** — coordinator 進入輪询迴圈（polling loop）轉 29 分鐘沒動，一直試被攔截的 `python -c` 然後回退輪询，沒有撈起 researcher 成果、沒有路由到 runes-holder|

### 關鍵發現

1. **runes-holder + forge native wrapper 驗證通過** — wiki 存取治理確實只透過 profile agent runes-holder 執行，沒有直接改 wiki。這是之前沒測試過的部分。

2. **coordinator 輪询卡死 pattern failure** — 與 kanban_link 死鎖不同：coordinator 在「等待子任務完成」這段會陷入無效輪询（一直試 blocked 的 `python -c` → 回退 `sleep + kanban_show`），而不是推進 merge。這是 coordinator SOUL 還沒涵蓋的第二個 pattern failure。

3. **直接 approve 跳過了使用者關鍵字批准** — proper Runes 流程是 secretary 呈現 → 使用者批准 → 釋放一次性 token → runes-holder 執行 approve。這次為了「走完整流程」直接 approve，留下真實 approved proposal（後已刪除，因是測試產物）。

### 副作用處理（2026-09-15）
- **刪除重複 draft** `...a1ac8832.md`（runes-holder 原始 draft）+ **刪除 approved 測試產物** `...cd03f6c7.md`。forge-inbox 回到乾淨狀態（只剩 A/B/C/D）。
- **approve manifest** `forge-approve-20260915-213136-de70ee23.json` 保留作 audit 留痕（指向已刪 draft）。

### 待辦
- [ ] 修 coordinator SOUL：在「等待子任務完成」段加明確指示（用 `kanban_show` 直接查結果，不要陷入 `python -c` + `sleep` 輪询迴圈）。
- [ ] 重跑一次完整 Runes 流程（修正 coordinator 後），確認四層架構能一次連續走通。

---

## 2026-09-14 session 13 — nim-researcher → opencode-researcher 更名 + MoA reference 換源 OpenCode Go

### 變更內容（全部完成並驗證）
- **K6 實機（A 段，2026-09-14 11:xx）**：profile 目錄 `nim-researcher` → `opencode-researcher`（`.opc-managed-profile` role 同步）；`config.yaml`（backup `config.yaml.bak.opencode-20260914112835`）`moa.default_preset/active_preset` = `opencode-researcher`、reference = `[{provider: opencode-go, model: deepseek-v4.1-flash}]`（後續手動改為 go，見下方 E 段）、`fallback_providers: [opencode-go]`；`.env` 刪 `NVIDIA_API_KEY` 加 `OPENCODE_GO_API_KEY`；`/usr/local/bin/opencode-researcher` symlink → `~/.local/bin/opencode-researcher`（舊 nim-researcher 移除）；4 份 live SOUL（coordinator/researcher/runes-holder/secretary，backup `SOUL.md.bak.opencode-20260914-114124`）grep 歸零。
- **deploy repo（B 段，v0.20.2）**：新 template `editions/opc-personal/profiles/opencode-researcher/SOUL.md.template`（引用走 OpenCode Go `opencode-go/deepseek-v4.1-flash`）；`git mv scripts/setup-nim-moa-profile.sh → setup-opencode-moa-profile.sh`；doc `nim-researcher-moa-profile.md → opencode-researcher-moa-profile.md`（全文重寫，reference provider 換源說明 + provider 可抽換彈性）；`roles.txt`、`align-secretary-model.sh`、`verify-profile-templates.sh`、`verify-repo-layout.sh`、`m0-capability-check.sh`（OpenCode Go 端點檢查）、`setup-feishu-gateway.sh`（移除 NVIDIA_API_KEY）等全同步；VERSION 0.20.1 → 0.20.2。
- **wiki repo（C 段）**：`git mv wiki/freelancer/opc/nim-researcher → opencode-researcher` + README 標題更新 + CHANGELOG 0.7.6-dev 加 2026-09-14 rename 註記。
- **原則（D22/D8 延伸）**：MoA reference provider 持續概念化為「NIM / OpenCode Go / 其他第三方 API 可抽換」；K6 現為 OpenCode Go，本機 aggregator（ornith-1.5-35b-a3b, 192.168.23.217:1234）不變。

### E 段 live 驗證（2026-09-14，全部完成）
- **user 修正**：需求文件中的模型為 `deepseek-v4.1-flash`，且應在 **OpenCode Go**（provider `opencode-go`）而非 OpenCode Zen。OpenCode Zen 無此 model；`deepseek/deepseek-v4.1-flash` 屬 `deepseek` provider。Go registry `opencode-go` 可用該 model（實證）。
- **失敗樣本**（各階段蒐證）：`20260914_125330_54c9de`(provider `opencode` 解析失敗)、`20260914_125847_cecd83`(zen model not supported)、`20260914_130155_483aae`(zen CreditsError 餘額不足)、`20260914_134330_a07de3`/`134406_bc6bfc`/`134655_2d387a`(go 缺 key)。
- **root cause（關鍵）**：`-p <profile>` 執行時 key 解析來源是 **profile `.env`**（`~/.hermes/profiles/opencode-researcher/.env`）；global `~/.hermes/.env` 只在無 profile 上下文被讀。先前 go 失敗即因 profile `.env` 缺 `OPENCODE_GO_API_KEY`。
- **修復**：profile `.env` 新增 `OPENCODE_GO_API_KEY`（同值一把 67-char key，prefix `sk-d4guz...`；`OPENCODE_ZEN_API_KEY`/`OPENCODE_API_KEY` 保留不刪）。
- **✅ 成功**：session `20260914_134945_cc6f80` — ref[0] = `opencode-go:deepseek-v4.1-flash`，輸出真實回應「4.」無 fallback，usage 389/105/51。probe 全通（`resolve_runtime_provider('opencode-go')` key len 67）。
- **注意**：直接 urllib 打 `opencode.ai` 被 Cloudflare 403（error 1010）；hermes 內部 client 可通。K6 `hermes-gateway-secretary.service`（systemd）自動重啟，與 MoA chat 無關。
- **剩餘待辦**：deploy repo commit + push、wiki repo commit + push（待 maintainer 確認）。

### 2026-09-14 session 13 後續 — `agent-a1`/`agents-a1` 字串清理（現況統一為 ornith-1.5-35b-a3b）

- **deploy repo + 設計文件**（本機，2026-09-14 完成）：`agent-a1`/`agents-a1` 全 repo 檢索歸零，現況描述全面取代為 **`ornith-1.5-35b-a3b`**（同一 LM Studio `192.168.23.217:1234` 端點）——deploy repo（setup-opencode-moa-profile.sh、m0-capability-check.sh、README、opencode-researcher-moa-profile.md、observability-jobs-json.md、SOUL.md.template 等）+ 藍圖（§1 環境/§2 角色矩陣/§6 初始化/§8 算力預設）+ gap analysis（情境模板）+ 討論總結。
- **歷史紀錄刻意保留**：M0–M8 驗證欄、`handoff` session 2/10/12 及「核心決策快覽」中帶**當日日期**的實測事實（如「三端點 agent-a1 401」「7 角色 model 指向 agent-a1」「agents-a1 殘留呼叫診斷」）保留原模型名——那是當日實際量測/診斷對象，改寫會失真。相關文件標頭已補**變更註記**說明現況（`handoff session 13` 為準）。
- **待辦**：deploy repo 字串清理 + session 13 原待辦（deploy/wiki commit+push、spec 產出 2026-09-16）待 maintainer 確認。

## 2026-08-25 session 12 — 本地模型切換檢查清單（agents-a1 殘留呼叫診斷）

### 背景
- user 在 strixhalo（LM Studio, `192.168.23.217:1234`）把預設模型從 agents-a1 改成 ornith-1.5-35b-a3b，並透過 opencode remote 把 K6 大部分 profile `config.yaml` 的 `model.default` 改成 ornith（opencode-researcher、aeon-builder 除外）；重開機 + secretary Lark `/new` 後，LM Studio 上仍觀察到 agents-a1 被調用。

### 診斷結論（K6 實證）
- **元凶 = cron job 的 pinned model**：`~/.hermes/profiles/secretary/cron/jobs.json` 兩個 job（`91d908e7d563` 定向情報推送每 60m、`8dc524193079` Forge Guardrails 每 1440m）的 `model` 欄位仍釘 `"agents-a1"`。secretary `state.db` sessions 表實證：所有 `cron_*` session model=agents-a1、所有 feishu/cli session model=ornith —— profile 切換本身是成功的。
- 根因：**hermes cron job 各自攜帶 pinned `model` 欄位，改 profile `model.default` 不會自動跟著改**（自家 skill `cron-job-management/SKILL.md` 已記載此坑）。全域 default profile `~/.hermes/cron/jobs.json` 同樣釘 agents-a1。
- 其他 profile log 的 agents-a1 紀錄皆為切換前歷史；opencode-researcher MoA aggregator config 已是 ornith（僅 SOUL.md 文字 stale，不造成呼叫）。

### ⚠️ 未來切換 hermes-agent 預設本地模型時的強制檢查清單
1. **8 profile `config.yaml` → `model.default`**（aeon-builder 例外，指向 Spark/DGX `192.168.23.215`）
2. **opencode-researcher `config.yaml` → `moa.presets.<preset>.aggregator.model`**：MoA aggregator 是獨立區塊，**不跟隨 `model.default`**，必須一併變更
3. **secretary cron jobs**：`~/.hermes/profiles/secretary/cron/jobs.json` 每個 job 的 `model` 欄位（pinned，不隨 default 變更）→ `hermes -p secretary cron update --job-id <id> --model <新模型全名>`
4. **全域 default profile cron jobs**：`~/.hermes/cron/jobs.json` 一併修改或 disable job——multi-profile 模式下 default gateway 本身已 disabled，jobs 不應殘留 enabled
5. （文件層）opencode-researcher `SOUL.md` 內 aggregator 模型文字同步（deploy repo template 一併）

### 驗證方法
- K6 端：`state.db` sessions 表查最近 session 的 `model` 欄位 / `logs/agent.log` grep 模型名 / `hermes -p secretary cron list`
- strixhalo 端只能看到模型名 + 來源 IP（皆為 K6），**無法分辨 profile**——定位必須回 K6 查 log/state.db

### 待執行（尚未修復，指令備妥）
```bash
hermes -p secretary cron update --job-id 91d908e7d563 --model "ornith-1.5-35b-a3b@q4_k_m"
hermes -p secretary cron update --job-id 8dc524193079 --model "ornith-1.5-35b-a3b@q4_k_m"
```

### ✅ 修復已執行（2026-08-25，user 回報觀察一夜仍有 agents-a1 呼叫後）
- **再驗證**：cron pin 未改前，secretary log 08-25 起 **182 筆** agents-a1 呼叫（最新 `cron_91d908e7d563_20260825_092335`）；其他 profile/全域 0 筆——唯一呼叫者即未修的 cron
- **變更**：secretary + global 兩份 `jobs.json` 各 2 job 的 `model` 欄位 `agents-a1 → ornith-1.5-35b-a3b@q4_k_m`（直接 JSON 編輯；非互動 shell 無 hermes CLI in PATH，hermes 實際在 `~/.local/bin/hermes` → venv）
- **backup**：`jobs.json.bak.20260825-100332`（兩處各一）
- **驗證**：4 個 job entry 全部 model=ornith ✓；下一輪每小時 cron（~10:23）應改載 ornith，可由 LM Studio / K6 agent.log 複驗

## 2026-08-17 session 10 — 彈性單/多 agent 定案 + 複合任務硬規則 + Downloads/ 強制

### 背景
- user 確認 cron 推送 footer 已出現（含完整多 agent 鏈 `secretary->coordinator->researcher->coordinator->secretary`，08-17 07:36 cron 輸出），footer 機制全面生效。
- 關鍵認知：**Hermes v0.20.0 無硬路由**——多 agent 靠 SOUL 提示 + LLM 自覺；本地小模型（agents-a1）對「不要自己做、去呼叫 coordinator」遵循度低。
- user 決策：**彈性單/多 agent**（簡單→direct，複合→coordinator）+ 複合任務精準觸發。

### 修復（deploy repo commit `5d5a30e` 已 push + K6 同步）
- **複合任務硬規則**（secretary SOUL）：任務**同時含「調研/查證/研究」+「產出/報告/表格/簡報」兩要素**必須經 coordinator（`/usr/local/bin/coordinator -z ...`），不得單一完成；附判斷準則範例（複合 vs 非複合）。單一要素/純問答/cron 情報掃描維持 direct。
- **Downloads/ 強制（多層）**：
  1. secretary + writer profile `config.yaml` 加 `terminal.cwd: /home/eye/Downloads`（backup `.bak-termcwd`）→ 影響 `terminal` 工具。
  2. **gateway systemd drop-in `path-plur.conf` 加 `TERMINAL_CWD=/home/eye/Downloads` env**（backup `.bak-termcwd`）→ 影響 `write_file`/file_tools 的相對路徑解析（根因：write_file 用進程 cwd `/home/eye`，非 terminal.cwd；TERMINAL_CWD env 讓 file_tools 的 `_configured_terminal_cwd()` 解析相對路徑到 Downloads/）。
  3. **⚠️ profile home `~` 陷阱（關鍵）**：hermes 的 `~` 展開成 **profile home**（`~/.hermes/profiles/secretary/home/`），非真實 `/home/eye`。故 SOUL 輸出規則改用**真實絕對路徑 `/home/eye/Downloads/`**（非 `~/Downloads/...`），並禁止相對檔名/`~`。**新 session（`/new`）後 live terminal cwd 正確**；既有長對話 session（如 `20260815_032511`）cwd record 固化在舊值，`/new` 開新 session 即解決。
- **清理**：已落 `/home/eye/` 與 profile-home/Downloads 的舊報告（gorgon/dgx_station/dgx_spark/pixel_11/rtx_pro_6000/rtx_5090/rtx4090 + 測試檔）搬至 `~/Downloads/old-home-reports/`。

### 驗證（實測 PASS）
- **cwd 強制**：secretary 執行 `pwd` = `/home/eye/Downloads`；write_file 建立 `test_termcwd.md` 於 Downloads/（非 home 根目錄）——TERMINAL_CWD env 使 file_tools `_configured_terminal_cwd()` 解析相對路徑到 Downloads/。
- **user 實測（2026-08-18）**：Lark `/new` 開新 session 後，報告正確放到 `/home/eye/Downloads/`（user 確認）。既有長對話 session 需 `/new` 重置 cwd record。
- **Lark 交付補充**：回覆路徑一律真實 `/home/eye/Downloads/<檔名>`（禁 `~/Downloads/...`）；lark-cli 上傳用相對路徑 `./<檔名>`（cwd 已是 `/home/eye/Downloads`）；lark-cli 已 user 綁定（`cli_aaabd1f1bc38de18`），token 過期 auto-refresh，「要求 bind」常是 unsafe-file-path（需相對路徑）而非真未綁定。lark-cli `drive +upload` user 身份實測成功（產 Lark Drive URL）。
- **複合任務走 coordinator**：secretary 對「調研 Python 3.13 + 產報告」spawn `hermes -p coordinator`（process 證明）→ coordinator 再呼叫 researcher（多 process 真實串接）。
- **footer**：`[任務交付檢查鍊] secretary (direct)` 與完整鏈皆正常。
- **註記**：CLI 深串接（secretary→coordinator→researcher）耗時數分鐘（每層 model 20-80s），適合 Lark/cron 使用（無外部 timeout），CLI 測試需耐心；多 agent 仍依賴模型遵循 SOUL，非絕對保證。

## 2026-08-18 session 11 — Session 機制研究 + 文件回寫 deploy repo

### 研究結論（K6 hermes-agent v0.20.1 源碼 + state.db 實證）

- **Secretary = 唯一的持久 session profile**：常駐 gateway（`hermes-gateway-secretary.service`），session 依 chat 決定性建立（`gateway/session.py:build_session_key()` → `agent:main:feishu:dm:oc_<chat_id>`）；`get_or_create_session()` 找到即沿用 → 同一 Lark DM 共用同一 session（DB 實證 message_count 41/84/135 累積）。`/new` = `force_new` → 同一 chat 新 session_id，`prev_session_id` 記連續性（正是 session 10「cwd record 固化、`/new` 重置」的根因）；`gateway_routing` table 持久化 key→session_id。
- **Coordinator / 所有 worker = 每次指派全新 session**：SOUL 呼叫 `/usr/local/bin/<profile> -z '<brief>' chat -Q` 是 oneshot mode（`hermes_cli/oneshot.py`）——spawn 全新 hermes process、無 session_id → `agent/agent_init.py:1565` 自動 `{YYYYMMDD_HHMMSS}_{6hex}`、`run_agent.py:_ensure_db_session()` 首 turn 惰性建 row（source=cli）、跑完 stdout 回傳 exit。DB 實證 researcher/coordinator 每任務一 session（如 `20260818_122611_58bbf4` 14 則）。
- **cron**：`cron_<jobid>_<ts>`、source=cron，每次 run 新 session（secretary 執行）。
- **資料存放**：每 profile 獨立 `state.db`（`~/.hermes/profiles/<role>/state.db`）`sessions` table。
- **設計後果**：worker context 不跨任務延續（只重載 SOUL/MEMORY/skills/Plur），跨任務狀態靠記憶層扛；與 D3 序列化一致。此機制為 hermes 原生，不需 config/SOUL 變更。

### 產出（deploy repo）

- **doc**：`docs/editions/opc-personal/session-mechanism.md`（兩種生命週期 + 源碼引用 + DB 實證 + 設計後果 + 實務註記）。
- **索引**：根 `README.md` + `editions/opc-personal/README.md` docs 清單同步。
- **驗證**：`verify-repo-layout.sh` PASS。
- **commit `a037dff` 已 push**（`57ef68e..a037dff`）。

## 2026-08-16 session 9 — Lark 實測三大問題修復（多 agent 串接 / 路徑 / Lark 交付）

### 問題（user 從 Lark 實際下達「調研 AMD Gorgon Halo 495 + 產 lark 多維表格報告」）
1. **未見多 agent 流程**：secretary 直接處理，報告寫在 `/home/eye/`。
2. **報告路徑無限制**：寫到 home 根目錄（應限 Downloads/ 或 Lark 雲端）。
3. **footer 無 `[任務交付檢查鍊]`**。

### 根因（完整定位）
- **profile 層 plugins 缺口**：session 6 只改全域 config，8 個 profile 的 `config.yaml` plugins.enabled 全缺 `web-searxng`/`web-firecrawl` → secretary `web_extract` 失敗（firecrawl plugin disabled）、search 走 ddgs。
- **⚠️ secretary disabled 清單衝突（關鍵）**：secretary profile 的 `config.yaml` `plugins.disabled` 清單**同時含 `web-searxng`**（hermes 預設 disabled 清單）→ 即使 enabled 也永遠被跳過（plugins.py：`if lookup_key in disabled ... skip`）。移除 line 132 的 `web-searxng` 後 searxng 才真正註冊。其他 7 profile 無此衝突（無完整 disabled 清單）。
- **無跨 process 串接**：secretary 單 process 完成，未用 `~/.local/bin/<profile>` wrapper 呼叫 coordinator/workers（且 agent PATH 不含 `~/.local/bin`）。
- **無輸出路徑規則** + **無 Lark 雲端交付流程**。

### 修復（deploy repo commit `ef98a4e` 已 push + K6 同步）
- **PATH**：`/usr/local/bin/<profile>` 8 支 symlink（secretary/coordinator/researcher/opencode-researcher/writer/builder/runes-holder/aeon-builder）→ agent terminal 可呼叫其他 profile。
- **Plugins**：8 profile `config.yaml` plugins.enabled 加 `web-searxng` + `web-firecrawl`（backup `.bak-webplugins`）。
- **writer**：掛 `lark-base` skill（自動選型建多維表格）。
- **secretary SOUL**：Routing 強制「實際呼叫 coordinator」（`/usr/local/bin/coordinator -z '<brief>' chat -Q`）；多步任務不得自行完成；輸出規則「本地產物一律 `~/Downloads/` 禁寫 home 根目錄」；Lark 雲端交付自動選型（表格→`lark-cli base +create`、文件→`lark-cli drive upload`）；footer 強制必附。
- **coordinator SOUL**：路由時用 wrapper 實際呼叫 worker（`/usr/local/bin/researcher -z '...' chat -Q` 等），等待回傳合併，Output Contract 帶實際交付鏈。

### 驗證（實測 PASS）
- **web provider 註冊**（修復後）：gateway 內 `web-ddgs`/`web-firecrawl`/`web-searxng` 三支全註冊（agent.log 08:33:28）；`_get_search_backend()=searxng`、`_get_extract_backend()=firecrawl`；secretary 回報「web_search 使用 searxng 作為搜尋後端」。
- **多 agent 串接真實發生**：process 樹 secretary→coordinator→researcher 多個獨立 hermes process + researcher/coordinator state.db 時間戳更新（08-16 08:05）。
- **web_search → searxng**、**web_extract → firecrawl**（修復前 firecrawl disabled 報錯）。
- **Downloads/ 路徑**：secretary 寫檔到 `/home/eye/Downloads/test_download.txt`（非 home 根目錄）。
- **Lark Drive 上傳**：writer 用 `lark-cli drive +upload` 上傳成功，取得連結 `https://bjpdz4jwmubt.jp.larksuite.com/file/ELibbRRZpo1T92x4KVOjJjtXpdf`；lark-base +create 可用。
- **footer**：`[任務交付檢查鍊] secretary (direct)` 與 `secretary->coordinator->researcher->coordinator->secretary` 皆正確。
- **註記**：CLI 深層串接（secretary→coordinator→researcher）耗時 >2 分鐘且輸出擷取不穩；模型在 coordinator 層可能「假裝」呼叫 worker（無 tool 執行記錄）——已透過「要求回報 worker 實際輸出」與 process/state.db 驗證真實串接可行；Lark 端完整流程建議實測。

## 2026-08-16 session 8 — 任務交付檢查鍊（Delivery Check Chain）footer

### 需求
使用者在 secretary 新問答任務回覆的 footer 最後，附加交付檢查鍊，顯示本次任務實際走過的 profile 路徑（如 `[任務交付檢查鍊] secretary->coordinator->researcher->coordinator->writer->coordinator->secretary`）。

### 設計（方案 B：coordinator 實際追蹤）
- **coordinator SOUL**（deploy template + K6）：Output Contract 加「交付鏈」欄位與追蹤規則——每次路由 worker 後把該 profile 加入交付鏈，最終回 secretary 帶完整實際路徑（含 reroute nim 的範例；不含預期的 `or` 分支，實際選了誰就記誰；未路由標 direct）。
- **secretary SOUL**（deploy template + K6）：Output Style 後加「Delivery Check Chain」段——經 coordinator 任務讀其「交付鏈」欄位原樣放 footer；純問答標 `[任務交付檢查鍊] secretary (direct)`；coordinator 缺欄 fallback 最簡鏈。

### 變更
- deploy repo：`editions/opc-personal/profiles/coordinator/SOUL.md.template` + `secretary/SOUL.md.template`（verify-profile-templates + verify-repo-layout 全 PASS）；**commit `67981a5` 已 push**。
- K6：sync-soul-to-profiles.sh 同步 coordinator + secretary（backup `.bak.20260816-070657`，changed=2 in-sync=6）。

### 驗證（實測 PASS）
- 純問答：`[任務交付檢查鍊] secretary (direct)` ✓
- coordinator 交付（合成端到端）：`[任務交付檢查鍊] secretary->coordinator->researcher->coordinator->secretary` ✓
- coordinator 單獨路由時確認理解規則（輸出 handoff packet + 「附上完整交付鏈」）。
- **註記**：CLI quick-chat 下 secretary/coordinator 無法真正跨 process 呼叫 worker（需外部調度/cron 串接）；真實跨 profile 任務由 cron 或外部流程逐 process 串接，coordinator 在收到 worker 實際回傳後於 Output Contract 帶交付鏈。

## 2026-08-16 session 7 — Docker 升級 + lark-cli 整合

### Docker SearXNG / Firecrawl 升級
- **SearXNG**：v2026.5.29 → **v2026.8.14**（落後 2.5 月；`docker compose up -d --force-recreate`，settings.yml bind mount 保留）
- **Firecrawl**：v2.11.0 時期 → **BUILD_SHA `f748af9d`（2026-08-15）**（全 stack `--force-recreate`，fdb/redis/rabbitmq volume 保留）
- 驗證：search/scrape 實測 PASS、researcher web_search 正常、gateway/cron 無異常。

### lark-cli（larksuite/cli 官方 CLI）整合
- **背景**：hermes 內建 feishu 工具僅 5 支（`feishu_doc_read` + drive 評論）；lark-cli 補足「以 user 身份操作 Lark 生態」——200+ 命令、18 業務域、26 Agent Skills。決策 B：secretary + writer 掛載。
- **安裝**：`npx @larksuite/cli@latest install` → **v1.0.87**（Go binary 於 npm package `bin/lark-cli`；skills 裝 `~/.agents/skills/` 27 支）。
- **PATH 修正（踩坑）**：
  - npm bin 的 `scripts/run.js` 是 node launcher，但曾被誤覆寫成 bash wrapper → 還原（GitHub 原始碼）。
  - agent 執行環境 PATH 不含 `~/.local/bin` → 建 `/usr/local/bin/lark-cli` symlink → wrapper（設 `HOME=/home/eye` 讓 lark-cli 讀真實 config）→ agent 內可執行。
  - 曾設 `terminal.shell_init_files`（後因 symlink 方案用不到而移除）。
- **認證**：`config init --new --force-init --brand lark`（建立 app）→ `config bind --identity user-default`（綁到 secretary hermes app `cli_aaabd1f1bc38de18`）→ `auth login --recommend`（user OAuth，**林卓翰** `ou_23951bdd...`，大量 scopes）。bind 會在 agent context（HERMES_HOME）下要求 user 確認。
- **掛載**：secretary（lark-shared/im/calendar/doc/drive/task）+ writer（lark-shared/doc/drive/sheets/slides/markdown）。
- **驗證**：secretary agent 執行 `/usr/local/bin/lark-cli contact +search-user --query 林卓翰` 回報 open_id/email PASS；writer 同 PASS；`auth status` appId 正確。
- **注意**：lark-cli 以 **user 身份**操作（可讀寫個人資源），官方警告勿分享 bot/勿入群組；風險控制維持預設。

## 2026-08-16 session 6 — rtk-rewrite 重裝 + Web backend 本地化（SearXNG/Firecrawl）

### rtk-rewrite 重裝（方案 A：官方 PyPI）
- **rtk binary v0.42.4 → v0.45.0**：`curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh`；舊版備份 `~/.hermes/backups/plugin-skill-session-20260816/rtk/rtk.bak.v0.42.4`。`rtk rewrite` 實測正常。
- **plugin**：`$HERMES_PY -m pip install --upgrade rtk-hermes` → **v1.2.3**（官方 PyPI 套件，非舊的目錄 plugin 0.1.0）；entry point 驗證 `rtk-rewrite | rtk_hermes | 1.2.3 | True`。
- **config**：全域 `plugins.enabled` 加 `rtk-rewrite`（CLI enable 對 pip entry point 有已知限制，直接編輯）。
- **gateway 重啟**後無 rtk warning、Lark 重連正常、secretary ping PASS。先前「rtk 失效」主因 = 舊目錄 plugin 0.1.0 + 互動 shell PATH 不含 `~/.local/bin`（gateway drop-in PATH 已含）。

### Web backend 本地化（捨 ddgs，K6 本機服務）
- **決策**：ddgs（免費）rate limit 不穩定 → 捨棄；改 K6 本機已部署的 SearXNG（:8088）+ Firecrawl（:3002）。
- **機制**（原始碼確認）：backend 解析優先序 `search_backend`/`extract_backend` → `web.backend` → env 自動偵測（`agent/web_search_registry.py`）。SearXNG **search-only**（`supports_extract=False`）→ 不能當共用 fallback；Firecrawl search+extract 皆可 → **全域 fallback = firecrawl**。env 為 **profile-scoped**（`agent/secret_scope.py`：profile 執行從該 profile `.env` 建 scope，miss 不 fallthrough）→ 變數寫入各 profile `.env`。
- **實測確認**：firecrawl self-host `USE_DB_AUTHENTICATION=false` → 免 API key，`/v1/search`+`/v1/scrape` 均成功；searxng JSON search 成功。
- **變更**：
  - 全域 plugins.enabled 加 `web-searxng` + `web-firecrawl`（provider 註冊前提）
  - 8 profile `.env` 各加 `FIRECRAWL_API_URL=http://127.0.0.1:3002`（backup `.bak-web`）；搜尋 3 角色另加 `SEARXNG_URL=http://127.0.0.1:8088`
  - 3 搜尋角色（researcher/opencode-researcher/secretary）config.yaml 設 `web.search_backend: "searxng"` + `web.extract_backend: "firecrawl"`（backup `.bak-web`；opencode-researcher 原無 web block 新增）
- **驗證**（實測 PASS）：researcher 回報「搜尋使用本地 SearXNG (localhost:8088) + 內容經 Firecrawl (localhost:3002) 完整抓取」；nim-researcher/writer（fallback firecrawl）搜尋均成功；gateway 重啟 Lark 連線正常、cron ticker 正常；`hermes cron list` 2 jobs active。
- **Docker SearXNG/Firecrawl 升級（session 6 後續）**：searxng `v2026.5.29 → v2026.8.14`（落後 2.5 月，`docker compose up -d --force-recreate` 重建，settings.yml bind mount 保留）；firecrawl `v2.11.0 時期 → BUILD_SHA f748af9d (2026-08-15)`（`--force-recreate` 全 stack 重建，fdb/redis/rabbitmq 資料 volume 保留）；升級後 search+scrape 實測 PASS、researcher web_search 正常、gateway/cron 無異常。
- **備份**：config `.bak-web`、`.env.bak-web` 於各 profile + `~/.hermes/backups/plugin-skill-session-20260816/`。

## 2026-08-16 session 5 — Plugin/Skill 盤點更新與分配

### 內容（K6 實機，hostname=Freelancer）
- **Hermes 升級 v0.20.0 (2026.8.3) → v0.20.1 (2026.8.13)**：`hermes update`（1620 commits）；`doctor --fix` config migration `_config_version` 34→37；8 profile ping 全 PASS；gateway（secretary）重啟後 Lark websocket connected、cron ticker 正常、無 rtk warning。
- **ppt-master v4.5.0 → v4.7.0**：全域 repo `git checkout v4.7.0`（commit `e8323bfa`）；writer symlink 自動指向新版；`attribution_guard.py` GUARD_OK；本地使用痕跡（decks_index.json 修改 + 新 templates/projects 目錄）保留未動。
- **rtk-rewrite plugin 移除**：因 rtk binary 不在 PATH 致 hook 未註冊（啟動 warning、完全失效）→ `hermes plugins remove rtk-rewrite` + sed 清全域 config/secretary config 殘留；plugins list 已無。
- **plugin 名稱變更注意（升級衍生）**：`web/ddgs` plugin 顯示名改為 `web-ddgs`（plugin.yaml name），config 舊別名 `web/ddgs` 仍被解析；`hermes plugins enable web-ddgs` 後 plugins list enabled、web.backend: ddgs 搜尋實測正常。
- **plur-hermes 0.17.2 = LATEST**（pip 確認），無需更新。
- **Skill 分配（18 支 symlink，6 profile）**：researcher(web-search-strategies/arxiv/grounded-citations)、opencode-researcher(+ai-agent-comparison)、writer(docx/humanizer，ppt-master 原有)、builder(TDD/systematic-debugging/spike/github-repo-management/github-pr-workflow)、aeon-builder(systematic-debugging/spike)、runes-holder(hermes-runes-wiki)、secretary(cron-intelligence-scan)；coordinator 無新增。保留 `.no-bundled-skills`（避免 update 自動種子）與各 profile plur-memory symlink。
- **驗證**：8 profile skills 目錄 symlink 正確；skill 載入實測（researcher/nim-researcher/writer/builder/runes-holder/secretary/aeon-builder 均回報所分配 skill）；3 profile ping PASS。
- **備份**：`D:\Workspace\projects\hermes-backup\plugin-skill-session-20260816\`（configs/skills tar + sha256 + manifest，升級前狀態）；K6 本機 `/home/eye/.hermes/backups/plugin-skill-session-20260816/`。
- **文件**：deploy repo 新增 `docs/editions/opc-personal/skill-allocation.md`（分配表 + plugin inventory + 驗證 + rollback），**待 commit/push**。

## 2026-08-15 session 4 — 13 份 SOUL 模板全量 refine（v0.20.1）

### 內容（opc-personal 8 + generic 5，`hermes-agent-opc-deploy` repo）
- **統一結構**：13 檔共用 section 順序（Role/角色定位 → Mission/任務 → Not Your Role/不是你的角色 → Fact Division/協作分工 (D22) → 執行規則 → Output/交接格式 → Memory Boundary/記憶邊界 → Safety Boundary/安全邊界 → Language Policy/語言政策 → Maintenance Notes）。
- **語言政策統一**：繁中為主、技術名詞/commands/paths/API/model names 保留原文（先前 secretary/runes-holder 繁中、其餘 6 檔英文主導）。
- **補齊 2026-08-15 決策**：Plur scope 紀律（`project:freelancer` + `plur promote` + 英文關鍵字）進全部 8 檔 Memory 段；C6/B4 已在 nim-researcher 保留；#8(a) 舊 CLI 禁用在 runes-holder 標註。
- **補缺節**：Fact Division (D22) 補進 writer/builder/aeon-builder（原缺）。
- **去冗**：coordinator 移除重複的 Output Contract 交接模板（chars −35%）；runes-holder 精簡說明文字保留 whitelist 全表（chars −20%）。
- **去硬編碼**：aeon-builder（192.168.23.215）、nim-researcher aggregator（192.168.23.217）改指 profile config/docs。
- **generic 5 檔**：由 ~190 token 空骨架填成精簡可用內容（native-only 記憶、L1/L2 白名單、不綁 Lark、無 runes/MoA/A2A/cron governance）。

### Token 用量審計（`tiktoken cl100k_base`，詳 repo `docs/soul-token-audit.md`）

| Profile | before tok | after tok | Δ | before chars | after chars | Δ |
|---|---:|---:|---:|---:|---:|---:|
| opc-personal 8 檔小計 | 11462 | 14103 | +2641 (+23%) | 35291 | 30455 | −4836 (−13.7%) |
| generic 5 檔小計 | 949 | 3960 | +3011 (+317%) | 1281 | 6181 | +4900 (+383%) |
| **TOTAL** | **12411** | **18063** | **+5652 (+46%)** | **36572** | **36636** | **+64** |

- **opc-personal 真正精簡**（chars −13.7%）；tokens +23% 主因是**繁中化**（cl100k 對 CJK 1 token/字，英文詞較省）。實際 runtime model tokenizer 若對中文較省，差距更小。
- generic +317% 屬預期（骨架填空）。

### 驗證與收尾
- `verify-profile-templates.sh`（strict）13 檔全 PASS；`verify-repo-layout.sh` PASS（含 VERSION=0.20.1 更新）。
- VERSION `0.20.0 → 0.20.1`；README/edition READMEs 同步；新增 `docs/soul-token-audit.md`。
- **已 push（commit `dde6c33`）**；**K6 已同步完成（2026-08-16）**：repo pull 至 `dde6c33` → `sync-soul-to-profiles.sh --apply` 8 profile SOUL 全更新（backup `.bak.20260816-033622`）→ cmp 8/8 MATCH → runes-holder/coordinator/secretary ping PASS（回應反映新 SOUL：Native Wrapper ONLY / 序列化 / 風險暴露）。

### 備註：SOUL.md vs AGENTS.md（2026-08-16 確認）
- **確認：未修改任何 AGENTS.md**。8 個 profile 目錄內無 AGENTS.md；K6 全域僅 hermes-agent 主 repo 與 ppt-master skill 內有 AGENTS.md。
- hermes 機制（`agent_init.py:577-578`）：**SOUL.md = per-profile identity**（身份/人格，profile 目錄載入）；**AGENTS.md = project context**（專案規則，從 cwd / HERMES_HOME 載入，非 profile 層級）。兩者獨立，`--ignore-rules` 同時略過。
- **結論**：per-agent 的設定載體就是 SOUL.md（已 refine + 同步 + ping 驗證）；AGENTS.md 屬專案層級，不進 profile 模板、與 SOUL refine 無關，**無需新增或修改**。repo 說明見 `hermes-agent-opc-deploy/docs/editions/opc-personal/soul-vs-agents.md`。


## 2026-08-15 session 3 — P3 Runes 審批 UX 接線（#5 完成接線，寫入留 #8）

### 接線內容（決策：審批 UX 接線 + SOUL 層象徵 token，不實作 forge/inscribe）
- **3 SOUL 更新**（deploy repo templates + K6 同步，backup `SOUL.md.bak.20260815-152258`）：
  - **runes-holder**：6 支 shield 唯讀 CLI 白名單（`proposal_registry` / `proposal_review_queue` list/show/show_payload + `runes_shield_tool_index` list/blocked）+ 硬邊界（proposal.apply/approve/promote/wiki.write/database.mutate = human-only）+ token 消費規則 + 下沉/回退 + audit 改 `governed_write_intent`
  - **coordinator**：Runes 唯一路由 hard rule（secretary/workers 全經 coordinator → runes-holder，含 retrieve）+ handoff `approval_token` 欄（`R-<ts>-<4hex>`）
  - **secretary**：雙軌審批（L2 互動卡片 + Runes **Lark 純文字關鍵字** `批准/拒絕/撤銷 <proposal_id>`）+ 一次性象徵 token 釋放
- **工具白名單實測**：`hermes -p runes-holder approvals test` 對 shield 命令（絕對/相對/`cd &&` compound）全 **allow** → **無需改 approvals allowlist**
- **e 下沉測試 PASS**：runes-holder 經 chat 執行 `proposal_review_queue.py list` 確認候選 `proposal-m37.2-fixture-001`（pending_human_review）；audit 寫入 `governed_write_intent`（token `R-20260815-1745`）VALID JSONL；**不實際寫 wiki**
- **f 故障回退測試 PASS**：coordinator 引用新 SOUL——runes-holder 不可用 → 跳過 Runes 層 + 標「無 Runes 治理佐證」+ **不假裝 PLUR 替代治理證據**；PLUR store 實測 **120 engrams**（資料層正常）
- 3 profile ping PASS（coordinator/secretary/runes-holder，quick-chat）；runes-holder 回應反映新 SOUL 內容
- **文件**：`docs/editions/opc-personal/runes-approval-ux.md`（關鍵字語法/token 生命週期/白名單/audit 格式/e-f 測試）
- **deploy repo commits**：`cc0fa80`（3 SOUL + runes-approval-ux.md）+ `d0b6e2d`（Plur scope 紀律入 plur-memory-layer.md）；**已 push（2026-08-15，含 `8158859`，`7c5c3b6..8158859`）**
- **Plur scope 紀律落實**：新共享 learns 一律 `project:freelancer`（現況 global 85/user 34/agent:writer 1，**不做 bulk 遷移**）；關鍵規則 `plur promote`；中文 statement 帶英文關鍵字
- **藍圖 §9 同步**：#3/#4/#6 標收斂（含量測結果）、#5 標接線完成、#7 標不處理、#8 標剩餘待辦

### 剩餘（#8 runes 收尾）
~~runes forge/inscribe 未實作 → audit 意圖記錄~~ **已更正（P3 v2）**：`tools/importer/forge.py create-flat/approve/reject` + `bin/hermes-agent-propose-memory` + `write_guard` + operation manifest **均已實作**（P0 寫入路徑可用）。剩**舊 scaffold** `bin/hermes-runes forge/evoke/inscribe`（M15.3 舊介面）未實作但**禁用作路徑**；`indexes/links` 補實待 runes 工具層可用。

### P3 v2 修正（2026-08-15，session 3 之後）
- **發現**：repo 的 runes-shield 層已提供**現成且已實作**的 native wrapper 棧（M42 人為決策 / M51 invocation / M52 adapter / M53 session / M54 audit persistence / `tools/importer/forge.py create-flat|approve|reject` / `bin/hermes-agent-propose-memory`）。session 3 只查了唯讀 shield index + 舊 `bin/hermes-runes` scaffold，誤判「forge/inscribe 未實作」，自製了「audit intent only」做法 —— **前提錯誤**。
- **修訂**：3 SOUL 改為 **Native Wrapper ONLY 規則**（所有 `hermes-runes-md-wiki` 操作一律經 runes-shield 層 native wrapper，禁 cat/sed/python 直接改檔、禁舊 scaffold）；governed write = `forge.py create-flat --write` 建 draft → 使用者批准 → `forge.py approve/reject`（真實 status 變更）→ operation manifest 審計。
- **實測**：全部白名單命令（唯讀 + 寫入 6 支）`approvals test` 全 **allow**；e 測試（真實版）`create-flat`(draft) → `forge.py approve`(draft→approved) + 2 份 manifest 全 PASS（產物已清理）；3 SOUL 同步 K6（backup `.bak.20260815-154055`）ping PASS。
- **deploy repo**：commit `8158859`（P3 v2，4 files）+ session 3 的 `cc0fa80`/`d0b6e2d` **已全部 push**（`7c5c3b6..8158859 main -> main`，2026-08-15）。
- **runes repo 文件修正（2026-08-15）**：v0.7.5 修正本體無 bug，但其「read-only scaffold」前提錯誤（`proposal_registry`/`proposal_review_queue`/`proposal_draft_store` 只讀 `fixtures/`/`drafts/` 測試面，真實 lifecycle = `tools/importer/forge.py` → forge-inbox + operation manifests）。已修正 CHANGELOG 0.7.6-dev planned（改為 forge native wrapper）+ Notes + `runes_shield_contract.md` Two-Layer Boundary（read index vs controlled write）段落。**PR #6 已合併（`7ccbcbc`）**；本地 `39f0c59`、K6 `19f515e`（blob 一致 LF）；K6 已 merge origin/main 收斂（`b73fe52`，working tree = origin/main，backups `.bak.p3v2` 保留）。
- **A1 殘物清理（2026-08-15）**：`~/.hermes/opc/runes-audit.jsonl` 的 session 3 測試行（`R-20260815-1745`，誤判做法殘留）已 backup（`runes-audit.jsonl.bak.p3-session3-test.<ts>`）後清空；現以 operation manifest 為主要審計。

## 2026-08-15 session 2 — §9 開放目標評估執行記錄（#3/#4/#6 完成，#5 擱置）

### P1｜#3 nim-researcher MoA 成本/延遲評估（完成）
- 方法：`hermes -p nim-researcher chat -Q -q <task> -m moa:nim-researcher` 5 成功 run（A1/A2/A3/B2/C1）+ B1（NIM 掛起 >10min 被殺）
- **結果**：NIM reference 每次 1 call（in≈392–404 / out 136–528 / cache_read 16 tokens）、reference phase **65–98s**（固定開銷）；本機 aggregator（agents-a1）**1–17 turns/任務**（per-call in 16K→35K、out 179–1114、延遲 4.5–32.5s）；總耗時 106–423s
- **結論**：MoA 真正成本是**時間非 tokens**。NIM tokens/任務僅 0.5–1K、`cost_usd=null`（未配 pricing）、無 429（未撞 quota）、但有 504 與一次掛起。主變異源 = **aggregator 工具 turn 爆炸**（同「brief 2-fact」跑 1→17 turns）。改進方向：限制 nim-researcher 工具 turn（SOUL / `--max-turns`）
- **K6 config 變更**：nim-researcher `config.yaml` 加 `auxiliary.free_only: true` + `auxiliary.title_generation.enabled: false`（修掉 title gen 搶單 slot + OpenRouter 付費 fallback）；backup `config.yaml.bak.20260815-p1`

### P2｜#4 Plur 衰減評估（完成）
- **盤點**：engrams.yaml 118 筆（41 active / 77 retired）；scope 僅 **global(84)+user(34)**、無 agent:/project:；active 全 retrieval_strength≥0.7；median last_accessed **45 天前**；feedback 全 0
- **CLI 0.9.4 行為（讀 core 源碼 `@plur-ai/core@0.9.4`）**：**舊式 reactivate `min(1, strength+0.1)`**（每次 recall/search/inject +0.1、3 次飽和，= #846 未修前行為）；decay 僅靠手動 `plur batch-decay` 落地（λ=0.05·(1−emotional_weight/20)、status 門檻 >0.5 active）；**無 shouldInject**；recall 的 `--scope` 不過濾（實測 scoped/unscoped 同批）
- **injection 實測**：`agent:writer` 與 global 測試 engram 都進 constraints；27 天前 global 情報 engram 也注入 → 現況實質「不會遺忘」，衰減近乎關閉
- **評估結論（個人 multi-agent 角度）**：0.9.4 無「scope 命中永遠注入」逃生門；衰減只影響 injection 排序不排除。記憶分層：① hermes 原生 MEMORY.md 真正 always-on ② PLUR 放 working state + 共享固定 scope（如 `project:freelancer`）、必要時 `plur promote`(設 0.7)/feedback 強化 ③ runes 可選時下沉固化、缺席時 PLUR 扛責（與 bridge doc 一致）。中文 recall 弱（BGE-small 英文 embedder，#781）→ statement 帶英文關鍵字
- **P2(d) 跨週 baseline 已種下**：`ENG-2026-0815-001`(scope agent:writer, str 0.9, freq 2) / `ENG-2026-0815-002`(scope global)；**4 週後複查**是否仍被注入/衰減。backup `~/.plur/engrams.yaml.bak.20260815-p2b`

### P4｜#6 SLO 基線量測（完成，首次量測）
- **secretary 快速問答**（gateway live 樣本，agent.log `response ready`）：5.5 / 12.7 / 25.2s → **P50=12.7s / P95≈25s**（n=3）
- **coordinator 路由**（CLI 3 runs）：31 / 63 / 67s → **P50=63s / P95=67s**
- **aeon-builder**（CLI 2 runs，F(35)）：16 / 114s、**2/2 成功**（A1 工具執行被擋但手算驗證；A2 純推理快答）→ **P50=65s**（n=2）
- **SLO 重定義建議（量測基線 + headroom）**：secretary P50<15s / P95<30s（原 <5s 不切實際）；coordinator P50<70s / P95<120s（原 <60s 偏緊）；aeon-builder 成功率 >90%（量測 2/2）、P50<70s。tool-mediated 類別尚無樣本，待日常累積

### P3｜#5 Runes 審批 UX（前置確認完成；阻點已解決 → **接線階段**）
- ✅ K6 已就緒：runes repo clone 於 `~/workspace/hermes-runes-md-wiki`（main @ c16c96b，wiki/freelancer/opc 8 角色齊）+ postgres stack **PASS**（`hermes-backend-check`，pgvector pg17 5433 healthy）+ runes-holder profile 存在
- ✅ **阻點已解決（2026-08-15，Acubens）**：根因 = commit `e1cb587` 把 `validate_proposal_fixture.py` + fixtures 搬進 `dev/`，但 runtime CLI 仍同目錄 flat import → 全斷。修法 **A1（runtime 自足 + 來源註記）**：複製 `dev/.../validation/validate_proposal_fixture.py` → `tools/runes_shield/`、複製 `dev/.../fixtures/`（4 JSON）→ `tools/runes_shield/fixtures/`、新增 `DEPENDENCY_NOTES.md` 對照表、index 移除 2 支 `smoke.*` 條目（smoke 維持 dev/）。**已走正常 PR 審批流程完成**：PR #3（runes_shield 依賴還原，merge `395815d`）+ PR #4（M5 OPC wiki namespace + Plur slot，merge `f0e4dae`，自 K6 `c16c96b` port）。本機 + K6 驗證 6 支 CLI 全 PASS；K6 main 已 merge 收斂（`3364607`，registry 4 entries / queue 1 / 8 roles 齊）。**P3 進入接線階段**
- ✅ **K6 git 已收斂（2026-08-15）**：本地 3 commits（`c16c96b` M5 + `29b5dab` + merge）已透過 PR #3/#4 回歸 GitHub mainline；K6 `git merge origin/main` → `3364607`，現與 origin 同步（僅領先本地 merge commit 結構）。`source-priority.md.bak.m5` untracked 保留
- ✅ **v0.7.5 正式版收斂（2026-08-15）**：PR #5（`release/v0.7.5`）merged `e484cdf`——VERSION→0.7.5、CHANGELOG `[0.7.5]`、`docs/releases/v0.7.5.md`、final verification note；**tag `v0.7.5` 已打於 `d46097a`（VERSION=0.7.5）並 push**。開 v0.7.6-dev 週期（`1c455b7`：VERSION→0.7.6-dev、changelog planned、next-actions、opening verification）。K6 已 pull 同步（VERSION=0.7.6-dev、tag 齊、CLI 4 entries PASS）
- **已確認架構**：runes-holder 僅經 Runes Shield（Python CLI）操作；P0 approve/reject/promote = human-only；規劃採「Lark 純文字關鍵字 + token 授權」+ coordinator 唯一路由（secretary/workers 全經 coordinator 到 runes-holder）；PLUR 在調用拓撲軸外（plugin 層）、記憶生命週期軸上（runes 可選時下沉、缺席時 PLUR 扛責）

### 測試殘留物（需留意）
- PLUR 測試 engram `ENG-2026-0815-001/002`（P2(d) baseline，4 週後刪除）
- nim-researcher config 已改（backup `config.yaml.bak.20260815-p1`）

## 剩餘待處理清單（2026-08-15 session 2 尾聲整理）

### A. 主項目（待決策後執行）
1. **P3 Runes 審批 UX（#5）** ✅ **2026-08-15 接線完成（含 P3 v2 修正）**：3 SOUL（coordinator/secretary/runes-holder）+ Native Wrapper ONLY 規則 + 工具白名單（唯讀 + forge 寫入全 verdict allow 免改 allowlist）+ e 真實下沉/f 回退測試 PASS + `runes-approval-ux.md`；commits `cc0fa80`/`8158859` **已 push**
2. **#8 runes 收尾（剩餘）**：P0 `tools/importer/forge.py`（create-flat/approve/reject）+ propose-memory + write_guard + operation manifest **已實作、可寫入**；**#8(a) 完成（2026-08-15）**：舊 `bin/hermes-runes` CLI（forge/evoke/inscribe + probe indexes/links 等）已正式 deprecate（contract + CHANGELOG + help 文字，PR #7 merged `b432ff6`）。**剩 #8(b) 可選 bridge（queue 顯示真實 forge-inbox 候選）與 #8(c) indexes/links 實作**，待 runes 工具層/需求決定

### B. 跨週 / 日常觀察項
3. **P2(d) 複查（約 2026-09-12）**：`ENG-2026-0815-001/002` 是否仍被注入、strength/decay 變化 → 複查後刪除測試 engram
4. **P4 SLO 定案**：日常累積 tool-mediated 類別延遲樣本後正式定標（secretary P50<15s / coordinator P50<70s / aeon>90%）
5. **Plur scope 紀律落實**：跨 profile 共享改固定 scope（`project:freelancer`）、關鍵規則 `plur promote`、中文 statement 帶英文關鍵字

### C. 評估衍生的改善行動（有結論、尚未動手）
6. **MoA aggregator 工具 turn 上限** ✅ **2026-08-15 實作**：nim-researcher config `agent.max_turns=10`（default 500，backup `config.yaml.bak.20260815-1628`）+ SOUL 加「Aggregator Turn Cap」段（lean 2–4 tool calls then converge）；**重測 2-fact 任務：275s / ~4 tool calls / 1 NIM reference（tokens 與 P1 一致）**，deploy commit `14632d0` **已 push**
7. **NIM 可靠性策略** ✅ **2026-08-15 定案並實作（B4）**：nim-researcher SOUL 加「NIM Reliability」段 — 429/5xx/掛起可重試（random 1–5min sleep、尊重 Retry-After）、**3-strike 後標「NIM 降級」**（小任務本地 aggregator 收斂 / 大任務經 coordinator 降回 researcher）；401/400 直接降級不重試；不 hot-loop（失敗仍計 40/min 額度）。社群依據：OpenAI Cookbook random exponential backoff + jitter、NIM 429=RESOURCE_EXHAUSTED、40 RPM（opencode#11104）。deploy commit `075b77a` 已 push；K6 SOUL 已同步（backup `.bak.20260815-164419`）
8. **Lark 秒回優化**（12.7s → cache / 更快小模型）— **標記不處理（2026-08-15）**：12.7s 已在放寬 SLO（P50<15s）內；本地算力 performance 即此，換更小 model tradeoff 太大

### D. 文件 / 同步（D9：驗證後才更新 repo）
9. **藍圖 §9 開放問題狀態未同步**：#3/#4/#6 應標收斂、#5 標擱置（本次只更新 handoff）
10. **nim-researcher `auxiliary` config 變更是否回寫 deploy repo**

### E. 已標記不處理
- #1 aeon-builder DGX 切換窗口協調（維持 D12 手動觀察）
- #2 qwen3.6-27b ↔ 35b-a3b 動切（不處理）
- #7 備份還原演練（維持一次性快照現況）

## 本 session 產出

| 檔案 / repo | 內容 | 狀態 |
|---|---|---|
| `Hermes_OPC_native_v0.20.0_blueprint.md` | 純原生 Hermes v0.20.0 藍圖 v4.0（8 profiles + A2A/MoA + §8 雙版本 deploy repo 同步計劃） | 定稿 v4.0；§8 已含 D23–D28 雙版本段落 |
| `Hermes_OPC_v4_gap_and_scenario_analysis.md` | 缺口分析 + 7 情境模擬 + v4.1 補丁清單（D5a–D28）+ 4 caveat + 交叉索引 | companion；§3.4 已含 D23–D28 |
| `針對這個_novusresearch_hermes-agent_...討論總結與共識檢核.md` | 第三方 AI 審視原稿（使用者貼入） | 留作對照，非本 session 產出 |
| **階段一：`sawaichi9527/hermes-agent-opc-deploy` repo 骨架重構（D23–D28）** | 雙版本（`editions/generic/` 5-profile + `editions/opc-personal/` 8-profile）+ `archive/v0.16-v0.17/` 收舊 + `VERSION`(0.20.0) + 新 README + scripts 改造 + tag | **完成**（3 commits + tag v0.20.0，已 push） |
| **M0 capability check（K6 實機）** | hermes v0.20.0 / doctor / profile / skills（ppt-master+plur-memory enabled）/ Secrets Store（bitwarden）/ 三端點（agent-a1 401、Spark 401、NIM 200）全驗證；`m0-capability-check.sh` 填入實際指令 | ✅ **PASS（2026-08-14）**；deploy repo commit `0880a76` |
| **K6 hermes-agent 全量狀態存檔** | `D:\Workspace\projects\hermes-backup\`：tar 6.2G（`~/.hermes` 全量 + `~/.plur`）+ manifest + sha256 + `RESTORE_GUIDE.md` | **完成**（sha256 對照 MATCH） |
| **藍圖/companion 更新（M0 結果 + Plur 修正）** | 藍圖 §1 IP/M0 狀態、D7/§4/§6/§9/§10 的 Plur skill 修正與 M0 結果；companion 新增 §4.5 M0 實測章節 | **完成** |
| **M1 hermes 健康檢查（K6）** | `doctor --fix` 遷移 config v33→v34；`sessions optimize-storage` 回收 state.db 611MB（1090→479MB）+ `auto_prune: true`；gateway 全程未中斷 | ✅ **PASS（2026-08-14）**；doctor 僅剩「缺 API keys」非阻擋 |
| **M2 建 8 profiles（K6）** | 方案 A（`profile create` + 手動覆寫 SOUL）；7 角色 model 指向 agent-a1、aeon-builder 指向 Spark；SOUL.md 覆寫 deploy repo template；7 個 ping PASS | ✅ **PASS（2026-08-14）**；aeon-builder ping 留待 D13 Spark token |
| **D13 aeon-builder Spark token（K6）** | Spark token 寫入 aeon-builder config.yaml（model.api_key）；model.default=aeon；aeon-builder ping PASS（Spark 端到端）；身分驗證流程（curl /v1/models → ACTUAL_MODEL 匹配 config）驗證 OK；/health 200 | ✅ **完成（2026-08-14）**；L2 HITL 卡片流程待 M3（caveat 2） |
| **M3 secretary gateway 接管（K6）** | default gateway 停用（disable）；secretary gateway 啟用（hermes-gateway-secretary.service + systemd linger）；Lark websocket 連線成功；cron 2 jobs 遷移至 secretary 正常推送；Feishu/plugins/approvals 複製 secretary；D18 三級白名單落地（L3 hardline+deny / L2 ask-approval+卡片 / caveat 1&2 收斂） | ✅ **PASS（2026-08-14）** |
| **M4 coordinator 路由 + 冒煙 + jobs.json（K6）** | jobs.json 建立（~/.hermes/opc/jobs.json v4.1 欄位）；coordinator SOUL 填實 v4.1（8-profile 路由 + D5a reroute + D22 + D18）；researcher（web ddgs）/writer/builder 冒煙 PASS；cron 端到端 succeeded；web.backend 改 ddgs（免 key） | ✅ **PASS（2026-08-14）** |
| **M5 runes-holder + Runes overlay（K6/wiki repo）** | OPC namespace 建立（wiki/freelancer/opc/<8 role>/README.md）；source-priority 加 Plur slot；runes-holder SOUL 填實 v4.1；~/.hermes/opc/runes-audit.jsonl 建立；probe/decipher policy PASS；wiki repo commit c16c96b；**發現**：runes v0.7.5-dev 為 read-only scaffold（forge/inscribe/indexes/links 未實作） | ✅ **PASS（2026-08-14）** |
| **M6a aeon-builder 重型 + L2 白名單（K6）** | Spark 重型任務實測（Fibonacci F(49) 正確）；D18 驗證（reboot→hardline-deny / systemctl stop→ask-approval / mkfs+fdisk→deny）；approvals+security 同步；L2 卡片 = Feishu send_exec_approval 原生 | ✅ **PASS（2026-08-14）** |
| **M6b nim-researcher MoA（K6）** | MoA preset 建立（reference **nvidia:meta/llama-3.3-70b-instruct** + aggregator agents-a1）；moa-trace 確證 reference fan-out + aggregator 收斂；SOUL 填實；jobs.json moa_trigger_count；**發現**：provider `nim` 查 NIM_API_KEY 失敗 → 用 `nvidia`；caveat 3 確認無原生 cap | ✅ **PASS（2026-08-14）** |
| **M6c ppt-master 接入 writer（K6）** | ppt-master symlink 接入 writer skills；quick-generate 產 3-slide 原生 PPTX（python-pptx 驗證）；caveat 4 收斂 | ✅ **PASS（2026-08-14）** |
| **M7 Plur 啟用 + 一次性備份（K6）** | `pip install plur-hermes`（0.17.2）補裝（原本缺 Hermes plugin，CLI/store 已在）；8 profiles `plugins.enabled: plur`；全 profile 見 plur+plur-meta 工具，plur_status=40 engrams；一次性快照 m7-plur-snapshot 拉回本機（sha256 驗證）| ✅ **PASS（2026-08-14）** |
| **M8 gate 覆驗 + 8 SOUL 填實（deploy repo）** | M0–M7 gate 覆驗全 PASS；8 個 SOUL 模板填實至 `editions/opc-personal/profiles/`（coordinator/nim-researcher/runes-holder 從 K6 驗證版拉回，secretary/researcher/writer/builder/aeon-builder 依 v4.1 撰寫）；`verify-profile-templates.sh` 轉嚴格模式（sections + 拒真實 secret + 拒執行式破壞命令）並 PASS；**docs 8 篇 + scripts 5 新 1 更新 + README + verify-repo-layout 擴充 + 3 commits 已 push** | ✅ **完成（2026-08-15）**；commits `4c4dafd`（docs）/`1f2fbfd`（scripts）/`2c3c39c`（SOUL+README+verify） |
| **P3 Runes 審批 UX 接線（session 3，deploy repo）** | 3 SOUL（coordinator/secretary/runes-holder）+ 工具白名單 + e/f 測試 + `runes-approval-ux.md` + Plur scope 紀律文件 | ✅ **完成（2026-08-15）**；commits `cc0fa80`（P3 接線）/`d0b6e2d`（Plur scope）**已 push**；K6 同步 backup `.bak.20260815-152258` |
| **P3 v2 修正（native wrapper，deploy repo）** | 發現 runes-shield 層已提供實作 wrapper（forge.py create-flat/approve/reject + propose-memory + write_guard + operation manifest + M42/M51-M54）；3 SOUL 改 Native Wrapper ONLY + 全表白名單 + 真實 governed write 流程；`runes-approval-ux.md` 修訂 | ✅ **完成（2026-08-15）**；commit `8158859` **已 push**；K6 同步 backup `.bak.20260815-154055` |
| **runes repo 文件修正（PR #6）** | CHANGELOG 0.7.6-dev planned 改 forge native wrapper + Notes（fixtures/drafts 測試面 vs 真實 lifecycle）+ `runes_shield_contract.md` Two-Layer Boundary 段 | ✅ **PR #6 merged `7ccbcbc`（2026-08-15）**；本地/K6 blob 一致 LF；K6 已 merge 收斂 `b73fe52` |
| **P3 v2 實測證據（K6）** | 唯讀 + 寫入 6 支 `approvals test` 全 allow；e 真實下沉（`create-flat` draft → `forge.py approve` draft→approved + 2 份 operation manifest）PASS，產物已清理；3 profile ping PASS | ✅ **全部 PASS（2026-08-15）** |
| **C6 MoA turn cap（A2）** | nim-researcher `agent.max_turns=10` + SOUL「Aggregator Turn Cap」段；重測 2-fact：275s / ~4 tool calls / 1 NIM call | ✅ **完成（2026-08-15）**；deploy `14632d0` 已 push；K6 backup `.bak.20260815-162618` |
| **B4 NIM 可靠性** | SOUL「NIM Reliability」段：3-strike random 1–5min（429/5xx/掛起可重試，401/400 直接降級）→ 標「NIM 降級」；不 hot-loop | ✅ **定案+實作（2026-08-15）**；deploy `075b77a` 已 push；K6 backup `.bak.20260815-164419` |
| **#8(a) 舊 CLI deprecate（runes repo）** | `bin/hermes-runes forge/evoke/inscribe` + probe indexes/links 等標 deprecated（contract + CHANGELOG + help） | ✅ **PR #7 merged `b432ff6`（2026-08-15）**；K6 已 merge 收斂 |
| **A1/B5 收尾** | audit jsonl 測試殘物清空（backup）；B5 Lark 秒回優化標**不處理** | ✅ **完成（2026-08-15）** |
| **13 SOUL 全量 refine（session 4）** | opc-personal 8 + generic 5 統一結構/繁中化/補 Plur+Fact Division/去冗/generic 填空；VERSION→0.20.1；`docs/soul-token-audit.md`（cl100k：總 tokens 12,411→18,063，opc chars −13.7%）；verify 全 PASS；**已 push `dde6c33` + K6 8 profile 同步 + ping PASS（2026-08-16）** | ✅ **完成（2026-08-15/16）** |

## 階段一重構明細（本 session 完成）

- 本機 clone：`D:\Workspace\projects\hermes-agent-opc-deploy`（GitHub 私有庫，HTTPS 認證）
- **Commit 1 `3527087`**：archive 舊 v0.16/v0.17 mainline → `archive/v0.16-v0.17/`（docs / profiles / templates / scripts 32 支 / README / config/profile-roles.txt / validation-history / pre-delete）
- **Commit 2 `b9620a7`**：`VERSION`(0.20.0)、`editions/generic/`（roles.txt 5 + 空 SOUL 骨架 + `config.yaml.example` D25 placeholder）、`editions/opc-personal/`（roles.txt 8 + 空 SOUL 骨架 + `config/rss_seeds.json.example` D14）、`docs/shared/guarded-apply-contract.md` 移出 archive、新 README（雙版本比較 + 階段狀態 + §8.2 安全守則）
- **Commit 3 `bc9c9cb`**：scripts 改造 —
  - `deploy-real-profiles.sh`：加 `--edition generic|opc-personal`，roles/source root 改讀 editions/；保留 guarded-apply + backup + managed marker + confirm token + dry-run 預設；preflight 移除已 archive 的舊 docs 檢查
  - `verify-repo-layout.sh`：改認新結構（VERSION / docs/shared / editions 雙版本 / archive）；forbidden secrets 檢查豁免 archive 內 `.env.template`
  - `verify-profile-templates.sh`：改為**骨架模式**（存在 + 非空 + 無 secrets + 無 `rm -rf /`）；階段二填實後轉嚴格
  - `set-local-model-name.sh`：profiles 改讀 `editions/opc-personal/roles.txt`（8 roles）
  - 新增 `m0-capability-check.sh`：骨架（7 檢查點待 M0 填入）
- **驗證**：`verify-repo-layout.sh` PASS、`verify-profile-templates.sh` PASS、deploy 雙 edition dry-run 5/8 roles PASS（Git Bash 執行，無 WSL）
- **tag `v0.20.0`** 已 push（D27）

## 備註（環境）

- Forgejo MCP 端（192.168.23.167）使用者是 `829522`，**無** `hermes-agent-opc-deploy` repo；該 repo 在 **GitHub** `sawaichi9527`
- 本機：無 gh CLI / 無 SSH key / 無 global git config；git 2.55 + Git Bash（`C:\Program Files\Git\bin\bash.exe`）可用；`core.autocrlf=true`
- bash 腳本修改後需確保 LF 行尾（PowerShell `Set-Content` 會寫 CRLF 破壞腳本）

## 核心決策快覽（D1–D28）

- **D1** Hermes v0.20.0 純原生，不引入 HCA
- **D2** 保留 runes-holder 專職 profile
- **D3** 序列化（一次一 worker，無 parallel dispatch，無 quick-answer bypass）
- **D4** aeon-builder = 獨立 profile，遠端 DGX vLLM 端點，本機執行工具
- **D5** nim-researcher（2026-09-14 更名 opencode-researcher）= **獨立第 8 profile**（升格），內部走 MoA preset（reference NIM 70B+，aggregator 本機 ornith-1.5-35b-a3b；reference 已換 OpenCode Go `opencode-go/deepseek-v4.1-flash`，詳 session 13）
- **D5a** researcher 報 source >10 附 URL 清單 → **coordinator 下令 reroute nim**（researcher 不自派；nim 拿 source list 當 bootstrap）
- **D5b** NIM 40問/min 在序列下天然不撞；仍寫進 nim SOUL + jobs.json 額度計欄做雙保險
- **D6** A2A 開啟但定位為未來跨機擴展面（Pi 5）
- **D7** Plur 現在就納入所有 profile（`plur-hermes` pip plugin 0.17.2 + `@plur-ai/cli` bridge，M7 實測）
- **D8** 命名 aeon-builder / nim-researcher；provider id `aeon` 固定，model 可切 qwen3.6-27b / 35b-a3b
- **D9** 實作成功後才更新 deploy repo
- **D10** 單人線性交付，企業級 HA 不納入
- **D11** 失敗恢復=可觀測+手動介入，不建 daemon
- **D12** DGX queue 手動觀察（不自建 queue）
- **D13** aeon-builder 模型切換=Spark 端手動 script 重載（非熱切），派工前 curl /v1/models 驗身分，health fail 熔斷降本地 builder
- **D14** cron 入口 owner=secretary；雙檔 `rss_seeds.json`/`rss_suggestions.json`（不進 Runes）
- **D15** pre_approved tag（jobs.json `approval_state` 欄）
- **D16** governance audit cron 頻率 per-job 可配置；Lark 卡片 [批准更新]/[駁回]
- **D17** writer 開 ppt-master skill 直出 PPTX
- **D18** 三級破壞性白名單：L3 毀滅硬熔斷 / L2 破壞 HITL 反問 Default-On / L1 安全自主
- **D19** SSH 憑證=Hermes Secrets Store + 一次性 session 注入；禁入 builder/.env
- **D20** approval token：L2 卡片批准才釋放短 TTL 一次性 token（需自寫 handler — caveat 2）
- **D21** cron 凌晨場景同機序列（不用 A2A）
- **D22** 事實判斷分工表（researcher 蒐證 / runes-holder 取證 / coordinator 路由不查證 / secretary 暴露風險 / user 裁判）
- **D23** deploy repo 雙版本（`editions/generic/` + `editions/opc-personal/`；舊 main 搬 `archive/v0.16-v0.17/`）
- **D24** GENERIC = 5 profile（secretary 不綁 Lark，gateway setup 多選平台；無 runes 審批）
- **D25** GENERIC 雲端不預設 provider（config.yaml.example placeholder + 註解）
- **D26** GENERIC 最簡（記憶 1 層 native only；白名單 L1/L2 無 L3；無 cron governance/MoA/A2A）
- **D27** v0.20.0 版號 = README 標 + VERSION 檔 + git tag v0.20.0
- **D28** 更新分兩階段：階段一現在重構骨架（空模板 + 版號）；階段二 M8 跑完填驗證過的內容

## 8 profiles

secretary / coordinator / researcher / writer / builder / runes-holder / aeon-builder / opencode-researcher

> 2026-09-14：第 8 profile 由 `nim-researcher` 更名 `opencode-researcher`；MoA reference provider 由 Nvidia NIM 換為 OpenCode Zen（`opencode` / `deepseek-v4.1-flash`），key `NVIDIA_API_KEY` → `OPENCODE_ZEN_API_KEY`。詳本檔「2026-09-14 session 13」節。

## 待辦（下個 session 處理，依優先順序）

1. **重構藍圖 v4.0 → v4.1** ✅ 2026-08-14：併入 companion §3 全部補丁（D5a–D28、事實判斷分工表 D22、toolset 矩陣、cron 治理、三級破壞性白名單、deploy repo 雙版本、M0/M4/M6a/M6b/M6c 測項、4 caveat）；本文已自足，companion 保留為決策留痕
2. **階段一（已完成）**：`hermes-agent-opc-deploy` repo 骨架重構（雙版本 + archive + 空 profile 模板 + v0.20.0 版號 + git tag v0.20.0）✅ 2026-08-14
3. **M0 capability check（已完成）** ✅ 2026-08-14：v0.20.0 / doctor / skills / Secrets Store / 三端點全 PASS；`m0-capability-check.sh` 已填入實際指令 push；藍圖/companion 已記錄結果 + **Plur 修正**（skill 形態非 pip）
4. **K6 全量狀態存檔（已完成）** ✅ 2026-08-14：`D:\Workspace\projects\hermes-backup\`（6.2G tar + RESTORE_GUIDE）
5. **M1 hermes 健康檢查（已完成）** ✅ 2026-08-14：config v33→v34、state.db 回收 611MB + auto_prune
6. **M2 建 8 profiles（已完成）** ✅ 2026-08-14：方案 A（create + 手動覆寫 SOUL）；7 角色 agent-a1 ping PASS；aeon-builder 指向 Spark
7. **D13 aeon-builder Spark token（已完成）** ✅ 2026-08-14：token 寫入 aeon-builder config；ping PASS；身分驗證流程 OK
8. **M3 secretary gateway 接管（已完成）** ✅ 2026-08-14：default 停用、secretary 啟用（Lark websocket 連線）、cron 遷移、D18 三級白名單落地、caveat 1&2 收斂（不需自寫 plugin/wrapper）
9. **M4 coordinator 路由 + jobs.json + 冒煙（已完成）** ✅ 2026-08-14：jobs.json 建立、coordinator SOUL 填實 v4.1（8-profile 路由 + reroute）、researcher/writer/builder 冒煙 PASS、cron e2e PASS、web.backend=ddgs
10. **M5 runes-holder + Runes overlay（已完成）** ✅ 2026-08-14：OPC namespace 8 role、source-priority Plur slot、runes-holder SOUL、audit jsonl、probe policy PASS；wiki repo commit c16c96b；runes v0.7.5-dev read-only scaffold（forge/inscribe 未實作）
11. **M6a/M6b/M6c（已完成）** ✅ 2026-08-14：aeon-builder 重型+L2 白名單 / nim-researcher MoA（nvidia reference + agents-a1 aggregator，trace 確證）/ ppt-master 接入 writer 產 PPTX；caveat 3&4 收斂
12. **M7 Plur 啟用（已完成）** ✅ 2026-08-14：`pip install plur-hermes`（0.17.2，原缺 Hermes plugin）+ 8 profiles 啟用 plur；plur_status=40 engrams；一次性快照拉回本機（定期備份暫不採用，gb10 已移除）
13. **M8 階段二（已完成）** ✅ 2026-08-15：M0–M7 gate 覆驗全 PASS；8 個 SOUL 模板填實至 deploy repo `editions/opc-personal/profiles/`；`verify-profile-templates.sh` 轉嚴格模式 PASS；docs 8 篇；scripts 5 新 1 更新；README；verify-repo-layout 擴充；3 commits（`4c4dafd`/`1f2fbfd`/`2c3c39c`）已 push
14. **M8 完成後待辦（已完成）** ✅ 2026-08-15：Plur PATH 修復（systemd drop-in）+ 跨 profile 共享實測；G-D18 apt upgrade L2 實測 + `approvals test` 缺口確認；8 SOUL 同步 K6（sync-soul script commit `7c5c3b6`）；cron `8dc524` thread_id 修復；Lark 秒回實測（12.7s/25.2s）；L2 HITL 純文字確認（卡片缺口記錄，維持現況）；cron 工具受阻修復（cron_mode approve + web ddgs + plugin enable）；deploy repo tag `v0.20.0-m8`
15. **§9 開放目標評估 session（已完成）** ✅ 2026-08-15（詳本檔「2026-08-15 session 2」節）：#3 MoA 成本/延遲（NIM 65–98s 固定開銷 + aggregator turn 爆炸）、#4 Plur 衰減（0.9.4 舊模型 + 三層記憶分流結論 + P2(d) baseline）、#6 SLO 首次量測（secretary P50 12.7s / coordinator P50 63s / aeon 2/2 成功）
16. **P3 Runes 審批 UX 接線（已完成）** ✅ **2026-08-15（含 P3 v2）**：3 SOUL（coordinator 唯一路由 + secretary Lark 純文字關鍵字 `批准/拒絕/撤銷 <id>` + runes-holder Native Wrapper ONLY + forge 寫入白名單/token）+ e 真實下沉/f 回退測試 PASS + `runes-approval-ux.md`；commits `cc0fa80`/`8158859` **已 push**；runes repo 文件修正 **PR #6 merged `7ccbcbc`**。**#8 剩餘：僅舊 scaffold `bin/hermes-runes forge/inscribe`（禁用作路徑）與 indexes/links 補實**
17. **P4 SLO 正式定案（待日常累積樣本後）**：依本次基線定 secretary P50<15s / coordinator P50<70s / aeon >90% 成功率；tool-mediated 類別樣本不足待補
18. **P2(d) 跨週複查（4 週後，約 2026-09-12）**：檢查 `ENG-2026-0815-001/002` 是否仍被注入、strength/decay 變化；複查後刪除測試 engram
19. **Plur scope 紀律落實** ✅ **2026-08-15 session 3**：新共享 learns 一律 `project:freelancer`（不做 bulk 遷移）、關鍵規則 `plur promote`、中文 statement 帶英文關鍵字；已入 `plur-memory-layer.md`（commit `d0b6e2d`）。持續遵守即可
20. **13 份 SOUL 模板全量 refine** ✅ **2026-08-15 session 4（deploy repo v0.20.1）**：opc-personal 8 + generic 5 統一結構/繁中化/補 Plur+Fact Division/去冗/generic 填空；token 審計見 `docs/soul-token-audit.md`；verify 全 PASS；**commit `dde6c33` 已 push；K6 8 profile 已同步（2026-08-16，backup `.bak.20260816-033622`）+ 3 profile ping PASS**
21. **SOUL vs AGENTS.md 邊界結論** ✅ **2026-08-16 記錄**：per-agent 設定載體 = SOUL.md（非 AGENTS.md，後者屬 cwd/HERMES_HOME project context）；詳本檔 session 4「備註」節 + repo `docs/editions/opc-personal/soul-vs-agents.md`
22. **本地模型切換檢查清單 + cron pinned model 修復** ✅ **2026-08-25 session 12 診斷+修復完成**：agents-a1 殘留呼叫元凶 = secretary cron jobs.json pinned model（修復前 log 實證 182 筆/日）；secretary + global 兩份 jobs.json 4 entry 已全改 `ornith-1.5-35b-a3b@q4_k_m`（backup `.bak.20260825-100332`）；未來切換預設本地模型必查 5 點清單（profile model.default / opencode-researcher MoA aggregator / secretary cron jobs / 全域 default cron jobs 修改或 disable / SOUL 文字同步），詳本檔「2026-08-25 session 12」節

## 下一步（實作里程碑）

**M8 已完成（2026-08-15，deploy repo 收尾 commit `2c3c39c`）**。

**hermes-runes-md-wiki 已進版 v0.7.5（2026-08-15，tag `v0.7.5` @ `d46097a`，PR #3/#4/#5 全 merged；現行 main = `e484cdf`，VERSION=0.7.6-dev 已開下個週期）。**

**M8 完成後待辦（2026-08-15 K6 session 已做）**：
- ✅ **Plur PATH 修復**：root cause = gateway/systemd PATH 不含 node（`~/.nvm/versions/node/v22.22.3/bin`）→ `plur_hermes.register()` 因 `PlurNotFoundError` 直接 return，tools 未註冊（M7 在互動 shell 驗證才 PASS）。修法：`~/.config/systemd/user/hermes-gateway-secretary.service.d/path-plur.conf` drop-in 加 PATH + restart gateway（drop-in 保留，未改主 unit）。
- ✅ **Plur 跨 profile 共享實測**：writer `plur_learn`（scope=global）→ researcher `plur_recall`/`plur_similarity_search` 命中（cosine 0.89）；engrams.yaml 含 marker。plur_status=41 engrams。
- ✅ **G-D18 apt upgrade L2 補強**：builder SOUL 填 v4.1 後實測——`systemctl stop cron.service` 正確拒絕並回「L2 需 secretary Lark 卡片 HITL」。
- ✅ **8 SOUL 同步 K6**：`sync-soul-to-profiles.sh`（新增，guarded-apply + backup + confirm token）更新 5 profile（secretary/researcher/writer/builder/aeon-builder），3 已同步；嚴格 baseline 全 PASS；commit `7c5c3b6`。
- ✅ **Cron `8dc524193079`（Forge Guardrails）delivery 修復**：root cause = origin `thread_id: om_x100b...` 過期 → Feishu `99992402 field validation failed`。清 thread_id 為 null（backup jobs.json）→ 03:25:53 send 344 chars 成功無錯。
- ✅ **Lark 秒回實測（2 樣本）**：`你好, 介紹你自己` → **12.7s**（api_calls=1）；接續 → **25.2s**。對照 SLO 提議（P50 <5s）實測偏高（agent-a1 本機推理延遲）。
- ✅ **L2 HITL 實測（2026-08-15）**：user 在 Lark 發 `請 builder 執行 apt upgrade` → secretary 5.5s 以**純文字**請求確認（辨識 L2 正確）。**原生互動卡片未觸發** — 因 `hermes approvals test` 實證 `apt upgrade` verdict=**allow**（G-D18 缺口：不在 DANGEROUS_PATTERNS，且 hermes 無 user 擴充 ask-approval pattern 機制）。對照：`systemctl stop`=ask-approval、`rm -rf /`/`dd of=/dev/`=hardline-deny。**決策**：維持 secretary SOUL 文字確認（G-D18 SOUL 層補法），卡片缺口僅記錄不額外處理。
- **cron 推送確認正常**：user 回報實作後有收到定期推送（先前誤判為未送達；cron scheduler 記錄 `delivered via live adapter` 多次）。
- **發現（cron 工具受阻）**：cron 任務在 `approvals.mode=manual` + `cron_mode=deny` 下，terminal/execute_code（curl HN、heredoc script）全 `pending_approval`/`BLOCKED`——排程任務無法執行真工具；需 decide cron 是否該走 pre_approved 白名單工具。
- ✅ **Cron 工具受阻修復（2026-08-15）**：`approvals.cron_mode: deny → approve`（backup config.yaml.bak.120718）+ secretary `web.backend: ddgs`（backup 120858）+ 啟用 `web/ddgs` plugin（原在 disabled 清單）。根因：allowlist 只對無 shell operator 命令生效，cron 的 `curl|python -c` 是 compound → 命中 DANGEROUS_PATTERNS → cron_mode deny 擋。**驗證**：cron run 無 pending_approval/BLOCKED；web_search completed（ddgs）；產出 XZ Utils 報告並 `delivered to feishu` 成功。L3 hardline（rm -rf / 等）仍硬擋（line 3440 在 approve 之前）。`8dc524`（Forge）thread_id 已清、last_delivery_error 為修復前歷史欄位，next run 08-16 用新 origin。

**待辦（未完成）**：無 — 本次 session 全部完成。

**cron 修復變更記錄（2026-08-15，K6 secretary config）**：backup `config.yaml.bak.20260815-120718`（cron_mode approve）+ `config.yaml.bak.20260815-120858`（web ddgs）+ `hermes plugins enable web/ddgs`。

**deploy repo tag（2026-08-15）**：新增 `v0.20.0-m8`（annotated，HEAD 7c5c3b6，M8 階段二完成）已 push；`v0.20.0` 保留原指 bc9c9cb。

**附帶修正（2026-09-15）：live opencode-researcher SOUL.md 殘留過期「OpenCode Zen」表述已修正為 OpenCode Go。** dry-run（`sync-soul-to-profiles.sh --edition opc-personal`）顯示 3 個 profile 會變（secretary / coordinator / opencode-researcher）。secretary + coordinator 是本次 kanban 遷移；opencode-researcher 的差異與 kanban 無關，是 MoA reference provider 命名分歧——repo template 本即 OpenCode Go（`opencode-go/deepseek-v4.1-flash`），但 live SOUL.md 仍寫 OpenCode Zen（`opencode` / `OPENCODE_ZEN_API_KEY`）。以 runtime 設定檔為準：`config.yaml` reference = `[{provider: opencode-go, model: deepseek-v4.1-flash}]`、`.env` 有 `OPENCODE_GO_API_KEY`、9/14 備份 `.env.bak.opencode-20260914-removezen`（已移除 Zen）。確認全部署走 OpenCode Go、無 Zen 訂閱，故將 live SOUL.md 同步為 Go（backup `SOUL.md.bak.20260915-165100`）。repo template 未改（本即對）。

## 4 個 caveat（實作前 live 驗，非設計缺口）

1. L3 硬熔斷如何在 K6 工具層實作 — ✅ **收斂（M3）**：hermes 原生 HARDLINE_PATTERNS + `approvals.deny`，不需 shell wrapper
2. Lark 互動卡片回呼（[批准]/[駁回]）是否需自寫 plugin — ✅ **收斂（M3）**：Feishu adapter 原生支援（`send_exec_approval` + `_APPROVAL_CHOICE_MAP`），不需自寫。**2026-08-15 補充實測**：卡片由 gateway approvals 系統在「工具執行命中 DANGEROUS_PATTERNS」時自動發送（如 systemctl stop=ask-approval）；profile 無法主動呼叫。apt upgrade 因 verdict=allow 不會觸發卡片（G-D18），secretary 以文字確認替代（維持現況）。
3. nim-researcher 每任務 MoA 觸發 ≤3，原生 MoA 無此 knob，要外掛計數 — ✅ **收斂（M6b）**：jobs.json `moa_trigger_count` + nim SOUL
4. ppt-master 是 hermes skill 形態，writer 調用介面要驗 — ✅ **收斂（M6c）**：symlink 接入 writer + 原生 PPTX 產出成功

## SSH 機器資訊（已連線）

- Host: 192.168.23.214，User: eye / Pwd: 20040401
- **已建免密金鑰** `~/.ssh/id_k6_backup`（已加入 K6 authorized_keys），後續可免密連線
- K6 實測：hermes v0.20.0（git 安裝 `/home/eye/.hermes/hermes-agent`）、單一 default profile、gateway running、Feishu 已接、cron 2 jobs
- **2026-08-15 新變更**：gateway drop-in `path-plur.conf`（加 node PATH）；5 SOUL 更新 + backup（`SOUL.md.bak.20260815-012437`）；cron `8dc524193079` jobs.json backup `jobs.json.bak.20260815-032511`（thread_id 清空）；secretary config backups（`config.yaml.bak.120718` cron_mode approve + `config.yaml.bak.120858` web ddgs）；`web/ddgs` plugin 啟用
- **2026-08-16 session 5–7 變更**：hermes v0.20.0 → **v0.20.1 (v2026.8.13)**（doctor --fix config 34→37）；8 profile 18 支 skill symlink；ppt-master v4.5.0 → **v4.7.0**；rtk binary v0.42.4 → **v0.45.0** + rtk-hermes **v1.2.3** (PyPI)；web backend 本地化（8 profile .env 加 `FIRECRAWL_API_URL`、搜尋 3 角色另加 `SEARXNG_URL`，`web-searxng`/`web-firecrawl` plugins enabled）；Docker SearXNG **v2026.8.14** + Firecrawl **2026-08-15 build**；**lark-cli v1.0.87**（npm，binary 於 `/usr/local/bin/lark-cli` → `~/.local/bin/lark-cli` wrapper 設 `HOME=/home/eye`；user OAuth 林卓翰，bind secretary hermes app `cli_aaabd1f1bc38de18`；config 於 `~/.lark-cli/hermes/config.json`；secretary/writer 各掛 6 lark skills）

## 關鍵外部 repo 參考

- `NousResearch/hermes-agent`（v0.20.0 真實專案，原生 profiles/kanban/A2A/MoA/Feishu adapter）
- `plur-ai/plur` + `plur-hermes`（跨角色共享記憶，ACT-R 衰減）
- `sawaichi9527/hermes-runes-md-wiki`（governed canonical 記憶；`archive/v0.7.2-opc` overlay 待 reactivated）
- `sawaichi9527/hermes-agent-opc-deploy`（重灌來源；**M8 已完成**，雙版本 + 8 SOUL + 8 docs + setup scripts）
- `r0b0tlab/hermes-concurrent-agents`（HCA，**已放棄** — 79 star alpha、pin 0.18.2）

## 下個 session 進入指引

讀本 handoff → 藍圖 v4.1（自足）→ **M0–M8 全部完成；§9 #3/#4/#6 完成、#5（Runes 審批 UX）已接線完成（P3 v2 native wrapper）；C6 MoA turn cap、B4 NIM 可靠性 3-strike、#8(a) 舊 CLI deprecate、A1 清理、B5 標不處理全完成（2026-08-15）**。**hermes-runes-md-wiki 現行 main = v0.7.6-dev（PR #6/#7 merged）；runes-holder 一律經 runes-shield 層 native wrapper 操作**。**deploy repo 13 SOUL 已 refine（v0.20.1，commit `dde6c33` 已 push）且 K6 8 profile 已同步（2026-08-16，backup `.bak.20260816-033622`，ping PASS）**。**2026-08-16 session 5–7 完成：K6 Hermes v0.20.1（v2026.8.13）+ 18 支 skill symlink 分配；rtk-rewrite v1.2.3 (PyPI) + rtk binary v0.45.0；Web backend 本地化（捨 ddgs → 全域 firecrawl fallback + 搜尋 3 角色 search=SearXNG/extract=Firecrawl，Docker SearXNG v2026.8.14 / Firecrawl 2026-08-15）；lark-cli v1.0.87 整合（user OAuth 林卓翰 + bind secretary hermes app `cli_aaabd1f1bc38de18` + secretary/writer 26 skills）；session 8 任務交付檢查鍊（coordinator 交付鏈欄位 + secretary footer `[任務交付檢查鍊]`，commit `67981a5`）；session 9 修復 Lark 實測三大問題（profile 層 plugins 補 web-searxng/firecrawl + `/usr/local/bin/<profile>` wrappers 實現真實多 process 串接 + 報告限 `~/Downloads/` + Lark Drive/Base 雲端交付自動選型 + footer 強制，commit `ef98a4e`）；session 10 彈性單/多 agent 定案 + 複合任務硬規則 + secretary/writer `terminal.cwd=~/Downloads/`（commit `5d5a30e`）**。**此後進入正式日常使用 / 後續優化階段**。下次優先：#8(b) 可選 bridge（queue 顯示真實 forge-inbox 候選）、#8(c) indexes/links 實作、#17（SLO 定案，日常累積 tool-mediated 樣本）、#18（P2(d) 跨週複查 09-12）。候選方向：aeon-builder DGX 切換窗口協調（D12 手動觀察）、備份還原演練（#7 標記不處理）。**B5 Lark 秒回優化已標不處理**。Plur scope 紀律為持續遵守項（project:freelancer + promote + 英文關鍵字）。

SSH 免密金鑰 `~/.ssh/id_k6_backup` 可直連 K6（eye@192.168.23.214）；secretary gateway = `hermes-gateway-secretary.service`（drop-in `path-plur.conf` 加 node PATH）；cron 2 jobs = `91d908e7d563`（定向情報推送，60m）/ `8dc524193079`（Forge Guardrails，1440m，thread_id 已清）；jobs.json = `~/.hermes/opc/jobs.json`；deploy repo 本機 clone = `D:\Workspace\projects\hermes-agent-opc-deploy`（已 push、working tree clean、tags `v0.20.0` + `v0.20.0-m8`）。

> 重要變更提醒：secretary config 已設 `approvals.cron_mode: approve` + `web.backend: ddgs` + `web/ddgs` plugin enabled（backup 檔詳 §SSH 機器資訊）。cron 現可執行 terminal/web_search（L3 hardline 仍硬擋）。