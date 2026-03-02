# 第5回：postfileで回帰結果をExcelに出力する 📤
（第4回の回帰：線形・ロジスティック・修正Poissonの「粗解析＋調整」を1枚のExcelにまとめる）

この回の狙いはシンプルです。

- Stataの結果を目で見て満足するだけでなく、**他人に渡せる形（Excel）で残す**
- 毎回コピペで表を作らず、**再現可能な“成果物生成”**をdoファイルに組み込む
- そのための定番道具が **`postfile`**（= 結果をためて“結果用データセット”を作る）です

---

## 1. 何を作るのか（出力フォーマット）

Excelの列は次の形にします。

- `glm`
- `estimate`
- `value (95%CI)`（粗解析）
- `p-value`（粗解析）
- （空列）
- `adjusted value (95%CI)`（調整）
- `p-value`（調整）

行は、今回の3モデル：

1. regress（coefficient）
2. logistic（odds ratio）
3. modified poisson（risk ratio）

---

## 2. なぜ `postfile` を使うのか

### 2.1 直感的なたとえ
`postfile` は、**「結果を1行ずつ書き込める“メモ帳（= 一時データセット）”」**だと思ってください。

- 結果を保存する枠を作る (postfile)
- 回帰を回す(regress, logistic, poisson)
- 推定値・CI・pを取り出す (lincom)
- 1行としてメモ帳に書く（post）
- 全部書けたらメモ帳を閉じる（postclose）
- 最後にExcelへ出力する

この流れができると、今後の研究でもずっと使えます ✨

---

## 3. 回帰結果（推定値・CI・p）を取り出すコツ

### 3.1 `lincom` と `r(xxx)` を使う
回帰の種類が違っても、次の形に統一できます。

- 線形回帰：`lincom dm`
- ロジスティック：`lincom dm, or`（OR）
- Poisson（修正Poisson）：`lincom dm, irr`（修正Poissonでは、IRRをRRとして読みかえる）

`lincom` の実行直後に、結果は `r(xxx)`というローカルマクロに入ります。  
この `r(xxx)` の意味は基本これ：

- `r(estimate)`：推定値
- `r(se)`：標準誤差
- `r(df)`：自由度
- `r(t)` or `r(z)`：検定統計量
- `r(p)`：p値
- `r(lb)` / `r(ub)`：95%CI 下限/上限
- `r(level)`：信頼水準

lbwデータで簡単な確認
``` stata
webuse lbw, clear

* 粗解析モデル
regress bwt smoke 
lincom smoke
return list

* 調整モデル
regress bwt smoke i.race ht ui
lincom smoke
return list

* ロジスティック回帰分析
logistic low smoke
lincom smoke, or
return list

```

この確認コードで、粗解析モデルでも調整モデルでも、ロジスティック回帰分析でもsmokeの解析結果が`r(xxx)`に格納されていることが分かります。

したがって、Excel出力用の値は **`r(estimate) r(lb) r(ub) r(p)`** を取り出して整形します。

---

## 4. 実装：`04_models_glm.do` に postfile + Excel出力を追加した完成版

> **注意**  
> - 下のコードは「第4回で紹介したコード」をベースに、(1) Excel出力機能を追加したものです  
> - `postfile` を必ず使っています  

05_models_glm_export.do
~~~stata
****************************************************
* 05_models_glm_export.do（Excel出力つき）
* 役割：線形回帰・ロジスティック回帰・修正Poisson回帰
* 追加：postfileで結果を貯めてExcelに出力
* 重要：欠損補完はこの回では行わない（e(N)を確認する）
****************************************************

local read_file  "$CLEAN/df01_clean.dta"
local write_file "$OUT/session5_models_results.xlsx"

di "`read_file'"
use "`read_file'", clear

capture log close
log using "$LOG/session4_models.log", text replace
di "=== Session 4: Regression basics (+postfile export) ==="

*--------------------------------------------------*
* 0) 欠損の確認（補完はしない）
*--------------------------------------------------*
misstable summarize bmi sbp fev1

*--------------------------------------------------*
* 1) 変数セット（他の解析をするときにはこのセクションだけ変更すればOK）
*--------------------------------------------------*
local expv dm

local outv_cont cv_time
local outv_bin  cv_event

local covars age bmi sbp fev1 smk htn_tx fhx_cvd af ckd ra copd

*--------------------------------------------------*
* 2) postfileの準備：結果を貯める"結果用データセット"を作る
*--------------------------------------------------*
tempname holder
tempfile results

* 文字列で持つと整形（xx.xx (lb, ub) や <0.001）が楽なので strで指定しています。
postfile `holder' ///
    str20 glm ///
    str20 estimate ///
    str10 N ///
    str40 value_ci ///
    str10 p_value ///
    str1  blank ///
    str10 adj_N ///
    str40 adj_value_ci ///
    str10 adj_p_value ///
    using `results', replace

*--------------------------------------------------*
* 3) 線形回帰：アウトカム=cv_time（教材用）
*--------------------------------------------------*
di "---- Linear regression (Outcome: cv_time) ----"

* 粗解析
regress `outv_cont' `expv' // ***** 異なる解析をする場合にはここを変更する *****
local N = string(`e(N)')

lincom `expv'
local est = r(estimate)
local lb  = r(lb)
local ub  = r(ub)
local pv  = r(p)

local crude_val = trim(string(`est',"%9.2f")) + " (" + trim(string(`lb',"%9.2f")) + ", " + trim(string(`ub',"%9.2f")) + ")"
local crude_p   = cond(`pv'<0.001, "<0.001", trim(string(`pv',"%6.3f")))

* 調整解析
regress `outv_cont' `expv' `covars' // ***** 異なる解析をする場合にはここを変更する *****
local adj_N = string(`e(N)')

lincom `expv'
local est = r(estimate)
local lb  = r(lb)
local ub  = r(ub)
local pv  = r(p)

local adj_val = trim(string(`est',"%9.2f")) + " (" + trim(string(`lb',"%9.2f")) + ", " + trim(string(`ub',"%9.2f")) + ")"
local adj_p   = cond(`pv'<0.001, "<0.001", trim(string(`pv',"%6.3f")))

* 1行としてpost（指定の空列 blank は "" を入れる）
post `holder' ("regress") ("coefficient") ("`N'") ("`crude_val'") ("`crude_p'") ("") ("`adj_N'") ("`adj_val'") ("`adj_p'")

*--------------------------------------------------*
* 4) ロジスティック回帰：アウトカム=cv_event（OR）
*--------------------------------------------------*
di "---- Logistic regression (Outcome: cv_event) ----"

* 粗解析（OR）
logistic `outv_bin' `expv' // ***** 異なる解析をする場合にはここを変更する *****
local N = string(`e(N)')

lincom `expv', eform
local est = r(estimate)
local lb  = r(lb)
local ub  = r(ub)
local pv  = r(p)

local crude_val = trim(string(`est',"%9.2f")) + " (" + trim(string(`lb',"%9.2f")) + ", " + trim(string(`ub',"%9.2f")) + ")"
local crude_p   = cond(`pv'<0.001, "<0.001", trim(string(`pv',"%6.3f")))

* 調整解析
logistic `outv_bin' `expv' `covars' // ***** 異なる解析をする場合にはここを変更する *****
local adj_N = string(`e(N)')

lincom `expv', eform
local est = r(estimate)
local lb  = r(lb)
local ub  = r(ub)
local pv  = r(p)

local adj_val = trim(string(`est',"%9.2f")) + " (" + trim(string(`lb',"%9.2f")) + ", " + trim(string(`ub',"%9.2f")) + ")"
local adj_p   = cond(`pv'<0.001, "<0.001", trim(string(`pv',"%6.3f")))

* 1行としてpost（指定の空列 blank は "" を入れる）
post `holder' ("logistic") ("Odds Ratio") ("`N'") ("`crude_val'") ("`crude_p'") ("") ("`adj_N'") ("`adj_val'") ("`adj_p'")

*--------------------------------------------------*
* 5) 修正Poisson回帰：アウトカム=cv_event（RR）
*   ※二値アウトカムにPoisson+robustを当てる定番手法
*--------------------------------------------------*
di "---- Modified Poisson regression (Outcome: cv_event) ----"

* 粗解析（RR）
poisson `outv_bin' `expv', vce(robust) irr // ***** 異なる解析をする場合にはここを変更する *****
local N = string(`e(N)')

lincom `expv', eform
local est = r(estimate)
local lb  = r(lb)
local ub  = r(ub)
local pv  = r(p)

local crude_val = trim(string(`est',"%9.2f")) + " (" + trim(string(`lb',"%9.2f")) + ", " + trim(string(`ub',"%9.2f")) + ")"
local crude_p   = cond(`pv'<0.001, "<0.001", trim(string(`pv',"%6.3f")))

* 調整解析
poisson `outv_bin' `expv' `covars', vce(robust) irr // ***** 異なる解析をする場合にはここを変更する *****
local adj_N = string(`e(N)')

lincom `expv', eform
local est = r(estimate)
local lb  = r(lb)
local ub  = r(ub)
local pv  = r(p)

local adj_val = trim(string(`est',"%9.2f")) + " (" + trim(string(`lb',"%9.2f")) + ", " + trim(string(`ub',"%9.2f")) + ")"
local adj_p   = cond(`pv'<0.001, "<0.001", trim(string(`pv',"%6.3f")))

* 1行としてpost（指定の空列 blank は "" を入れる）
post `holder' ("modified Poison") ("Risk Ratio") ("`N'") ("`crude_val'") ("`crude_p'") ("") ("`adj_N'") ("`adj_val'") ("`adj_p'")

*--------------------------------------------------*
* 7) postfileを閉じて、Excelへ出力
*--------------------------------------------------*
postclose `holder'

use `results', clear

* 列名を"指定の見た目"に寄せる（Excelのヘッダをvarlabelにする）
label var glm         "glm"
label var estimate    "estimate"
label var N            "N for crude model"     
label var value_ci    "value (95%CI)"
label var p_value     "p-value"
label var blank       "　"                       // 空列の見出し（空にする）
label var adj_N        "N for adjusted model"
label var adj_value_ci "adjusted value (95%CI)"
label var adj_p_value  "p-value"

* Excel出力：ヘッダはvarlabelを使う
export excel using "`write_file'", firstrow(varlabels) replace

di "=== Results exported to: Excel file ==="

log close
~~~

---

## 5. ここで受講者に言わせたい「大事な一言」
この回の価値は、ただExcelに出たことではなく、

> **解析結果が“再現可能な成果物”として残るようになった**

ことです。

以後、回帰を追加しても `post` を1行足すだけで表が育ちます。

---

## 6. よくあるトラブルと対処
### Q1. OR/RR にならない（係数が出る）
`lincom , eform` を忘れている可能性が高いです。

- logistic：`lincom dm, eform`
- poisson ：`lincom dm, eform`

### Q2. p値の表示を「<0.001」にしたい
この資料では

~~~stata
local pstr = cond(pv<0.001, "<0.001", trim(string(pv,"%6.3f")))
~~~

で統一しています。

---

## 7. ミニ演習

1) `covars` から `fev1` を外して回す  
→ どのモデルで `e(N)` が増えるか確認（欠損の影響が見える）

2) 修正Poissonに `vce(robust)` を付け忘れるとどうなるか確認  
→ 標準誤差（CI）が変わり得ることを観察

---

## まとめ 🎉
- `postfile` は「結果をためて表にする」ための定番技術
- `lincom` + `r(table)` で、回帰の種類が違っても同じ手順で結果を抜き出せる
- Excel出力までdoファイル化すると、解析が“成果物生成”になる
