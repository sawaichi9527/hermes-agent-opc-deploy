# Skill Allocation / Plugin Inventory（OPC-PERSONAL, v0.20.1 / Hermes v0.20.1）

> 2026-08-16 盤點與分配結果。K6（eye@192.168.23.214, hostname=Freelancer）實際同步完成。
> Hermes v0.20.0 (2026.8.3) → **v0.20.1 (2026.8.13)**；ppt-master v4.5.0 → **v4.7.0**；rtk binary v0.42.4 → **v0.45.0**；rtk-hermes → **v1.2.3 (PyPI)**。

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
| `web/ddgs` | bundled 1.0.0 | enabled | 全域 config 仍列出但**不再實際作為主要 backend**（web backend 本地化後保留作 legacy fallback） |
| `web-searxng` | bundled 1.0.0 | enabled | 搜尋 3 角色 `web.search_backend`（K6 :8088） |
| `web-firecrawl` | bundled 1.0.0 | enabled | 全域 fallback + 搜尋 3 角色 `web.extract_backend`（K6 :3002 self-host） |
| `rtk-rewrite` | **1.2.3** (PyPI) | enabled | **2026-08-16 重裝**：官方 PyPI 套件 `rtk-hermes` v1.2.3（entry point `rtk-rewrite | rtk_hermes | 1.2.3 | True`）+ rtk binary v0.45.0（`~/.local/bin/rtk`）。先前移除的舊 0.1.0 目錄 plugin 因 rtk binary PATH 問題失效。 |

## lark-cli 整合（2026-08-16）

**背景**：hermes 內建 feishu 工具僅 `feishu_doc_read` + drive 評論（5 支）；`larksuite/cli`（lark-cli）補足「以 user 身份操作 Lark 生態」——200+ 命令、18 業務域、26 Agent Skills。

- **安裝**：`npx @larksuite/cli@latest install` → **v1.0.87**（Go binary 於 npm package `bin/lark-cli`；skills 裝 `~/.agents/skills/`）。
- **PATH**：`/usr/local/bin/lark-cli` symlink → `~/.local/bin/lark-cli` wrapper（設 `HOME=/home/eye` 讓 lark-cli 讀真實 config；因 agent 執行環境 HOME 被 hermes 重定向且 PATH 不含 `~/.local/bin`）。
- **認證**：`config init --new --force-init --brand lark` → `config bind --identity user-default`（綁 secretary hermes app `cli_aaabd1f1bc38de18`）→ `auth login --recommend`（user OAuth）。bind 在 agent context（HERMES_HOME）下需 user 確認。
- **掛載**：secretary（lark-shared/im/calendar/doc/drive/task）+ writer（lark-shared/doc/drive/sheets/slides/markdown），symlink → `~/.agents/skills/<name>`。
- **驗證**：secretary/writer agent 執行 `lark-cli contact +search-user` 回報 open_id/email PASS。
- **安全**：lark-cli 以 user 身份操作（可讀寫個人資源）；官方警告勿分享 bot/勿入群組；風險控制維持預設。

## Web Backend 本地化（2026-08-16）

**決策**：捨 ddgs（免費 rate limit 不穩定），改用 K6 本機部署的 SearXNG（`127.0.0.1:8088`）+ Firecrawl（`127.0.0.1:3002`）。

**機制**（`agent/web_search_registry.py`）：backend 解析優先序 `search_backend`/`extract_backend` → `web.backend` → env 自動偵測。SearXNG search-only（`supports_extract=False`）不能當共用 fallback；Firecrawl search+extract 皆可 → 全域 fallback = firecrawl。env 為 **profile-scoped**（`agent/secret_scope.py`：profile 執行從該 profile `.env` 建 scope）→ 變數寫入各 profile `.env`。

**設定**：
```yaml
# 全域 config.yaml（fallback）
web:
  backend: firecrawl

# 搜尋 3 角色（researcher / nim-researcher / secretary）config.yaml
web:
  search_backend: "searxng"
  extract_backend: "firecrawl"
```
```bash
# 8 profile .env（fallback 全角色可用）
FIRECRAWL_API_URL=http://127.0.0.1:3002
# 搜尋 3 角色 .env 另加
SEARXNG_URL=http://127.0.0.1:8088
```
Firecrawl self-host `USE_DB_AUTHENTICATION=false` → 免 API key。plugins：`web-searxng` + `web-firecrawl` enabled。

**Docker 版本（2026-08-16 升級）**：
- SearXNG：v2026.5.29 → **v2026.8.14**（`docker compose up -d --force-recreate`；settings.yml bind mount 保留）
- Firecrawl：v2.11.0 時期 → **BUILD_SHA `f748af9d`（2026-08-15）**（全 stack `--force-recreate`；fdb/redis/rabbitmq volume 保留）
- 升級後 search/scrape 實測 PASS、researcher web_search 正常。

## 驗證（2026-08-16）

- 8 profile ping 全 PASS（升級後）。
- profile `skills/` symlink 指向正確（researcher/nim-researcher/writer/builder/aeon-builder/runes-holder/secretary 確認）。
- skill 載入實測：researcher/nim-researcher/writer/builder/runes-holder/secretary/aeon-builder 均回報所分配的 skill。
- `hermes doctor` 無 config migration issue（34→37）。
- ppt-master `attribution_guard.py` PASS（GUARD_OK）。
- gateway（secretary）重啟後 Lark websocket connected，無 rtk warning。
- **Web backend 實測**：researcher 回報「搜尋使用本地 SearXNG (localhost:8088) + 內容經 Firecrawl (localhost:3002) 完整抓取」；nim-researcher/writer（fallback firecrawl）搜尋成功；cron 2 jobs active。
- **rtk 重裝實測**：`rtk rewrite` 正常；plugin 載入無 warning；secretary ping PASS。

## Rollback

- skill symlink：刪除對應 profile `skills/<name>` 即回退，不動 SOUL/config。
- ppt-master：`cd ~/.hermes/skills/ppt-master && git checkout v4.5.0`。
- Web backend：還原 profile `config.yaml.bak-web` + `.env.bak-web`；或 `hermes plugins disable web-searxng web-firecrawl`。
- rtk：`$HERMES_PY -m pip uninstall rtk-hermes` + 全域 config 移除 `rtk-rewrite`；rtk binary 還原 `rtk.bak.v0.42.4`。
- Hermes：備份 `D:\Workspace\projects\hermes-backup\plugin-skill-session-20260816\`（含 configs/skills tar + sha256 + manifest）。
