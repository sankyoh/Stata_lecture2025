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
global PROJ "C:\stata_course_project" // 例

* 5) よく使うフォルダをグローバルにしておく
global RAW "$PROJ\data_raw"
global CLEAN "$PROJ\data_clean"
global DO "$PROJ\do"
global LOG "$PROJ\log"
global OUT "$PROJ\output"

di "=== Config loaded ==="
di "Project root: $PROJ"
```

### グローバル / ローカルの使い分け（この回の必須）
Stataにおけるグルーバルマクロ / ローカルマクロとは何か？
- global：プロジェクト全体で共有したい（パス、定数）
- local：そのdoファイル内だけで使いたい（共変量リスト、作業用の短期変数）

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
****************************************************

* 1) 生データの場所（例：Zenodoから落として data_raw に置いた想定）
local in_file "$RAW\cvd_synthetic_dataset_v0.2.csv"
local out_file "$RAW\df00.dta"

* 2) import delimited（TSVなので delimiter(tab) を明示）
import delimited using "`in_file'", delimiter(tab) varnames(1) clear


* 3) Sanity Check Lv1
// 目的：データが壊れていないか確認する

* 変数型・行数
describe  // 変数型がおかしくないか？
count     // 行数は想定通りか？

* patient_id の欠損確認
count if missing(patient_id) 

* patient_id の重複
duplicates report patient_id 

* 明らかにおかしい値が「見えてしまう」か確認
summarize age body_mass_index systolic_blood_pressure ///
    time_to_event_or_censoring

* ここでは直さない。判断もしない。
di "Sanity Check Lv1 completed (no modification applied)"

* 4) raw保存（ここではまだ整形しない）
save "`out_file'", replace

di "=== Import done: saved `out_file' ==="
```

# 3. データクリーニング

ここが第2回の主役です。
以後の回で、回帰もPSも生存解析もやりますが、**それらが正しく動くかどうかはここで決まります**。

この回でやるのは、次の5つです。

1. `patient_id` の一意性に問題があれば修正。
2. bool変数（二値変数）に0/1以外があれば、その対応。
3. `gender` が文字列なので、0/1（またはラベル付きカテゴリ）に整形。
4. 欠損を「把握」する（補完は第5回）
5. 変数ラベル・値ラベルを付ける（読めるデータにする）

---
## 3.1 02_clean.do（サンプル）
``` stata
****************************************************
* 02_clean.do
* 役割：分析可能なデータセットに整形して保存
****************************************************

use "${RAW}\cardio_raw.dta", clear

****************************************************
* 0) IDチェック（最重要）
****************************************************

* patient_id が欠損していないか
count if missing(patient_id)
* もし欠損があるなら、ここで止める方針もあり得る
* （今回は合成データで通常はない想定）

* patient_id が一意か（重複があると以後の解析が崩壊する）
capture noisily isid patient_id
if _rc != 0 {
    di as error "ERROR: patient_id is not unique. Please check duplicates."
    duplicates report patient_id
    exit 459
}

****************************************************
* 1) 文字列のトリム（意外と重要）
****************************************************
* TSV由来で余計な空白が混ざることがあるため、先に除去しておく
foreach v in gender {
    replace `v' = strtrim(`v') if !missing(`v')
}

****************************************************
* 2) gender の整形
****************************************************
* 方針：M/F を 0/1 に変換し、ラベルを付与する
gen byte female = .
replace female = 1 if gender == "F"
replace female = 0 if gender == "M"

label define L_female 0 "Male" 1 "Female"
label values female L_female
label variable female "Female (1) vs Male (0)"

* 元のgenderは残してもよいが、分析では female を使う前提にする
label variable gender "Gender (raw: M/F)"

****************************************************
* 3) bool → 0/1 変換
****************************************************
* 合成データの bool は、"true"/"false" の文字列として入ることがある
* ここでは「文字列なら文字列として処理」「既に数値ならそのまま」を想定して安全に書く

local boolvars ///
    smoker hypertension_treated family_history_of_cardiovascular_disease ///
    atrial_fibrillation chronic_kidney_disease rheumatoid_arthritis ///
    diabetes chronic_obstructive_pulmonary_disorder ///
    heart_attack_or_stroke_occurred

foreach v of local boolvars {

    * 変数型の確認：文字列なら変換、数値なら確認のみ
    capture confirm string variable `v'
    if _rc == 0 {
        * 文字列の場合：true/false を 1/0 に
        gen byte `v'_bin = .
        replace `v'_bin = 1 if lower(`v') == "true"
        replace `v'_bin = 0 if lower(`v') == "false"

        * 変換後の欠損が多いなら、想定外の値がある可能性
        count if missing(`v'_bin) & !missing(`v')
        if r(N) > 0 {
            di as error "WARNING: unexpected values in `v' (raw). Check!"
            tab `v', missing
        }

        drop `v'
        rename `v'_bin `v'
    }
    else {
        * 数値の場合：0/1かどうかをざっくり確認
        tab `v', missing
    }

    * 値ラベル付け（0/1）
    label define L01 0 "No/False" 1 "Yes/True", replace
    label values `v' L01
}

****************************************************
* 4) 連続変数の型・単位の確認
****************************************************
* ここでは “解析” はしないが、異常値や型は早めに気づく
describe age body_mass_index systolic_blood_pressure forced_expiratory_volume_1 ///
    time_to_event_or_censoring

summarize age body_mass_index systolic_blood_pressure forced_expiratory_volume_1 ///
    time_to_event_or_censoring, detail

* 例：BMIが負の値など、明らかな異常値があればフラグを立てる（今回は合成なので通常ない想定）
gen byte bmi_outlier = (body_mass_index < 10 | body_mass_index > 60) if !missing(body_mass_index)
label variable bmi_outlier "BMI outlier flag (10-60 outside)"
tab bmi_outlier, missing

****************************************************
* 5) 欠損の把握（補完は第5回）
****************************************************
* 第4回で回帰をするときに「Stataが勝手に欠損行を落とす」ことを見せるため、
* 欠損を “消さずに” ここでは把握だけする

misstable summarize age body_mass_index systolic_blood_pressure forced_expiratory_volume_1 ///
    smoker diabetes hypertension_treated heart_attack_or_stroke_occurred ///
    time_to_event_or_censoring

****************************************************
* 6) 変数ラベル（読みやすさは再現性）
****************************************************
label variable patient_id "Patient identifier"

label variable age "Age (years)"
label variable body_mass_index "Body mass index (kg/m^2)"
label variable systolic_blood_pressure "Systolic blood pressure (mmHg)"
label variable forced_expiratory_volume_1 "FEV1 (% predicted)"
label variable time_to_event_or_censoring "Time to event or censoring (years)"

label variable hypertension_treated "On hypertension treatment (binary)"
label variable family_history_of_cardiovascular_disease "Family history of CVD (binary)"
label variable atrial_fibrillation "Atrial fibrillation (binary)"
label variable chronic_kidney_disease "Chronic kidney disease (binary)"
label variable rheumatoid_arthritis "Rheumatoid arthritis (binary)"
label variable diabetes "Diabetes (binary)"
label variable chronic_obstructive_pulmonary_disorder "COPD (binary)"
label variable smoker "Smoker (binary)"
label variable heart_attack_or_stroke_occurred "Heart attack or stroke occurred (binary)"

****************************************************
* 7) 最終チェック＆保存
****************************************************

* 最後に型と分布を確認
codebook patient_id female age body_mass_index systolic_blood_pressure ///
    smoker diabetes hypertension_treated time_to_event_or_censoring ///
    heart_attack_or_stroke_occurred

compress

save "${CLEAN}\cardio_clean.dta", replace

di "=== Clean done: saved cardio_clean.dta ==="
```
