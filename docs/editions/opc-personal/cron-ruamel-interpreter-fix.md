# Cron external worker ruamel crash（interpreter 修復）

> ⚠️ **本檔已被取代。** session 20 的 venv-interpreter workaround（`0df6ea6e84`）
> 只把 interpreter 改成 venv 3.11，但 `run_agent` 的 `hermes_bootstrap.prepare_launch()`
> 仍會把該 worker `os.execv` re-exec 到受管理 store interpreter（3.14），store 3.14 缺
> `ruamel.yaml` → 崩。真正的根因是「re-exec 換 interpreter」，不是 interpreter 選錯。
> **正式修訂見 `cron-external-worker-interpreter-fix.md`（commit `069b677d46`）。**

**日期：** 2026-09-28（v1，已被取代）
**嚴重度：** 高（3/4 cron job 每小時崩，Lark 情報推送中斷 >1 天）
**Patch commit（hermes-agent source）：** `0df6ea6e84`（本地，未 push upstream；已被 `069b677d46` 取代）
**適用版本：** v0.21.5+（default-profile multiplex gateway）

## 症狀

gateway 多工化之後，4 個 cron job 有 3 個每小時崩潰，錯誤完全相同：

```
ModuleNotFoundError: No module named 'ruamel'
```

| Job ID | 名稱 | Schedule | 狀態 |
|---|---|---|---|
| `91d908e7d563` | 定向情報推送 | every 90m | ❌ error（連崩）|
| `4e1a92d56868` | 繁中後置過濾器（純腳本）| every 60m | ❌ error |
| `3c4b65e4a2c6` | 繁中後置過濾器（Forge）| every 60m | ❌ error |
| `8dc524193079` | Forge Guardrails | every 1440m | ✅ ok（原本就没崩）|

## 根因

Default multiplex gateway 跑在 **store interpreter**（standalone python-3.14，
`.hermes/tools/python-3.14.7+.../bin/python3`），它的 site-packages **沒有**
hermes 依賴（如 `ruamel.yaml`）。

cron external worker 用 `sys.executable` 繼承 gateway 的 interpreter：

```python
command = [
    sys.executable,          # ← standalone python-3.14，沒有 ruamel
    "-m", "cron.scheduler",
    ...
]
```

standalone python-3.14 的 sys.path 根本沒包含 hermes-agent 的 site-packages，
所以 `import cron.scheduler` → `hermes_yaml` → `ruamel.yaml` 崩潰。

對照：kanban dispatcher（`hermes_cli/kanban_db_dispatch.py:2549`）**已經**會檢查
`$HERMES_BIN` 解析 venv，所以 kanban worker 正常；cron **沒有**檢查 → 崩。

## 修法（方案 A）

在 `cron/scheduler.py` 的 `_launch_external_cron_worker()` 加入 interpreter resolver：

```python
def _cron_worker_interpreter() -> str:
    """The interpreter for ``-m cron.scheduler``.

    Mirrors how kanban resolves its ``hermes`` argv (``$HERMES_BIN`` first):
    the managed gateway runs on the store interpreter, whose site-packages
    may lack hermes deps like ``ruamel.yaml``. When ``$HERMES_BIN`` names a
    venv launcher, use that venv's own python3 so the worker sees the same
    installed packages as the rest of the stack; fall back to the running
    interpreter only when no launcher is configured. The module import
    itself is unaffected: this caller pins ``PYTHONPATH`` to the checkout
    (see below) and spawns with ``cwd=repo_root``, so ``cron.scheduler``
    resolves regardless of interpreter.
    """
    env_bin = os.environ.get("HERMES_BIN", "").strip()
    if env_bin:
        try:
            resolved = os.path.realpath(env_bin)
            sibling = os.path.join(os.path.dirname(resolved), "python3")
            if os.path.isfile(sibling):
                return sibling
        except OSError:
            pass
    return sys.executable

command = [
    _cron_worker_interpreter(),   # ← 改用 venv python3（若 $HERMES_BIN 指向 venv）
    "-m", "cron.scheduler",
    ...
]
```

關鍵：venv/bin/hermes 是一個 shell 腳本，內部 exec `$(dirname "$0")/python3`。
所以從 `$HERMES_BIN` 的同目錄找 `python3`，就能拿到 venv 的 interpreter。
cron worker 已經會 pin PYTHONPATH 到 repo_root + cwd=repo_root（line ~3561-3571），
所以只要 interpreter 對，`cron.scheduler` 和 `ruamel.yaml` 都能找到。

## 驗證

重啟 gateway 後：
- 繁中过滤器（4e1a92d56868）02:05 成功，产出输出档 `output/4e1a92d56868/2026-09-28_02-05-19.md`
- Forge 變體（3c4b65e4a2c6）手動觸發 "Ran now: succeeded"
- 定向情報推送（91d908e7d563）手動觸發跑完，無 ruamel 錯誤
- incidents 表所有「Last seen」都在重啟前，重啟後零新 incident

## ⚠️ 重要：hermes update 會蓋掉這個 patch

`cron/scheduler.py` 是 hermes-agent source（git-tracked）。下次 `hermes update`
會 checkout 新版本，**這個 patch 會消失**。重放方式：

1. 把下面的 diff 存成 `/tmp/cron_ruamel_fix.patch`
2. `cd /home/eye/.hermes/hermes-agent && git checkout cron/scheduler.py && git apply /tmp/cron_ruamel_fix.patch`
3. `systemctl --user restart hermes-gateway.service`（從 gateway 之外的 shell 執行）

## 完整 diff（供重放）

```diff
--- a/cron/scheduler.py
+++ b/cron/scheduler.py
@@ -3470,8 +3470,33 @@ def _launch_external_cron_worker(job: dict) -> bool:
     ack_path = handoff_dir / f"{execution_id}.ready"
     # Captured so a worker that dies before its acknowledgement can name the cause (#112729).
     stderr_path = handoff_dir / f"{execution_id}.stderr"
+
+    def _cron_worker_interpreter() -> str:
+        """The interpreter for ``-m cron.scheduler``.
+
+        Mirrors how kanban resolves its ``hermes`` argv (``$HERMES_BIN`` first):
+        the managed gateway runs on the store interpreter, whose site-packages
+        may lack hermes deps like ``ruamel.yaml``. When ``$HERMES_BIN`` names a
+        venv launcher, use that venv's own python3 so the worker sees the same
+        installed packages as the rest of the stack; fall back to the running
+        interpreter only when no launcher is configured. The module import
+        itself is unaffected: this caller pins ``PYTHONPATH`` to the checkout
+        (see below) and spawns with ``cwd=repo_root``, so ``cron.scheduler``
+        resolves regardless of interpreter.
+        """
+        env_bin = os.environ.get("HERMES_BIN", "").strip()
+        if env_bin:
+            try:
+                resolved = os.path.realpath(env_bin)
+                sibling = os.path.join(os.path.dirname(resolved), "python3")
+                if os.path.isfile(sibling):
+                    return sibling
+            except OSError:
+                pass
+        return sys.executable
+
     command = [
-        sys.executable,
+        _cron_worker_interpreter(),
         "-m",
         "cron.scheduler",
         "--external-worker-file",
```

## 備註

- Gateway multiplexer 本身仍然跑在 store interpreter（standalone python-3.14），這**沒問題**——
  patch 只改 cron worker 的 interpreter，與 gateway 本身的 interpreter 無關。
- launcher shim（`.hermes/bin/hermes`）每次 gateway 重啟會從 PM `facts.json` 重建，
  所以直接改 shim 無效（方案 B 已排除）。本 patch 走 `$HERMES_BIN` env，不受重建影響。
- 若日後想根治 gateway interpreter（讓 multiplexer 跑 venv），需改 `facts.json` 的 store python pin，
  但那動到 PM 管理的依赖管理，風險較高，留待日後評估。
