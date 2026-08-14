# 降級矩陣（D11，M6a 實測）

**適用 hermes-agent v0.20.0**。單人線性交付的失敗恢復原則：**可觀測 + 手動介入**，不建自動 failover daemon。

## 降級矩陣（coordinator SOUL 寫死；secretary 回覆暴露風險欄）

| 不可用 | 降級動作 | secretary 暴露 |
|---|---|---|
| aeon-builder（health fail） | fallback 本地 builder | 標註「重型代碼降級本地」 |
| nim-researcher（NIM 端點 fail） | fallback researcher | 標註「大規模調研降級日常查證」 |
| runes-holder | 跳過 Runes 層 | 標註「無 Runes 治理佐證」 |
| researcher（OOM） | 跳過查證 | 標註「未查證」 |

## aeon-builder 熔斷（D13，M6a 實測）

- 派工前必做 health check：`curl -s -o /dev/null -w '%{http_code}' http://192.168.23.215:1234/health`。
- **health fail → 立即 fallback 本地 builder**，不重試遠端。
- 切換窗口（Spark 端 model 重載）亦依此熔斷。

## 失敗恢復流程（D11）

1. worker 卡住 → **回報 blocker**（不靜默重試）。
2. secretary Lark 端見無回應 → 手動 `/stop` 或重發。
3. 可選：coordinator cron 監看卡狀態推播。

## aeon-builder 心跳協定

- 每 60s 更新 jobs.json `last_ping_at`。
- 20min 無進展 → 主動 ping。
- 30min 無回應 → 推 Feishu card 通知 maintainer。

## 驗證（M6a PASS）

- Spark 重型任務（Fibonacci F(49)）正常完成，無誤觸熔斷。
- health / 身分驗證流程 OK；熔斷路徑已定義並實作於 coordinator SOUL。

## 設計原則

- 個人使用（D10）：失敗可見、介入成本低，**不需 daemon / 自動 failover**。
- 降級標註務必由 secretary 傳遞給 user，維持「未查證 / 降級」透明性。
