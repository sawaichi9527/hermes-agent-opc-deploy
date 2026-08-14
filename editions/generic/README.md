# GENERIC edition

適用 hermes-agent **v0.20.0** 的一般使用者參考 edition（D23/D24/D25/D26）。

## 角色（5 profiles）

```text
secretary      入口、語氣、降級暴露（不綁 Lark，gateway setup 多選平台）
coordinator    規劃與路由
researcher     查證
builder        實作
writer         寫作
```

## 特性（對比 OPC-PERSONAL）

- 記憶：1 層（native only）
- 破壞性白名單：L1/L2（無 L3 硬熔斷，generic 無 K6 工具層）
- 無 cron governance、無 MoA、無 A2A、無 runes 審批
- 算力：雲端為主，provider 由使用者自選（見 `config.yaml.example`）

## 目錄

```text
roles.txt                   角色清單（5）
profiles/<role>/SOUL.md.template   角色 SOUL 模板（階段一空骨架）
config.yaml.example         provider placeholder + 註解
```

## 狀態

- 階段一（骨架）：完成
- 階段二（M8 驗證後填入內容）：待辦

## 安全守則

請勿在本 repo 放入真 `.env`、API key、token、password、credential、runtime session DB、log/cache 或複製 hermes/runes 內容。
