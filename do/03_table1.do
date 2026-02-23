****************************************************
* 03_table1.do
* 役割：記述統計の確認と Table 1 作成（Excel出力）
* データ：data_clean\cardio_clean.dta を前提
****************************************************

****************************************************
* 0) 準備
****************************************************
cap log close
log using "$LOG/log_03_tale1.smcl", replace
di "=== Session 3: Table 1 ==="

* 読込みデータファイルと書出しデータファイル
local read_file  "$CLEAN/df01_clean.dta"
local write_file "$OUT/table1.xlsx"

* 変数の定義
local expv dm

* des_vars = dtableで利用する：記述統計量で示す変数リスト（i.もつける）
local des_vars ///
	age bmi sbp fev1 cv_time ///
	i.smk i.htn_tx i.fhx_cvd i.af i.ckd i.ra i.copd i.cv_event ///
	i.age_outlier i.bmi_outlier i.sbp_outlier i.cv_time_outlier ///
	i.miss_bmi i.miss_sbp i.miss_fev1 i.miss_cv_time

use "`read_file'", clear

****************************************************
* 1) 記述統計（連続変数）
****************************************************
* 記述統計量を確認する
su age bmi sbp fev1 cv_time, detail

****************************************************
* 2) カテゴリ変数
****************************************************
* 二値変数の分布を確認する
foreach v in cv_event dm smk htn_tx fhx_cvd af ckd ra copd {
    tab `v', missing
}

****************************************************
* 3) 欠損の可視化
****************************************************
misstable summarize bmi sbp fev1

****************************************************
* 4) Table 1 を作る（dtable）
*    FEV1のみ中央値表示にする。
****************************************************
local sd_vars  age bmi sbp cv_time // これらは平均値（標準偏差）で表示する
local iqr_vars fev1                // fev1は中央値（第1四分位, 第3四分位）で表示する

dtable `des_vars', ///
		by(`expv', nototals notests missing) ///
		column(by(label)) /// 
		sample(, place(seplabels)) ///
		///
		define(iqi = q1 q3, delimiter(", ")) ///
		sformat("[%s]" iqi) /// 
		///	
		nformat(%16.2fc mean sd q1 q2 q3) ///
		continuous(`sd_vars',  statistics(mean sd) test(regress)) ///
		continuous(`iqr_vars', statistic(q2 iqi)) ///
		factor(,test(pearson)) ///
		///
		note(Mean(SD) or N(%)) ///
		note(Median[IQR]) ///
		///
		export("`write_file'", as(xlsx) replace)


log close