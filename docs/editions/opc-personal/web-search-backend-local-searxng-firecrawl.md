# 本地 web 搜尋/提取後端：searXNG + Firecrawl（multiplexed gateway 實作）

**適用 hermes-agent v0.23.0+，OPC-PERSONAL 多 profile multiplexed 部署。** 記錄 2026-11-08 把 `web_search` 接到本機 searXNG、`web_extract` 接到本機 Firecrawl 的過程、踩到的坑與根因修正。

單一事實來源：本檔專注「**為什麼寫了 `.env` + config 还是不生效，真正原因與修法**」。架構細節見 `gateway-multiplex.md`；web provider 解析邏輯見下方「根因」段引用的 `get_env_value` / `load_env`。

## TL;DR

```text
目標： web_search   → 本機 searXNG   (127.0.0.1:8088)
       web_extract  → 本機 Firecrawl (127.0.0.1:3002, /v1/scrape)

寫了這兩份還不生效：
  ~/.hermes/config.yaml : web.backend=firecrawl / search_backend=searxng / extract_backend=firecrawl
  ~/.hermes/.env        : SEARXNG_URL=… / FIRECRAWL_API_URL=…

根因：multiplexed gateway 的 profile worker 是「frozen-policy worker」，
      load_env() 對它直接回 {} → 根本不去讀 ~/.hermes/.env。
      runtime 在 os.environ 找不到 SEARXNG_URL → 判定 searxng 不可用 → 掉回 firecrawl。

修法：把 URL 寫進 systemd user 服務環境（不碰 .service 檔）：
      systemctl --user set-environment SEARXNG_URL=http://127.0.0.1:8088 \
                                       FIRECRAWL_API_URL=http://127.0.0.1:3002
      再 restart gateway，讓 process 的 os.environ 載入。重啟不會被蓋掉。
```

## 背景與目標

使用者希望 hermes-agent 的網路搜尋/抓取**走本機自架服務**，不碰雲端：

- **searXNG**（docker `hermes-searxng`，`127.0.0.1:8088`）：免費元搜尋，`/search?q=…&format=json` 回 JSON，**不需要 API key**。
- **Firecrawl**（docker `firecrawl-api-1`，`0.0.0.0:3002`）：`/v1/scrape` 抓 markdown、`/v1/search` 也內接本機 searXNG。**自架 + `USE_DB_AUTHENTICATION=false` 時免 key**。

hermes web provider 配置語法（官方 `configuration.md`）：

```yaml
web:
  backend: firecrawl        # firecrawl | searxng | parallel | tavily | perplexity | keenable | exa
  search_backend: "searxng"   # 搜尋用 searXNG
  extract_backend: "firecrawl" # 提取用 firecrawl
```

解析優先序（`agent/web_search_registry.py`）：`web.search_backend` / `web.extract_backend` > `web.backend`。

## 初始設定（對的，但沒生效）

```bash
# ~/.hermes/.env（provider 連線 URL，hermes 設計就放這裡）
SEARXNG_URL=http://127.0.0.1:8088
FIRECRAWL_API_URL=http://127.0.0.1:3002

# config（hermes config set 會寫到 active profile；runtime 實際讀 home/default）
hermes -p default config set web.search_backend searxng
hermes -p default config set web.extract_backend firecrawl
```

重啟 gateway 後**實測仍走 firecrawl**：`hermes chat -q "web_search …"` 回的结果 firecrawl 也拿得到，但 **searXNG 容器在這個波搜尋裡收到 0 個請求**。

## 根因（關鍵）

runtime 解析 provider 用 `get_provider_env()` → `get_env_value()`：

```python
# hermes_cli/config.py:get_env_value
def get_env_value(key):
    val = _scoped_environ_get(key)                 # 讀 os.environ（multiplex 下受 scope 控管）
    return load_env().get(key) if val is None else val   # miss 才退回 ~/.hermes/.env

# hermes_cli/config.py:load_env
def load_env():
    if _worker_config_snapshot() is not None:      # frozen-policy worker
        return {}                                   # ← 直接回空，不讀 .env
    ...
```

**multiplexed gateway 服務的 profile worker 就是「frozen-policy worker」**，`load_env()` 對它回 `{}`——**根本不去讀 `~/.hermes/.env`**。所以：

- `.env` 有 `SEARXNG_URL`，但 worker 讀不到 → `_scoped_environ_get` 在 os.environ 也找不到 → `val is None` → 退回的 `load_env()` 又是 `{}` → 結果仍是空。
- searxng provider 的 `is_available()` 判為 false → 掉回 `web.backend=firecrawl`。

**結論**：在 multiplexed gateway 情境，provider URL/key **必須進 process 的 `os.environ`**，光寫 `.env` 不夠（`.env` 只對互動式 CLI / delegate children 等非 frozen worker 生效）。

## 修法

把兩個 URL 寫進 **systemd user manager 環境**（不是手動改 `.service` 檔）：

```bash
systemctl --user set-environment \
  SEARXNG_URL=http://127.0.0.1:8088 \
  FIRECRAWL_API_URL=http://127.0.0.1:3002

# 確認註冊
systemctl --user show-environment | grep -E '^SEARXNG_URL=|^FIRECRAWL_API_URL='

# 重啟 gateway 讓 process 載入（這會切斷當前 live session）
systemctl --user restart hermes-gateway.service
# 或（若 gateway 拒絕因有 live session）：hermes -p secretary gateway restart --yes
```

**為什麼用 `set-environment` 而不是改 `.service`**：`hermes gateway` 重啟時會用 `generate_systemd_unit()` 模板重新生成 unit，**手動改 `.service` 的 `Environment=` 會被蓋掉**。`systemctl --user set-environment` 寫進 manager 層環境，systemd 在 unit 啟動時套上它，**不碰 .service 檔、重啟不被蓋**（與 `gateway-multiplex-upgrade.md`「drop-in 原則」同邏輯）。

## 驗證（三項 Ground truth）

不要信 agent 自己讀 config 回報——直接看容器有沒有收到請求。

### ① process environ 有變數

```bash
PID=$(hermes gateway status | grep -oE 'PID [0-9]+' | head -1 | awk '{print $2}')
tr '\0' '\n' < /proc/$PID/environ | grep -E '^SEARXNG_URL=|^FIRECRAWL_API_URL='
# 應輸出兩個 http://127.0.0.1:… 行
```

### ② web_search → searXNG 收到請求

searXNG 容器會記 engine 級 activity（`searx.engines.*` warning/info）。測前後計數應增加：

```bash
docker logs hermes-searxng 2>&1 | grep -c 'searx.engines'   # 前
hermes chat -q "Use web_search for 'Nous Research Hermes Agent'. Reply with ONLY the top result URL."
docker logs hermes-searxng 2>&1 | grep -c 'searx.engines'   # 後（應 +N）
```

實測：133 → 134，新增一筆 16:42:36 請求 → **搜尋真的走 searXNG**。

> 備註：searXNG 的 DuckDuckGo 後端引擎會回 CAPTCHA（log 可見），但 searXNG 還跑其他 70+ 引擎，搜尋仍正常回結果。這是內部引擎問題，不是路由問題。

### ③ web_extract → firecrawl `/v1/scrape` 收到請求

```bash
hermes chat -q "Use web_extract on https://hermes-agent.nousresearch.com/docs/ . Reply with ONLY the first heading."
docker logs --tail 20 firecrawl-api-1 2>&1 | grep -iE 'ScrapeURL|POST /v1'
# 應見：[ScrapeURL:] Scraping URL "…"; Scraping via playwright... deemed successful.
```

實測：16:43:02 `[ScrapeURL:]` 成功 → **提取真的走 firecrawl**。

## ⚠️ 教訓

### 教訓 #1：multiplexed worker 不讀 .env，provider 連線要進 os.environ

`.env` 的 fallback 在 frozen-policy worker 下失效（`load_env()` 回 `{}`）。凡 runtime **在 gateway turn 中需要**的 provider URL/key（searXNG_URL、FIRECRAWL_API_URL、各 provider key），multiplexed 部署要放 **systemd user manager 環境**（`systemctl --user set-environment`），互動式 CLI 才用 `.env`。

### 教訓 #2：改 gateway 環境用 `set-environment`，不要手動 edit .service

`hermes gateway restart` 會用模板重生成 unit，蓋掉手動改的 `Environment`。`systemctl --user set-environment` 寫 manager 層、不碰 .service、重啟不被蓋。

### 教訓 #3：路由驗證看容器 log，不要信 agent 自報

agent 會自己 `grep` config 然後「推斷」backend——那只是讀檔案，不代表 runtime 真路由。**Ground truth 是容器有沒有收到對應請求**（searXNG `searx.engines.*`、firecrawl `[ScrapeURL:]`）。

### 教訓 #4：事實下沉層級

本檔屬於「部署/架構事實」→ 放 repo docs（git clone 後仍在，不佔 session prefill），是最佳下沉層。不要塞進 native memory 或 plur（plur 會 leak 進其他角色）。

## 快速重做清單（新機器接手）

```bash
# 1. config（home/default profile）
hermes -p default config set web.backend firecrawl
hermes -p default config set web.search_backend searxng
hermes -p default config set web.extract_backend firecrawl

# 2. provider 連線進 systemd manager 環境（multiplexed gateway 真正讀這個）
systemctl --user set-environment \
  SEARXNG_URL=http://127.0.0.1:8088 \
  FIRECRAWL_API_URL=http://127.0.0.1:3002

# 3. 重啟 gateway
systemctl --user restart hermes-gateway.service

# 4. 驗證（參考上方 ①②③）
PID=$(hermes gateway status | grep -oE 'PID [0-9]+' | head -1 | awk '{print $2}')
tr '\0' '\n' < /proc/$PID/environ | grep -E 'SEARXNG_URL|FIRECRAWL_API_URL'
```

## 相關文件

- `gateway-multiplex.md` — multiplexed gateway 現行架構（default multiplexer 統一服務 9 profile）。
- `gateway-multiplex-upgrade.md` — 同系列「改 systemd 環境用 drop-in / set-environment、不要手動 edit .service」原則。
- `hermes-upgrade-verify.md` — 升級後健康檢查序列（可順帶確認 web 段未壞）。
- 官方 web provider 解析：`agent/web_search_provider.py`、`agent/web_search_registry.py`、`hermes_cli/config.py:get_env_value`。

---

*本檔記錄 2026-11-08 本地 searXNG + Firecrawl web 後端接上 multiplexed gateway 的根因與修法。核心一句：multiplexed worker 不讀 `.env`，provider 連線要進 os.environ（systemd `set-environment`）。*
