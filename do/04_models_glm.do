****************************************************
* 04_models_glm.do
* 役割：線形回帰・ロジスティック回帰・修正Poisson回帰
* 重要：欠損補完はこの回では行わない（e(N)を確認する）
****************************************************

use "$CLEAN\df01_clean.dta", clear

capture log close
log using "$LOG/session4_models.log", text replace
di "=== Session 4: Regression basics ==="

*--------------------------------------------------*
* 0) 欠損の確認（補完はしない）
*--------------------------------------------------*
misstable summarize bmi sbp fev1

*--------------------------------------------------*
* 1) 変数セット（他の解析をするときにはこのセクションだけ変更すればOK）
*--------------------------------------------------*
* 曝露変数
local expv dm

* アウトカム 
local outv_cont cv_time
local outv_bin  cv_event


* 交絡候補
local covars age bmi sbp fev1 smk htn_tx fhx_cvd af ckd ra copd

*--------------------------------------------------*
* 2) 線形回帰：アウトカム=cv_time（教材用）
*--------------------------------------------------*
di "---- Linear regression (Outcome: cv_time) ----"

* 粗解析（dmのみ）
regress `outv_cont' `expv'
di "N used (crude): " e(N)

* 調整解析（dm + covars）
regress `outv_cont' `expv' `covars'
di "N used (adjusted): " e(N)

*--------------------------------------------------*
* 3) ロジスティック回帰：アウトカム=cv_event（OR）
*--------------------------------------------------*
di "---- Logistic regression (Outcome: cv_event) ----"

* 粗解析（OR）
logistic `outv_bin' `expv'
di "N used (crude): " e(N)

* 調整解析（OR）
logistic `outv_bin' `expv' `covars'
di "N used (adjusted): " e(N)

*--------------------------------------------------*
* 4) 修正Poisson回帰：アウトカム=cv_event（RR）
*--------------------------------------------------*
di "---- Modified Poisson regression (Outcome: cv_event) ----"

* 粗解析（RR）
poisson `outv_bin' `expv', robust irr
di "N used (crude): " e(N)

* 調整解析（RR）
poisson `outv_bin' `expv' `covars', robust irr
di "N used (adjusted): " e(N)

*--------------------------------------------------*
* 5) 欠損によるNの減少を可視化
*--------------------------------------------------*
di "---- What reduced N? (missingness check) ----"
* 回帰に使った変数のどれかが欠損すると落ちる
egen miss_any = rowmiss(dm `covars' cv_time cv_event)
tab miss_any

di "=== Session 4 completed ==="
log close