****************************************************
* master.do
* 役割：上から順にモジュールを呼ぶ
****************************************************

* 0) config
// 00_config.doのみは、master.doと同じディレクトリに置く。グローバルマクロ「$DO」の設定は00_config.do内で行うため。
do 00_config.do

* 1) import
// raw.csv -> df00.dta
do "$DO/01_import.do"

* 2) clean
// df00.dta -> df01.dta
do "$DO/02_clean.do"

* 3) descriptive statistics
// df01.do -> Excel file
do "$DO/03_table1.do"

// make_table1.adoを利用したバージョン

do "$DO/03_table1suppl.do"

* 4) GLM analysis (regress, logistic, modified poisson)
do "$DO/04_models_glm.do"

* 5) Results: Export to Excel
do "$DO/05_models_glm_export.do"

* 6) Results: Export to Excel, compact
do "$DO/06_models_glm_export_compact.do"
