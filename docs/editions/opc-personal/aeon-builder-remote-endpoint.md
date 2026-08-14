# aeon-builder 遠端端點（D4 / D8 / D13，M6a 實測）

**適用 hermes-agent v0.20.0**。OPC-PERSONAL edition 第 7 profile：遠端 DGX Spark vLLM 端點思考、本機 K6 沙盒執行工具。處理算法死鎖 / 高併發 / 複雜除錯。

## 端點架構

| 項目 | 值 |
|---|---|
| provider id | `aeon`（固定；與 model 名解耦，切模型不換 provider，D8） |
| api_base | `http://192.168.23.215:1234/v1`（Spark vLLM Docker `aeon-7/vllm-dflash`） |
| model | `qwen3.6-27b`（預設）↔ `qwen3.6-35b-a3b`（切換） |
| 驗證 | `/v1/models` 回傳 model `aeon`（max 229K）；token 已設入 aeon-builder config（D13） |
| 本機 | 工具全部在 K6 本機沙盒執行；遠端只當模型端點 |

## 身分驗證（D13，派工前必做）

`hermes -p aeon-builder` 派工前，先 curl 驗證端點身分與可用性：

```bash
# 身分：ACTUAL_MODEL 需匹配 config model.name
curl -s http://192.168.23.215:1234/v1/models | jq '.data[].id'

# 健康：/health 需 200
curl -s -o /dev/null -w '%{http_code}' http://192.168.23.215:1234/health
```

流程：curl /v1/models → 取 ACTUAL_MODEL → 比對 config → 相符才派工，並把 ACTUAL_MODEL 寫入 jobs.json `model_used`。

## 模型切換（Spark 端手動 script 重載，非熱切）

- vLLM 換模型需重載；**不做熱切**（D13）。
- Spark 端手動 script 重載（非 deploy repo 內本機 script）；切換窗口為已知中斷期。
- 切換窗口協調：探端點 busy（原生 `--enable-metrics` + `/health`）、先到先 claim、**不自建 queue**（D12，手動觀察）。

## 熔斷降級

- **health fail → fallback 本機 builder**，secretary 回覆標「重型代碼降級本地」（降級矩陣 §degradation-matrix）。
- 任務每 60s 更新 `last_ping_at`；20min 無進展主動 ping；30min 無回應推 Feishu card。

## 派工（v0.20.0 CLI）

```bash
hermes -p aeon-builder chat -Q -q "<prompt>"   # 單任務派發，不占本地 slot
```

溫度建議 0（重型推理任務）；身分驗證 + health 檢查先行。

## 驗證（M6a PASS）

- Spark 重型任務實測：Fibonacci F(49) 正確產出。
- 身分驗證流程 OK（`/v1/models` ACTUAL_MODEL 匹配 config）。
- `/health` 200；token 已設入 config，ping PASS。

## 安全守則

- Spark token 存 Hermes Secrets Store / profile config；**禁入 builder/.env**（D19）。
- 不自建 queue；不把 token 寫入 jobs.json（G-B4）。
