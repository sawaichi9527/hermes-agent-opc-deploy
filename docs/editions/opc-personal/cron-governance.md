# cron 治理（D14 / D15 / D16 / D21，M3–M4 實測）

**適用 hermes-agent v0.21.5+3435**。cron 入口 owner = **secretary**；雙檔 rss 種子 + governance audit cron；排程任務走同機序列（不用 A2A）。Gateway 現行架構見 `gateway-multiplex.md`（default-profile multiplexer 統一服務 9 profile，secretary 無獨立 service）。

## cron 雙檔（D14，secretary 沙盒目錄）

```text
~/.hermes/opc/secretary/
├── rss_seeds.json          # 正式，唯讀排程用
└── rss_suggestions.json    # 影子建議（不進 Runes）
```

- 刻意**不進 Runes**：降治理重量換機讀性。
- 範例見 `editions/opc-personal/config/rss_seeds.json.example`。

## 排程任務流程（D21，同機序列）

```text
cron(owner=secretary) -> secretary 組 brief -> coordinator -> 同機序列 researcher/writer
                    -> secretary 推 Lark card
```

- **不用 A2A**（同機；跨機才用，見 a2a-expansion-pi5）。
- 每小時 RSS 情報 cron + governance audit cron。

## pre_approved tag（D15）

- jobs.json `approval_state: pre_approved`：排程任務走免審批通路。

## governance audit cron（D16）

- **頻率 per-job 可配置**（非固定週五）。
- 流程：coordinator 比對 seeds/suggestions → Lark 互動卡片 [批准更新]/[駁回] → 點批准才喚 builder 寫入 `rss_seeds.json`。

## M3 實測結果（cron 遷移）— 歷史（2026-08-14，已被 multiplex 取代）

> ⚠️ 以下為 M3 舊架構記錄，**現行架構已改走 default-profile multiplexer**（見 `gateway-multiplex.md`）。保留此段作為演進史。

- default gateway 停用；secretary gateway 啟用（`hermes-gateway-secretary.service` + systemd linger）。
- cron 2 jobs 遷移至 secretary，正常排程推送（21:34 run ok）。
- Feishu 設定（`.env` FEISHU_*）+ plugins（feishu/plur/rtk-rewrite）+ approvals/security 已複製 secretary。

## 現行架構：multiplex（2026-09-27）

- `hermes gateway migrate --multiplex` → `gateway.multiplex_profiles: true`。
- default multiplexer（`hermes-gateway.service`，systemd user）統一服務全部 9 profile，含 secretary。
- secretary 獨立 gateway service 已 stop + uninstall；cron jobs 仍 owner=secretary（執行形態不變）。
- 詳 `gateway-multiplex.md`。

## 設定腳本

```bash
bash scripts/setup-feishu-gateway.sh    # secretary gateway 接管（env 複製 + plugins + approvals + cron 遷移）
bash scripts/jobs-json-init.sh          # jobs.json 初始化（含 approval_state 欄）
```

## 驗證（M3–M4 PASS）

- secretary gateway Lark websocket 連線成功。
- cron 端到端 succeeded + deliver origin。
- approvals/security 同步 secretary。
