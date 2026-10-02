# Cron external worker interpreter fix（re-exec 根因版）

**日期：** 2026-10-01
**嚴重度：** 高（定向情報推送 job 執行永遠 `unknown`，Lark 情報推送中斷）
**Patch commit（hermes-agent source）：** `069b677d46`（本地，未 push upstream）
**取代：** `cron-ruamel-interpreter-fix.md`（session 20 的 venv-interpreter workaround，commit `0df6ea6e84`）
**適用版本：** v0.21.5+（default-profile multiplex gateway）

## 症狀

job `91d908e7d563`（定向情報推送）：execution 永遠 `unknown`，worker 只活約 1–2 秒，
recovery 每 ~6 分鐘重掛。debug marker 顯示死在 `from run_agent import AIAgent`。
無 stderr、無 `[IMPORT_ERR]`、無 core dump。

對照：3 個 no-agent 過濾器 job（不含 agent 的純腳本）不受影響、始終正常——
因為它們不 `import run_agent`，不會觸發 re-exec。

## 根因

1. session 20 的 `_cron_worker_interpreter()`（`0df6ea6e84`）用 venv 的 `python3`（3.11，
   有 `ruamel.yaml`）啟動外部 worker。
2. `run_agent` 頂部 `import hermes_bootstrap` → `prepare_launch()`：
   `sys.executable`（venv 3.11）≠ `resolve_store_python()`（受管理 store 3.14）→
   **`os.execv` 把 worker 換成 store 3.14**，以 `runpy.run_module('cron.scheduler')` 重跑。
3. store 3.14 預設 site-packages 沒有 `ruamel.yaml`；重跑時在任何 bootstrap 生效前就
   `import cron/__init__ → hermes_yaml → ruamel` → `ModuleNotFoundError` → 進程無聲消失。
4. **真正的根因不是 interpreter 選錯，而是 re-exec**：venv 3.11 的 worker 被換成 store 3.14，
   而 store 3.14 缺 hermes 依賴。

## 修法（`cron/scheduler.py`）

- `_cron_worker_interpreter()`：改回使用 `resolve_store_python(root)`（受管理 store interpreter）。
- `_launch_external_cron_worker()`：把 `activation_environment(repo_root)["PYTHONPATH"]`
  （= repo root + committed `…/venv/lib/python3.14/site-packages`）併入 worker 的 `PYTHONPATH`，
  使 `cron` 的 imports 在 bootstrap 之前即可解析，且 ABI 與 3.14 相符。

## 驗證（2026-10-01 → 2026-10-02）

- 重啟 gateway 後，job `91d908e7d563` 執行 `completed`（輸出檔 `output/91d908e7d563/<ts>.md` 產生）。
- 5 個 secretary job 全部 `last_status: ok`：
  `91d908e7d563`、`81910c46118d`（cron-watchdog，新增）、`4e1a92d56868`、`3c4b65e4a2c6`、`8dc524193079`。
- `executions.db` 近期皆 `completed`；watchdog job `81910c46118d` 每 30m 正常觸發。

## ⚠️ 重要：hermes update 會蓋掉這個 patch

`cron/scheduler.py` 是 hermes-agent source（git-tracked）。下次 `hermes update`
會 checkout 新版本，**這個 patch 會消失**。重放方式：

```bash
cd ~/.hermes/hermes-agent
git checkout cron/scheduler.py
git apply ~/Downloads/cron_worker_interpreter_fix.patch
systemctl --user restart hermes-gateway.service
```

重放後 gateway 重啟、job 下一輪自然排程完成即恢復 `ok`。

## 附帶環境問題（非 source bug）

單執行緒本地模型後端被 **3 個卡住 1–2 天的 kanban worker** 佔滿，使 cron run 在模型請求階段停滯；
停掉該 3 個 worker 後 cron 立即完成。建議後續檢視 kanban worker 的卡死防護（timeout / 無进度判定 / 自動中止）。

## 備註

- 本文件與 `cron-ruamel-interpreter-fix.md` 是同一個 bug 的兩次修訂：
  v1（`0df6ea6e84`）把 interpreter 改成 venv 3.11 → 仍被 re-exec 到 store 3.14 → 崩；
  v2（`069b677d46`）直接用受管理 store interpreter + PYTHONPATH 併入 committed site-packages → 解。
- 重放 patch 存放：`~/Downloads/cron_worker_interpreter_fix.patch`（與 `069b677d46` 內容一致）。
