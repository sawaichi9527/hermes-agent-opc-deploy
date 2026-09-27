# Gateway 架構：multiplexing（default-profile multiplexer 統一服務）

**適用 hermes-agent v0.21.5+3435（2026-09-27）。** 本檔是「gateway 如何服務各 profile」的單一事實來源，取代 `session-mechanism.md` §1、`cron-governance.md` M3、`setup-feishu-gateway.sh` 描述的 **M3 單 profile gateway 架構**。

## TL;DR（2026-09-27 實測）

```text
default-profile multiplexer（hermes-gateway.service, systemd user, PID 10106）
  └─ 統一服務全部 9 個 profile：
       default, aeon-builder, builder, coordinator,
     opencode-researcher, researcher, runes-holder, secretary, writer
```

- `gateway.multiplex_profiles: true`（`~/.hermes/config.yaml`）。
- secretary **不再**有獨立 gateway process / systemd service。它的 Lark websocket 由 host multiplexer 接管。
- 重啟 PC 後 `hermes-gateway.service`（default）自動拉起，9 profile 全服務。

## 架構演進

| 階段 | 架構 | secretary 執行形態 | default gateway |
|---|---|---|---|
| **M3（2026-08-14）** | 單 profile gateway | `hermes-gateway-secretary.service` + systemd linger（常駐） | 停用（disable） |
| **multiplex（2026-09-27）** | default multiplexer 統一服務 | 由 host multiplexer 服務（無獨立 service） | 啟用，`multiplex_profiles: true` |

M3 架構的 `hermes-gateway-secretary.service` 已在 migrate 時 **stop + uninstall**（service file 已刪）。剩餘唯一痕跡：`~/.config/systemd/user/hermes-gateway-secretary.service.d/` drop-in 目錄（`path-plur.conf` 等）仍殘留，**無害但可清理**。

## 遷移過程（2026-09-27）

```bash
hermes gateway migrate --multiplex
```

執行結果（已驗證）：
- ✓ `default: gateway.multiplex_profiles: true`
- ✓ secretary standalone gateway（pid 2045）stop + systemd user service uninstall
- ✓ default gateway 經 systemd restart，verify 服務 9 profiles
- ✓ 重啟後 `hermes-gateway.service` active，PID 10106

## Session 持久性（未變）

M3 架構與 multiplex 架構的 **session 生命週期行為完全相同**——變的只是 gateway 由誰執行：

- **secretary = 唯一持久 session profile**（綁 Lark chat）。session key `agent:main:feishu:dm:oc_<chat_id>`，`get_or_create_session()` 找到即沿用 → 同一 Lark DM 共用同一 session。`/new` = `force_new`。
  - 註：單 profile gateway 與 multiplexing gateway 都用 `agent:main` namespace（session-mechanism.md §1）。
- **coordinator / 所有 worker = oneshot**（`-z`，一任務一 session）。
- **cron = `cron_<jobid>_<ts>` 新 session**。

資料存放不變：各 profile 獨立 `state.db`（`~/.hermes/profiles/<role>/state.db`）。

## 驗證方法

```bash
# gateway 狀態（應顯示 default-profile multiplexer 服務）
hermes gateway status

# systemd service
systemctl --user is-active hermes-gateway.service   # active

# config 確認
grep -n multiplex_profiles ~/.hermes/config.yaml     # true

# 重啟後自動恢复：hermes-gateway.service 為 systemd user service，StartLimitIntervalSec=0, Restart=always
```

## 清理建議（可選）

```bash
# 殘留的 secretary 獨立 gateway drop-in 目錄（無害，migrate 未清）
rm -rf ~/.config/systemd/user/hermes-gateway-secretary.service.d
systemctl --user daemon-reload
```

## 重灌流程更新（對應 README §重灌流程 step 7）

舊：「重啟 secretary gateway；Lark 冒煙測試」
新：**default multiplexer 自動服務 secretary**（`hermes-gateway.service` systemd user，`multiplex_profiles: true`）。重啟後無需手動重啟任何 gateway；直接 Lark 冒煙測試 secretary。

---

*本檔取代 session-mechanism.md §1、cron-governance.md M3、setup-feishu-gateway.sh 的 gateway 描述。M3 單 profile gateway 架構保留於 archive。*
