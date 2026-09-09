# hermes-agent-opc-deploy

**Stable baseline：0.20.1**；Hermes 基準為 **v0.20.0**。

> **Development track:** branch `dev/opencode-integration`, `VERSION=0.21.0-dev.1`  
> Freelancer/k6 已完成 OPC-PERSONAL 8-profile live deployment；本支線現在用於既有架構的 OpenCode Go 導入與角色 migration/refactor 設計，不是從零部署 8-profile。

Hermes 原生 profile 客製化與部署指南 repo。本 repo 是 Freelancer 重灌與演進的**單一事實來源**，同時提供 GENERIC edition 供一般人參考。

本 repo 不定義新的 runtime / 部署框架 / queue / router / daemon / dispatcher / orchestration layer。Hermes Agent 仍是 runtime owner。

## Development track：0.21.0-dev.1

目前 OpenCode 整合支線維持 **Hermes-first** 原則：

- OPC-PERSONAL 8-profile 已在 Freelancer/k6 實作並作為 live baseline。
- `0.21.0` 是增量修改，不重做現有 Hermes 架構。
- 路徑 A：OpenCode Go API 作為選定 Hermes profile 的 reasoning/model provider。
- 路徑 B：本機 OpenCode CLI 作為 coding sub-agent；目前仍延後，不因 Go 導入而一併安裝。
- 新增候選 migration：因目前實務上 NVIDIA NIM 模型服務穩定度不理想，評估以 `opencode-researcher` **一對一取代** `nim-researcher`，避免額外擴張成第 9 profile。
- `nim-researcher -> opencode-researcher` 目前仍是設計候選，需先 remote inspect live profile/provider/MoA/routing dependency，再決定是否實作。
- 後續討論造成的目標／方向變更，先更新 dev 文件，再由另一台 OpenCode 工作站 remote 實作 Freelancer/k6。

開發規格：

- `docs/editions/opc-personal/opencode-integration-dev.md`
- `docs/editions/opc-personal/remote-implementation-handoff-dev.md`

`main` / `0.20.1` 在 migration 驗證完成前維持 stable source of truth。

## 雙版本（D23）

| | GENERIC（給一般人參考） | OPC-PERSONAL（本藍圖 8-profile） |
|---|---|---|
| 角色 | 5（secretary, coordinator, researcher, builder, writer） | 8（5 core + runes-holder + aeon-builder + nim-researcher；dev 評估以 opencode-researcher 取代 nim-researcher） |
| 算力預設 | 雲端（provider **placeholder**，使用者自選） | Strix Halo 本機 `agent-a1` + 外部顧問模型；dev 評估 OpenCode Go |
| secretary 綁定 | 不綁 Lark；`gateway setup` 多選平台 | Lark/Feishu |
| 記憶 | 1 層（native only） | 3 層（native + Plur + Runes） |
| cron 治理 | 無 | 雙檔 `rss_seeds.json`/`rss_suggestions.json` + pre_approved + governance audit cron |
| 破壞性白名單 | L1/L2 簡化（無 L3 硬熔斷） | 三級完整（L3 需 K6 wrapper） |
| MoA / A2A | 無 | stable baseline 含 nim-researcher MoA；dev 需評估其保留/重構/退役 + A2A 留給未來 Pi 5 |
| 事實判斷分工 | 簡化三層（researcher / coordinator / user） | 完整五層（D22） |
| secret 守則 | 共用 | 共用 |

版本基準：stable repo 對應 hermes-agent **v0.20.0**；舊 v0.16/v0.17 內容整批保留於 `archive/v0.16-v0.17/`（含 M1–M7 驗證史）。

## Repository layout

```text
README.md
VERSION                        # dev branch: 0.21.0-dev.1; main: 0.20.1
docs/shared/                   # 共用文件（guarded-apply-contract、安全守則）
docs/editions/{generic,opc-personal}/   # edition 專屬文件
docs/editions/opc-personal/opencode-integration-dev.md
docs/editions/opc-personal/remote-implementation-handoff-dev.md
docs/soul-token-audit.md       # 13 份 SOUL 模板 token 用量審計（2026-08-15 refine）
scripts/                       # deploy / verify / setup 腳本
editions/generic/              # 5-profile 一般版
editions/opc-personal/         # 8-profile 個人版
archive/v0.16-v0.17/           # 舊版整批（含 validation-history）
config/                        # shared defaults
```

## 狀態

- **階段一**：repo 骨架重構完成（雙版本 + archive + 空 profile 模板 + placeholder config + v0.20.0 版號）。
- **階段二（M8 完成）**：填入 v4.1 補丁已驗證的 v0.20.0 內容——8 個 SOUL 模板、`docs/editions/opc-personal/` 8 篇、setup 腳本 5 支 + `set-local-model-name.sh` 更新、README 同步。
- **v0.20.1（2026-08-15）**：13 份 SOUL 模板全量 refine——統一結構/語言政策（繁中為主）、補齊 2026-08-15 決策（Plur scope 紀律、C6/B4、#8(a)）、補 Fact Division、opc-personal 去冗（chars −13.7%）、generic 5 檔骨架填空；token 對照見 `docs/soul-token-audit.md`。
- **v0.21.0-dev.0（2026-09-09）**：建立 OpenCode integration development track；記錄 A（Go API）/B（local CLI）、Hermes-first 邊界與 remote implementation handoff。
- **v0.21.0-dev.1（2026-09-09）**：修正 live baseline——OPC-PERSONAL 8-profile 已部署；dev 工作改以 incremental migration/refactor 為核心，新增 `nim-researcher -> opencode-researcher` 候選替換與 NIM dependency cleanup/rollback 要求。

## OPC-PERSONAL stable setup 腳本（K6 執行）

以下仍描述 stable `main` / 0.20.1 基準；dev migration 尚未批准前不要自行把 `nim-researcher` 改名：

```bash
bash scripts/m0-capability-check.sh                # 端點/套件可達性（M0）
bash scripts/jobs-json-init.sh --apply             # jobs.json 初始化（M4）
bash scripts/setup-plur.sh --apply                 # 8 profiles 啟用 plur（M7）
bash scripts/setup-feishu-gateway.sh --apply --confirm REAL_FEISHU_GATEWAY_TAKEOVER  # secretary gateway 接管（M3）
bash scripts/setup-nim-moa-profile.sh --apply      # stable baseline: nim-researcher MoA preset（M6b）
bash scripts/approvals-deny-init.sh --apply        # D18 L3 deny 清單（M6a）
bash scripts/align-secretary-model.sh --apply      # 對齊 secretary 模型到 coordinator/builder/writer/researcher（2026-08-24）
PROFILE_LIST=aeon-builder MODEL_NAME=qwen3.6-27b \
  bash scripts/set-local-model-name.sh --apply --verify   # aeon-builder 切換 + 身分驗證（D13）
```

各腳本說明見對應 doc（`docs/editions/opc-personal/`）。

## 基本驗證

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
```

## 重灌流程（stable baseline）

```text
1. 裝 hermes v0.20.0（官方 installer）
2. git clone sawaichi9527/hermes-agent-opc-deploy
3. bash scripts/m0-capability-check.sh
4. bash scripts/verify-repo-layout.sh && verify-profile-templates.sh
5. bash scripts/deploy-real-profiles.sh --edition <generic|opc-personal> --dry-run
6. 依 docs/editions/opc-personal/ 逐步設定 model/plugin/gateway/MoA/jobs.json
7. 重啟 secretary gateway；Lark 冒煙測試
8. runes inscribe + probe；verify-runes
```

`0.21.0` dev migration 最終若改變 profile 名稱或 provider，需在驗證完成後同步修改這個重灌流程，確保 repo 可重建實際 live 狀態。

## 安全守則（不可移除）

- 不放入真 `.env`/API key/token/session DB/log/cache/複製 hermes 原始碼/複製 runes content。
- guarded apply 需 `--confirm REAL_DEPLOY_PROFILES` + backup；dry-run 為預設。
- 真 profile 變更、cleanup、Lark cutover 需 maintainer 明確批准。
