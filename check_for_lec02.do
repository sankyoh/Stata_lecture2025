* 環境のチェック
display "OS: " c(os)
display "PWD: " c(pwd)

* 00_config.doで設定したglobal macroの中身を確認する
macro list PROJ RAW CLEAN DO LOG OUT

* doフォルダの確認
display "$DO"
dir "$DO/"

* スラッシュとバックスラッシュ
confirm file "$DO/01_import.do"
confirm file "$DO\01_import.do"
