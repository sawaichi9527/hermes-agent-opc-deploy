# OPC 5+2 混合算力多代理矩陣 — 純原生 Hermes v0.20.0 實作藍圖

**版本：** v4.1（併入 companion §3 全部補丁：D5a–D28 決策、事實判斷分工表 D22、toolset 矩陣、cron 治理、三級破壞性白名單、deploy repo 雙版本；清理結構讓流程整潔；**M0 實測結果與 Plur skill 修正**）
**基礎：** NousResearch/hermes-agent v0.20.0（純原生，**不引入 HCA**；**M0 已實機驗證 v0.20.0 2026.8.3**）
**關聯 repo：** sawaichi9527/hermes-agent-opc-deploy（階段一骨架已完成，tag v0.20.0；`m0-capability-check.sh` 已填入實際指令；階段二 M8 後填驗證內容）
**最後更新：** 2026-08-14

> **變更註記（2026-09-14）：** 本藍圖為定格歷史決策文件，下列稱呼保留當時決策原貌，**現況以實際部署為準**：第 8 profile `nim-researcher` 已更名 `opencode-researcher`；其 MoA reference provider 由 Nvidia NIM（`nvidia:meta/llama-3.3-70b-instruct`）換為 OpenCode Go（`opencode-go:deepseek-v4.1-flash`，key `OPENCODE_GO_API_KEY`）；本機預設模型由 `agent-a1`/`agents-a1`（192.168.23.217:1234）改為 **`ornith-1.5-35b-a3b`**（同一 LM Studio 端點）。§10 M0–M8 驗證紀錄與「M0 實測」blockquote 內之 `agent-a1` 為當日實測當時之名，保留原樣。詳 `handoff.md`「2026-09-14 session 13」「2026-08-25 session 12」節與 deploy repo（v0.20.2）。

> 本藍圖以 Hermes 原生 profiles、序列化路由、A2A、MoA、Feishu/Lark adapter
> 實作「5 核心 + 2 重型顧問 + 1 治理」能力矩陣（8 profiles），刻意不引入第三方控制層（HCA）。
> 記憶採三層堆疊：Hermes native、Plur（跨角色共享）、Runes MD Wiki
> （治理式長期 canonical，經 runes-holder 存取）。
>
> v4.1 = v4.0 + companion `Hermes_OPC_v4_gap_and_scenario_analysis.md` §3 已定稿補丁。
> 本文已自足，無需再併其他檔；companion 保留作為補丁決策留痕與情境模擬參考。

## 0. 設計決策記錄

| # | 決策 | 理由 |
|---|---|---|
| D1 | 用 Hermes **v0.20.0**，**不用 HCA** | HCA 非官方、79 star alpha、pin 0.18.2，追不上 v0.20.0 迭代（使用者判定） |
| D2 | 保留舊 deploy repo 的 **runes-holder 專職 profile** | runes 治理需專責 + secretary-mediated 審批，舊 repo 已驗證此邊界 |
| D3 | 併發**序列化**（一次一 worker，無 parallel dispatch，**無 quick-answer bypass**） | 本地 LM Studio 是個人資源；舊 repo 序列設計正確。第三方一致收斂為嚴格序列、移除 bypass |
| D4 | 高階 builder = **`aeon-builder` profile**（路線 A：遠端 vLLM 端點，本機執行工具） | 重型代碼要遠端模型真做決策並驅動工具 |
| D5 | 高階 researcher = **`nim-researcher` 獨立第 8 profile**（路線 B：內部走 MoA preset，reference NIM 70B+，aggregator 本機 ornith-1.5-35b-a3b） | 升格獨立 profile 以得失敗隔離、成本上限、獨立 timeout/retry |
| D5a | researcher 報 **source>10 附 URL 清單** → **coordinator 下令 reroute nim** | researcher **不自派** nim（D3 無 kanban dispatcher）；nim 拿 researcher 已蒐的 source list 當 bootstrap **不重抓**；coordinator 看 `evidence_urls` 長度做判定，**不重新查證**（coordinator 沒開 web_search） |
| D5b | NIM 40問/min 免費額度在序列下**天然不撞** | 序列下 nim-researcher 一次一任務、每任務 MoA 觸發 ≤3 → 每分鐘 ≤3 ref call，遠低於 40；仍寫進 nim SOUL + jobs.json 額度計欄做雙保險 |
| D6 | 開啟 **A2A**，但定位為「未來跨機擴展面」（Pi 5 Hermes peer） | 同機角色間用序列路由即可；A2A 跨機跨 framework |
| D7 | **Plur 現在就納入**所有 profile（**`plur-hermes` pip plugin + `@plur-ai/cli` bridge**，M7 實測） | 跨角色學得 conventions 一處共享；**M7 實測**：`pip install plur-hermes`（0.17.2，註冊 pre_llm_call/post_llm_call hooks）+ 既有 `@plur-ai/cli`（0.9.4，`~/.plur/` 已有 40 engrams/1224 episodes）；8 profiles `plugins.enabled: plur` |
| D8 | 角色命名：`aeon-builder` / `nim-researcher`；aeon 為 DGX vLLM provider 名，可在 qwen3.6-27b / qwen3.6-35b-a3b 間切換 | provider 名與 model 名解耦，切模型不換 provider |
| D9 | 實作成功後才更新 deploy repo（重灌單一事實來源） | repo 有 guarded-apply + 禁 secrets 守則；只收驗證過的內容 |
| D10 | **個人使用定位**：單一使用者、線性交付、Spark 最多 2-3 併發；企業級 HA/排隊/多租戶隔離**不納入** | K6 專為服務發起人一人架設；三方一致 |
| D11 | **失敗恢復**：可觀測 + 手動介入為主，**不建自動 failover daemon** | 單人線性交付下失敗可見、介入成本低 |
| D12 | **DGX queue 監測降為手動觀察** | 2-3 併發下 queue length ≠ ETA、有 TOCTOU race；用原生 `--enable-metrics` + `/health`，不自建 queue 服務 |
| D13 | **aeon-builder 模型切換 = Spark 端手動 script 重載**（非熱切）+ 派工前動態驗身分 + 切換窗口熔斷降級 | vLLM 換模型需重載為已知限制；provider id 固定 `aeon`，但任務記錄要寫實際 model；**M2/D13 實測**：Spark 215:1234 token 已設入 aeon-builder config，`/v1/models` 回傳 model `aeon`（max 229K），身份驗證流程驗證 OK（ACTUAL_MODEL=aeon 匹配 config） |
| D14 | **cron 入口 owner = secretary** | secretary 沙盒目錄下雙檔 `rss_seeds.json`（正式，唯讀排程用）/ `rss_suggestions.json`（影子建議）；**不進 Runes**（刻意降治理重量換機讀性） |
| D15 | **pre_approved tag** | jobs.json 加 `approval_state` 欄位；排程任務帶 `pre_approved` 走免審批通路 |
| D16 | **governance audit cron** | **頻率 per-job 可配置**（非固定週五）；coordinator 比對 seeds/suggestions → Lark 互動卡片 [批准更新]/[駁回] → 點批准才喚 builder 寫入 `rss_seeds.json` |
| D17 | **writer 開 ppt-master skill** | ppt-master 是 hermes skill 形態；writer 透過 skill 呼叫直出 PPTX |
| D18 | **三級破壞性白名單** | L3 毀滅（dd of=/dev/、rm -rf /、mkfs、fdisk、shred）：K6 工具層**硬熔斷**，AI 連申請資格都沒；L2 破壞（apt upgrade/dist-upgrade、rm 非暫存、systemctl stop 核心、reboot、改 /etc/）：**強制 HITL 反問 Default-On**；L1 安全（apt update、git clone、cat、grep、systemctl status）：自主執行 |
| D19 | **SSH 憑證 = Hermes Secrets Store + 一次性 session 注入** | **禁入 builder/.env**；jobs.json 禁記任何 secret（G-B4 強化） |
| D20 | **approval token** | L2 卡片批准才釋放一次性短 TTL token；token 單次用、用後即毀；需 secretary 自訂 approval handler + Lark 卡片回呼（**自寫小工具/插件 — caveat 2**） |
| D21 | **cron 凌晨場景採同機序列** | 3am 直接跑 secretary→coordinator→researcher→writer→secretary 序列；**不用 A2A**（同機）；跨機才用 A2A（D6） |
| D22 | **事實判斷分工表** | 五層：researcher 蒐證 / runes-holder 取證 / coordinator 路由不查證 / secretary 暴露風險 / user 最終裁判（見 §3） |
| D23 | **deploy repo 雙版本** | `editions/generic/`（5-profile）+ `editions/opc-personal/`（8-profile）；舊 main 搬 `archive/v0.16-v0.17/`；`scripts/`/`docs/shared/` 共用 + per-edition |
| D24 | **GENERIC = 5 profile** | secretary + coordinator + researcher + builder + writer；secretary **不綁 Lark**，`gateway setup` 多選平台（Telegram/Discord/Slack/WhatsApp/Signal/Feishu/Email）；職責縮為入口+語氣+降級暴露（**無 runes 審批**，因 generic 無 runes） |
| D25 | **GENERIC 雲端不預設 provider** | `config.yaml.example` 留 placeholder + 註解指引使用者選 OpenRouter/Nous Portal/NIM/本地等；不寫死 |
| D26 | **GENERIC 最簡作用域** | 記憶 1 層（native only）；破壞白名單 L1/L2（**不含 L3 硬熔斷**，generic 無 K6 工具層）；無 cron governance、無 MoA、無 A2A |
| D27 | **v0.20.0 版號** | README 標「適用 hermes-agent v0.20.0」+ `VERSION` 檔 + `git tag v0.20.0`（三者都要） |
| D28 | **更新分兩階段** | **階段一**：repo 重構骨架（雙版本 + archive + 空 profile 模板 + placeholder config）+ 版號 + README（**已完成**）；**階段二**（M8 跑完）：填入 v4.1 補丁已驗證的 v0.20.0 內容 |

## 1. 系統硬體與環境

* **主控/執行端 (Freelancer, GMKtec K6)** — `192.168.23.214`，Ubuntu Desktop；hermes-agent **v0.20.0（2026.8.3，git 安裝，commit `481ccdafb`，已 M0 驗證）**；**8 個 profile 已建（M2 完成）**：default（ornith-1.5-35b-a3b, gateway running）+ 7 worker profiles + aeon-builder（Spark）；所有工具沙盒在本機
* **地端核心算力 (辦公室)** — AMD Strix Halo 395+ / 128GB；LM Studio + AMD ROCm；`ornith-1.5-35b-a3b`，**`192.168.23.217:1234`**（M0：HTTP 401 可達，api_key 已在 config）；承載日常 5 角色 + runes-holder（**序列化**，一次一呼叫）
* **地端重型算力 (DGX Spark，團隊共用)** — `192.168.23.215:1234`；vLLM Docker (`aeon-7/vllm-dflash`)；provider name `aeon`；`qwen3.6-27b` / `qwen3.6-35b-a3b` 切換（**手動 script 重載，非熱切**）；僅作 OpenAI 兼容 API 端點（**token 已設入 aeon-builder config（D13），model id `aeon`，/v1/models 與 /health 皆 200**）
* **雲端彈性算力 (NVIDIA NIM)** — 標準 NVIDIA NIM 服務（**外網，非內網**），`https://integrate.api.nvidia.com`（M0：HTTP 200 可達，key 走 `.env` 的 `NVIDIA_API_KEY`）；`meta/llama-3.3-70b-instruct` 量級；作 nim-researcher 內 MoA 的 reference，不直接執行工具
* **(未來擴展) Raspberry Pi 5** — 第二台 hermes-agent，作 A2A peer；不在首期

> 所有 agent 進程留 K6 本機；遠端只當模型端點（aeon-builder）或純建議（nim-researcher 內 MoA reference）。
> **M0 實測（2026-08-14）**：hermes CLI v0.20.0 / doctor PASS（3 個非阻擋 warning）/ profile 單一 default / ppt-master + plur-memory skill enabled / Secrets Store (bitwarden) 設定完成 / 三端點（agent-a1 401、Spark 401、NIM 200）全 reachable。

## 2. 角色矩陣（8 profiles + A2A 擴展面）

```
                 【 Feishu/Lark gateway (secretary profile, K6) 】
                                   │
                                   ▼ (標準化 brief)
┌────────────────────────────────────────────────────────────────────────┐
│          🧠 核心辦公室：AMD Strix Halo 395+ (LM Studio, ornith-1.5-35b-a3b)        │
│                        【序列化：一次一 profile 呼叫、無 bypass】          │
│                                                                        │
│  ┌───────────────┐   ┌─────────────────┐   ┌────────────────────────┐  │
│  │ 1. secretary  │ ─► 2. coordinator  │ ─► 3. researcher (日常)     │  │
│  └───────────────┘   └────────┬────────┘   └───────────┬────────────┘  │
│                               │                        │              │
│        ┌──────────────┐       │       ┌────────────────┼──────────┐   │
│        │ 6. runes-    │ ◄─────┤──────►│ 4. writer / 5. builder     │   │
│        │    holder    │       │       │    (一次一個)               │   │
│        └──────────────┘       │       └────────────────────────────┘   │
│                               │                        │              │
│                               ├─► 8. nim-researcher    │ D5a reroute  │
│                               │     [內部 MoA: NIM 70B  │ (source>10:  │
│                               │      ref → ornith-1.5-35b-a3b │  researcher  │
│                               │      aggregator；bootstrap          │  │
│                               │      從 researcher     │  report →    │
│                               │      source list；     │  coordinator │
│                               │      觸發上限 3]        │  下令 → nim) │
└───────────────────────────────┼─────────────────────────────────────────┘
                                │ (重型代碼/算法難題 — 單任務派發)
                                ▼
        【 ⚡ 7. aeon-builder (DGX Spark, vLLM/aeon) 】
           思考：遠端 qwen3.6-27b / 35b-a3b（A 路線，手動 script 切）
           執行：本機 K6 沙盒
           派工前 curl $SPARK/v1/models 驗身分；health fail 熔斷降本地 builder

        【 🔌 A2A 擴展面 (未來 Pi 5 Hermes peer) 】
           同機角色間不用 A2A；跨機才用 a2a_call
```

### 角色定義

| # | 角色 | 實作 | 模型 | 核心職責 | 記憶策略 |
|---|---|---|---|---|---|
| 1 | `secretary` | profile + Feishu gateway | ornith-1.5-35b-a3b | Lark 唯一窗口；修飾語氣；標準化 brief 交 coordinator；runes write 審批中樞 | **`USER.md`（你的語氣/偏好）**；`SOUL.md` 繁中；不寫工作雜訊 |
| 2 | `coordinator` | profile（**序列路由器**） | ornith-1.5-35b-a3b | 把 brief 拆成單一 worker 任務；決定「下一個 profile」；merge 回報；**內含降級矩陣（§3）** | **不放 USER.md**（純粹，不吸附語氣）；繁中 handoff |
| 3 | `researcher` | worker profile | ornith-1.5-35b-a3b | **日常**聯網查單頁/事實；證據比對 | MEMORY.md 任務筆記；Plur 共享；經 runes-holder 取 Runes 上下文 |
| 4 | `writer` | worker profile | ornith-1.5-35b-a3b | 整合產出 Markdown/PPTX；source/uncertainty 保留；**簡報走 ppt-master skill 直出 PPTX（D17）** | 同上 |
| 5 | `builder` | worker profile | ornith-1.5-35b-a3b | 日常 Python/Bash 自動化腳本；驗證；**aeon-builder 降級時接手** | 同上 |
| 6 | `runes-holder` | worker profile（**保留**） | ornith-1.5-35b-a3b | Runes MD Wiki 存取/治理專責；runes shield 只在 secretary/user 同意後 invoke；**不 gatekeeper 別人 native memory** | 自己的 native memory 學 `wiki/_system/`；繁中/英混 |
| 7 | `aeon-builder` | worker profile，`model.provider: custom`，`api_base: http://<DGX>:<port>/v1`，`model.name: qwen3.6-27b`（手動 script 切 35b-a3b） | 遠端 qwen | 算法死鎖/高併發/複雜除錯；遠端模型思考、本機執行工具 | runes `opc/aeon-builder/`；**DGX 共用需協調取徑（§6）** |
| 8 | `nim-researcher` | worker profile（**獨立，升格**）；**內部走 MoA preset**：`reference_models: [{provider: nvidia, model: llama-3.3-70b-instruct}], aggregator: {provider: local, model: ornith-1.5-35b-a3b}, reference_max_tokens: 600, fanout: user_turn` | NIM 70B+ 當 MoA reference / ornith-1.5-35b-a3b 當 aggregator | **大規模文獻調研/多國來源**（>10 份）；**由 coordinator reroute 才出動（D5a）**，拿 researcher 已蒐的 source list 當 bootstrap 不重抓；遠端出建議、本機 aggregator 落地 | 輸出落 `opc/nim-researcher/research-advisory/`；**MoA 每任務觸發上限 3 防迴圈放大**；獨立 timeout/retry/每日 token cap；jobs.json 額度計欄雙保險（D5b） |

**語言政策**（沿用舊 repo）：secretary / runes-holder 繁中為主；coordinator/researcher/writer/builder/aeon-builder/nim-researcher 英文為主的角色定義；runtime handoff 繁中優先，技術名詞保留原文。

## 3. 控制面（序列化，無 kanban dispatcher，無 bypass）

- **序列路由**：coordinator 一次只選「下一個 profile」，`secretary brief → coordinator plan → 單一 worker → coordinator merge → secretary reply`。**禁止** parallel dispatch、background swarm、**quick-answer bypass**（D3/D12）。
- **路由規則**（coordinator SOUL，顯式訊號優先）：
  - 需日常證據/事實/來源比對 → **researcher**
  - 需**大量文獻調研/多國來源**（>10 份、跨語） → **nim-researcher**（內部 MoA）
  - researcher 回報 `evidence_urls` 長度 **>10** → **coordinator 下令 reroute nim**（D5a）：nim 拿 researcher 已蒐的 source list 當 bootstrap，**不重抓**；researcher 不自派 nim
  - 需行文/報告/簡報 → **writer**（簡報走 ppt-master skill）
  - 需 code/shell/deploy/日常除錯 → **builder**
  - 需算法死鎖/高併發/複雜除錯 → **aeon-builder**（單任務，不占本地 slot）
  - 需 Runes wiki 上下文或 governed 提案 → **runes-holder**（retrieve 無需審批；**governed write 需 secretary-mediated user 同意**）
- **toolset 矩陣**（G-A1，per-profile 工具開關；實作時以 v0.20.0 真實 tool 名校準）：
  | profile | 開 | 不開 |
  |---|---|---|
  | secretary | gateway/feishu、jobs.json、secrets store 存取 | 不做深度查證工具 |
  | coordinator | 路由、handoff、merge、jobs.json | **web_search / fetch_webpage（明文禁深度查證）** |
  | researcher | web_search（**backend ddgs 免 key**，M4 驗證）、fetch_webpage、read/write（`~/opc-out/`） | 不開終端破壞指令 |
  | writer | read/write、ppt-master skill | 不開 terminal |
  | builder | terminal、ssh、execute_code、git/gh、read/write | 受三級白名單（§3）約束 |
  | runes-holder | runes shield、probe、Runes wiki 路徑 | 不開對外網頁查證 |
  | aeon-builder | 遠端端點 curl 驗身分、terminal（本機執行） | 不自建 queue |
  | nim-researcher | moa、NIM 端點、research-advisory 輸出 | 不直接執行工具 |
- **事實判斷分工表（D22）**：
  | 層級 | 角色 | 對「事實」做什麼 | 不做什麼 |
  |---|---|---|---|
  | 證據蒐集與比對 | **researcher** | 蒐集多源、比對、標 source status / uncertainty；附 `evidence_urls` 清單 | 不下「最終真偽裁決」 |
  | 治理證據提供 | **runes-holder** | 取 Runes wiki 的 governed canonical 當證據材料 | 不當 truth authority（runes ROADMAP 明定「不成為第二 agent」） |
  | 路由與合併 | **coordinator** | 讀 researcher 證據清單做決策（如 `evidence_urls` 長度 >10 → reroute nim）——信任 researcher 附加 URL 視為軟驗證 | **明文禁止深度事實查證**（不開 web_search）；不重新查證 URL |
  | 呈現與風險暴露 | **secretary** | 把「已確認/未確認/衝突/風險」標給 user 看 | 不自己查證 |
  | 最終真偽裁判 | **使用者** | Hermes 只給證據與可信度，**最終判斷在 user** | — |

  原則：沒有「查證者的查證者」無限迴圈——保底是 secretary 在 Lark 暴露「未查證/來源數不足以升 nim」欄位，user 看到可介入。
- **手動入口 vs cron 入口**（並存）：
  - **反式入口**（user 在 Lark 發訊息）→ secretary 收 brief → coordinator 路由 → 單一 worker（§2 流程）
  - **非反式入口**（cron，owner=secretary，D14）→ secretary 組 brief → coordinator → 同機序列 researcher/writer → secretary 推 Lark card。**cron 同機不用 A2A（D21）**。
  - cron 雙檔：`~/.hermes/opc/secretary/rss_seeds.json`（正式，pre_approved 免審批）+ `rss_suggestions.json`（影子建議，不進 Runes）
  - governance audit cron（D16）：頻率 per-job 可配置；coordinator 比對 seeds/suggestions → Lark 互動卡片 [批准更新]/[駁回] → 點批准才喚 builder 寫入 `rss_seeds.json`
- **三級破壞性白名單（D18）**：
  | 級別 | 範例 | 處置 |
  |---|---|---|
  | **L3 毀滅** | `dd of=/dev/*`、`rm -rf /`、`mkfs`、`fdisk`、`shred` | K6 工具層**硬熔斷**：AI 連申請資格都沒，直接回報不支援（caveat 1） |
  | **L2 破壞** | `apt upgrade/dist-upgrade`、rm 非暫存、`systemctl stop` 核心服務、reboot、改 `/etc/` | **強制 HITL 反問 Default-On**：Lark 卡片 [批准執行]/[拒絕]/[修改命令] → 批准才釋放一次性 token（D20） |
  | **L1 安全** | `apt update`、`git clone`、`cat`、`grep`、`systemctl status` | 自主執行 |

  **hermes 落地方式（M3 實測）**：
  - **L3** = 原生 `HARDLINE_PATTERNS`（rm -rf /、mkfs、dd of=/dev/ 等，hardline-deny 連 --yolo 都擋）+ user `approvals.deny` glob（fdisk 等補強，亦不可繞過）
  - **L2** = 原生 `DANGEROUS_PATTERNS`（systemctl stop 等 → ask-approval）+ Feishu 互動卡片按鈕審批（`send_exec_approval`，原生支援 caveat 2 收斂）
  - **缺口（G-D18）**：hermes 內建 pattern 不含 `apt upgrade`（會 allow）；藍圖定義其 L2。hermes 無 user 擴充 ask-approval pattern 的公開機制（只有 deny=硬擋）→ **L2 補法**：coordinator/builder SOUL 明訂「apt upgrade/dist-upgrade 屬 L2 需 HITL」，或視需加 `approvals.deny`（會升級成硬擋）
- **handoff packet**（compact、繁中）：
  ```
  目的: 必要背景: 目標 profile: 可用來源: 限制: 需要回傳: 風險:
  ```
  **禁止整段 transcript 轉貼**；每過一層先 merge 壓縮。
- **降級矩陣**（coordinator SOUL 寫死；secretary 回覆暴露風險欄）：
  | 不可用 | 降級動作 | 暴露 |
  |---|---|---|
  | aeon-builder（health fail） | fallback 本地 builder | 標註「重型代碼降級本地」 |
  | nim-researcher（NIM 端點 fail） | fallback researcher | 標註「大規模調研降級日常查證」 |
  | runes-holder | 跳過 Runes 層 | 標註「無 Runes 治理佐證」 |
  | researcher（OOM） | 跳過查證 | 標註「未查證」 |
- **失敗恢復**（D11，無 daemon）：worker 卡住回報 blocker（不靜默重試）；secretary Lark 端見無回應手動 `/stop` 或重發；可選 coordinator cron 監看卡狀態推播。

## 4. 三層記憶堆疊

| 層 | 範圍 | 寫入 | 生命週期 | 角色 |
|---|---|---|---|---|
| Hermes native `MEMORY.md`/`USER.md` | per-profile | agent-currated；`write_approval` 可開 | 短而 bounded | secretary 持 `USER.md`；coordinator 不放；worker 各自筆記 |
| **Plur**（`plur-hermes` pip plugin（0.17.2）+ `@plur-ai/cli` bridge（0.9.4）+ `~/.plur/`，M7 實測） | 全機共享跨 profile | plugin 自動 learn/inject（`plur_learn`/`plur_recall`/`plur_status`）；ACT-R 衰減 | 中期 decay | 跨角色 conventions/修正/偏好；scope：`global` / `project:opc` / `local`；**一次性備份至本機 `D:\Workspace\projects\hermes-backup\`（定期備份暫不採用）** |
| Runes MD Wiki（經 runes-holder） | `wiki/<slug>/opc/<role>/` | 僅 `forge` + secretary-mediated user 同意 | 長期 canonical | 專案/組織真相來源；**僅供證據，Hermes 下判斷** |

**Source priority**（擴充 runes ROADMAP P0.3，加入 Plur slot）：
1. 當下使用者指令 / 當下對話
2. Hermes native memory（runtime/偏好/skill cache，非 canonical）
3. Runes MD Wiki（governed long-term evidence）
4. Plur（學得 conventions，可 decay；與 Runes 衝突時 Runes 為準並標該 engram 待手動 prune）
5. 第三方 RAG / Obsidian
6. Web 公開來源

> Runes 不成為第二 agent；Hermes 做來源比對與最終判斷。runes-holder 只 retrieve，requesting profile 負責驗證。
> Runes governed write 流程須記錄（audit jsonl 留痕）；**自動 prune 降為手動觀察**（個人使用定位 D10）。Plur ACT-R 衰減下靜默行為漂移靠一次性快照與手動抽檢處理。

**jobs.json 可觀測欄位**（`~/.hermes/opc/jobs.json`，G-B2/B3/B4）：
- 每任務：`task_id, profile, model_used, started_at, last_ping_at, status, evidence_urls, approval_state, host`
- 加計數欄：`moa_trigger_count`（nim 每任務觸發 ≤3，D5b/G-B1）、`daily_token_used`（每日 token cap，G-B2）
- `approval_state`（pre_approved / pending / approved / rejected，D15）
- 並發寫入用 **flock 寫鎖**（G-B3）
- **secret redaction 強制**（G-B4/D19）：禁記 base_url token / SSH key / password；只記 host 名 + status

## 5. A2A 擴展面（未來 Pi 5）

- 現期同機不用 A2A。**cron 凌晨場景也走同機序列，不用 A2A（D21）**——只有跨機（Pi 5 Hermes peer）才用。在 coordinator profile 預留 `a2a_agents` slot 與 inbound 設定：
  ```yaml
  a2a_agents:
    pi5-helper:
      url: "http://pi5.local:9900"
      auth: { type: bearer, token: "..." }
      capabilities: [...]
  ```
  Inbound：`A2A_BEARER_TOKEN` + `A2A_HOST` + `A2A_PEER_TOKENS`；六層安全（127.0.0.1 預設、per-peer token、prompt-injection filter、出站 redact、audit jsonl、anti-loop）全原生。
- coordinator 用 `a2a_discover(pi5.local:9900)` 看 Agent Card、`a2a_call(pi5-helper, ...)` 跨機派。
- **Pi 5 記憶策略（建議）**：只 plur 共享（git 同步 `global/project:opc` 範圍）、runes 不進 Pi 5。

## 6. 初始化/設定（真實 CLI，v0.20.0）

```bash
#!/bin/bash
# OPC 5+2 native v0.20.0 — K6 初始化腳本（藍圖版；實作後依驗證結果再進 deploy repo）

# --- 8 個 profile ---
for role in secretary coordinator researcher writer builder runes-holder aeon-builder nim-researcher; do
  hermes profile create $role --description "<role 職責描述>"
done

# 每個 profile model 指向 Strix Halo LM Studio（aeon-builder 除外，nim-researcher 另設 MoA）
# <role> config set model.provider custom
# <role> config set model.api_base http://<STRIX_HALO_IP>:1234/v1
# <role> config set model.name ornith-1.5-35b-a3b

# secretary 專屬：Feishu gateway + SOUL/USER
# secretary gateway setup            # 選 Feishu/Lark，填 App ID/Secret
# secretary gateway install && secretary gateway start

# aeon-builder：遠端 DGX vLLM 端點（A 路線）
# aeon-builder config set model.provider custom
# aeon-builder config set model.api_base http://<DGX_SPARK_IP>:<PORT>/v1
# aeon-builder config set model.name qwen3.6-27b     # 手動 script 切 qwen3.6-35b-a3b
# aeon-builder config set temperature 0

# nim-researcher：獨立 profile，內部 MoA preset（M6b 實測）
# config.yaml moa.presets.nim-researcher：
#   reference_models: [{provider: nvidia, model: meta/llama-3.3-70b-instruct}]  # 用 nvidia 非 nim（NIM_API_KEY 不存在，nvidia 用 NVIDIA_API_KEY）
#   aggregator: {provider: custom, model: ornith-1.5-35b-a3b, base_url: http://192.168.23.217:1234/v1}
#   reference_max_tokens: 600, fanout: user_turn
# 觸發：hermes -p nim-researcher chat -Q -q "<prompt>" -m moa:nim-researcher（one-shot）
# 或互動式 /moa <prompt>
#（另設獨立 timeout / retry / 每日 token cap；每任務 MoA 觸發上限 3 = jobs.json moa_trigger_count）

# Plur：pip install plur-hermes（Hermes plugin）+ @plur-ai/cli（bridge，npm global）
# 確認所有 profile plugins.enabled 含 plur；驗證：hermes -p <role> tools list | grep plur
# 備份（一次性，非定期）：~/.plur 含於全量存檔（本機 hermes-backup / D:\Workspace\projects\hermes-backup\）

# Runes：runes-holder 走 shield；reactivate archive/v0.7.2-opc overlay（§7）
# A2A（未來 Pi 5）：coordinator 上 a2a_agents + token

# --- cron 治理（D14/D15/D16/D21）---
mkdir -p ~/.hermes/opc/secretary
# 雙檔：rss_seeds.json（正式）+ rss_suggestions.json（影子建議），不進 Runes
# 排程任務：secretary 組 brief → coordinator → 同機序列 → secretary 推 Lark card（不用 A2A）
# 註冊 cron：每小時 RSS 情報 + governance audit cron（頻率 per-job 可配置，非固定週五）
# jobs.json 每任務帶 approval_state（排程任務 = pre_approved 免審批）

# --- Secrets Store（D19）---
# SSH 憑證/API key 存 Hermes Secrets Store + 一次性 session 注入；禁入 builder/.env
# jobs.json 禁記任何 secret（G-B4）

# --- L3 硬熔斷 wrapper（D18，caveat 1）---
# K6 工具層攔截 L3 毀滅指令（dd/rm -rf/mkfs/fdisk/shred），AI 連申請資格都沒
# L2 破壞指令 → Lark HITL 卡片 → 批准才釋放一次性 token（D20）

# --- 可觀測性：jobs.json + 身分驗證 + 熔斷 ---
mkdir -p ~/.hermes/opc
# ~/.hermes/opc/jobs.json 記錄：task_id, profile, model_used, started_at, last_ping_at, status
# aeon-builder 派工前：curl $SPARK/v1/models 取 ACTUAL_MODEL，寫入 model_used
# aeon-builder health fail → 熔斷降級本地 builder，secretary 回覆標降級理由
# aeon-builder 任務每 60s 更新 last_ping_at；20min 無進展主動 ping；30min 無回應推 Feishu card

# --- ppt-master skill（D17）---
# writer 確認 skill 已裝：hermes -p writer skills list | grep ppt-master
```

**DGX 共用取徑協調**（D12，手動觀察）：派 aeon-builder 前 coordinator 先探端點 busy（用原生 `--enable-metrics` + `/health`）；先到先 claim；不自建 queue。切換窗口熔斷：health 檢查失敗即 fallback 本地 builder（§3 降級矩陣）。

## 7. Runes OPC overlay + runes-holder

**M5 實測（2026-08-14）**：K6 repo 已到 **v0.7.5-dev**，`archive/v0.7.2-opc` **不存在**（藍圖原假設的 overlay 來源已過期）；runes 工具 `bin/hermes-runes`（decipher/probe/forge/evoke/inscribe）目前是 **read-only scaffold**——`probe policy/decipher policy` 可用，但 `probe indexes/links`、`forge`、`inscribe` 為「planned but not implemented」。實作採：

1. ~~archive/v0.7.2-opc 拉 overlay~~ → 直接在 K6 現有 repo 建 `wiki/freelancer/opc/`
2. ✅ 建各 role namespace：`wiki/freelancer/opc/{secretary,coordinator,researcher,writer,builder,runes-holder,aeon-builder,nim-researcher}/README.md`（M5 完成）
3. ✅ `wiki/_system/source-priority.md` 加入 Plur slot（§4，M5 完成）
4. ~~inscribe 重建索引~~ → 現階段 `probe policy` + `decipher policy` 驗證（M5 PASS）；`indexes/links` 待 runes 工具實作後補（開放問題）
5. ✅ runes-holder SOUL 填實（M5）：不 gatekeeper native memory；write 需 secretary-mediated 同意
6. ✅ **governed write 流程寫 audit jsonl 留痕**（`~/.hermes/opc/runes-audit.jsonl`，M5 建立）；自動 prune 降手動（D10）

## 8. Deploy repo 同步計劃（sawaichi9527/hermes-agent-opc-deploy）

**定位**：本 repo 是 Freelancer 重灌的**單一事實來源**；同時提供 GENERIC edition 供一般人參考。
**適用 hermes-agent 版本**：v0.20.0（D27：README 標 + `VERSION` 檔 + `git tag v0.20.0` 三者都要）。

### 8.0 雙版本結構與更新階段（D23–D28）

repo 改為**雙 edition**；舊 main 內容整批搬 `archive/v0.16-v0.17/`（保留 M1–M7 驗證史）。

**雙版本分工**

| | GENERIC（給一般人參考） | OPC-PERSONAL（本藍圖的 8-profile） |
|---|---|---|
| 角色 | secretary + coordinator + researcher + builder + writer = **5** | 上述 + runes-holder + aeon-builder + nim-researcher = **8** |
| 算力預設 | 雲端（provider **placeholder**，使用者自選 OpenRouter/Nous Portal/NIM/本地） | Strix Halo 本機 `ornith-1.5-35b-a3b` + DGX/NIM 遠端顧問 |
| secretary 綁定 | **不綁 Lark**；`gateway setup` 多選平台（Telegram/Discord/Slack/WhatsApp/Signal/Feishu/Email） | Lark/Feishu |
| 記憶 | 1 層（native only） | 3 層（native + Plur + Runes） |
| cron 治理 | 無 | 雙檔 `rss_seeds.json`/`rss_suggestions.json` + pre_approved + governance audit cron |
| 破壞性白名單 | L1/L2 簡化（**不含 L3 硬熔斷**，generic 無 K6 工具層） | 三級完整（L3 需 K6 wrapper） |
| MoA / A2A | 無 | nim-researcher 內部 MoA + A2A 留給未來 Pi 5 |
| D22 事實判斷 | 簡化三層（researcher 蒐證 / coordinator 路由 / user 裁判；無 runes-holder） | 完整五層 |
| secret 守則 | 共用 | 共用 |

**階段一（已完成 2026-08-14）— 重構骨架（不待 M8）**

```
hermes-agent-opc-deploy/
├── README.md                    # 適用 hermes-agent v0.20.0；雙版本說明 + 階段狀態
├── VERSION                       # 0.20.0
├── docs/{shared, editions/generic, editions/opc-personal}/
├── scripts/                      # deploy-real-profiles.sh 加 --edition generic|opc-personal；m0-capability-check.sh、verify-* 等
├── editions/
│   ├── generic/{roles.txt, profiles/<5>/SOUL.md.template(空骨架), config.yaml.example(placeholder), README.md}
│   └── opc-personal/{roles.txt(8), profiles/<8>/SOUL.md.template(空骨架), config/rss_seeds.json.example, README.md}
├── archive/v0.16-v0.17/          # 現有 main 整批搬此（保留 M1–M7 驗證史）
└── config/                       # shared defaults
```
階段一末已下 `git tag v0.20.0`（D27 三者俱備）。

**階段二（M8 跑完）— 填入 v4.1 補丁已驗證的 v0.20.0 內容**：見 §8.1（opc-personal）。

### 8.1 OPC-PERSONAL edition 要更新的內容（階段二）
- `editions/opc-personal/roles.txt`：角色清單 **8 profile**（secretary, coordinator, researcher, writer, builder, runes-holder, aeon-builder, nim-researcher）
- `editions/opc-personal/profiles/<role>/SOUL.md.template`：新增/更新 8 個模板（aeon-builder、nim-researcher 新增；其餘沿用 M5 格式 + v4.1 補丁：序列化、降級矩陣、事實判斷分工、三級白名單、Plur、A2A 邊界、cron 雙檔、ppt-master skill）
- `docs/editions/opc-personal/`：新增 `nim-researcher-moa-profile.md`、`aeon-builder-remote-endpoint.md`、`plur-memory-layer.md`、`a2a-expansion-pi5.md`、`observability-jobs-json.md`、`degradation-matrix.md`、`cron-governance.md`、`destruction-whitelist.md`；更新 `opc-profile-set-design.md`（8 profile）、`local-compute-policy.md`（序列化、無 bypass）
- `scripts/`：更新 `deploy-real-profiles.sh`（沿用 guarded-apply + backup-before-write + managed marker + confirm token + `--edition`）、`set-local-model-name.sh`（aeon-builder 模型切換 + 身分驗證）、新增 `setup-plur.sh`（**確認所有 profile 啟用 plur-memory skill**，非 pip 安裝；備份=一次性至本機，見 §8.3）、`setup-feishu-gateway.sh`（**secretary gateway 接管：feishu env 複製 + plugins + approvals + cron 遷移**）、`setup-nim-moa-profile.sh`、`m0-capability-check.sh`（**已填入實際指令**）、`jobs-json-init.sh`、`approvals-deny-init.sh`（**寫入 D18 L3 清單至 approvals.deny**；L3 硬熔斷為 hermes 內建 HARDLINE_PATTERNS + user deny，**不需 l3-mcb-wrapper**（caveat 1 收斂））
- `README.md`：相容目標更新為 **v0.20.0**；補 8 profile + aeon-builder + nim-researcher + Plur + A2A + jobs.json + 降級矩陣 + cron 雙檔 + 三級白名單說明
- **v0.16/v0.17 → v0.20.0 CLI 校正**：檢查舊腳本裡已變更的指令（model provider 設定、moa、plugin install 語法），全部改用 v0.20.0 真實 CLI

### 8.2 保留的安全守則（不可移除）
- 不放入真 `.env`/API key/token/session DB/log/cache/複製 hermes 原始碼/複製 runes content
- guarded apply 需 `--confirm REAL_DEPLOY_PROFILES` + backup；dry-run 為預設
- 真 profile 變更、cleanup、Lark cutover 需 maintainer 明確批准

### 8.3 重灌流程（從 repo）
```
1. 裝 hermes v0.20.0（官方 installer）
2. git clone sawaichi9527/hermes-agent-opc-deploy
3. bash scripts/m0-capability-check.sh                          # 端點/套件可達性
4. bash scripts/verify-repo-layout.sh && verify-profile-templates.sh   # 驗 repo 本身
5. bash scripts/deploy-real-profiles.sh --edition opc-personal --dry-run   # 檢視 copy map
6. 手動跑 §6 的 model/plugin/gateway/MoA/A2A/cron/jobs.json/Secrets Store 設定（依 docs 逐步）
7. 重啟 secretary gateway；Lark 冒煙測試
8. runes inscribe + probe；verify-runes
```

## 9. 開放問題（第三方 AI 審視）

已收斂移除：
- ~~序列 vs 遠端並行~~（→ 嚴格序列、無 bypass，D3/D12）
- ~~DGX queue 監測粒度~~（→ 手動觀察，D12）
- ~~researcher vs nim 觸發閾值~~（→ D5a：>10 source + coordinator reroute）
- ~~cron 入口 / 興趣清單存放~~（→ D14/D15/D16）
- ~~slide 生成路徑~~（→ D17 ppt-master skill）
- ~~SSH 憑證注入 / builder SSH 權限~~（→ D19）
- ~~破壞性操作安全策略~~（→ D18 三級白名單）
- ~~8 profiles 命名~~（→ v4.0 已統一為 8，本版沿用）

仍開放：
1. **aeon-builder 的 DGX 切換窗口協調**：探 busy + 不自建 queue 下，是否需 lock 檔防同儕撞車？（手動觀察是否足夠）
2. **qwen3.6-27b ↔ 35b-a3b 動切**：`hermes -p aeon-builder config set model.name` 熱切被多方假設不可行；採 Spark 端手動 script 重載（D13）— 仍待 live 驗 script 的重載時間與中斷窗口
3. **nim-researcher MoA 成本與延遲量化** ✅ **收斂（2026-08-15，§9 評估 session）**：NIM reference 每次 1 call（in≈392–404 / out 136–528）、reference phase **65–98s** 固定開銷；aggregator 1–17 turns/任務（總耗時 106–423s）；**主變異源 = aggregator 工具 turn 爆炸**；NIM tokens 0.5–1K/任務、cost_usd=null（未配 pricing）、有 504 與一次掛起。改進：限制 nim-researcher 工具 turn（SOUL / `--max-turns`）。
4. **Plur ACT-R 實機行為** ✅ **收斂（2026-08-15，§9 評估 session）**：CLI 0.9.4 讀源碼確認**舊式 reactivate `min(1, strength+0.1)`**（3 次飽和）、decay 僅手動 `plur batch-decay` 落地、無 shouldInject、recall `--scope` 不過濾、**無「scope 命中永遠注入」逃生門**。結論：PLUR 放 working state + 共享固定 scope（`project:freelancer`）、必要 `plur promote`/feedback；runes 可選時下沉、缺席時 PLUR 扛責；中文 statement 帶英文關鍵字（BGE-small 英文 embedder，#781）。P2(d) baseline 已種下（`ENG-2026-0815-001/002`），4 週後複查。
5. **Runes 審批 UX** ✅ **接線完成（2026-08-15，P3）**：採 **Lark 純文字關鍵字**（`批准/拒絕/撤銷 <proposal_id>`）+ **SOUL 層象徵 token**（`R-<ts>-<4hex>`，單次用/不回傳）+ coordinator 唯一路由 + runes-holder 工具白名單（6 支 shield 唯讀 CLI，verdict 全 allow 免改 allowlist）+ audit jsonl 意圖記錄（`governed_write_intent`，forge/inscribe 未實作故不實際寫 wiki）。e 下沉 / f 故障回退測試 PASS。詳 `docs/editions/opc-personal/runes-approval-ux.md`。
6. **個人使用 SLO 數字** ✅ **首次基線量測（2026-08-15，§9 評估 session）**：secretary P50=12.7s / P95≈25s（n=3，gateway live 樣本）；coordinator 路由 P50=63s（n=3）；aeon-builder 2/2 成功、P50=65s（n=2）。**SLO 重定義建議**：secretary P50<15s/P95<30s（原 <5s 不切實際）、coordinator P50<70s/P95<120s、aeon 成功率>90%。tool-mediated 類別樣本不足，日常累積後正式定案。
7. **備份與還原演練**：`~/.plur/` 與 Runes wiki 的一次性備份還原流程未實際演練，RTO 未定義（維持一次性快照現況，不處理）
8. **runes / plugin 介面 drift（M0 部分收斂 + P3）**：M0 已實機驗證 hermes v0.20.0 CLI、skills、Secrets Store、三端點 reachable；**M5 發現** runes `bin/hermes-runes` read-only scaffold；**P3（2026-08-15）**：runes_shield runtime 依賴已還原（PR #3）+ M5 OPC namespace 納入 mainline（PR #4）+ v0.7.5 進版（PR #5）；審批 UX 已接線（#5）。**剩餘 #8**：`forge`/`inscribe`/`indexes`/`links` 未實作——真實 wiki 寫入仍待 runes 工具層完成（現以 audit 意圖記錄替代）

### 4 個 caveat（實作前 live 驗，非設計缺口）

| # | caveat | 關聯決策 | live 驗方式 | M0 狀態 |
|---|---|---|---|---|
| 1 | L3 硬熔斷如何在 K6 工具層實作（hermes 工具白名單？shell wrapper？） | D18 | M0 在 K6 測 `hermes -p builder tools` 看能否禁特定指令；或測 shell wrapper 攔截 | ✅ **收斂（M3 實測）**：hermes 原生 HARDLINE_PATTERNS（rm -rf /、mkfs、dd of=/dev/ 等 → hardline-deny 不可繞過）+ `approvals.deny`（user glob 硬熔斷，--yolo 也擋）+ DANGEROUS_PATTERNS（systemctl stop 等 → ask-approval） |
| 2 | Lark 互動卡片回呼機制（[批准]/[駁回]）是否需自寫 plugin | D20 | M3 Feishu gateway 打通後測原生卡片按鈕回呼；無則標「需自寫 plugin」 | ✅ **收斂（M3 實測）**：**不需自寫 plugin**——Feishu adapter 原生支援（`_APPROVAL_CHOICE_MAP`：approve_once/session/always/deny + `P2CardActionTriggerResponse` 卡片回呼 → synthetic COMMAND event；gateway `send_exec_approval` button-based approval） |
| 3 | nim-researcher「每任務 MoA 觸發 ≤3」原生 MoA 無此 knob，要外掛計數 | D5a/D5b | M6b 在 nim profile 測 `hermes moa` config 是否有 per-task cap；無則 jobs.json 計數 + plugin hook | ✅ **收斂（M6b 實測）**：確認原生無 per-task cap；採 jobs.json `moa_trigger_count` 計數（≤3/task）+ nim SOUL 規範 |
| 4 | ppt-master 是 hermes skill 形態——writer 調用介面要驗 | D17 | M0 `hermes -p writer skills list \| grep ppt-master`；M6c 測一次完整 PPTX 產出 | ✅ **收斂（M6c 實測）**：skill symlink 接入 writer + quick-generate 產出原生 PPTX 3 頁驗證成功 |

## 10. 實作里程碑與驗證 gate

| 里程碑 | 內容 | 驗證 gate（過才進下一步） |
|---|---|---|
| **M0** | **capability checklist**（M1 前執行）：`hermes --version`/`doctor`、`profile list`、`skills list \| grep ppt-master`（caveat 4）、plur-memory skill 確認、Secrets Store 可達、`curl` agent-a1 / Spark vLLM `/v1/models` / NIM 端點可達 | ✅ **PASS（2026-08-14）**：hermes v0.20.0、doctor PASS（3 非阻擋 warning）、ppt-master+plur-memory enabled、bitwarden 設定、agent-a1 401 / Spark 401 / NIM 200；`m0-capability-check.sh` 已填入實際指令並 push deploy repo |
| M1 | K6 裝 v0.20.0；確認 hermes 本身健康 | ✅ **PASS（2026-08-14）**：v0.20.0 已裝；`doctor --fix` 遷移 config v33→v34；`optimize-storage` 回收 state.db 611MB（1090→479MB）+ 開 auto_prune；gateway 全程未中斷；doctor 僅剩「缺 API keys」非阻擋項 |
| M2 | 建 8 profiles；Strix Halo agent-a1 端點全接 | ✅ **PASS（2026-08-14）**：`profile create`（方案 A：create + 手動覆寫 SOUL）建 8 profiles；7 角色 model 指向 agent-a1（config set model.base_url），aeon-builder 指向 Spark；7 個 ping PASS；SOUL.md 覆寫為 deploy repo template（空骨架，階段二填實）；gateway 未中斷。aeon-builder 因 Spark 需 token（D13）未測 ping |
| M3 | secretary Feishu gateway 打通 Lark | ✅ **PASS（2026-08-14）**：default gateway 停用（systemctl disable）、secretary gateway 啟用（`hermes-gateway-secretary.service`，systemd linger）、Lark websocket 連線成功；cron 2 jobs 遷移至 secretary 且正常排程推送（21:34 run ok）；Feishu 設定（.env FEISHU_*+NVIDIA_API_KEY）+ plugins（feishu/plur/rtk-rewrite）+ approvals/security 已複製 secretary；Lark 秒回待實測 |
| M4 | coordinator 序列路由 + handoff；researcher/writer/builder 冒煙；**jobs.json 啟用**；**cron 端到端（D14/D21）** | ✅ **PASS（2026-08-14）**：jobs.json 建立於 `~/.hermes/opc/jobs.json`（含 v4.1 欄位）；coordinator SOUL 填實 v4.1（8-profile 路由 + D5a reroute + D22 + D18）並驗證 12-sources→nim reroute 正確；researcher（web_search ddgs 查證成功）/writer（寫檔）/builder（寫+執行）冒煙 PASS；cron 手動觸發 succeeded + deliver origin；**發現**：web.backend 改 ddgs（免 key，default 用 firecrawl 缺 key） |
| M5 | runes-holder + Runes overlay 啟用；**audit jsonl 留痕** | ✅ **PASS（2026-08-14）**：OPC namespace 建立（`wiki/freelancer/opc/<8 role>/README.md`）；source-priority 加 Plur slot（§4）；runes-holder SOUL 填實 v4.1（D22 + 治理寫入流程 + audit）；`~/.hermes/opc/runes-audit.jsonl` 建立；probe policy PASS、decipher policy PASS、runes-holder ping PASS；wiki repo commit `c16c96b`。**發現**：runes v0.7.5-dev 是 **read-only scaffold**（probe indexes/links、forge、inscribe 未實作）|
| M6a | aeon-builder 遠端端點 + 身分驗證 + 熔斷降級 + **L2 HITL 卡片流程（D18/D20）** | ✅ **PASS（2026-08-14）**：Spark 重型任務實測（Fibonacci 正確產出 F(49)）；D18 白名單驗證（reboot→hardline-deny / systemctl stop→ask-approval / mkfs+fdisk→deny）；approvals+security 同步；L2 卡片機制確認 Feishu `send_exec_approval` 原生可用 |
| M6b | nim-researcher 獨立 profile + 內部 MoA；輸出落 `research-advisory`；**reroute bootstrap（D5a）+ 觸發上限 3 + NIM 額度計數驗證（D5b）** | ✅ **PASS（2026-08-14）**：MoA preset `nim-researcher` 建立（reference **nvidia:meta/llama-3.3-70b-instruct**（NIM 實測 404 排除 nemotron）+ aggregator custom:agents-a1）；`chat -Q -m moa:nim-researcher` 觸發成功，**moa-trace 確證 reference fan-out + aggregator 收斂**；nim-researcher SOUL 填實（觸發上限+reroute）；jobs.json 加 moa_trigger_count。**發現**：reference provider 用 `nim` 查 NIM_API_KEY → 改用 `nvidia`（NVIDIA_API_KEY）；caveat 3 確認無原生 per-task cap → jobs.json 計數 |
| M6c | writer ppt-master skill 完整 PPTX 產出（D17，caveat 4） | ✅ **PASS（2026-08-14）**：ppt-master symlink 接入 writer profile skills（skills list 顯示 2 ppt skills）；quick-generate 產出 3-slide 原生 PPTX（16KB，python-pptx 驗證 3 頁）；caveat 4 收斂（writer 調用介面 + PPTX 產出皆驗證）|
| M7 | Plur 全 profile 啟用 skill 與共享；**一次性備份至本機**（M8 前做一次）| ✅ **PASS（2026-08-14）**：`pip install plur-hermes`（0.17.2，hooks 註冊）+ `@plur-ai/cli`（0.9.4 既有）+ 8 profiles `plugins.enabled: plur`；全 profile 見 plur 工具（plur + plur-meta），plur_status 回報 40 engrams；一次性快照 `m7-plur-snapshot-*.tar.gz` 拉回本機（sha256 驗證）|
| M8 | 全部 PASS → **更新 deploy repo（§8 階段二）** | `verify-repo-layout.sh` / `verify-profile-templates.sh` PASS；dry-run deploy PASS |

> 任一 gate FAIL 即回退前一里程碑修復，不進下一步。全部完成後才更新 deploy repo。