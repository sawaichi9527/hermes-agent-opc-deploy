# hermes-agent-opc-deploy

**Stable baseline：0.20.1**；Hermes 基準為 **v0.20.0**。

> **Development track:** branch `dev/opencode-integration`, `VERSION=0.21.0-dev.2`  
> Freelancer/k6 已完成 OPC-PERSONAL 8-profile live deployment；本支線用於既有架構的 OpenCode Go 導入與角色 migration/refactor，不是從零部署。

Hermes 原生 profile 客製化與部署指南 repo。本 repo 是 Freelancer 重灌與演進的**單一事實來源**，同時保留可供 fork user 調整的部署彈性。

本 repo 不定義新的 runtime / queue / router / daemon / dispatcher / orchestration layer。Hermes Agent 仍是 runtime owner。

## Development track：0.21.0-dev.2

目前維持 **Hermes-first** 原則：

- OPC-PERSONAL 8-profile 已在 Freelancer/k6 實作並作為 live baseline。
- `0.21.0` 是增量 migration/refactor。
- 路徑 A：OpenCode Go API 作為選定 Hermes profile 的 reasoning/model provider。
- 路徑 B：本機 OpenCode CLI 作為 coding sub-agent；目前仍 deferred，不因 Go 導入而一併安裝。
- **Maintainer live target 已決定：`nim-researcher` 由 `opencode-researcher` 一對一取代**，前提是 remote implementation 先完成 OpenCode Go proof-of-capability。
- **Repo 不移除 `nim-researcher` 支援**：fork user 若有穩定 NVIDIA NIM 服務，仍可選 NIM variant。
- `opencode-researcher` 與 `nim-researcher` 是同一個 **external-researcher slot** 的互斥 variant；正常 OPC-PERSONAL 仍維持 8 active profiles，不擴成 9 profiles。
- 後續目標／方向變更先更新 dev 文件，再由另一台 OpenCode 工作站 remote 實作 Freelancer/k6。

開發規格：

- `docs/editions/opc-personal/opencode-integration-dev.md`
- `docs/editions/opc-personal/external-researcher-variants.md`
- `docs/editions/opc-personal/remote-implementation-handoff-dev.md`

`main` / `0.20.1` 在 migration 驗證完成前維持 stable source of truth。

## 雙版本（D23）

| | GENERIC（給一般人參考） | OPC-PERSONAL |
|---|---|---|
| 角色 | 5（secretary, coordinator, researcher, builder, writer） | 8（5 core + runes-holder + aeon-builder + 1 external-researcher slot） |
| External researcher | 無固定專用角色 | maintainer default=`opencode-researcher`；optional fork variant=`nim-researcher` |
| 算力預設 | 雲端 provider placeholder | Strix Halo 本機 `agent-a1` + 外部顧問模型 |
| secretary 綁定 | 不綁 Lark；`gateway setup` 多選平台 | Lark/Feishu |
| 記憶 | 1 層（native only） | 3 層（native + Plur + Runes） |
| cron 治理 | 無 | 雙檔 `rss_seeds.json`/`rss_suggestions.json` + pre_approved + governance audit cron |
| 破壞性白名單 | L1/L2 簡化 | 三級完整（L3 需 K6 wrapper） |
| MoA / A2A | 無 | NIM variant 可保留 nim-researcher MoA；OpenCode variant 不以 NIM 為 runtime dependency；A2A 留給未來 Pi 5 |
| 事實判斷分工 | 簡化三層 | 完整五層（D22） |
| secret 守則 | 共用 | 共用 |

### OPC-PERSONAL external-researcher slot

Maintainer / Freelancer-k6 的 0.21.0 目標：

```text
aeon-builder
builder
coordinator
opencode-researcher
researcher
runes-holder
secretary
writer
```

Fork user 若選 NVIDIA NIM variant：

```text
aeon-builder
builder
coordinator
nim-researcher
researcher
runes-holder
secretary
writer
```

兩者為二選一，不是同時啟用。

版本基準：stable repo 對應 hermes-agent **v0.20.0**；舊 v0.16/v0.17 內容保留於 `archive/v0.16-v0.17/`。

## Repository layout

```text
README.md
VERSION                        # dev: 0.21.0-dev.2; main: 0.20.1
docs/shared/
docs/editions/{generic,opc-personal}/
docs/editions/opc-personal/opencode-integration-dev.md
docs/editions/opc-personal/external-researcher-variants.md
docs/editions/opc-personal/remote-implementation-handoff-dev.md
docs/soul-token-audit.md
scripts/
editions/generic/
editions/opc-personal/
archive/v0.16-v0.17/
config/
```

## 狀態

- **階段一**：repo 骨架重構完成。
- **階段二（M8 完成）**：8 profile SOUL/templates/setup 文件完成。
- **v0.20.1（2026-08-15）**：13 份 SOUL 模板 refine、語言/Fact Division/Plur scope 等同步。
- **v0.21.0-dev.0（2026-09-09）**：建立 OpenCode integration development track，記錄 A/B 與 remote handoff。
- **v0.21.0-dev.1（2026-09-09）**：修正為既有 OPC-PERSONAL live system 的 incremental migration；提出 `nim-researcher -> opencode-researcher`。
- **v0.21.0-dev.2（2026-09-09）**：maintainer live deployment 決定以 `opencode-researcher` 取代 `nim-researcher`；repo 則保留 NIM 作為 external-researcher optional variant，供 fork user 選擇。

## OPC-PERSONAL stable setup 腳本（K6 執行）

以下仍描述 stable `main` / 0.20.1 基準；dev migration 尚未 remote 實作前，不要直接把 stable script 當成 0.21.0 最終狀態：

```bash
bash scripts/m0-capability-check.sh
bash scripts/jobs-json-init.sh --apply
bash scripts/setup-plur.sh --apply
bash scripts/setup-feishu-gateway.sh --apply --confirm REAL_FEISHU_GATEWAY_TAKEOVER
bash scripts/setup-nim-moa-profile.sh --apply      # stable 0.20.1 NIM baseline / future optional NIM variant
bash scripts/approvals-deny-init.sh --apply
bash scripts/align-secretary-model.sh --apply
PROFILE_LIST=aeon-builder MODEL_NAME=qwen3.6-27b \
  bash scripts/set-local-model-name.sh --apply --verify
```

0.21.0 remote implementation 後，deploy/verify/reinstall tooling 應明確表達 external-researcher variant，而不是讓 fork user 靠手動刪檔切換。

## 基本驗證

```bash
bash scripts/verify-repo-layout.sh
bash scripts/verify-profile-templates.sh
```

## 重灌流程（stable baseline）

```text
1. 安裝 hermes v0.20.0
2. git clone sawaichi9527/hermes-agent-opc-deploy
3. capability check
4. repo/profile verification
5. deploy OPC-PERSONAL / GENERIC
6. 設定 model/plugin/gateway/MoA/jobs.json
7. secretary/Lark smoke test
8. Runes probe/verify
```

0.21.0 promotion 前必須同步更新重灌流程，使 repo 能重建 maintainer 的 OpenCode variant，同時保留 fork user 可選的 NIM variant。

## 安全守則（不可移除）

- 不放入真 `.env` / API key / token / session DB / runtime log/cache。
- guarded apply 需 backup、dry-run 與既有確認機制。
- 真 profile migration、cleanup、Lark cutover 需 maintainer 明確批准。
- live host 移除 NIM dependency **不等於** repo 可以刪掉 NIM optional variant。
