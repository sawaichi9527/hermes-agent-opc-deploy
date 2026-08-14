# 三級破壞性白名單（D18，M3 / M6a 實測）

**適用 hermes-agent v0.20.0**。OPC-PERSONAL edition 對 builder / aeon-builder 終端指令的分級管制。

## 三級定義

| 級別 | 範例 | 處置 |
|---|---|---|
| **L3 毀滅** | `dd of=/dev/*`、`rm -rf /`、`mkfs`、`fdisk`、`shred` | **硬熔斷**：AI 連申請資格都沒，直接回報不支援 |
| **L2 破壞** | `apt upgrade/dist-upgrade`、rm 非暫存、`systemctl stop` 核心服務、reboot、改 `/etc/` | **強制 HITL 反問 Default-On**：Lark 卡片 [批准執行]/[拒絕]/[修改命令] → 批准才釋放一次性 token（D20） |
| **L1 安全** | `apt update`、`git clone`、`cat`、`grep`、`systemctl status` | 自主執行 |

## hermes 落地方式（M3 / M6a 實測，caveat 1 收斂）

**不需 shell wrapper / 自寫 plugin。** hermes 原生：

- **L3** = `HARDLINE_PATTERNS`（rm -rf /、mkfs、dd of=/dev/ 等 → **hardline-deny，連 --yolo 都擋**）+ user `approvals.deny` glob（fdisk 等補強，亦不可繞過）。
- **L2** = `DANGEROUS_PATTERNS`（systemctl stop 等 → ask-approval）+ Feishu 互動卡片按鈕審批（`send_exec_approval` 原生支援，caveat 2 收斂：不需自寫 plugin）。
- 初始化：`bash scripts/approvals-deny-init.sh`（寫入 D18 L3 清單至 `approvals.deny`）。

## 已知缺口（G-D18）

- hermes 內建 pattern **不含 `apt upgrade`**（會 allow）；藍圖定義其 L2。
- hermes 無 user 擴充 ask-approval pattern 的公開機制（只有 deny = 硬擋）。
- **L2 補法**：coordinator/builder SOUL 明訂「apt upgrade/dist-upgrade 屬 L2 需 HITL」；或視需加 `approvals.deny`（會升級成硬擋）。

## 驗證（M6a PASS）

| 測試 | 結果 |
|---|---|
| `reboot` | hardline-deny |
| `systemctl stop` | ask-approval（L2 卡片） |
| `mkfs` / `fdisk` | deny（L3） |
| approvals + security 同步 | PASS |

## 相關決策

- D20 approval token：L2 卡片批准才釋放一次性短 TTL token；單次用、用後即毀。
- D19：SSH 憑證 = Secrets Store + 一次性 session 注入；**禁入 builder/.env**。
