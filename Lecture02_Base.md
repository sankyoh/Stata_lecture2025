# 第2回— Stataプロジェクトの作り方 ＋ データクリーニングの作法

この回は「解析そのもの」ではなく、**解析に耐える土台づくり**を目的にします。  
実務で一番トラブルが起きやすく、それに気づけないと大きな間違いに繋がるのは、回帰や生存解析のコマンドではなく、**データの読み込み・整形・管理**です。ここが曖昧なまま進むと、同じ解析を再現できなかったり、変数の意味が途中でズレたり、doファイルが破綻したりします。

---

## テーマ

**「Stataプロジェクトの作り方 ＋ データクリーニングの作法」**

---

## 到達目標

この回のゴールは3つです。

1) doファイルを**分割する理由**が腹落ちする  
2) 生データ（今回はcsvファイル）を「分析可能なデータ」に変換できる  
3) 次回以降の分析がブレないように、**共通の作法**（命名・ラベル・ログ・保存）を身につける  

---

## データの入手先

- データ：CC0 合成データ（心筋梗塞/脳卒中リスク）
- [Zenodo](https://zenodo.org/records/12567416)

<img width="2118" height="608" alt="image" src="https://github.com/user-attachments/assets/9dc31ec3-6869-4f1a-ac8e-b2fc451f06db" />

## データの内容
ダウンロードした`cvd_synthetic_dataset_v0.2_metadata.xlsx`に説明があります（もちろん英語）。
- 形式：CSV（comma separated values）
- 重要変数：
  - `patient_id`（個体識別子）
  - `gender`（"M"/"F"）
  - `smoker` や `diabetes` など（bool：true/false想定）
  - `time_to_event_or_censoring`（年単位）
  - `heart_attack_or_stroke_occurred`（イベント発生：bool）

> 注意：この回では **解析（回帰や生存解析）はしません**。  
> 「分析用データセット」を作って保存するところまでがゴールです。

---

# 1. プロジェクト設計

## 1.1 なぜ「1 do = 1役割」なのか

Stata初心者から脱し、doファイルを作るようになると、まず陥りやすい罠として、「とりあえず全部1本のdoに書く」があります。  
短期的には楽ですが、長期的には次の問題が必ず起きます。

- 途中の整形を変更したら、後半の解析が壊れる。
- どこで何をしているか、あとから追えない。
- 同じ処理を別案件で再利用できない。
- 実務で必要な「レビュー」「共同作業」「再現性」が至難になる（最悪の場合、不可能に）。

そこで本コースでは、最初から以下の考え方で進めます。

- **1つ1つのdoファイルは小さく、役割を明確に（モジュール化）**
- **master.do が各モジュールを順に呼び出す**
- どの回でも「読み込み→整形→保存」や「読込み→解析」の流れが追える

---

## 1.2 推奨フォルダ構成

次のような構成を推奨します（手元PCで作れる範囲でOK）。

``` text
project/
├─ data_raw/ # ダウンロードした元データ（絶対に上書きしない）
├─ data_clean/ # 分析用に整形済みデータ
├─ do/ # doファイル置き場
├─ log/ # ログ置き場
└─ output/ # 表・図などの成果物（数が多い時は、分類用にフォルダを増やしても良い）
master.do / # 司令塔的存在
00_config.do / # 分析環境の固定
tutorial.stpr / # Stataプロジェクトファイル
```

**ポイント**
- `data_raw` は「触らない」領域です。
元データを上書きすると、やり直しができなくなります（このコースで使っているのは、ダウンロード可能なので、やり直し可能ですが…）。
- 整形済みデータは `data_clean` に置きます。
「解析は data_clean から始まる」というルールにするとデータ破壊事故が減ります。

## 補足：Stataプロジェクトファイル（.stpr）について

Stataには「プロジェクトファイル（`.stpr`）」という仕組みがあります。
これは、解析結果やデータそのものを保存するものではなく、
**「作業環境」をまとめて管理するためのファイル**です。

具体的には、

- どのフォルダを作業ディレクトリとして使っているか
- どの do ファイルやデータを開いていたか

といった情報を記録してくれます。

中断した解析を再開するときには、stprファイルを開くことでスムーズに再開出来ます。

### Stataプロジェクトファイルを生成する
doファイルエディターで、【ファイル】>【新規】>【プロジェクト…】を選択することで、新しいStataプロジェクトファイルの作成ができます。

<img width="456" height="386" alt="image" src="https://github.com/user-attachments/assets/565cd620-6929-4962-b575-2883e0e74e7c" />

今回は、`csv_synthetic_prf.stpr`を`project`フォルダに作成します。

Stataプロジェクトファイルが開いている状態だと、doファイルエディターの左端（環境によっては右端）に、下記の様な「プロジェクト」が出現します。

これを利用して、doファイルやdtaファイルなどを管理します。

<img width="288" height="234" alt="image" src="https://github.com/user-attachments/assets/76cbc809-c6a9-4a91-9ec9-0db719d4fb16" />

### Stataプロジェクトファイルを構成する
#### 1. プロジェクト内にグループを作ります。【cvd_synthetic_prj】右クリックして、新規グループを追加を選択します。
新規グループとして、`00_Dataset`と`10_DataICL`を追加してください。なお、ICLは、Import, Cleaning, and Labelingの略語です（三橋による造語ですので、他ではICLは通じません）。

#### 2. 【cvd_synthetic_prj】を右クリックして、【新規ファイルを追加】を選択します。

<img width="413" height="388" alt="image" src="https://github.com/user-attachments/assets/a8aa419f-f1e0-4786-a3ad-fa724e5c1c53" />

新規ファイルとして、`master.do`と`00_config.do`を`project`フォルダ直下に置きます。

<img width="289" height="179" alt="image" src="https://github.com/user-attachments/assets/4ee54468-7421-4482-a850-0fc4a156b9e5" />

出来上がりはこのようになります。

#### 3. 【01_DataICL】を右クリックして、【新規ファイルを追加】を選択します。

<img width="422" height="425" alt="image" src="https://github.com/user-attachments/assets/34e4d484-4b0e-4853-949b-c4eae0d80b09" />

新規ファイルとして、として`01_import.do`と`02_clean.do`を`project\do`フォルダに置きます。

<img width="288" height="233" alt="image" src="https://github.com/user-attachments/assets/0e76b15d-0ad2-48c9-802e-4865741d9266" />

出来上がりはこのようになります。

第2回は、ここまで出来ればOKです。次回以降も適宜追加していきます。

### なぜ本コースで .stpr を使うのか

このコースでは、解析を「単発の作業」ではなく、
**プロジェクトとして積み上げる**ことを重視します。

`.stpr` を使うことで、

- 毎回 cd で迷わない
- 関連ファイルを1か所にまとめられる
- master.do を中心とした構造が分かりやすくなる

といったメリットがあります。

### 注意点

- Stataプロジェクトファイルを使わなくても解析はできます。
- 本コースの再現性は、主に`master.do`ファイルによって担保されます
- Stataプロジェクトファイルの目的はあくまで「環境の整理」です。

---
## 1.3 master.do の考え方

`master.do` は「上から順に処理を流すだけ」の司令塔です。
中身に処理を書きすぎないことが重要です。

- `00_config.do`（環境・パス・共通設定）
- `01_import.do`（読み込み）
- `02_clean.do`（クリーニング）
- （次回以降）`03_table1.do`, `04_models...do` など

---
## 1.4 master.do（サンプル）
``` stata
****************************************************
* master.do
* 役割：上から順にモジュールを呼ぶ
****************************************************

* 0) config
// 00_config.doのみは、master.doと同じディレクトリに置く。グローバルマクロ「$DO」の設定は00_config.do内で行うため。
do 00_config.do

* 1) import
// raw.csv -> df00.dta
do "$DO\01_import.do"

* 2) clean
// df00.dta -> df01.dta
do "$DO\02_clean.do"

di "=== Session 2 completed successfully ==="
```

この構造にしておくと、「第2回の範囲は master.do を回せば再現できる」状態になります。

---
## 1.5 00_config.do の役割（超重要）

`00_config.do` は「分析の環境」を固定します。
ここがあるだけで再現性が段違いに上がります。

### 00_config.do（サンプル）

``` stata
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
global PROJ "C:\Users\sanky\Dropbox\kougi学部・大学院講義\eki疫学統計分析演習2\FY2025\project" 

* 5) よく使うフォルダをグローバルにしておく
global RAW "$PROJ\data_raw"
global CLEAN "$PROJ\data_clean"
global DO "$PROJ\do"
global LOG "$PROJ\log"
global OUT "$PROJ\output"

di "=== Config loaded ==="
di "Project root: $PROJ"
```

## 補足：Stataにおける「マクロ」とは何か
Stataでいう **マクロ（macro）** とは、
> **文字列に名前を付けて、一時的に保存・再利用する仕組み**
のことです。

難しく考える必要はなく、
**「Stata用のメモ帳」や「置き換え用のラベル」** だと思ってください。
- global：プロジェクト全体で共有したい（パス、定数）
- local：そのdoファイル内だけで使いたい（共変量リスト、作業用の短期変数）

グローバルマクロ（`global`コマンドで設定）は、「Stataを起動している間、どの do ファイルからでも参照できるマクロ」です。これを濫用すると後で困るので、最小限の利用にします。
- プロジェクトのフォルダの位置
- プロジェクト全体で共通の設定

ローカルマクロ（`local`コマンドで設定）は、「その do ファイル（あるいはプログラム）の中だけで使える一時的なマクロ」です。
- 回帰モデルの共変量リスト
- foreach / forvalues の制御変数
- 一時的な作業用の名前

今回のルール：
- パスは globalマクロで指定する（例：global RAW）
- 変数リスト等はlocalマクロで指定する（例：local x age bmi sbp ...）

---
# 2. データ読み込み

CSVやExcelファイルなどの読み込みは一見簡単ですが、実務では罠が多いです。
この回では特に次の点を意識します。
- gender が文字列として入っている
- bool（true/false）が文字列として入ることがある
- patient_id の重複があると、以後の解析すべてが崩れる

## 2.1 01_import.do の作り方

読み込みのdoは「読み込んで保存する」および「最低限のチェック」だけにします。
このように細かくチェックするのではなく、とりあえず辻褄があっているかどうか、明らかな不整合や不具合がないかどうかを手早く確認することSanity Checkと呼びます。
ここでは、Sanity Checkまで行い、整形は次の 02_clean.do に回します。

### Sanity Check の考え方

Sanity check とは、「そのデータが常識的におかしくないか」を確認する工程です。  
重要なのは、**sanity check は解析ではない**という点です。

- 統計的に正しいか → まだ考えない
- 因果的に妥当か → まだ考えない
- **人間の感覚で見て変ではないか** → ここで確認する

このコースでは sanity check を2段階に分けます。

- Lv1：読み込み直後（壊れていないかの確認、01_import.doで実行する）
- Lv2：クリーニング後（使ってよいかの確認、02_clearn.doで実行する）

01_import.do（サンプル）

``` stata
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
```

# 3. データクリーニング

ここが第2回の主役です。
以後の回で、回帰もPSも生存解析もやりますが、**それらが正しく動くかどうかはここで決まります**。

この回でやるのは、次の6つです。

1. `patient_id` の一意性に問題があれば修正。
2. `gender` が文字列なので、0/1（ラベル付きカテゴリ）に整形。
3. bool変数（二値変数）に0/1以外があれば、その対応。
4. 異常値があれば、それを「把握」する。
5. 欠損を「把握」する。
6. 変数ラベル・値ラベルを付ける。

- 他のデータセットを触るときでも、1から5については、ここで示しているサンプルコードを少し手を加えることで対応可能です。
- 6については、データセット毎に一から作り直す必要がありますが、変数表があれば、それをLLM(ChatGPTなど)に読み込ませて、Stataのコードを作らせると良いです。

---
## 3.1 02_clean.do
``` stata
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
assert patient_id!=""

* patient_id が一意か（重複があると以後の解析が崩壊する）
// idの重複があれば、ここで止る
isid patient_id

****************************************************
* 1) 文字列のトリム
****************************************************
* CSV由来で余計な空白が混ざることがあるため、先に除去しておく
// "F"の代わりに" F"となっていても、人間の眼ではわからないので、機械的に変換する。
foreach v in gender {
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
	* 値ラベル付け（0/1）
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
```

## 3.2 第2回で強調する「作法」

### (A) 生データは上書きしない
* `data_raw`フォルダは保護区・聖域・禁漁区なので、このデータには触らないようにします。
* 編集は `data_clean` に作って保存して、利用します。

### (B) 変数の意味が伝わるようにする（ラベル）
* 共同研究で効いてくるのは、変数名よりラベルです。
* `label variable` と `label define/values` を必ず入れてください。

### (C) 欠損値は「この回では直さない」
* 欠損を直したくなるのが人情ですが、ここでは一旦おいておきます。
* 後の回（第4回を予定）で回帰をやる際に「欠損があるとNが減る」を体験するため、欠損は残します。
* 欠損への対応は、第5回（オンデマンド）などで扱います

### (D) 「安全に書く」習慣
`02_clean.do`では、ところどころで「止る」ための`assert`コマンドを入れています。
また、外れ値のフラグも作成しました。これらに注目することで、後の解析で「安全に」解析を進めることができます。

---
# 4. この回の小課題
「doを分割する理由」を体感できるように、下記が出来るようにして下さい。

## 課題1：フォルダ構成を作る
* `data_raw`, `data_clean`, `do`, `log` を`project`フォルダに作成して下さい。
* `00_config.do` の `global PROJ` を自分のPCに合わせて修正してください。

## 課題2：master.do を回して `cardio_clean.dta` を生成
* `master.do`を実行し、クリーニングしたデータセットが`data_clean`フォルダに出力されることを確認して下さい。
* `master.do`を実行し、ログが `log`フォルダに出力されることを確認してください。

## 課題3：変数が正しいかチェック
* logを確認し、genderが正しく変換できていることを確認して下さい。
* どの変数に欠損値がどのくらいあるのか、確認して下さい。
* どの変数に外れ値があるのか、確認して下さい。

# 5. まとめ（第2回の位置づけ）

第2回で作った`df01_clean.dta` は、次回以降で使います。
つまり、第2回は「すべての回の土台」です。

* doを分割する理由は「きれいに見せるため」ではなく、**事故を防ぎ再現性を担保するため**
* データクリーニングは、単なる整形ではなく「意味を固定する作業」

次回（第3回）では、この `df01_clean.dta` を使って記述統計（Table 1）を作ります。
推測統計・解析へ進む前に、データを正しく語れる状態にしていきます。

