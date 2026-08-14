# Plur 記憶層（D7，M7 實測）

**適用 hermes-agent v0.20.0**。三層記憶堆疊（native + Plur + Runes）的中層：跨角色共享、ACT-R 衰減、中期 lifecycle。

## 組成（M7 實測確認）

| 元件 | 版本 / 型態 | 角色 |
|---|---|---|
| `plur-hermes` | pip plugin **0.17.2** | 註冊 `pre_llm_call` / `post_llm_call` hooks，自動 learn / inject |
| `@plur-ai/cli` | npm global **0.9.4**（既有） | CLI bridge；`~/.plur/` 儲存 |
| `~/.plur/` | engrams（M7 實測：**40 engrams / 1224 episodes**） | 共享記憶本體 |

> **skill vs pip 修正**：plur-memory 是 hermes **skill 形態**（`~/.hermes/skills/plur-memory.SKILL.md`，M0 確認）；`plur-hermes` 是 **pip plugin**（M7 補裝，原缺 Hermes plugin）。兩者都需存在。

## 啟用（v0.20.0）

```bash
pip install plur-hermes            # 0.17.2；若已裝但缺 Hermes plugin 則重裝補齊
npm i -g @plur-ai/cli              # 既有

# 8 profiles 全部啟用 plugin
hermes -p <role> config set plugins.enabled plur    # 每個 profile

# 驗證：每個 profile 都看得到 plur 工具
hermes -p <role> tools list | grep plur
```

`plur_status` 回報 engrams 數量（M7：40）。

## 使用工具

`plur_learn` / `plur_recall` / `plur_status`（自動 learn/inject 由 plugin hooks 驅動）。Scope：`global` / `project:opc` / `local`。

## Source priority（Runes ROADMAP P0.3 擴充）

```text
1. 當下使用者指令 / 當下對話
2. Hermes native memory（runtime/偏好/skill cache，非 canonical）
3. Runes MD Wiki（governed long-term evidence）
4. Plur（學得 conventions，可 decay；與 Runes 衝突時 Runes 為準，標該 engram 待手動 prune）
5. 第三方 RAG / Obsidian
6. Web 公開來源
```

## 備份策略

- **一次性快照至本機**（M7 已做：`m7-plur-snapshot-*.tar.gz` 拉回 `D:\Workspace\projects\hermes-backup\`，sha256 驗證）。
- **定期備份暫不採用**（個人使用定位 D10）。
- ACT-R 衰減下靜默行為漂移 → 靠一次性快照 + 手動抽檢兜底；自動 prune 降為手動觀察。

## 驗證（M7 PASS）

- 8 profiles `plugins.enabled: plur` 全啟用。
- 全 profile 見 plur + plur-meta 工具；`plur_status` = 40 engrams。
- 一次性快照 sha256 對照 MATCH。

## 待 live 驗證（開放問題 4）

跨 profile 共享與 ACT-R 衰減實際行為仍需 live verify。

## 安全守則

- `~/.plur/` 含於全量存檔即可；**不** commit 至 git。
- 不把 engrams/session 內容複製進 deploy repo。
