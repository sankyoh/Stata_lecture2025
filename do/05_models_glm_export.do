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