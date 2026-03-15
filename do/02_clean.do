****************************************************
* 02_clean.do
* 役割：分析可能なデータセットに整形して保存
* * df00.dta -> df01_clean.dta
****************************************************

* 0) ログを取る
cap log close
log using "$LOG\log_02_clean.smcl", replace

* 1) 読込みデータファイルと書出しデータファイル
local read_file  "$RAW\df00.dta"
local write_file "$CLEAN\df01_clean.dta"

use "`read_file'", clear

****************************************************
* 0) IDチェック
****************************************************

* patient_id が欠損していないか
// もし欠損があるなら、ここで止る
count if missing(patient_id)
assert patient_id != ""

* patient_id が一意か（重複があると以後の解析が崩壊する）
// idの重複があれば、ここで止る
isid patient_id

****************************************************
* 1) 文字列のトリム
****************************************************
* Excel/CSV由来で余計な空白が混ざることがあるため、先に除去しておく
ds, has(type string)
local str_vars `r(varlist)'
foreach v of local str_vars {
	replace `v' = strtrim(`v') if !missing(`v')
}

****************************************************
* 2) gender の整形
****************************************************
* 方針：M/F を 0/1 に変換し、ラベルを付与する
gen byte tmp_gender = ., after(gender)
replace tmp_gender = 1 if gender == "F"
replace tmp_gender = 0 if gender == "M"

// 元変数との一致を確認する
tab tmp_gender gender
drop gender
rename tmp_gender gender

label define gender 0 "Male" 1 "Female", replace
label values gender gender
label variable gender "gender"


****************************************************
* 3) 長い変数名を短くし、ラベルを付けた
* Powered by ChatGPTで、一部は修正
* https://chatgpt.com/share/69779aa2-14f4-8006-a515-10e16a36f4e3
****************************************************
rename body_mass_index                          bmi
rename smoker                                   smk
rename systolic_blood_pressure                  sbp
rename hypertension_treated                     htn_tx
rename family_history_of_cardiovascular         fhx_cvd
rename atrial_fibrillation                      af
rename chronic_kidney_disease                   ckd
rename rheumatoid_arthritis                     ra
rename diabetes                                 dm
rename chronic_obstructive_pulmonary_di         copd
rename forced_expiratory_volume_1               fev1
rename time_to_event_or_censoring               cv_time   // 生存時間で使う「時間」と
rename heart_attack_or_stroke_occurred          cv_event  // 生存時間で使う「イベント」の名前を揃えておくと後で便利

* --- variable labels (use original long names as labels) ---
label variable patient_id "patient_id"
label variable gender "gender"
label variable age "age"
label variable bmi "body_mass_index"
label variable smk "smoker"
label variable sbp "systolic_blood_pressure"
label variable htn_tx "hypertension_treated"
label variable fhx_cvd "family_history_of_cardiovascular_disease"
label variable af "atrial_fibrillation"
label variable ckd "chronic_kidney_disease"
label variable ra "rheumatoid_arthritis"
label variable dm "diabetes"
label variable copd "chronic_obstructive_pulmonary_disorder"
label variable fev1 "forced_expiratory_volume_1"
label variable cv_time "time_to_event_or_censoring"
label variable cv_event "heart_attack_or_stroke_occurred"

****************************************************
* 4) bool変数のラベル
****************************************************
local boolvars ///
	smk htn_tx fhx_cvd af ckd ra dm copd cv_event

foreach v of local boolvars {
	* 値ラベル付け（0/1）
	label define ny 0 "No" 1 "Yes", replace
	label values `v' ny
}

****************************************************
* 5)　Sanity Check Lv2: 分析前チェック
****************************************************
* 変数型の確認
des

* 二値変数が0/1であることの確認。それ以外の時は止る。
su `boolvars' 
foreach v of local boolvars {
	assert `v'==0 | `v'==1
}

* 性別も0/1であることの確認。それ以外の時は止る。
assert gender==0 | gender==1

* 年齢： 許容範囲 18-120
gen byte age_outlier = (age < 18 | age > 120) if !missing(age)
label variable age_outlier "Age out of plausible range (18-120)"
tab age_outlier, missing
su age if age_outlier == 1

* BMI： 許容範囲 10-60
gen byte bmi_outlier = (bmi < 10 | bmi > 60) if !missing(bmi)
label variable bmi_outlier "BMI out of plausible range (10-60)"
tab bmi_outlier, missing
su bmi if bmi_outlier==1

* 収縮期血圧： 許容範囲 50-300
gen byte sbp_outlier = (sbp < 50 | sbp > 300) if !missing(sbp)
label variable sbp_outlier "SBP out of plausible range (50-300)"
tab sbp_outlier, missing
su sbp if sbp_outlier==1

* 追跡時間： 非負
gen byte cv_time_outlier = (cv_time < 0) if !missing(cv_time)
label variable cv_time_outlier "Negative follow-up time"
tab cv_time_outlier, missing
su cv_time if cv_time_outlier==1

****************************************************
* 6) 欠損の把握
****************************************************
* ここでは一旦、欠損への対応はせずに、把握だけする
misstable summarize 


foreach v in bmi sbp fev1 cv_time {
    gen byte miss_`v' = missing(`v')         // 1 if missing
    label values miss_`v' miss01
    label variable miss_`v' "`v' missingness"
}

****************************************************
* 7) 保存
****************************************************
* 最終チェック
codebook 

compress
label data "Cleaning済"
save "`write_file'", replace

di "=== Clean done: saved cardio_clean.dta ==="

cap log close
