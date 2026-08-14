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
profiles/<role>/SOUL.md.template   角色 SOUL 模板（階段一空骨架）
config/rss_seeds.json.example    cron 種子檔範例（D14）
```

## 狀態

- 階段一（骨架）：完成
- 階段二（M8 驗證後填入內容）：待辦。待填內容見藍圖 §8.1（含 8 個 SOUL 模板 + docs + scripts 更新）

## 安全守則

請勿在本 repo 放入真 `.env`、API key、token、password、credential、runtime session DB、log/cache 或複製 hermes/runes 內容。SSH 憑證走 Hermes Secrets Store（D19）。
