# Hermes OPC v4.0 — 缺口分析、情境模擬與 v4.1 補丁清單

**關聯藍圖：** `Hermes_OPC_native_v0.20.0_blueprint.md`（v4.1，本檔為其 companion；v4.1 起補丁已併入藍圖，本檔作為決策留痕）
**目的：** 留痕缺口分析與 7 情境模擬過程、收納已定稿的 v4.1 補丁決策與 M0 實測結果
**最後更新：** 2026-08-14

> **變更註記（2026-09-14）：** 本檔為定格歷史決策文件，保留當時決策原貌，**現況以實際部署為準**：第 8 profile `nim-researcher` 已更名 `opencode-researcher`；其 MoA reference provider 由 Nvidia NIM 換為 OpenCode Go（`opencode-go:deepseek-v4.1-flash`）；本機預設模型由 `agent-a1`/`agents-a1` 改為 **`ornith-1.5-35b-a3b`**（同一 `192.168.23.217:1234` 端點）。§1 情境模擬與 §4.5 M0 實測結果表中之 `agent-a1` 為當日實測當時之名，保留原樣。詳 `handoff.md`「2026-09-14 session 13」節與 deploy repo（v0.20.2）。

---

## 1. 7 情境流程模擬

格式：`flow → 涉及 profile/工具/記憶 → 降級 → 暴露缺口編號（見 §2）`

### 2a. 今天天氣如何
```
user → secretary(Lark) → brief
secretary classify: 單一交付物 + 日常事實 → coordinator
coordinator route → researcher
researcher: web_search "天氣 [location]" / fetch_webpage(氣象源)
  └ location 從哪來？USER.md(原生) 或 Plur 應有 "user location" 學得項
researcher → coordinator merge → secretary(繁中修飾) → user
jobs.json: {task_id, profile:researcher, model:ornith-1.5-35b-a3b, evidence_urls:[...], ...}
```
- 降級：researcher OOM/無位置 → secretary 誠實標「未查證」+ 反問 user 位置
- **暴露缺口**：G-A1（researcher 是否開 web_search）、位置偏好來源是否在 USER.md/Plur、氣象專用工具或通用 web_search

### 2b. cron 情報推送（每小時 RSS 科技新聞）
```
[非反式入口] cron tick（owner: secretary profile）
secretary: 從 cron payload 模板組 brief "調查 RSS seed 關注科技新聞"
  └ secretary 沙盒目錄讀 rss_seeds.json（正式清單，pre_approved 免審批）
secretary → coordinator（同機序列，不用 A2A）
coordinator → researcher（fetch RSS, 按 rss_seeds.json 過濾）
coordinator → writer（summarize 成卡片清單）
coordinator → secretary（推 Lark card）
[全程序列；unattended 無使用者在場]

每週治理 cron（頻率 per-job 可配置，非固定週五）：
coordinator 比對 rss_seeds.json vs rss_suggestions.json → Lark 互動卡片
  [批准更新] → 喚 builder 用 Python 腳本寫入 rss_seeds.json
  [駁回] → 丟棄 suggestions
```
- 降級：RSS 端點 down → researcher 報 → secretary 推「本次未取得 + 原因」
- **暴露缺口**：G-D1（cron 入口/owner）、G-D2（定向清單存放 + 雙檔 + 自動跑時 pre_approved 變體）、每小時 ornith-1.5-35b-a3b token 成本 vs 每日 cap 衝突、K6 忙時排程佇列

### 2c. 查詢最新的 qwen3.8-27b 與 Meta Muse Glimmer 差異
```
user → secretary → brief
secretary/coordinator classify: 兩個近期模型比較
  ├ 交付物=1（差異說明）
  └ 來源數 ≈ 數份（未達 >10 閾值） → researcher
researcher: web_search 兩模型 + fetch release notes；Plur 查過往模型筆記
  └ 附 evidence_urls 清單；若發現來源爆量 → 回報 coordinator（不自派 nim）
  └ coordinator 看 evidence_urls 長度 >10 → reroute nim-researcher（D5a）
    nim 拿 researcher 已蒐的 source list 當 bootstrap（不重抓）
researcher/nim → coordinator merge → secretary → user（Markdown diff）
```
- 降級：researcher 拿不到官方資訊 → 跳查證標「未查證」；或 coordinator reroute nim；nim NIM 端點 down → fallback researcher
- **暴露缺口**：G-F1（researcher vs nim 觸發閾值量化（b)+(c) 混合 + coordinator reroute）、G-A1（researcher web_search 權限）、G-B1（nim 每任務 MoA 觸發 ≤3 原生無 knob）、中途 reroute 路徑（序列下撤回重派 nim 的流程）

### 2d. 調研同主題 + 給簡報
```
user → secretary → brief（兩個交付物：研究 + 簡報）
coordinator 序列拆：
  (1) coordinator → researcher（或 nim-researcher，視來源數）→ 收差異（附 evidence_urls）
  (2) coordinator → writer（把研究做成 PPTX）
  └ writer 開啟 ppt-master skill 直出 PPTX（D17）
coordinator → secretary → user
[runes-holder：若 user 要納入 canonical，governed write `opc/<role>/...` 經 secretary-mediated 同意 + audit jsonl]
secretary 交付檔案給 user via Lark（驗 Feishu 原生檔案上傳；不行則回 K6 路徑）
```
- 降級：ppt-master skill 未安裝 → 降為 Markdown 藍圖；writer 失敗 → secretary 標
- **暴露缺口**：G-C2（slide pipeline = ppt-master skill 路徑）、G-C1（artifact 交付回 Lark）、多交付物序列拆解規則、研究段量大時 reroute nim 觸發

### 2e. 連線到某 ubuntu pc 系統更新
```
user → secretary → brief【含 host/user/key — SECRETS】
secretary: secret 偵測 → 不寫 jobs.json/runes/git
  → 憑證存 Hermes Secrets Store + 一次性 session 注入（D19）；禁入 builder/.env
secretary: L2 破壞級判定（apt upgrade 屬 L2）→ 強制 HITL 反問 Default-On（D18）
  → Lark 推精美確認卡片：
    🚨 一人公司 運作審批要求
    執行角色：builder
    目標機器：OpenCode_PC (Ubuntu 26.04)
    欲執行破壞性命令：sudo apt-get upgrade -y
    AI 執行理由：為了更新 CUDA 依賴...
    [ 批准執行 ]  [ 拒絕並中止 ]  [ 修改命令 ]
[user 點批准] → 一次性 token 釋放（D20）
secretary → coordinator → builder
builder: SSH terminal backend / terminal+ssh client
builder: 執行 apt upgrade（L2 已批准）；自動執行 apt update（L1 不需再問）
builder → coordinator（log + summary）→ secretary → user
jobs.json: 記 host（非 secret）+ status + approval_state；禁記 key/password
```
- 降級：SSH fail/auth fail → builder 報 → secretary 反問 user 重提供
- L3 毀滅命令（dd of=/dev/, rm -rf /, mkfs, fdisk, shred）：K6 工具層硬熔斷，AI 連申請資格都沒，直接回報不支援
- **暴露缺口**：G-E1（per-task SSH + Hermes Secrets Store）、G-E2（builder 開 SSH 權限）、G-D18（三級破壞性白名單 + HITL）、G-D20（approval token + Lark 卡片回呼）、G-B4（jobs.json secret redaction 強制）

### 2f. 利用 HTML 產生俄羅斯方塊小遊戲交付
```
user → secretary → brief（單一交付物：HTML 檔）
coordinator → builder
builder: write_file ~/opc-out/tetris.html（HTML+JS），回路徑
builder → coordinator merge → secretary
secretary: 交付檔案給 user via Lark
  └ Feishu 原生工具支援檔案上傳？待驗；不支援 → 回 K6 路徑請 user 自取
```
- 降級：builder 寫失敗 → secretary 標
- **暴露缺口**：G-C1（artifact 交付回 Lark）、G-A1（builder 開 write_file/terminal）、artifact 暫存目錄約定（`~/opc-out/`？）

### 2g. 讀取 github 上的 repo 專案，提供分析
```
user → secretary → brief（含 repo URL；若 private 需 token）
coordinator classify: hybrid（code + 事實）
  規則候選：要 clone/static 分析 → builder 為主；要對外查作者/release → researcher 為主
[假設：純 repo code 分析]
coordinator → builder（git clone --depth 1 / gh API；rg、語言統計、deps、README 摘要）
  └ 大 repo context 壓力 → builder 的 context/compression 政策
builder → coordinator merge
  ├ user 要 prose → coordinator → writer → secretary → user
  └ user 要 raw → secretary → user
```
- 降級：private/inaccessible → builder 報 → secretary 反問 user token
- 記憶：Plur 學「已分析過 repo X」；要不要進 Runes 由 user 透過 runes-holder 走 governed write
- **暴露缺口**：G-F2（researcher vs builder 在 hybrid 任務的邊界）、G-A1（builder 開 git/gh + read-only token 處理）、大 repo context 策略、GitHub token 安全

---

## 2. 缺口分類

### 2.1 需要拍板的決策缺口（已拍板，見 §3）

| 編號 | 缺口 | 拍板結果 |
|---|---|---|
| G-F1 | researcher vs nim 觸發閾值 | (b)+(c) 混合：secretary 前置 classifier prompt + 量化閾值來源數 >10；researcher 報事實、coordinator 下令 reroute nim |
| G-D1 | cron 入口 owner | secretary |
| G-D2 | 興趣清單存放 + 自動跑時審批 | secretary 沙盒下雙檔 `rss_seeds.json`/`rss_suggestions.json`；pre_approved tag；治理 cron per-job 可配置頻率 |
| G-C2 | slide 生成路徑 | ppt-master 已裝（hermes skill 形態），writer 調用直出 PPTX |
| G-E1 | SSH 憑證 per-task 注入 | Hermes Secrets Store + 一次性 session 注入；禁入 builder/.env |
| G-E2 | builder 開 SSH 權限 | 接受 |
| G-D18 | 破壞性操作安全策略 | 三級白名單：L3 毀滅硬熔斷 / L2 破壞 HITL 反問 Default-On / L1 安全自主 |

### 2.2 我能自己補的實作缺口（待重構時併入藍圖）

| 編號 | 缺口 | 預設補法 |
|---|---|---|
| G-A1 | 無 per-profile toolset 矩陣 | 依角色職責推斷開 web_search/fetch_webpage/execute_code/read_file/write_file/terminal/ssh/a2a/moa/ppt-master；coordinator **不開 web_search**（明文禁深度查證） |
| G-B1 | nim 每任務 MoA 觸發 ≤3 原生無 knob | jobs.json 加 `moa_trigger_count` 欄位 + per-task 計數 + cron 重置；超量擋 |
| G-B2 | 每日 token cap 原生無 knob | jobs.json 加 `daily_token_used` + cron 重置；secretary 派工前檢查 |
| G-B3 | jobs.json 並發寫入 | schema 定型 + flock 寫鎖 |
| G-B4 | jobs.json secret redaction | 強制規則：禁記 base_url token / SSH key / password；只記 host 名 + status |
| G-C1 | artifact 交付回 Lark | 先驗 Feishu 原生檔案上傳；不支援則回 K6 路徑；artifact 暫存 `~/opc-out/` |
| G-F2 | hybrid researcher/builder 邊界 | 要 clone/static 分析 → builder 為主；要對外查作者/release → researcher 為主；兩者要 → 序列跑 builder 再 writer |

### 2.3 仍 open 的 caveat（實作前 live 驗）

1. **L3 硬熔斷如何在 K6 工具層實作**（hermes 工具白名單？shell wrapper？）—— A1 toolset 矩陣要含這
2. **Lark 互動卡片回呼機制**（[批准]/[駁回]）是否需自寫 plugin —— D20 handler 未定
3. **nim-researcher「每任務 MoA 觸發 ≤3」**原生 MoA 無此 knob，要外掛計數
4. **ppt-master 是 hermes skill 形態**——writer 調用介面要驗

---

## 3. 已定稿的 v4.1 補丁決策清單

### 3.1 新增決策（D5a–D28）

| # | 決策 | 內容 |
|---|---|---|
| D5a | researcher 報 source>10 附 URL 清單 → **coordinator 下令 reroute nim** | researcher 不自派 nim（D3 無 kanban dispatcher）；nim 拿 researcher 已蒐 source list 當 bootstrap 不重抓；coordinator 看 `evidence_urls` 長度做判定，**不重新查證**（coordinator 沒開 web_search） |
| D5b | NIM 40問/min 免費額度在序列模型下天然不撞 | 序列下 nim-researcher 一次只跑一任務、每任務 MoA 觸發 ≤3 → 每分鐘 ≤3 ref call，遠低於 40；仍寫進 nim SOUL + jobs.json 額度計欄做雙保險 |
| D14 | cron 入口 owner=secretary | secretary 沙盒目錄下雙檔 `rss_seeds.json`（正式，唯讀排程用）/ `rss_suggestions.json`（影子建議）；**不進 Runes**（刻意降治理重量換機讀性） |
| D15 | pre_approved tag | jobs.json 加 `approval_state` 欄位；排程任務帶 `pre_approved` 走免審批通路 |
| D16 | governance audit cron | **頻率 per-job 可配置**（非固定週五）；coordinator 比對 seeds/suggestions → Lark 互動卡片 [批准更新]/[駁回] → 點批准才喚 builder 寫入 rss_seeds.json |
| D17 | writer 開 ppt-master skill | ppt-master 是 hermes skill 形態；writer 透過 skill 呼叫直出 PPTX |
| D18 | 三級破壞性白名單 | L3 毀滅（dd of=/dev/, rm -rf /, mkfs, fdisk, shred）：K6 工具層**硬熔斷**，AI 連申請資格都沒；L2 破壞（apt upgrade/dist-upgrade、rm 非暫存、systemctl stop 核心、reboot、改 /etc/）：**強制 HITL 反問 Default-On**；L1 安全（apt update、git clone、cat、grep、systemctl status）：自主執行 |
| D19 | SSH 憑證 = Hermes Secrets Store + 一次性 session 注入 | **禁入 builder/.env**；jobs.json 禁記任何 secret（B4 強化） |
| D20 | approval token | L2 卡片批准才釋放一次性短 TTL token；token 單次用、用後即毀；需在 secretary 加自訂 approval handler + Lark 卡片回呼（**自寫小工具/插件 — caveat 2**） |
| D21 | cron 凌晨場景採同機序列 | option (i)：3am 直接跑 secretary→coordinator→researcher→writer→secretary 序列；**不用 A2A**（同機）；跨機才用 A2A（D6） |
| D22 | 事實判斷分工表 | 見 §3.2 |

### 3.2 事實判斷分工表（D22）

| 層級 | 角色 | 對「事實」做什麼 | 不做什麼 |
|---|---|---|---|
| 證據蒐集與比對 | **researcher** | 蒐集多源、比對、標 source status / uncertainty；附 `evidence_urls` 清單 | 不下「最終真偽裁決」 |
| 治理證據提供 | **runes-holder** | 取 Runes wiki 的 governed canonical 當證據材料 | 不當 truth authority（runes ROADMAP 明定「不成為第二 agent」） |
| 路由與合併 | **coordinator** | 讀 researcher 報告的證據清單做決策（如 evidence_urls 長度 >10 → reroute nim）— 信任 researcher 附加的 URL 視為軟驗證 | **明文禁止做深度事實查證**（coordinator 不開 web_search）；不重新查證 URL |
| 呈現與風險暴露 | **secretary** | 把「已確認/未確認/衝突/風險」標給 user 看 | 不自己查證 |
| 最終真偽裁判 | **使用者** | Hermes 只給證據與可信度，**最終判斷在 user** | — |

原則：沒有「查證者的查證者」無限迴圈——保底是 secretary 在 Lark 暴露「未查證/來源數不足以升 nim」欄位，user 看到可介入。

### 3.3 v4.1 對藍圖章節的修補指引（重構時用）

| 藍圖章節 | 補丁動作 |
|---|---|
| §0 決策表 | 加 D5a–D28 |
| §2 角色矩陣 | 圖加「reroute 箭頭 researcher→coordinator→nim（附 source list）」；nim 行補證據清單 bootstrap 與額度計；writer 行加 ppt-master skill |
| §3 控制面 | 加「事實判斷分工表」段落；加「非反式 cron 入口與反式 user 入口並存」段落；加「三級破壞性白名單」段落；路由規則加 reroute nim 路徑與 L2/L1/L3 門控 |
| §4 記憶 | Plur 備份＝**一次性至本機**（非 gb10 每日；使用者確認）；補 jobs.json 加 `moa_trigger_count`/`daily_token_used`/`approval_state` 欄位 |
| §5 A2A | 明寫「cron 同機序列不用 A2A」（D21） |
| §6 初始化 | 加 cron job 註冊範例、雙檔路徑 `~/.hermes/opc/secretary/rss_seeds.json`、governance audit cron 配置、Secrets Store 設定、L3 熔斷 wrapper（caveat 1）、ppt-master skill 安裝驗證 |
| §8 deploy repo | 加 D23–D28：雙版本（`editions/generic/` 5-profile + `editions/opc-personal/` 8-profile）、archive 舊 main、`VERSION`+`git tag v0.20.0`、generic provider placeholder、階段一重構骨架 / 階段二 M8 填內容 |
| §9 開放問題 | 移除已收斂項；補 4 個 caveat（L3 熔斷實作、Lark 卡片回呼 plugin、nim 觸發計數外掛、ppt-master 調用介面） |
| §10 里程碑 | M0 加 `hermes -p writer skills list \| grep ppt-master`、Secrets Store 可達、L3 熔斷測項；M4 加 cron e2e；M6a 加 L2 HITL 卡片流程；M6b 加 NIM 額度計數驗證 |

### 3.4 deploy repo 雙版本與更新時機（D23–D28）

| # | 決策 | 內容 |
|---|---|---|
| D23 | deploy repo 雙版本 | `editions/generic/` + `editions/opc-personal/`；舊 main 搬 `archive/v0.16-v0.17/`；`scripts/`/`docs/shared/` 共用 + per-edition |
| D24 | GENERIC = 5 profile | secretary + coordinator + researcher + builder + writer；secretary **不綁 Lark**，`gateway setup` 多選平台（Telegram/Discord/Slack/WhatsApp/Signal/Feishu/Email）；職責縮為入口+語氣+降級暴露（**無 runes 審批**，因 generic 無 runes） |
| D25 | GENERIC 雲端不預設 provider | `config.yaml.example` 留 placeholder + 註解指引使用者選 OpenRouter/Nous Portal/NIM/本地等；不寫死 |
| D26 | GENERIC 最簡作用域 | 記憶 1 層（native only）；破壞白名單 L1/L2（**不包含 L3 硬熔斷**，generic 無 K6 工具層）；無 cron governance、無 MoA、無 A2A |
| D27 | v0.20.0 版號 | README 標「適用 hermes-agent v0.20.0」+ `VERSION` 檔 + `git tag v0.20.0`（三者都要） |
| D28 | 更新分兩階段 | **階段一**（現在）：repo 重構骨架（雙版本 + archive + 空 profile 模板 + placeholder config）+ 版號 + README；**階段二**（M8 跑完）：填入 v4.1 補丁已驗證的 v0.20.0 內容 |

**雙版本分工**

| | GENERIC（給一般人參考） | OPC-PERSONAL（你的 8-profile） |
|---|---|---|
| 角色 | secretary + coordinator + researcher + builder + writer = 5 | 上述 + runes-holder + aeon-builder + nim-researcher = 8 |
| 算力預設 | 雲端（provider placeholder，使用者自選） | Strix Halo 本機 `ornith-1.5-35b-a3b`（+DGX/NIM 遠端顧問） |
| secretary 綁定 | 不綁 Lark；`gateway setup` 多選平台 | Lark/Feishu |
| 記憶 | 1 層（native） | 3 層（native + Plur + Runes） |
| cron 治理 | 無 | 雙檔 + pre_approved + governance audit cron |
| 破壞性白名單 | L1/L2 簡化（無 L3 硬熔斷） | 三級完整（L3 硬熔斷需 K6 工具層 wrapper） |
| MoA / A2A | 無 | nim-researcher 內部 MoA + A2A 留給未來 Pi 5 |
| D22 事實判斷表 | 簡化（researcher 蒐證 / coordinator 路由 / user 裁判；無 runes-holder 層） | 完整五層 |
| secret 守則 | 共用（不放入真 `.env`/token/key/session DB/log/cache） | 共用 |

**階段一 repo 骨架**

```
hermes-agent-opc-deploy/
├── README.md                    # 適用 hermes-agent v0.20.0；雙版本說明 + 階段段狀態
├── VERSION                       # 0.20.0
├── docs/
│   ├── shared/                  # profile 概念、guarded-apply、安全守則
│   ├── editions/generic/         # generic 專屬
│   └── editions/opc-personal/    # 你的 8-profile 專屬（階段二填 v4.1 補丁產物）
├── scripts/
│   ├── deploy-real-profiles.sh  # 加 --edition generic|opc-personal
│   ├── m0-capability-check.sh
│   ├── verify-repo-layout.sh
│   └── ...
├── editions/
│   ├── generic/
│   │   ├── roles.txt            # secretary coordinator researcher builder writer
│   │   ├── profiles/<5 roles>/SOUL.md.template  # 階段一空骨架
│   │   ├── config.yaml.example  # provider placeholder + 註解
│   │   └── README.md            # 5 role + 雲端 + 簡化白名單 + 記憶 1 層
│   └── opc-personal/
│       ├── roles.txt            # 8 角色
│       ├── profiles/<8 roles>/SOUL.md.template  # 階段一空骨架，階段二填
│       ├── config/rss_seeds.json.example
│       └── README.md
├── archive/
│   └── v0.16-v0.17/             # 現有 main 整批搬此（保留 M1–M7 驗證史）
└── config/                      # shared defaults
```

`git tag v0.20.0` 在階段一末下。

---

## 4. 4 個 caveat（實作前 live 驗）

| # | caveat | 關聯決策 | live 驗方式 |
|---|---|---|---|
| 1 | L3 硬熔斷如何在 K6 工具層實作（hermes 工具白名單？shell wrapper？） | D18 | M0 在 K6 測 `hermes -p builder tools` 看能否禁特定指令；或測 shell wrapper 攔截 |
| 2 | Lark 互動卡片回呼機制（[批准]/[駁回]）是否需自寫 plugin | D20 | M3 Feishu gateway 打通後測原生卡片按鈕回呼；無則標「需自寫 plugin」 |
| 3 | nim-researcher「每任務 MoA 觸發 ≤3」原生 MoA 無此 knob，要外掛計數 | D5a/D5b | M6b 在 nim profile 測 `hermes moa` config 是否有 per-task cap；無則 jobs.json 計數 + plugin hook |
| 4 | ppt-master 是 hermes skill 形態——writer 調用介面要驗 | D17 | M0 `hermes -p writer skills list \| grep ppt-master`；M6c 測一次完整 PPTX 產出 |

---

## 4.5 M0 實測結果（K6 實機，2026-08-14）

> 對應藍圖 §1 環境實測 + §10 M0 里程碑。由本機經 SSH（免密金鑰 `~/.ssh/id_k6_backup`）於 K6（192.168.23.214）執行 `m0-capability-check.sh` 驗證。

### 4.5.1 實測發現（與藍圖假設差異）

| 項目 | 藍圖 v4.0/§1 假設 | K6 實測 |
|---|---|---|
| hermes 版本 | 待 M1 裝 v0.20.0 | **已是 v0.20.0**（2026.8.3，git 安裝，commit `481ccdafb`）|
| profiles | 8 profiles 待建 | **單一 `default`**（agents-a1，gateway running）|
| plur | 待裝 `plur-hermes` pip | **skill 形態已內建**：`plur-memory.SKILL.md` v0.10.0（非 pip plugin）；`~/.plur/` 已有 engram/episodes 資料；config 已含 plur 欄位 |
| ppt-master | 待驗（caveat 4） | **enabled**（local） |
| Feishu/Lark | 待 M3 打通 | **已接通、gateway running**（2 cron jobs 正常推送）|
| agent-a1 | 待接 | `192.168.23.217:1234` HTTP **401**（api_key 已在 config）|
| Spark vLLM | 待接 | `192.168.23.215:1234` HTTP **401**（token 待 D13 設定）|
| NIM | 待接 | `https://integrate.api.nvidia.com`（外網）HTTP **200**（key 走 `NVIDIA_API_KEY`）|
| Secrets Store | 待設定 | **bitwarden 已設定** |

### 4.5.2 Plur 修正（重要）

- **D7/M7 實測修正**：Plur 完整實作 = **`plur-hermes` pip plugin（0.17.2）** + **`@plur-ai/cli`（npm，0.9.4，bridge）** + `~/.plur/` store。
- K6 原本已有 `@plur-ai/cli` 與 `~/.plur/` 資料（40 engrams/1224 episodes），但**缺 `plur-hermes` Hermes plugin**——M7 補裝後，hermes 暴露 plur + plur-meta 工具，8 profiles `plugins.enabled: plur` 全啟用。
- `plur-memory.SKILL.md`（v0.10.0）是 plur-ai/plur 的 skill 文件（描述 plur_learn 等用法），非獨立實作。
- **M7 調整**：從「安裝 plur-hermes」改為「確認所有 profile 啟用 plur plugin」；備份＝**一次性**至本機（gb10 為第三方建議用語，K6 無此掛載；使用者確認定期備份暫不採用）。
- **存檔已含**：`~/.plur/` 已納入 2026-08-14 全量備份 tar + M7 一次性快照。

### 4.5.3 M0 各檢查點結果

| # | 檢查 | 結果 |
|---|---|---|
| 1 | hermes CLI | ✅ v0.20.0 (2026.8.3) |
| 2 | hermes doctor | ✅ PASS（3 非阻擋 warning：config v33→v34 遷移、state.db 1.1G 需 auto_prune、缺部分 API key）|
| 3 | profile list | ✅ 單一 `default` |
| 4 | ppt-master skill（caveat 4）| ✅ enabled |
| 5 | plur-memory skill（D7）| ✅ enabled + `~/.plur/` 有資料 |
| 6 | Secrets Store（D19）| ✅ bitwarden 已設定 |
| 7 | agent-a1 端點 | ✅ HTTP 401（reachable，需 api_key 屬正常）|
| 8 | Spark vLLM 端點 | ✅ HTTP 401（reachable，需 token 屬正常）|
| 9 | NIM 外網端點 | ✅ HTTP 200 |
| 10 | L3 熔斷（caveat 1）| ⏳ 待 M2 建 builder profile 後於工具層測 |
| 11 | L2 HITL 卡片（caveat 2）| ⏳ 待 M3（gateway 已運行）|

### 4.5.4 M0 產物

- `m0-capability-check.sh` 已填入實際指令（deploy repo commit `0880a76`），支援 K6 本機或 SSH 遠端執行。
- K6 全量狀態備份已存本機 `D:\Workspace\projects\hermes-backup\`（含 `RESTORE_GUIDE.md`）。

---

## 5. 交叉索引
| 缺口 | 對應情境 | 對應決策 | 對應 caveat |
|---|---|---|---|
| G-A1 toolset 矩陣 | 2a/2e/2f/2g | （實作缺口，推斷開工具） | 1（L3 熔斷） |
| G-B1 nim 觸發計數 | 2c/2d | D5a/D5b | 3 |
| G-B2 每日 token cap | 2b/2c/2d | D5b | — |
| G-B3 jobs.json 寫鎖 | 全 | （實作缺口） | — |
| G-B4 secret redaction | 2e/2g | D19 | — |
| G-C1 artifact 交付 | 2d/2f | （實作缺口，驗 Feishu 檔案上傳） | — |
| G-C2 slide pipeline | 2d | D17 | 4 |
| G-D1 cron 入口 | 2b | D14 | — |
| G-D2 興趣清單存放 | 2b | D14/D15/D16 | — |
| G-D18 破壞性白名單 | 2e | D18/D20 | 1/2 |
| G-E1 SSH 憑證注入 | 2e | D19 | — |
| G-E2 builder SSH 權限 | 2e | D19 | — |
| G-F1 researcher vs nim 閾值 | 2c/2d | D5a/D5b | 3 |
| G-F2 hybrid researcher/builder | 2g | （實作缺口，規則定） | — |
| 事實判斷分工 | 2c/2d/2g | D22 | — |
| deploy repo 雙版本 | —（藍圖 §8） | D23/D24/D25/D26 | — |
| v0.20.0 版號 | —（藍圖 §8 + repo） | D27 | — |
| repo 更新時機 | —（藍圖 §8） | D28 | — |