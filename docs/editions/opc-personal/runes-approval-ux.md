# Runes 審批 UX（#5 / P3 接線，2026-08-15）

**適用 hermes-agent v0.20.0 + hermes-runes-md-wiki v0.7.6-dev**。runes-holder 僅經 Runes Shield（Python CLI）操作；P0 approve/reject/promote = human-only；審批採「Lark 純文字關鍵字 + SOUL 層象徵 token」；runes 不在調用拓撲軸內，只在記憶生命週期軸上（可選時下沉、缺席時 PLUR 扛責）。

## 雙軌審批

| 軌道 | 對象 | 機制 | 實測狀態 |
|---|---|---|---|
| A | L2 破壞命令（apt upgrade / systemctl stop 核心 / reboot / 改 /etc/） | **Lark 互動卡片** [批准]/[拒絕]/[修改命令] | ✅ M3/M6a 原生支援（Feishu `send_exec_approval`） |
| B | Runes governed write 候選 | **Lark 純文字關鍵字** `批准/拒絕/撤銷 <proposal_id>` + 一次性象徵 token | ✅ P3 接線（2026-08-15） |

L3 毀滅命令（dd of=/dev/、rm -rf /、mkfs、fdisk、shred）由 hermes 硬熔斷，連申請資格都沒。

## Runes 審批關鍵字語法（軌道 B）

使用者透過 Lark 對 secretary 回覆：

```text
【Runes 治理寫入請求】            <- secretary 送出
proposal_id: <id>
target: wiki/freelancer/opc/<role>/...
summary: <一句話摘要>
風險: <風險說明>
回覆「批准 <proposal_id>」同意，或「拒絕 <proposal_id>」駁回。

批准 <proposal_id>               <- 使用者同意（一次）
拒絕 <proposal_id>               <- 使用者駁回
撤銷 <proposal_id>               <- audit jsonl 記錄前撤銷
```

- 批准後 secretary 產生**一次性象徵 token**（D20，SOUL 層，不需自寫基礎設施）。
- 流程：secretary → coordinator（handoff 帶 token）→ runes-holder（單次用、用後即棄、不回傳、不落檔）。

## token 生命週期

```text
格式:  R-<ts>-<4hex>             例: R-20260815-3f9a
來源:  secretary（使用者「批准」後產生）
傳遞:  secretary -> coordinator handoff（approval_token 欄）-> runes-holder
使用:  單次；runes-holder 收到才視為 governed write 已核准
銷毀:  用後即棄；不 echo、不復用、不寫入 git/wiki/jobs.json
留存:  僅 audit jsonl 的 token_id 欄位
```

無 token 的 handoff = 寫入未核准 → runes-holder 回 coordinator「無 Runes 治理佐證 / awaiting approval」。

## runes-holder 工具白名單（唯讀）

runes-holder 只允許執行下列 shield 唯讀 CLI（wiki repo root = `~/workspace/hermes-runes-md-wiki`）：

```text
discovery:
  python3 tools/runes_shield/runes_shield_tool_index.py list --format json
  python3 tools/runes_shield/runes_shield_tool_index.py blocked --format json

proposal registry:
  python3 tools/runes_shield/proposal_registry.py list --format json
  python3 tools/runes_shield/proposal_registry.py show <id> --format json
  python3 tools/runes_shield/proposal_registry.py show <id> --include-payload --format json

review queue:
  python3 tools/runes_shield/proposal_review_queue.py list --format json
  python3 tools/runes_shield/proposal_review_queue.py show <id> --format json
  python3 tools/runes_shield/proposal_review_queue.py show <id> --include-payload --format json
```

**硬邊界（永不 invoke）**：`proposal.apply` / `proposal.approve` / `proposal.promote` / `wiki.write` / `database.mutate`。

**審批 verdict 實測（K6，2026-08-15）**：`hermes -p runes-holder approvals test` 對上述命令（含 `cd … && python3 …` compound、絕對路徑、相對路徑）全數 **allow**（no guard matched）。**無需修改 runes-holder approvals allowlist**。

## audit jsonl

路徑 `~/.hermes/opc/runes-audit.jsonl`（D16）。因 `forge`/`inscribe` 尚未實作（#8），寫入以意圖記錄替代：

```jsonl
{"ts": "...", "action": "governed_write_intent", "target": "wiki/freelancer/opc/...", "approved_by": "user", "token_id": "R-<ts>-<4hex>", "profile": "runes-holder", "notes": "awaiting forge/inscribe; intent only"}
```

禁記 secrets / tokens（token_id 短碼除外）。

## 下沉 / 回退（記憶生命週期軸）

```text
runes 可用 + 已批准  -> 候選下沉（shield 唯讀確認 + audit 意圖記錄）
runes 不可用/未同意  -> 不硬寫 wiki；回 coordinator 標「無 Runes 治理佐證」
                       -> 請求端 profile 以 PLUR / native memory 扛責
```

## 唯一路由

secretary 與所有 worker 只能經 **coordinator** 到 runes-holder（retrieve 亦同）。worker 不得直接呼叫 runes-holder。

## 驗證（2026-08-15 P3 接線）

- 3 SOUL（coordinator / secretary / runes-holder）同步 K6，ping PASS。
- shield 6 支唯讀工具 `allow` verdict。
- e 下沉測試：candidate → coordinator → runes-holder（shield list）→ secretary 關鍵字審批 → token → audit jsonl 意圖記錄 PASS（不實際寫 wiki）。
- f 故障回退測試：runes-holder/wiki 不可用 → coordinator 標「無 Runes 治理佐證」→ PLUR recall 提供同主題 PASS。

## 剩餘（#8 runes 收尾）

實際 wiki 寫入待 `forge` / `inscribe` 實作；`indexes/links` 補實待 runes 工具層可用。
