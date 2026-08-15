# SOUL.md vs AGENTS.md（per-agent 設定邊界）

**確認日期**：2026-08-16。適用 hermes-agent **v0.20.1**。

## 分工（hermes 源碼機制，`agent/agent_init.py:577-578`）

```text
SOUL.md  = per-profile identity（身份/人格）：由 profile 目錄載入
AGENTS.md / .hermes.md / CLAUDE.md / .cursorrules = project context（專案規則）：
           由 cwd / HERMES_HOME 載入，非 profile 層級
```

- 兩者獨立載入；`--ignore-rules` / `HERMES_IGNORE_RULES=1` 同時略過兩者。
- SOUL.md 的 per-profile 載入由 `hermes profile` 機制處理（`hermes_cli/main.py`：profile 目錄內 `SOUL.md` 決定人格）。

## 對 deploy repo 的意義

- **8 個 profile 的身份規則載體只有 `SOUL.md.template`**（`editions/*/profiles/<role>/SOUL.md.template`，v0.20.1 已 refine）。
- **AGENTS.md 不屬於 `editions/*/profiles/*` 的模板範圍**——它是專案層級檔案，放在 agent 的工作目錄（cwd）而非 profile 目錄。
- 目前 deploy repo、8 個 profile 目錄內皆無 AGENTS.md，此為正常狀態，**無需新增或修改**。

## 若日後想給某 worker 專案層級指示

在該 worker 的**工作目錄**放 `AGENTS.md` / `.hermes.md`（二者同等級、取先命中者），由 hermes 在該 cwd 執行時自動載入；不經 profile 模板、不進 deploy repo 的 editions 樹。cron 任務可用 `--cwd` 指定載入目錄（`hermes_cli/subcommands/cron.py`）。
