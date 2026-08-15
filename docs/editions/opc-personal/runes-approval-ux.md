# Runes 審批 UX（#5 / P3 接線，2026-08-15）

**適用 hermes-agent v0.20.0 + hermes-runes-md-wiki v0.7.6-dev**。runes-holder 對 `hermes-runes-md-wiki` 的**所有操作一律透過 runes-shield 層提供的 native wrapper**（見下），P0 approve/reject/promote = human-only；審批採「Lark 純文字關鍵字 + SOUL 層象徵 token」；runes 不在調用拓撲軸內，只在記憶生命週期軸上（可選時下沉、缺席時 PLUR 扛責）。

## Native Wrapper ONLY 原則

runes-holder 只能經由 runes-shield 層既有的 native wrapper CLI 操作 wiki：

- **不得**直接讀/寫 `wiki/*.md`（禁止 `cat >` / `echo >>` / `sed -i` / `perl -i` / python `write_text` 等 ad-hoc 方法）。
- **不得**呼叫未在白名單的 CLI（含舊 scaffold `bin/hermes-runes forge/evoke/inscribe` —— 未實作的舊介面）。
- 寫入僅在 secretary 審批 + handoff 攜帶 token 時執行（`--write`）。
- 白名單 wrapper 不足時，停下來回報 coordinator/secretary，不繞過護盾。

## 雙軌審批

| 軌道 | 對象 | 機制 | 實測狀態 |
|---|---|---|---|
| A | L2 破壞命令（apt upgrade / systemctl stop 核心 / reboot / 改 /etc/） | **Lark 互動卡片** [批准]/[拒絕]/[修改命令] | ✅ M3/M6a 原生支援（Feishu `send_exec_approval`） |
| B | Runes governed write 候選 | **Lark 純文字關鍵字** `批准/拒絕/撤銷 <proposal_id>` + 一次性象徵 token + **forge native wrapper 執行狀態變更** | ✅ P3 接線（2026-08-15） |

L3 毀滅命令（dd of=/dev/、rm -rf /、mkfs、fdisk、shred）由 hermes 硬熔斷，連申請資格都沒。

## Runes 審批關鍵字語法（軌道 B）

使用者透過 Lark 對 secretary 回覆：

```text
【Runes 治理寫入請求】            <- secretary 送出
proposal_id: <id>
target: wiki/freelancer/forge-inbox/<file>.md
summary: <一句話摘要>
風險: <風險說明>
回覆「批准 <proposal_id>」同意，或「拒絕 <proposal_id>」駁回。

批准 <proposal_id>               <- 使用者同意（一次）
拒絕 <proposal_id>               <- 使用者駁回
撤銷 <proposal_id>               <- 狀態變更執行前撤銷
```

- 批准後 secretary 產生**一次性象徵 token**（D20，SOUL 層，不需自寫基礎設施）。
- 流程：secretary → coordinator（handoff 帶 token + proposal path + 決策）→ runes-holder 以 **forge native wrapper** 執行 `approve`/`reject`。
- secretary 自己**不 invoke** runes shield / forge。

## token 生命週期

```text
格式:  R-<ts>-<4hex>             例: R-20260815-3f9a
來源:  secretary（使用者「批准」後產生）
傳遞:  secretary -> coordinator handoff（approval_token 欄）-> runes-holder
使用:  單次；runes-holder 收到才視為 governed write 已核准
銷毀:  用後即棄；不 echo、不復用、不寫入 git/wiki/jobs.json
留存:  僅 operation manifest / audit jsonl 的 token_id 欄位
```

無 token 的 handoff = 寫入未核准 → runes-holder 回 coordinator「無 Runes 治理佐證 / awaiting approval」。

## runes-holder 工具白名單（native wrapper 全表）

wiki repo root = `~/workspace/hermes-runes-md-wiki`。

### 唯讀 / 查詢（免審批）

```text
discovery:
  python3 tools/runes_shield/runes_shield_tool_index.py list --format json
  python3 tools/runes_shield/runes_shield_tool_index.py blocked --format json

proposal registry / review queue:
  python3 tools/runes_shield/proposal_registry.py list|show [--include-payload] <id> --format json
  python3 tools/runes_shield/proposal_review_queue.py list|show [--include-payload] <id> --format json

shield invocation / decision store:
  python3 tools/runes_shield/runes_shield_invocation.py discover --format json
  python3 tools/runes_shield/runes_shield_invocation.py invoke <tool> [--proposal-id <id>] --format json
  python3 tools/runes_shield/proposal_attunement_decision.py list --format json
  python3 tools/runes_shield/proposal_attunement_decision.py show <proposal_id> --format json
```

### 治理寫入（僅審批 + token 後執行）

```text
建立 draft proposal:
  python3 tools/importer/forge.py create-flat --project freelancer --title "<title>" \
    --body "<body>" --proposal-type agent_memory --proposed-by <role> --provenance agent_cli \
    --confidence 0.5 --trust-class unverified --write --json
  # 或現成入口：
  ./bin/hermes-agent-propose-memory --project freelancer --title "<title>" --body "<body>" --write --json

人為決策（狀態變更）:
  python3 tools/importer/forge.py approve --path wiki/freelancer/forge-inbox/<file>.md --json
  python3 tools/importer/forge.py reject --path wiki/freelancer/forge-inbox/<file>.md --reason "<reason>" --json

人為決策記錄（shield 側補充，可選）:
  python3 tools/runes_shield/proposal_attunement_decision.py record <proposal_id> \
    --decision approved|rejected --reviewer user --note "<note>"

結構化審計持久化:
  python3 tools/runes_shield/runes_shield_audit_persistence.py --request <session.json> --write
```

**硬邊界（永不 invoke）**：`proposal.apply` / `proposal.promote` / `wiki.write` / `database.mutate` 及舊 scaffold `bin/hermes-runes forge|evoke|inscribe`。

**審批 verdict 實測（K6，2026-08-15）**：`hermes -p runes-holder approvals test` 對唯讀 + 全部寫入命令（create-flat / propose-memory / approve / reject / M42 record / M54 audit）**全數 allow**（no guard matched）。**無需修改 runes-holder approvals allowlist**。

## write_guard（P0 寫入邊界）

`tools/importer/write_guard.py`：`assert_p0_write_allowed` 限制寫入只能落在 `wiki/<project>/forge-inbox/*.md`（實測 forge-inbox 外 → `WriteGuardError` 拒絕）；`file_lock` 防併發；`new_operation_id` 產生 op id。forge-inbox 內容是 draft / untrusted，不進 trusted memory；reviewed 內容才屬 wiki 其他位置。

## 審計

每次 forge 寫入（create-flat / approve / reject）自動在 `var/operations/<op_id>.json` 寫 **operation manifest**（原生審計）。可再以 `runes_shield_audit_persistence.py --write` 落結構化 JSONL（`logs/runes_shield/audit/`）。`~/.hermes/opc/runes-audit.jsonl` 保留為跨機輕量補充記錄。禁記 secrets（token_id 短碼除外）。

```jsonl
{"ts": "...", "action": "governed_write", "target": "wiki/freelancer/forge-inbox/<file>.md", "op": "forge.approve", "operation_id": "forge-approve-...", "approved_by": "user", "token_id": "R-<ts>-<4hex>", "profile": "runes-holder", "notes": "..."}
```

## 下沉 / 回退（記憶生命週期軸）

```text
runes 可用 + 已批准  -> 候選下沉：forge create-flat 建 draft -> approve/reject 狀態變更
                       -> operation manifest 審計（真實寫入，非意圖）
runes 不可用/未同意  -> 不硬寫 wiki；回 coordinator 標「無 Runes 治理佐證」
                       -> 請求端 profile 以 PLUR / native memory 扛責
```

## 唯一路由

secretary 與所有 worker 只能經 **coordinator** 到 runes-holder（retrieve 亦同）。worker 不得直接呼叫 runes-holder。

## 驗證（2026-08-15 P3 接線）

- 3 SOUL（coordinator / secretary / runes-holder）同步 K6（backup `.bak.20260815-154055`），ping PASS。
- 全部白名單命令（唯讀 + 寫入）`approvals test` = **allow**。
- **e 下沉測試（真實版）**：runes-holder 以 forge native wrapper 執行 `create-flat --write` 建 draft（`status: draft` + manifest）→ 執行 `forge.py approve`（`status: draft→approved` + manifest `forge-approve-*.json`）→ 全鏈路 PASS；測試產物已清理。
- **f 故障回退測試**：runes-holder/wiki 不可用 → coordinator 標「無 Runes 治理佐證」+ 不假裝 PLUR 替代治理證據 PASS。

## 剩餘（#8）

`tools/importer/forge.py` P0 寫入路徑已實作；剩舊 `bin/hermes-runes forge/inscribe`（M15.3 scaffold）未實作但**禁用作路徑**。`indexes/links` 補實待 runes 工具層可用。
