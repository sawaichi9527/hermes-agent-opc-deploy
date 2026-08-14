# A2A 擴展面（未來 Pi 5）（D6 / D21）

**適用 hermes-agent v0.20.0**。A2A 在 OPC 中**開啟但僅定位為未來跨機擴展面**；現期同機角色間**不用 A2A**。

## 決策（D6 / D21）

- 同機角色間：序列路由（secretary → coordinator → 單一 worker → merge）。
- **cron 凌晨場景也走同機序列，不用 A2A**（D21）。
- **只有跨機**（Pi 5 Hermes peer）才用 A2A。

## coordinator 預留設定

```yaml
# coordinator config.yaml
a2a_agents:
  pi5-helper:
    url: "http://pi5.local:9900"
    auth: { type: bearer, token: "..." }
    capabilities: [...]
```

Inbound 環境變數（原生支援）：`A2A_BEARER_TOKEN` + `A2A_HOST` + `A2A_PEER_TOKENS`。

## 六層安全（hermes 原生）

1. 預設綁 `127.0.0.1`
2. per-peer token
3. prompt-injection filter
4. 出站 redact
5. audit jsonl
6. anti-loop

## 使用（未來 Pi 5 上線後）

```bash
a2a_discover(pi5.local:9900)   # 看 Agent Card
a2a_call(pi5-helper, ...)      # 跨機派單
```

## Pi 5 記憶策略（建議）

- 只 Plur 共享（git 同步 `global` / `project:opc` scope）。
- Runes **不進** Pi 5。

## 狀態

- **首期不實作**（不在 M0–M8 里程碑）。
- coordinator SOUL 僅預留 A2A 邊界與 awareness，無實際呼叫。
