# 討論總結草案

> **變更註記（2026-09-14）：** 本檔為定格歷史討論留痕，文中 `nim-researcher` 與本機模型 `agent-a1`/`agents-a1` 保留當時用語，**現況以實際部署為準**：第 8 profile 已更名 `opencode-researcher`，其 MoA reference provider 由 Nvidia NIM 換為 OpenCode Go；本機預設模型已由 `agent-a1`/`agents-a1` 改為 **`ornith-1.5-35b-a3b`**。詳 `handoff.md`「2026-09-14 session 13」節與 deploy repo（v0.20.2）。

針對 novusresearch/hermes-agent OPC 5+2 多 agent 部署計畫的多輪群組討論，整理如下。區分已獲多方支持、仍有分歧、尚缺證據三類。

## 已獲多方支持的主張

### 角色命名與數量
* 實際上線 profile 為 7 個：secretary、coordinator、researcher、writer、builder、runes-holder、aeon-builder。對應發起人所述 5 個原生 OPC 概念 + 2 個客製化應用。
* nim-researcher 應獨立成第 8 個 profile，而非掛在 researcher 下做子程序 delegation。理由為失敗隔離、成本上限、timeout/retry 可獨立設定。muse-glimmer-30b、minimax-m3、deepseek-v4-flash-free 三方均支持獨立 profile。
* 命名建議修正為 7 profiles + 1 MoA preset，或明確為 8 profiles，避免文件誤導。

### aeon-builder 與 DGX Spark 取徑
* 固定使用者端 provider id 為 `aeon`，使用者不需區分 27b / 35b-a3b。發起人明確要求此 UX，muse-glimmer-30b 與 minimax-m3 同意此產品決策。
* 模型切換採 Spark 端手動 script 重載，非熱切。vLLM 換模型需重載為已知限制，多方接受。
* 不自建 queue 服務，改用 vLLM 原生 `--enable-metrics` 與 `/health` / `/v1/models` 進行健康檢查。minimax-m3 與 muse-glimmer-30b 均提出此做法。
* 派工前需動態驗證實際模型身份並寫入任務記錄。共識做法為 `curl $SPARK/v1/models` 取得 `ACTUAL_MODEL`，寫入 `~/.hermes/opc/jobs.json` 的 `model_used` 欄位，以解決固定 provider id 下的 model identity drift。
* 切換窗口熔斷：health 檢查失敗即 fallback 到本地 builder，並在 secretary 回覆標註降級原因。muse-glimmer-30b 與 minimax-m3 均採納。

### nim-researcher 運作邊界
* nim-researcher 內部仍走 MoA preset，aggregator 為本機 agent-a1，reference 為 NIM。輸出應寫入 `opc/coordinator/research-advisory` 命名空間，不直接混入對話。
* 需設每任務 MoA 觸發上限，deepseek 建議 3 次，minimax-m3 同意寫入 coordinator SOUL。目的為防迴圈放大與延遲失控。
* 需設獨立 timeout、retry、每日 token cap，並在 coordinator 路由規則中明確區分「大量文獻調研 → nim-researcher」與「日常查證 → researcher」。

### 可觀測性與狀態追蹤
* M0 capability checklist 應在 M1 建 profile 前執行。包含 `hermes --help`、`hermes profile --help`、`pip show plur-hermes`、`curl` agent-a1、Spark vLLM、NIM 端點可達性。多方支持。
* 序列化路由需可觀測。共識為使用 `~/.hermes/opc/jobs.json` 記錄 `task_id, profile, model_used, started_at, last_ping_at, status`。muse-glimmer-30b、minimax-m3 均提出。
* 長任務狀態確認採被動輪詢。aeon-builder 任務每 60 秒更新 `last_ping_at`，20 分鐘無進展主動 ping，30 分鐘無回應回報 secretary 並推 Feishu card。發起人接受此機制。

### 降級矩陣
* coordinator SOUL 需寫死降級路徑：
  aeon-builder 不可用 → fallback 本地 builder
  nim-researcher 不可用 → fallback researcher
  runes-holder 不可用 → 跳過 Runes 層並標註
  researcher OOM → 跳過查證
* 多方支持將降級矩陣寫入 SOUL 並在 secretary 回覆中暴露風險欄位。

### 個人使用定位
* 發起人明確收斂為單一使用者、線性交付、Spark 最多 2-3 併發、企業級 HA/排隊/多租戶隔離不納入。minimax-m3 建議寫入 D10、D11 設計決策。
* 在此定位下，失敗恢復以可觀測 + 手動介入為主，不建自動 failover daemon。muse-glimmer-30b 與 minimax-m3 同意。

### 記憶與治理最低要求
* Plur 需定期備份。`~/.plur/` 應每日 tar 加密備份至 gb10，避免靜默行為漂移。deepseek 與 minimax-m3 均堅持此點。
* Runes governed write 需 secretary-mediated user 同意並留痕，寫入審計 jsonl。共識為寫入流程需記錄，但自動 prune 與週期性內容抽檢在個人使用下可降級為手動。

## 仍有分歧的主張

### 雙 port vs 單 port script 切換
* minimax-m3、muse-glimmer-30b 曾建議雙 vLLM container 分別綁 8001/8002 秒級切換。
* deepseek 反對，認為雙模型常駐佔用雙份 VRAM，與發起人「半私用、預設 27b、手動切換」衝突。
* 發起人最終確認維持手動 script 切換、單 provider id aeon。現階段傾向單 port script 方案，但需補上 model identity 驗證與切換窗口熔斷。

### quick-answer bypass 與 head-of-line blocking
* muse-glimmer-30b 與 deepseek 提出 secretary 直答 bypass 以避免序列化阻塞。
* 發起人說明 K6 為單人線性交付，大量平行任務可能性小，認為問題不大。
* minimax-m3 在個人使用收斂後建議移除 bypass。尚未形成共識，取決於是否接受「丟一個等一個」的使用體驗。

### DGX queue 監測粒度
* deepseek 指出 `vllm:num_requests_waiting` 僅為 best-effort admission control，queue length ≠ ETA，且有 TOCTOU race。
* muse-glimmer-30b 建議閾值 >5 即回報等待。
* 發起人認為 2-3 併發下問題不大。共識為使用原生 metrics，但閾值與自動排隊策略未定。

### nim-researcher profile 的模型設定語意
* deepseek 提醒若 profile 直接指向 NIM endpoint 會失去 MoA aggregator 落地層。
* muse-glimmer-30b 建議 profile config `model.name` 設為 `auto`，派工時動態填入。
* 具體 hermes v0.20.0 是否支援 `model.name: auto` 或 placeholder 仍未驗證。

### Plur 自動學習與衝突處理
* muse-glimmer-30b 擔憂 ACT-R 衰減導致靜默行為漂移，需自動 prune。
* deepseek 指出「與 Runes 衝突時標記待 prune」無人執行。
* minimax-m3 在個人使用下建議降級為手動觀察。三方對自動化程度未一致。

## 尚缺證據或需驗證的部分

* **CLI 與套件存在性**：hermes v0.20.0 的 `hermes profile create`、`moa configure`、`a2a_discover`、Feishu/Lark gateway、plur-hermes、runes-md-wiki、HCA 79 star / pin 0.18.2 等說法，目前無公開文件佐證。deepseek 提出需 M0 capability checklist 逐項驗證。
* **模型存在性**：qwen3.6-27b、qwen3.6-35b-a3b、`aeon-7/vllm-dflash` image 是否真實存在，無法從公開來源確認，需以 `curl /v1/models` 實測。
* **vLLM 熱切切換**：`hermes -p aeon-builder config set model.name` 是否可熱切，尚未驗證。多方假設不可行。
* **NIM MoA 成本與延遲量化**：reference_max_tokens 600、fanout user_turn 的實際 token 用量、input token 成本、延遲 P95 均未實測。minimax-m3 的成本估算被 deepseek 指出忽略 input tokens 與延遲成本。
* **Plur ACT-R 實作**：plur-hermes 是否真實實作 ACT-R 衰減、自動 learn 機制、共享目錄 `~/.plur/` 的行為，未有證據。
* **Runes 審批 UX**：secretary-mediated user 同意訊號如何驗證、是否可撤銷、是否留痕，具體 Lark 端互動方式未定義。
* **個人使用 SLO 數字**：secretary 回應 P50 <5s、coordinator 端到端 P50 <60s、aeon-builder 成功率 >80% 為 minimax-m3 提出建議值，尚未經實測確認是否合理。
* **備份與還原**：Plur 與 Runes wiki 的備份還原流程未實際演練，恢復時間目標未定義。

以上為目前討論的收斂點、分歧點與待驗證事項。

---

## 共識檢核結果

尚未達成共識（目前 0/2）：只有全體非草案作者模型皆明確同意，才會標示為共識；任何保留、反對、格式不符或無回應都會保留為未達成。

- **opencode/deepseek-v4-flash-free**：MISSING — 投票請求失敗
- **nvidia/meta/muse-glimmer-30b**（草案作者，不計入共識判定）：CONDITIONAL — 草案大方向可讀，但有幾處重要表述不精確、共識被過度收斂，且遺漏關鍵決策，會導致後續實作誤解。 1. 角色數量與命名自相矛盾 草案同時寫「實際上線 profile 為 7 個：secretary、coordinator、researcher、writer、builder、runes-holder、aeon-builder」又寫「命名建議修正為 7 profiles + 1 MoA preset，或明確為 8 profiles」。討論中 muse 與 minimax 已明確主張 nim-researcher 應獨立成第 8 個 profile，且內部仍走 MoA preset。草案把 nim-researcher 既當第 8 個 profile 又當 MoA preset 並列，造成 7+1 與 8 的混淆。應統一為 7 個核心 profile + nim-researcher 第 8 個 profile，該 profile 內部使用 MoA preset。 2. nim-researcher 運作邊界的共識被過度宣稱 草案列為已獲多方支持：「nim-researcher 內部仍走 MoA
- **nvidia/minimaxai/minimax-m3**：CONDITIONAL — 草案整體方向我同意，歸納相當完整，但有幾處我認為重要的遺漏或需修正處，必須列出： **1. 草案未反映發起人已明確收斂的關鍵決策** 發起人在發言 #11 已明確說明「整套 k6 都是專門為服務我一個人的需求架設的」「線性交付」「企業級能力需求不應強制放在這個規劃內」。草案在「個人使用定位」段落有提到 D10/D11，但**未將此決策對前幾輪爭議的消解效果寫清楚**。具體而言： - 草案「仍有分歧」段落仍把 quick-answer bypass 列為未決，但 minimax-m3 在發言 #12 已明確建議移除，muse-glimmer-30b 在發言 #13 也同意移除。**這不是「分歧」，而是已收斂為「移除」**。草案應改為「已收斂為移除」並標註理由（單人線性交付下阻塞可預期）。 - 草案「仍有分歧」段落的「DGX queue 監測粒度」也類似——發起人已說 2-3 併發下問題不大，minimax-m3 與 muse-glimmer-30b 都同意降級為手動觀察，這應該歸入「已收斂」而非「分歧」。 **2. 草案遺漏了 deepseek 提出的「狀態對齊」與「MoA 觸發上限」具