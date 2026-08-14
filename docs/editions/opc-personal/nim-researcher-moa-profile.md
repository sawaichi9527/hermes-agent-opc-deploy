# nim-researcher MoA profile（D5 / D5a / D5b，M6b 實測）

**適用 hermes-agent v0.20.0**。OPC-PERSONAL edition 第 8 profile（獨立升格），負責**大規模文獻調研 / 多國來源**（>10 份、跨語），內部走 MoA preset，不直接執行工具。

## 定位

- 只在 **coordinator reroute（D5a）** 時出動：researcher 回報 `evidence_urls` 長度 **>10** → coordinator 下令 → nim-researcher 拿 researcher 已蒐的 source list 當 **bootstrap，不重抓**。
- researcher **不自派** nim（D3 序列化，無 dispatcher）。
- 遠端 NIM 70B+ 只出建議（reference）；本機 agent-a1（aggregator）落地收斂。

## MoA preset（M6b 實測驗證）

```yaml
# config.yaml moa.presets.nim-researcher
preset: nim-researcher
  reference_models:
    - { provider: nvidia, model: meta/llama-3.3-70b-instruct }
  aggregator:
    { provider: custom, model: agents-a1, base_url: http://192.168.23.217:1234/v1 }
  reference_max_tokens: 600
  fanout: user_turn
```

- **provider 用 `nvidia` 而非 `nim`**（實測：`nim` 查 `NIM_API_KEY` 失敗；`nvidia` 讀 `.env` 的 `NVIDIA_API_KEY`）。
- reference 排除 nemotron 系列（NIM 實測 404）。

## 觸發方式（v0.20.0 CLI）

```bash
# one-shot
hermes -p nim-researcher chat -Q -q "<prompt>" -m moa:nim-researcher

# 互動式
hermes -p nim-researcher chat
/moa <prompt>
```

驗證 fan-out / 收斂：查 moa-trace（M6b 已確證 reference fan-out + aggregator 收斂）。

## MoA 觸發上限（D5b，caveat 3 收斂）

Hermes MoA **無原生 per-task cap**。採外部計數：

- 每任務記錄 jobs.json `moa_trigger_count`。
- 上限 **≤3 / task**；超過即停止 escalate，僅用本機 aggregator 收斂。
- NIM 免費額度 40 問/min：序列化 + cap-3 天然遠低於此（雙保險：nim SOUL + jobs.json 額度計欄）。

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

輸出落 `opc/nim-researcher/research-advisory/`。

## 獨立配置要求

- 獨立 timeout / retry / 每日 token cap（jobs.json `daily_token_used`）。
- 失敗隔離：NIM 端點 fail → 降級日常 researcher（見 degradation-matrix）。

## 驗證（M6b PASS）

- preset 建立 + `chat -Q -m moa:nim-researcher` 觸發成功。
- moa-trace 確證 reference fan-out + aggregator 收斂。
- caveat 3 收斂：無原生 cap → jobs.json 計數。

## 安全守則

- NIM key 在 profile `.env`（`NVIDIA_API_KEY`）；**禁 log**。
- 不把 `.env`/token/session dump 放進 git 或 Runes candidates。
