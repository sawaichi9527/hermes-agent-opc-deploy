# hermes-agent-opc-deploy

**適用 hermes-agent v0.20.0**（D27：README 標 + `VERSION` 檔 + `git tag v0.20.0`）。

Hermes 原生 profile 客製化與部署指南 repo。本 repo 是 Freelancer 重灌的**單一事實來源**，同時提供 GENERIC edition 供一般人參考。

本 repo 不定義新的 runtime / 部署框架 / queue / router / daemon / dispatcher / orchestration layer。Hermes Agent 仍是 runtime owner。

## 雙版本（D23）

| | GENERIC（給一般人參考） | OPC-PERSONAL（本藍圖 8-profile） |
|---|---|---|
| 角色 | 5（secretary, coordinator, researcher, builder, writer） | 8（5 core + runes-holder + aeon-builder + nim-researcher） |
| 算力預設 | 雲端（provider **placeholder**，使用者自選） | Strix Halo 本機 `agent-a1` + DGX/NIM 遠端顧問 |
| secretary 綁定 | 不綁 Lark；`gateway setup` 多選平台 | Lark/Feishu |
| 記憶 | 1 層（native only） | 3 層（native + Plur + Runes） |
| cron 治理 | 無 | 雙檔 `rss_seeds.json`/`rss_suggestions.json` + pre_approved + governance audit cron |
| 破壞性白名單 | L1/L2 簡化（無 L3 硬熔斷） | 三級完整（L3 需 K6 wrapper） |
| MoA / A2A | 無 | nim-researcher 內部 MoA + A2A 留給未來 Pi 5 |
| 事實判斷分工 | 簡化三層（researcher / coordinator / user） | 完整五層（D22） |
| secret 守則 | 共用 | 共用 |

版本基準：本 repo 對應 hermes-agent **v0.20.0**；舊 v0.16/v0.17 內容整批保留於 `archive/v0.16-v0.17/`（含 M1–M7 驗證史）。

## Repository layout

```text
README.md
VERSION                        # 0.20.1
docs/shared/                   # 共用文件（guarded-apply-contract、安全守則）
docs/editions/{generic,opc-personal}/   # edition 專屬文件（opc-personal 已填 M8 內容；soul-vs-agents.md 標 SOUL/AGENTS 邊界）
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

## OPC-PERSONAL setup 腳本（K6 執行）

```bash
bash scripts/m0-capability-check.sh                # 端點/套件可達性（M0）
bash scripts/jobs-json-init.sh --apply             # jobs.json 初始化（M4）
bash scripts/setup-plur.sh --apply                 # 8 profiles 啟用 plur（M7）
bash scripts/setup-feishu-gateway.sh --apply --confirm REAL_FEISHU_GATEWAY_TAKEOVER  # secretary gateway 接管（M3）
bash scripts/setup-nim-moa-profile.sh --apply      # nim-researcher MoA preset（M6b）
bash scripts/approvals-deny-init.sh --apply        # D18 L3 deny 清單（M6a）
PROFILE_LIST=aeon-builder MODEL_NAME=qwen3.6-27b \
  bash scripts/set-local-model-name.sh --apply --verify   # aeon-builder 切換 + 身分驗證（D13）
```

各腳本說明見對應 doc（`docs/editions/opc-personal/`）。

## 基本驗證

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
```

## 重灌流程（從 repo）

```text
1. 裝 hermes v0.20.0（官方 installer）
2. git clone sawaichi9527/hermes-agent-opc-deploy
3. bash scripts/m0-capability-check.sh                          # 端點/套件可達性
4. bash scripts/verify-repo-layout.sh && verify-profile-templates.sh   # 驗 repo 本身
5. bash scripts/deploy-real-profiles.sh --edition <generic|opc-personal> --dry-run
6. 依 docs/editions/opc-personal/ 逐步設定 model/plugin/gateway/MoA/jobs.json（見上「OPC-PERSONAL setup 腳本」）
7. 重啟 secretary gateway；Lark 冒煙測試
8. runes inscribe + probe；verify-runes
```

## 安全守則（不可移除）

- 不放入真 `.env`/API key/token/session DB/log/cache/複製 hermes 原始碼/複製 runes content。
- guarded apply 需 `--confirm REAL_DEPLOY_PROFILES` + backup；dry-run 為預設。
- 真 profile 變更、cleanup、Lark cutover 需 maintainer 明確批准。
