# opencode-researcher MoA profile（D5 / D5a / D5b，M6b 實測）

**適用 hermes-agent v0.20.0+**。OPC-PERSONAL edition 第 8 profile（獨立升格），負責**大規模文獻調研 / 多國來源**（>10 份、跨語），內部走 MoA preset，不直接執行工具。

## 定位

- 只在 **coordinator reroute（D5a）** 時出動：researcher 回報 `evidence_urls` 長度 **>10** → coordinator 下令 → opencode-researcher 拿 researcher 已蒐的 source list 當 **bootstrap，不重抓**。
- researcher **不自派** opencode-researcher（D3 序列化，無 dispatcher）。
- reference provider（遠端 LLM API）只出建議（reference）；本機 ornith-1.5-35b-a3b（aggregator）落地收斂。

## MoA preset（M6b 實測驗證；2026-09-14 reference 換源）

```yaml
# config.yaml moa.presets.opencode-researcher
preset: opencode-researcher
  reference_models:
    - { provider: opencode-go, model: deepseek-v4.1-flash }
  aggregator:
    { provider: custom, model: ornith-1.5-35b-a3b, base_url: http://192.168.23.217:1234/v1 }
  reference_max_tokens: 600
  fanout: user_turn
```

- **provider 用 `opencode-go`**（OpenCode Go），讀 `.env` 的 `OPENCODE_GO_API_KEY`；model 用 `deepseek-v4.1-flash`（2026-09-14 由 Nvidia NIM `meta/llama-3.3-70b-instruct` 換源，`NVIDIA_API_KEY` 已移除）。
- reference provider 為**可抽換概念**：NIM / opencode-go / 其他第三方 OpenAI-compatible API 皆可設定，profile 結構不變。
- fallback_providers 亦為 `[opencode-go]`（aggregator/task model 失敗時降級）。

## 觸發方式（v0.20.0 CLI）

```bash
# one-shot
hermes -p opencode-researcher chat -Q -q "<prompt>" -m moa:opencode-researcher

# 互動式
hermes -p opencode-researcher chat
/moa <prompt>
```

驗證 fan-out / 收斂：查 moa-trace（M6b 已確證 reference fan-out + aggregator 收斂）。

## MoA 觸發上限（D5b，caveat 3 收斂）

Hermes MoA **無原生 per-task cap**。採外部計數：

- 每任務記錄 jobs.json `moa_trigger_count`。
- 上限 **≤3 / task**；超過即停止 escalate，僅用本機 aggregator 收斂。
- reference 額度：依 provider 方案（OpenCode Go / NIM 皆有速率限制）；序列化 + cap-3 天然遠低於此（雙保險：opencode-researcher SOUL + jobs.json 額度計欄）。

## 輸出

```text
topic:
sources_used:      # bootstrap + 新增，保留 verbatim
evidence_urls:
confirmed:
uncertain:
conflicts:
recommendation:
```

輸出落 `opc/opencode-researcher/research-advisory/`。

## 獨立配置要求

- 獨立 timeout / retry / 每日 token cap（jobs.json `daily_token_used`）。
- 失敗隔離：reference 端點 fail → 降級日常 researcher（見 degradation-matrix）。

## 驗證（M6b PASS；reference 換源 2026-09-14）

- preset 建立 + `chat -Q -m moa:opencode-researcher` 觸發成功。
- moa-trace 確證 reference fan-out + aggregator 收斂。
- caveat 3 收斂：無原生 cap → jobs.json 計數。
- 2026-09-14：provider opencode-go / deepseek-v4.1-flash preset 已寫入，`.env` 已換 `OPENCODE_GO_API_KEY`。

## 安全守則

- reference key 在 profile `.env`（`OPENCODE_GO_API_KEY`）；**禁 log**。
- 不把 `.env`/token/session dump 放進 git 或 Runes candidates。