# OPC-PERSONAL edition

本藍圖（Hermes OPC 5+2 / 8-profile）的個人 edition。適用 hermes-agent **v0.20.0**（D27）。

## 角色（8 profiles）

```text
secretary      Lark-facing 入口（D14 cron 雙檔）
coordinator    序列路由（D3 嚴格序列、無 bypass）
researcher     查證蒐證（D22 事實判斷分工）
writer         寫作（含 ppt-master skill，D17）
builder        本機實作（L3 白名單硬熔斷，D18）
runes-holder   Runes 治理取證（D2 專職保留）
aeon-builder   遠端 DGX vLLM 端點重型實作（D4/D8/D13）
nim-researcher 獨立第 8 profile，內部 MoA（D5/D5a/D5b）
```

## 特性（對比 GENERIC）

- 記憶：3 層（native + Plur + Runes）
- 破壞性白名單：三級完整（L3 硬熔斷需 K6 wrapper，caveat 1）
- cron 治理：雙檔 `rss_seeds.json`/`rss_suggestions.json` + pre_approved + governance audit cron
- MoA / A2A：nim-researcher 內部 MoA；A2A 留給未來 Pi 5（D6/D21）
- 算力：Strix Halo 本機 `agent-a1` + DGX/NIM 遠端顧問

## 目錄

```text
roles.txt                       角色清單（8）
profiles/<role>/SOUL.md.template   角色 SOUL 模板（M8 填實 v4.1）
config/rss_seeds.json.example    cron 種子檔範例（D14）
```

## 文件與腳本

- `docs/editions/opc-personal/`：8 篇（nim-researcher-moa-profile / aeon-builder-remote-endpoint / plur-memory-layer / a2a-expansion-pi5 / observability-jobs-json / degradation-matrix / cron-governance / destruction-whitelist）。
- setup 腳本（K6 執行）：`scripts/setup-plur.sh`、`scripts/setup-feishu-gateway.sh`、`scripts/setup-nim-moa-profile.sh`、`scripts/jobs-json-init.sh`、`scripts/approvals-deny-init.sh`、`scripts/set-local-model-name.sh`（aeon-builder 切換 + 身分驗證）。

## 狀態

- 階段一（骨架）：完成
- 階段二（M8）：完成 — 8 SOUL 模板 + 8 docs + setup 腳本已填 v4.1 驗證內容

## 安全守則

請勿在本 repo 放入真 `.env`、API key、token、password、credential、runtime session DB、log/cache 或複製 hermes/runes 內容。SSH 憑證走 Hermes Secrets Store（D19）。
