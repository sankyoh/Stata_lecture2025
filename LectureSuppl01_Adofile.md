# 番外編：`dtable` を ado ファイル化して「自分専用コマンド」を作ろう 
（make_table1.ado を PERSONAL に置いて、以後ずっと楽に運用する）

この番外編は、**長い `dtable` を毎回コピペする苦痛**を、今ここで終わらせる方法について説明します。

Lecture03では、`dtable`に沢山のオプションを付けて、自分用のTable.1を作成しました。
この方法でも良いですが、課題もあります。

- Table 1 を作るたびに `dtable ...` を探して貼り付け
- ちょっと修正して、別の場所では古い版を貼り付け
- どれが最新版か分からなくなって混乱

…これで地味に時間を削られます。  
そこで **「カスタムコマンド化（ado化）」**すると、最初だけ少し面倒でも、その後はずっと楽になります。

---

## 今日のゴール 🎯

1. `dtable` の長い呪文を **`make_table1`** という短いコマンドにまとめる。
2. `sysdir` で **PERSONAL** の場所を確認して、そこに `make_table1.ado` を格納する。
3. 以後はどのプロジェクトでも `make_table1 ...` で Table 1 を一発出力できるようにする。

---

## イントロ：なぜ ado ファイル化するのか

### do ファイルのコピペは、最初は楽。でも…
最初は「とりあえず動けばOK」で、コピペでも回ります。  
ただし、回数を重ねるとコピペが地獄になります。

- **同じ処理**をあちこちに複製する（DRY原則[^1]が崩れる）
- 修正が入ったとき、全部直すのが面倒で **直し漏れが起きる**
- 微修正した「自分の正解」が散らばって、**再現性が落ちる**

### ado 化のメリット
ado 化すると、Table 1 作成が次のように変わります。

- Before：長い `dtable ...` を探して貼って、変数名を直して…（毎回）
- After ：`make_table1` を呼ぶだけ（毎回同じ）

> **最初に1回だけ頑張ると、その後ずっと楽。**  
> これが**ado化**のメリットです。

---

## Lecture03の長い `dtable`

以下が、adoファイルにする元ネタの `dtable` コマンドです（長い！）：

~~~stata
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
		export("`write_file1'", as(xlsx) replace)
~~~

「毎回これをコピペして、`des_vars` とか `sd_vars` とか入れ替える」  
…そのうち、面倒になります。また、微修正したマイナーチェンジバージョンが大量に発生してしまいます。
そして、「どれが最新版だったっけ…？」という現象が生じます。

---

# 1. ado ファイル化の基本を端的に

## ado ファイルとは？
Stata では、`program define ... end` で作ったコマンドを

- `make_table1.ado`

のようなadoファイルにして、Stata が検索できる場所（PERSONAL など）に置くと、  
**`make_table1` というコマンドとして呼べる**ようになります。

### 名前のルール
- ファイル名：`make_table1.ado`
- 内部のprogram定義：`make_table1`
- 呼び出すコマンド名：`make_table1`

つまり、ファイル名・program名・コマンド名が一致していることが必要です。

---

# 2. コマンド設計：どんな引数を受け取るか

今回の `make_table1` は、以下を受け取る設計です。

- **varlist（Table1で表示したい変数の一覧）**
  - 連続変数はそのまま（例：`age bmi sbp`）
  - カテゴリ変数は `i.` を付ける（例：`i.smk i.dm`）
- **by()**：層別する変数（例：`by(dm)` や `by(cv_event)`）
- **sdvars()**：平均±SDで出す連続変数
- **iqrvars()**：中央値[IQR]で出す連続変数（任意）
- **writefile()**：出力するExcelファイル名
- **[weight] [if] [in]**：必要なら重みや解析対象も指定できる

> 設計の狙い：  
> 「Table 1 に何を表示するか？という「意思決定」はユーザーにやらせる」  
> 「表の体裁はコマンドが面倒を見る」  
> という分業です。

---

# 3. ado ファイル内で引数をどう処理するか（ポイント解説）

`make_table1.ado` の中では、ざっくり次の流れで処理しています。

1. `syntax` で引数（varlistやoption）を受け取る  
2. `marksample` で `if/in` を含めた解析対象（touse）を作る  
3. 重みがある場合は、dtableに渡す指定を組み立てる（＋安全チェック）
4. sdvars / iqrvars の整合性をチェック（重複や指定ミスを早期に止める）
5. `dtable` を実行し、`export()` でExcel出力する

> コピペ運用だと「ミスっても気づきにくい」ですが、  
> ado 化すると「間違いを検知して止める」安全装置を入れやすいのが強みです 👍

---

# 4. ado ファイルの提示（添付の make_table1.ado をそのまま）

以下は ** `make_table1.ado` を変更せず、そのまま**貼り付けたものです。
これをStataのDoファイルエディタにコピペして、`make_table1.ado`という名前で保存してください。
拡張子が`.do`ではなく、`.ado`になっていることを確認して下さい。

~~~stata
*! make_table1.ado  v1.2.0  16feb2026
program define make_table1
    version 18.0

    // varlist は i. を含んでOK（fv）
    // [weight] も受け取る（pweight/aweight/fweight/iweight）
    syntax varlist(fv) [if] [in] [fweight aweight pweight iweight], ///
        BY(name) ///
        SDVARS(varlist numeric) ///
        [ IQRVARS(varlist numeric) ] ///
        WRITEFILE(string asis)

    marksample touse, strok

    // --------------------------
    // 0) 重みの処理（オプション文字列を組み立て）
    // --------------------------
    local wopt ""
    local wnoteopt ""
    local wfmtopt ""

    if "`weight'" != "" {
        // dtableへ渡すweight指定（例: [pweight=sw]）
        local wopt "[`weight'`exp']"

        // exp から式だけ取り出す（=を除去）
        local wexpr = strtrim(subinstr("`exp'", "=", "", .))

        // 解析対象内で重み欠損/<=0 を弾く（安全策）
        quietly count if `touse' & missing(`wexpr')
        if r(N) > 0 {
            di as error "重みが欠損の観察が含まれています（if/in を含む解析対象内）: N=" r(N)
            exit 2000
        }
        quietly count if `touse' & (`wexpr'<=0)
        if r(N) > 0 {
            di as error "重みが0以下の観察が含まれています（if/in を含む解析対象内）: N=" r(N)
            exit 2000
        }

        // (1) カテゴリ変数（因子）の度数は fvfrequency / fvrawfrequency で出る
        //     重み付きのときは非整数になり得るので小数2桁に上書き
        // (2) sample 行は重みなし=frequency, 重みあり=sumw になる（dtableの仕様）
        //     こちらも小数2桁に（重み付きのときだけ）
        local wfmtopt ///
            "nformat(%16.2fc fvfrequency fvrawfrequency frequency sumw)"

        // (3) 重み付きのときだけ note を自動追記
        local wnoteopt "note("Weighted using `weight'`exp'")"
    }

    // --------------------------
    // 1) 事前チェック：sdvars/iqrvars の整合
    // --------------------------
    local overlap : list sdvars & iqrvars
    if "`overlap'" != "" {
        di as error "sdvars() と iqrvars() が重複しています: `overlap'"
        exit 198
    }

    local allcont "`sdvars' `iqrvars'"

    // varlist 内の「素の変数名」一覧（i.等の接頭辞を剥がす）
    local rawvars ""
    foreach tok of local varlist {
        local base "`tok'"
        if strpos("`tok'", ".") {
            local base = substr("`tok'", strpos("`tok'", ".")+1, .)
        }
        // 念のため # を分解（通常は入れない想定）
        local base2 : subinstr local base "#" " ", all
        foreach v of local base2 {
            local rawvars `rawvars' `v'
        }
    }
    local rawvars : list uniq rawvars

    // sdvars/iqrvars が des_vars に含まれているかチェック
    foreach v of local allcont {
        local pos : list posof "`v'" in rawvars
        if `pos'==0 {
            di as error "連続変数 `v' が des_vars(varlist) に含まれていません。"
            di as error " -> des_vars に `v' を追加してください（i.は付けない）。"
            exit 198
        }
    }

    // 「連続以外」は i. になっているかチェック
    // 連続が i. になってたらエラー
    foreach tok of local varlist {
        local base "`tok'"
        if strpos("`tok'", ".") {
            local base   = substr("`tok'", strpos("`tok'", ".")+1, .)
        }
        if strpos("`base'", "#") continue

        local posc : list posof "`base'" in allcont
        if `posc' > 0 {
            if substr("`tok'",1,2)=="i." {
                di as error "連続変数 `base' が因子表記(i.)になっています: `tok'"
                di as error " -> i. を外すか、sdvars()/iqrvars() の指定を見直してください。"
                exit 198
            }
        }
        else {
            if substr("`tok'",1,2)!="i." {
                di as error "非連続変数は i.varname の形にしてください。問題トークン: `tok'"
                di as error " -> もし連続なら sdvars() か iqrvars() に入れてください。"
                exit 198
            }
        }
    }

    // --------------------------
    // 2) 出力ファイル名
    // --------------------------
    local outfile `writefile'
    if !regexm(lower("`outfile'"), "\\.xlsx$") {
        local outfile "`outfile'.xlsx"
    }

    // iqrvars が空なら、その指定は省略（空だと全連続のデフォルト上書きの危険）
    local iqr_opt ""
    if "`iqrvars'" != "" {
        local iqr_opt `"`iqr_opt' continuous(`iqrvars', statistics(q2 iqi))"'
    }

    // --------------------------
    // 3) dtable 本体（重み・フォーマット・注記を条件付きで追加）
    // --------------------------
    dtable `varlist' if `touse' `wopt', ///
        by(`by', nototals notests missing) ///
        column(by(label)) ///
        sample(, place(seplabels)) ///
        ///
        define(iqi = q1 q3, delimiter(", ")) ///
        sformat("[%s]" iqi) ///
        ///
        nformat(%16.2fc mean sd q1 q2 q3) ///
        `wfmtopt' ///
        continuous(`sdvars', statistics(mean sd) test(regress)) ///
        `iqr_opt' ///
        factor(, test(pearson)) ///
        ///
        note(Mean(SD) or N(%)) ///
        note(Median[IQR]) ///
        `wnoteopt' ///
        export("`outfile'", as(xlsx) replace)

end
~~~

## 4.2 adoファイルの中身がかなり長い
Lecture03で提示していた`dtable`コマンドからすると大分ながくなっています。

これは、
- `syntax`コマンドを付け加える必要がある
- エラー処理を行う必要があること
という理由があります。

エラー処理については、完全にエラーがない利用を行い続けるのであれば、必要ありません。
そのため、自分でadoファイルをつくるときには、エラー処理を省略してしまうことも可能です。

今回は、0から2がエラー処理になっています。
いろいろな条件で使っていると、dtableの実行中になんだかエラーが出る事があったので、段々と拡張していった感じです。
Stataの公式コマンドや他の人がつくっている外部コマンドも読み解いてみると、「エラー処理」に結構な労力を割いていることが分かります。
- 0) 重みの処理（オプション文字列を組み立て）
- 1) 事前チェック：sdvars/iqrvars の整合
- 2) 出力ファイル名
 
この部分の説明は、今回は省略しますが、「誰が使っても使えるような工夫があるんだなぁ」くらいに思っておいて下さい。
完全に自分しかつかわない場合は、自らがエラーになるような使い方を敢てしないはずなので、エラー処理はここまで長くしなくても大丈夫と思います。
 
実態として必須の部分は、
- syntaxコマンド
- 3) dtable 本体（重み・フォーマット・注記を条件付きで追加）
この2箇所です。

このうち、「3) dtable 本体（重み・フォーマット・注記を条件付きで追加）」は、Lecture03と同等なので、説明を省略します。

残ったsyntaxコマンドの部分を確認します。


## 4.3 syntaxコマンド

---

# 5. 完成した ado を格納する（PERSONAL に置く）

## 5.1 `sysdir` で PERSONAL を確認する
Stata のコマンドウィンドウで：

~~~stata
sysdir
~~~

すると、`PERSONAL` の行に「個人用 ado の置き場所」が出ます。  
例（出力イメージ）：

- PERSONAL: `C:\Users\...\ado\personal\`

> 注意：環境によって場所は違います。  
> **出力された PERSONAL のパス**が正解です。

## 5.2 PERSONAL 内に「m」フォルダを作る理由
Stata の慣習として、PERSONAL の下に **コマンドの先頭1文字フォルダ**を作り、

- `make_table1` → `m` フォルダ

に入れると整理しやすいです（後で増えても迷子になりにくい）。

## 5.3 実際に置く（やり方2通り）

### 方法A：エクスプローラーで作業（おすすめ）
1. `sysdir` で出た PERSONAL のフォルダを開く
2. `m` フォルダを作る（なければ新規作成）
3. その中に `make_table1.ado` をコピーする

配置はこうなります：

- `... \PERSONAL\m\make_table1.ado`

### 方法B：Stataからコピー（慣れたら便利）
手元にある `make_table1.ado` の場所（例）から PERSONAL にコピーします。

~~~stata
* 例：元ファイル（ダウンロードフォルダ等）から PERSONAL\m へコピー
* 元パスは各自の環境に合わせて修正してください
copy "C:\path\to\make_table1.ado" "C:\path\to\PERSONAL\m\make_table1.ado", replace
~~~

> PERSONAL のパスが長い場合は、`sysdir` の結果をコピペして使うのが安全です。

---

# 6. 置けたか確認する（必須チェック）

## 6.1 `which` で Stata が見つけられるか確認
~~~stata
which make_table1
~~~

期待するのは、「PERSONAL\m\make_table1.ado を見ている」ことです。  
もし違う場所（古い版）を指していたら、検索パスに別の `make_table1.ado` がある可能性があります。

---

# 7. 実際に使う：`make_table1` の基本形

## 7.1 基本の呼び出し（重みなし）

ポイントは2つだけです。

- 連続変数：そのまま書く（例：`age bmi sbp fev1 cv_time`）
- カテゴリ変数：`i.` を付ける（例：`i.smk i.htn_tx ...`）

例：`dm` で層別して Table 1 を作る（仮説の導入に便利）

~~~stata
* 例：Table 1（dm で層別）
* - sdvars(): 平均±SD で出したい連続
* - iqrvars(): 中央値[IQR] で出したい連続（任意）
* - writefile(): 出力xlsx（拡張子は省略可：自動で .xlsx が付く）

make_table1 ///
    age bmi sbp fev1 cv_time ///
    i.gender ///
    i.smk i.htn_tx i.fhx_cvd i.af i.ckd i.ra i.copd ///
    i.cv_event ///
    i.age_outlier i.bmi_outlier i.sbp_outlier i.cv_time_outlier ///
    , by(dm) ///
      sdvars(age bmi sbp fev1) ///
      iqrvars(cv_time) ///
      writefile("${OUT}\Table1_by_dm")
~~~

## 7.2 `cv_event` で層別して Table 1（イベント有無で比較）
~~~stata
make_table1 ///
    age bmi sbp fev1 cv_time ///
    i.gender ///
    i.smk i.htn_tx i.fhx_cvd i.af i.ckd i.ra i.copd ///
    i.dm ///
    i.age_outlier i.bmi_outlier i.sbp_outlier i.cv_time_outlier ///
    , by(cv_event) ///
      sdvars(age bmi sbp fev1) ///
      iqrvars(cv_time) ///
      writefile("${OUT}\Table1_by_event")
~~~

> コツ：`by()` に入れる変数は、通常は varlist 側に入れません（重複して見づらくなるため）。

---

# 8. 応用：重み付き（weight）で Table 1 を作る

`make_table1.ado` は `[pweight=] [aweight=] [fweight=] [iweight=]` を受け取ります。  
重みが指定されると、内部で安全チェックが動きます：

- 解析対象内で重みが欠損 → エラーで停止
- 解析対象内で重みが 0 以下 → エラーで停止
- 重み付きのときは度数が非整数になり得るので、表示フォーマットも調整

例（pweight の例）：

~~~stata
* 例：pweight=sw を使う（sw は各自のデータに合わせて）
make_table1 ///
    age bmi sbp fev1 cv_time ///
    i.gender i.smk i.htn_tx i.dm ///
    , by(cv_event) ///
      sdvars(age bmi sbp fev1) ///
      iqrvars(cv_time) ///
      writefile("${OUT}\Table1_weighted") ///
      [pweight=sw]
~~~

---

# 9. ありがちなエラーと対処（make_table1 が親切に止めてくれるやつ）

## 9.1 `sdvars()` と `iqrvars()` の重複
- 同じ変数を両方に入れるとエラーになります  
  → どちらで要約したいか決める

## 9.2 連続変数に `i.` を付けてしまった
- `sdvars(age)` なのに varlist で `i.age` と書くと止められます  
  → 連続は `i.` なしで書く

## 9.3 カテゴリ変数に `i.` を付け忘れた
- `smk` を `i.smk` にしていないと止められます  
  → カテゴリ（0/1含む）は基本 `i.` を付ける

## 9.4 `sdvars()` / `iqrvars()` が varlist に含まれていない
- 連続変数は「表に出す」前提なので、varlistにも含める必要があります  
  → varlist へ追加する

---

# 10. まとめ：今後ずっと効く “投資” 💪

この番外編でやったことは、ただの小技ではなく、

- **作業をプロジェクト化する**
- **同じ処理を再利用する**
- **自分の正解を1か所に集約する**

という研究実務の基礎体力です。

一度 PERSONAL に入れてしまえば、次からは：

- `make_table1 ...` で一発
- 表の体裁も統一
- 修正もadoだけ直せばOK

になります。

> ここから先の講義（回帰、PS、サバイバル）でも  
> 「コマンド化できる部分はコマンド化する」発想が使えます。

（おまけ）余力があれば、`make_table1.sthlp` を作って `help make_table1` を出せるようにすると、さらに“自分専用パッケージ感”が出て気持ちいいです 😎

[^1]: DRY原則（Don't Repeat Yourself）は、「同じ知識や情報を、複数の場所に重複して持たせない」という、ソフトウェア開発における重要な指針です。
