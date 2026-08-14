# jobs.json 可觀測性（G-B2/B3/B4，M4 實測）

**適用 hermes-agent v0.20.0**。`~/.hermes/opc/jobs.json` 是 OPC 的任務可觀測性單一事實來源。M4 已建立並含 v4.1 欄位。

## 路徑

```text
~/.hermes/opc/jobs.json
```

初始化：`bash scripts/jobs-json-init.sh`。

## 每任務欄位（v4.1）

```json
{
  "task_id": "uuid",
  "profile": "builder",
  "model_used": "agent-a1",
  "started_at": "2026-08-14T21:00:00+08:00",
  "last_ping_at": "2026-08-14T21:01:00+08:00",
  "status": "running",
  "evidence_urls": [],
  "approval_state": "pre_approved",
  "host": "k6"
}
```

計數欄：
- `moa_trigger_count` — nim-researcher 每任務 MoA 觸發數（**≤3**，D5b / caveat 3）。
- `daily_token_used` — 每日 token cap（G-B2）。

## approval_state（D15 / D16）

```text
pre_approved   # 排程任務走免審批通路
pending        # L2 HITL 等待 Lark 卡片回應
approved       # 卡片批准後（D20 token 釋放）
rejected       # 卡片駁回
```

## 寫入守則

- **flock 寫鎖**（G-B3）：並發寫入需加鎖，避免 jobs.json 損毀。
- **secret redaction 強制**（G-B4 / D19）：**禁記** base_url token / SSH key / password；只記 host 名 + status。
- 時戳統一 ISO-8601 + 時區。

## 用途

| 消費者 | 用途 |
|---|---|
| secretary | Lark 回覆風險暴露欄；卡任務狀態 |
| coordinator | 路由決策（evidence_urls 長度）、moa_trigger_count 判定 |
| aeon-builder | 派工前寫 model_used（ACTUAL_MODEL） |
| governance audit cron | 比對 seeds/suggestions → 卡片審批 |

## 驗證（M4 PASS）

- jobs.json 建立於 `~/.hermes/opc/jobs.json`（v4.1 欄位完整）。
- coordinator SOUL 讀取 + D5a reroute 驗證（12-sources → nim reroute 正確）。
- cron 端到端 succeeded + deliver origin。
