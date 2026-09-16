# Plur 記憶層（D7，M7 實測）

**適用 hermes-agent v0.21.3**。三層記憶堆疊（native + Plur + Runes）的中層：跨角色共享、ACT-R 衰減、中期 lifecycle。

## 組成（M7 實測確認）

| 元件 | 版本 / 型態 | 角色 |
|---|---|---|
|| `plur-hermes` | pip plugin **0.19.4**（2026-08-31 升級自 0.17.2）| 註冊 `pre_llm_call` / `post_llm_call` hooks，自動 learn / inject |
|| `@plur-ai/cli` | npm global **0.19.4**（2026-09-16 升級自 0.9.4）| CLI bridge；`~/.plur/` 儲存 |
|| `~/.plur/` | engrams（2026-09-16 實測：**128 engrams**） | 共享記憶本體 |

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

`plur_status` 回報 engrams 數量（M7：40；2026-08-15 實測 **120**）。

## 使用工具

`plur_learn` / `plur_recall` / `plur_status`（自動 learn/inject 由 plugin hooks 驅動）。Scope：`global` / `user` / `agent:<role>` / `project:<slug>`。

## Scope 紀律（§9 #4 評估結論，2026-08-15）

CLI 0.9.4 無「scope 命中永遠注入」逃生門；recall 的 `--scope` 不過濾（scoped/unscoped 同批）。因此：

- **跨 profile 共享**：改用固定 scope `project:freelancer`（不要散落一堆 `global`）。2026-08-15 現況：global 85 / user 34 / agent:writer 1 / project 0。
- **關鍵長期規則**：`plur promote`（設 retrieval_strength 0.7）或 feedback 強化，避免衰退出注入範圍。
- **中文 statement 帶英文關鍵字**（BGE-small 英文 embedder，#781），提高 recall 命中。
- 既有 `global` engrams **不做 bulk 遷移**（共享 store 改動需謹慎）；新共享 learns 一律 `project:freelancer`。
- P2(d) 跨週複查（約 2026-09-12）：`ENG-2026-0815-001`（agent:writer）/ `ENG-2026-0815-002`（global）是否仍被注入/衰減，複查後刪除測試 engram。

## Source priority（Runes ROADMAP P0.3 擴充）

```text
1. 當下使用者指令 / 當下對話
2. Hermes native memory（runtime/偏好/skill cache，非 canonical）
3. Runes MD Wiki（governed long-term evidence）
4. Plur（學得 conventions，可 decay；與 Runes 衝突時 Runes 為準，標該 engram 待手動 prune）
5. 第三方 RAG / Obsidian
6. Web 公開來源
```

## 兩條整合路徑實驗（2026-09-16，v0.21.3）——原生 MemoryProvider 對 plur 無效

plur-hermes 0.19.x 同時宣告兩個 entry point：`hermes_agent.plugins`（舊插件路徑）與 `hermes_agent.memory_providers`（新原生路徑）。後者透過 config `memory.provider: plur` 啟用，理論上讓 plur 以 Hermes MemoryProvider ABC 的第一方身分出現。

**實測結論：原生 MemoryProvider 路徑對 plur 完全無效，插件路徑才是唯一實際運作的路徑。**

### 實驗與證據
- 2026-09-16 在 secretary profile 加 `memory.provider: plur`（保留 `plugins.enabled: [plur]`，雙路徑並存），觀察 agent.log：
  ```
  WARNING hermes_cli.plugins: Plugin 'plur' tried to register a memory provider 
       that does not inherit from MemoryProvider. Ignoring.
  INFO plur_hermes: PLUR MemoryProvider registered (hermes_agent.memory_providers path)
  ```
- 原始碼實證：Hermes `register_memory_provider()`（`hermes_cli/plugins.py`）有 `_wrong_type` 檢查，要求 provider 必須繼承 `MemoryProvider(ABC)`。但 plur 的 `PlurMemoryProvider`（`plur_hermes/memory_provider.py:397`）是**plain class、故意不繼承 ABC**——這是 zero-dependency guarantee 的設計：讓 plur-hermes 不把 hermes_agent 當硬依賴。
- 結果：原生路徑被 Hermes **忽略**，`_memory_provider` 未被設定；inject/learn/feedback 全部由插件路徑（`plugins.enabled: [plur]`）的 `pre_llm_call` / `post_llm_call` hooks 處理。

### 對現況的影響
| 項目 | 狀態 |
|---|---|
| inject / learn / feedback | ✅ 全部由插件路徑 hooks 處理（唯一實際生效）|
| system_prompt_block()（system prompt 加一行 PLUR status）| ❌ 不出現（原生路徑被忽略）|
| `hermes plugins --memory` 列出 plur | ❌ 不會列出（未成功註冊）|
| `memory.provider: plur` 設定值 | ⚪ **零功能效果**——改了也無用，且 log 多一行 WARNING |

### 決策與維護
- **維持現狀**：`plugins.enabled: [plur]` 保留、`memory.provider` 保持 `''`。
- **不要**設 `memory.provider: plur`——除了 log 多一行 WARNING、無實際效益，反而可能讓未來的操作者誤解「原生路徑已啟用」。
- 這是 plur 團隊的零依賴設計，不是本機環境的問題；多 profile + kanban + L1 記憶層架構**完全不用改**。
- 升級記錄：plur-hermes 0.17.2 → 0.19.4（2026-08-31）、`@plur-ai/cli` 0.9.4 → 0.19.4（2026-09-16）。升級前已完整備份 `~/.plur/` 與 config，128 engrams 零遺失。

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
