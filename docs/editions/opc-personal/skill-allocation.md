# Skill Allocation / Plugin Inventory（OPC-PERSONAL, v0.20.1 / Hermes v0.20.1）

> 2026-08-16 盤點與分配結果。K6（eye@192.168.23.214, hostname=Freelancer）實際同步完成。
> Hermes v0.20.0 (2026.8.3) → **v0.20.1 (2026.8.13)**；ppt-master v4.5.0 → **v4.7.0**。

## 原則

- Profile 層 `skills/` 使用 **symlink** 指向全域 `~/.hermes/skills/<category>/<skill>`。
- 保留 `.no-bundled-skills` 標記（避免 `hermes update` 自動種子塞入全部 bundled skills）。
- 只分配職責明確需要的 skill，避免 context 負擔（D26 精簡精神）。
- 所有 profile 一律保留 `plur-memory.SKILL.md`。

## 分配表

| Profile | 分配 skill（symlink → 全域路徑） |
|---|---|
| **researcher** | `web-search-strategies` (research/), `arxiv` (research/), `grounded-citations` (research/) |
| **nim-researcher** | `web-search-strategies`, `arxiv`, `ai-agent-comparison` (research/), `grounded-citations` |
| **writer** | `ppt-master`（D17, 原有）, `ppt-master-config`, `docx` (productivity/), `humanizer` (creative/) |
| **builder** | `test-driven-development`, `systematic-debugging`, `spike` (software-development/), `github-repo-management`, `github-pr-workflow` (github/) |
| **aeon-builder** | `systematic-debugging`, `spike` |
| **runes-holder** | `hermes-runes-wiki` (note-taking/) |
| **secretary** | `cron-intelligence-scan` |
| **coordinator** | （無額外 skill，純路由） |

> `ppt-master-config` 非手動分配，為 ppt-master skill 自身的 config 子目錄（skill 載入時自動可見）。

## Plugin Inventory（Hermes plugins）

| Plugin | 版本 | 狀態 | 備註 |
|---|---|---|---|
| `platforms/feishu` | bundled 1.0.0 | enabled | secretary gateway 用（全域 + secretary config） |
| `plur` | 0.17.2 | enabled | 全部 8 profile；`pip` 最新版 |
| `web/ddgs` | bundled 1.0.0 | enabled | secretary；升級後 plugin name 顯示為 `web-ddgs`，config 舊別名 `web/ddgs` 仍被解析（web.backend: ddgs 正常） |
| `rtk-rewrite` | 0.1.0 | **removed (2026-08-16)** | rtk binary 不在 PATH，hook 未註冊（失效）；已 `hermes plugins remove` + config 清殘留 |

## 驗證（2026-08-16）

- 8 profile ping 全 PASS（升級後）。
- profile `skills/` symlink 指向正確（researcher/nim-researcher/writer/builder/aeon-builder/runes-holder/secretary 確認）。
- skill 載入實測：researcher/nim-researcher/writer/builder/runes-holder/secretary/aeon-builder 均回報所分配的 skill。
- `hermes doctor` 無 config migration issue（34→37）。
- ppt-master `attribution_guard.py` PASS（GUARD_OK）。
- gateway（secretary）重啟後 Lark websocket connected，無 rtk warning。

## Rollback

- skill symlink：刪除對應 profile `skills/<name>` 即回退，不動 SOUL/config。
- ppt-master：`cd ~/.hermes/skills/ppt-master && git checkout v4.5.0`。
- Hermes：備份 `D:\Workspace\projects\hermes-backup\plugin-skill-session-20260816\`（含 configs/skills tar + sha256 + manifest）。
