# SOUL 模板 token 用量審計（2026-08-15 refine）

**計量方式**：`tiktoken` `cl100k_base`（GPT-4 家族編碼）。CJK 字元在 cl100k 下約 1 token/字，英文詞較省——因此「繁中化」會使 token 數上升，即使字數（chars）下降。chars 是內容多寡的中立指標。

## 對照表

| Profile | before tokens | after tokens | Δ tokens | before chars | after chars | Δ chars |
|---|---|---:|---:|---:|---:|---:|
| opc-personal/secretary | 2268 | 2253 | −15 | 4383 | 4299 | −84 |
| opc-personal/coordinator | 2061 | 2576 | +515 | 8328 | 5393 | −2935 |
| opc-personal/researcher | 607 | 876 | +269 | 2313 | 1825 | −488 |
| opc-personal/writer | 480 | 806 | +326 | 1772 | 1564 | −208 |
| opc-personal/builder | 833 | 1236 | +403 | 3702 | 2527 | −1175 |
| opc-personal/runes-holder | 2909 | 3241 | +332 | 10822 | 8666 | −2156 |
| opc-personal/aeon-builder | 783 | 1190 | +407 | 2596 | 2286 | −310 |
| opc-personal/nim-researcher | 1521 | 1925 | +404 | 5375 | 3895 | −1480 |
| **opc-personal 小計** | **11462** | **14103** | **+2641 (+23%)** | **35291** | **30455** | **−4836 (−13.7%)** |
| generic/secretary | 188 | 889 | +701 | 256 | 1372 | +1116 |
| generic/coordinator | 194 | 1158 | +964 | 261 | 1909 | +1648 |
| generic/researcher | 189 | 605 | +416 | 257 | 908 | +651 |
| generic/writer | 189 | 549 | +360 | 253 | 777 | +524 |
| generic/builder | 189 | 759 | +570 | 254 | 1215 | +961 |
| **generic 小計** | **949** | **3960** | **+3011 (+317%)** | **1281** | **6181** | **+4900 (+383%)** |
| **TOTAL** | **12411** | **18063** | **+5652 (+46%)** | **36572** | **36636** | **+64** |

## 解讀

- **opc-personal 真正精簡了**：chars −13.7%（35,291 → 30,455），內容去冗有效；tokens +23% 主因是**繁中化**（cl100k 對 CJK 1 token/字，對英文詞較省）。實際 runtime model 的 tokenizer 若對中文較省，差距會小於此值。
- **coordinator 最瘦身**：chars −35%（8,328 → 5,393，移除重複的 Output Contract 交接模板）。
- **runes-holder**：chars −20%（10,822 → 8,666），保留 whitelist 全表，只精簡說明文字。
- **generic 5 檔**：由 ~190 token 的空骨架填成完整內容（+317%），屬預期——「骨架 → 可用的精簡版 SOUL」。
- 全 13 檔通過 `verify-profile-templates.sh`（strict）與 `verify-repo-layout.sh`。

## 重新計量

```bash
pip install tiktoken
python -c "import tiktoken,glob,os; e=tiktoken.get_encoding('cl100k_base'); t=0
for ed in ['opc-personal','generic']:
  for p in sorted(os.listdir(f'editions/{ed}/profiles')):
    n=len(e.encode(open(f'editions/{ed}/profiles/{p}/SOUL.md.template').read())); t+=n
    print(ed, p, n)
print('TOTAL', t)"
```
