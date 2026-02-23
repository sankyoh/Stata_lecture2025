****************************************************
* 00_config.do
* 役割：環境設定・パス設定・共通オプション
****************************************************

* 1) Stataのバージョン固定（再現性のため）
version 19.0

* 2) 出力の停止を防ぐ
set more off

* 3) 実行結果の表示桁数（好みで調整：通常は触らないで良いので、コメントアウトしている）
// set cformat %9.3f
// set pformat %9.3f
// set sformat %9.3f

* 4) プロジェクトルートの指定
* 受講者PCのパスは環境で異なるため、ここだけ編集すれば良い設計にしている。
global PROJ "<ここにプロジェクトのルートフォルダを入れる>" 

* 5) よく使うフォルダをグローバルにしておく
global RAW   "$PROJ\data_raw"
global CLEAN "$PROJ\data_clean"
global DO    "$PROJ\do"
global LOG   "$PROJ\log"
global OUT   "$PROJ\output"

di "=== Config loaded ==="
di "Project root: $PROJ"