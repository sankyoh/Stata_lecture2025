****************************************************
* 01_import.do
* 役割：CSVを読み込み、dtaファイルとして保存
* csv -> df00.dta
****************************************************

* 0) ログを取る
cap log close
log using "$LOG\log_01_import.smcl", replace

* 1) 読込みデータファイルと書出しデータファイル
local read_file  "$RAW\cvd_synthetic_dataset_v0.2.csv"
local write_file "$RAW\df00.dta"

* 2) import delimited（CSV）
import delimited using "`read_file'", delimiter(",") varnames(1) clear

* 3) Sanity Check Lv1
// 目的：データが壊れていないか確認する

* 変数型・行数
describe  // 変数型がおかしくないか？
count     // 行数は想定通りか？

* patient_id の欠損確認
count if missing(patient_id) 

* patient_id の重複
duplicates report patient_id 

* 連続変数について簡単に確認
su age body_mass_index systolic_blood_pressure ///
    time_to_event_or_censoring
	
* bool変数（二値変数）について簡単に確認
su smoker hypertension_treated family_history_of_cardiovascular atrial_fibrillation ///
	chronic_kidney_disease rheumatoid_arthritis diabetes chronic_obstructive_pulmonary_di ///
	heart_attack_or_stroke_occurred

* ここでは直さない。一旦、見るだけ。
di "Sanity Check Lv1 completed (no modification applied)"

* 4) raw保存
compress
label data "RAW data"
save "`write_file'", replace

di "=== Import done: saved `out_file' ==="

log close