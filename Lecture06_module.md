# 第6回：コードを短くする工夫 — `program` と `collect_result.ado` で回帰結果出力を整理する ✨

この回は、第5回の内容を一歩進めて、**「動くコード」から「保守しやすいコード」へ進む**ことを目的にします。  
第5回では、`postfile` を使って回帰結果をExcelへ出力する方法を学びました。

この方法はとても実務的で、成果物を残すという意味で大事でした。特に、試行錯誤したりして作業が何度も発生するときに有効です。

ただし、1つ弱点がありました。**コードが長い**ことです。

たとえば、線形回帰・ロジスティック回帰・修正Poisson回帰のそれぞれについて、

- 回帰を実行する
- `lincom` を回す
- `r(estimate)` や `r(p)` を取り出す
- `xx.xx (lb, ub)` の形に整形する
- `post` で1行書き込む

という流れを、ほぼ同じ形で何度も書いていました。  
これは最初は理解のために必要ですが、実務では次の問題が出てきます。

- 同じ処理を何回も書くので、なんらかの修正が必要な時に、修正漏れが起きやすい
- どこが「本質」でどこが「定型処理」か分かりにくい

そこで第6回では、**繰り返し部分を `program` にまとめる**という考え方を扱います。  
さらに、その `program` を `.ado` にして **`collect_result.ado`** として保存すれば、以後は自分専用コマンドのように使い回せます。

---

## この回の到達目標

この回のゴールは次の3つです。

1. 第5回のコードのうち、どこが「繰り返し」なのかを見抜ける  
2. その繰り返しを `program` として切り出す意味が分かる  
3. `collect_result.ado` を使って、回帰結果出力コードを短く書ける  

---

## 1. 第5回コードのどこが長かったのか

第5回のコードでは、各モデルの解析の後に次のような処理を繰り返していました。

~~~stata
local N = string(e(N))

lincom `expv'
local est = r(estimate)
local lb  = r(lb)
local ub  = r(ub)
local pv  = r(p)

local crude_val = trim(string(`est',"%9.2f")) + ///
    " (" + trim(string(`lb',"%9.2f")) + ", " + ///
    trim(string(`ub',"%9.2f")) + ")"

local crude_p = cond(`pv'<0.001, "<0.001", trim(string(`pv',"%6.3f")))
~~~

そして調整モデルでも、ほぼ同じものをもう一度書いていました。  
つまり、「解析の本体」は 1 行の `regress` や `logistic` なのに、その後の**結果回収と整形**が何度も何度も出てきます。
しかも、これらは数行にわたっていますので、**doファイルを見直す時に目が滑りやすい**をいう問題があります。

このようなときに考えるべきことは、

> これは毎回違う処理なのか？  
> それとも「いつも同じ定型処理」なのか？

です。

今回のケースでは、`lincom` の後に

- Nを取る
- estimate / CI / p を取る
- 文字列を整形する

という流れは、**毎回同じ**です。  
したがって、ここは `program` に切り出す価値があります。

---

## 2. `program` にまとめる、とはどういうことか

Stata の `program` は、**自分でコマンドを作る仕組み**です。  
つまり、「毎回同じように書いている処理」を1つの名前にまとめてしまえる、ということです。

今回で言えば、

- 回帰モデルを回した直後に
- `collect_result, expv(dm)` あるいは `collect_result, expv(dm) eform`

と書けば、

- `r(Nstr)`
- `r(val)`
- `r(p)`

が返ってくるようにしておけばよいわけです。

こうすると、講義コードは次のように短くできます。

~~~stata
* 粗解析モデル
regress `outv_cont' `expv'
collect_result, expv(`expv')
local crude_N   "`r(Nstr)'"
local crude_val "`r(val)'"
local crude_p   "`r(p)'"

* 調整モデル
regress `outv_cont' `expv' `covars'
collect_result, expv(`expv')
local adj_N   "`r(Nstr)'"
local adj_val "`r(val)'"
local adj_p   "`r(p)'"
~~~

かなり見通しが良くなります。  
解析そのもの（`regress` なのか `logistic` なのか）が見えやすくなり、「何をしているか」が伝わりやすくなります。

---

## 3. `collect_result.ado` の役割

今回の主役が **`collect_result.ado`** です。  
このコマンドは、直前に実行した回帰モデルを前提にして、

- `e(N)` を文字列化する
- `lincom` を実行する
- `r(estimate)`, `r(lb)`, `r(ub)`, `r(p)` を取得する
- `xx.xx (lb, ub)` 形式に整形する
- `r(Nstr)`, `r(val)`, `r(p)` としてdoファイル本体に返す

という役割を持っています。

つまり、これまでモデルごとに繰り返し書いていた「回収＋整形」の部分を、  
**`collect_result` という1つのコマンド名で呼べるようにした**わけです。

ここで大事なのは、

> `collect_result` は「解析そのもの」ではなく、  
> **解析結果の回収・整形を担当する補助コマンド**

だということです。

この役割分担ができると、コード全体がかなり整理されます。

---

## 4. `collect_result.ado` の使い方

使い方はシンプルです。

### 線形回帰
~~~stata
regress `outv_cont' `expv'
collect_result, expv(`expv')
~~~

### ロジスティック回帰
~~~stata
logistic `outv_bin' `expv'
collect_result, expv(`expv') eform
~~~

### 修正Poisson回帰
~~~stata
poisson `outv_bin' `expv', vce(robust) irr
collect_result, expv(`expv') eform
~~~

`eform` を付けると、`lincom` が指数変換された値を返すため、

- ロジスティック回帰なら OR
- 修正Poissonなら RR

として解釈できる形になります。

---

## 5. compact版 do ファイルの考え方

今回の `06_models_glm_export_compact.do` は、第5回の長い do ファイルを、`collect_result.ado` を使って整理した版です。

考え方は次の通りです。

### 第5回の発想
1. 回帰を回す  
2. その場で `lincom`  
3. その場で `local est = r(estimate)` などを書く  
4. その場で整形する  
5. `post` する  

### 第6回の発想
1. 回帰を回す  
2. `collect_result` を呼ぶ  
3. `r(Nstr)`, `r(val)`, `r(p)` を local に受け取る  
4. `post` する  

つまり、**解析結果を整える責任を `collect_result.ado` に移した**のが、第6回のポイントです。

---

## 6. compact版の骨格

コードの骨格は、次のようになります。

~~~stata
* 線形回帰
regress `outv_cont' `expv'
collect_result, expv(`expv')
local crude_N   "`r(Nstr)'"
local crude_val "`r(val)'"
local crude_p   "`r(p)'"

regress `outv_cont' `expv' `covars'
collect_result, expv(`expv')
local adj_N   "`r(Nstr)'"
local adj_val "`r(val)'"
local adj_p   "`r(p)'"

post `holder' ///
    ("regress") ///
    ("coefficient") ///
    ("`crude_N'") ///
    ("`crude_val'") ///
    ("`crude_p'") ///
    ("") ///
    ("`adj_N'") ///
    ("`adj_val'") ///
    ("`adj_p'")
~~~

ここではまだ `post` の行は残っていますが、少なくとも

- `lincom`
- `r(estimate)` 等の回収
- 文字列整形

を毎回書かなくてよくなりました。  
これだけでも、コードの見通しはかなり改善します。

---

## 7. 何が良くなったのか

### 7.1 読みやすくなった
コードを読んだときに、まず目に入るのが

- `regress`
- `logistic`
- `poisson`

になりました。  
つまり、「どんな解析をしたか」が見えやすくなっています。

### 7.2 修正しやすくなった
もし p 値のフォーマットを変えたい、CI の書式を変えたい、という場合、  
第5回のコードだと3か所全部直す必要がありました。  
第6回では、**`collect_result.ado` を1か所直せば済みます**。

### 7.3 再利用しやすくなった
今後、別のアウトカムや別の曝露で同じ形式の表を作りたいときも、  
`collect_result.ado` があれば使い回せます。  
これは、do ファイルをただの「その場の作業記録」から、  
**再利用可能な部品の集合**へ変える発想です。

---

## 8. `ado` にする意味

ここで一歩引いて考えると、`collect_result.ado` にしたことの意味は大きいです。

もし `program define collect_result ... end` を毎回 do ファイルの先頭に書くなら、  
結局それもコピペになります。  
しかし `.ado` にして PERSONAL などに置けば、Stata はそれを **自分のコマンド**として認識します。

つまり、

~~~stata
collect_result, expv(dm)
~~~

と書くだけで動くようになります。

これは、以前の `make_table1.ado` と同じ発想です。  
**長くて定型的な処理は、ado 化すると後が楽になる**、ということです。

---

## 9. 第5回とのつながり

第5回では、

- `postfile` という“結果を貯める仕組み”
- `lincom` と `r()` を使って結果を取り出す方法
- `export excel` で表にする方法

を学びました。

第6回では、それを否定するのではなく、

> **第5回のやり方を、より読みやすく・短く・再利用しやすくした**

と捉えるのが大切です。

つまり流れとしてはこうです。

1. まずはベタ書きで、何をやっているかを理解する（第5回）
2. そのあと、繰り返し部分を切り出して整理する（第6回）

この順番が教育的には自然です。  
最初から短いコードだけ見せると、「なぜそれで動くのか」が分かりにくくなるからです。

---

## 10. 比較ポイント

### 第5回の雰囲気
「全部その場で書く」

### 第6回の雰囲気
「定型処理は部品にして呼び出す」

- ただ動けばいい、ではなく
- 読みやすく、直しやすく、再利用できるコードを書く

という意識が重要です。

---

## 11. サンプル：第6回用の短い例

~~~stata
* 曝露・アウトカム・共変量
local expv dm
local outv_bin cv_event
local covars age bmi sbp fev1 smk htn_tx fhx_cvd af ckd ra copd

* 粗解析
logistic `outv_bin' `expv'
collect_result, expv(`expv') eform
local crude_N   "`r(Nstr)'"
local crude_val "`r(val)'"
local crude_p   "`r(p)'"

* 調整解析
logistic `outv_bin' `expv' `covars'
collect_result, expv(`expv') eform
local adj_N   "`r(Nstr)'"
local adj_val "`r(val)'"
local adj_p   "`r(p)'"

* post
post `holder' ///
    ("logistic") ///
    ("Odds Ratio") ///
    ("`crude_N'") ///
    ("`crude_val'") ///
    ("`crude_p'") ///
    ("") ///
    ("`adj_N'") ///
    ("`adj_val'") ///
    ("`adj_p'")
~~~

この例では、ロジスティック回帰の「本体」がすぐ目に入ります。  
それに対して、結果回収は `collect_result` に任せています。  
これが第6回で身につけてほしいスタイルです。

---

## 12. まとめ

第6回のポイントは、単にコードを短くすることではありません。  
本当に大事なのは、

> **繰り返しの定型処理を見抜き、部品化する発想**

を身につけることです。

今回の `collect_result.ado` は、その最初の一歩です。

- 第5回：まずはベタ書きで、`postfile`・`lincom`・`r()` の流れを理解する  
- 第6回：そのうえで、繰り返し部分を `program` / `ado` にまとめる  

この順番で学ぶことで、
「Stataコードを書く人」から、  
**「再利用可能な解析部品を作れる人」**へ一歩進めます。

---

## 演習課題

1. `collect_result.ado` を使って、線形回帰の部分を短く書き換える  
2. ロジスティック回帰と修正Poisson回帰も同様に書き換える  
3. `collect_result.ado` を使わずにベタ書きした版と見比べて、どちらが読みやすいか考える

- べた書きした版 = 05_models_glm_export.do
- collect_result利用版 = 06_models_glm_export_compact.do

---

## 補足メッセージ

第5回の長いコードは、決して“悪いコード”ではありません。  
むしろ、学習の最初の段階では必要なコードでした。  
ただし、理解したあともずっとそのままでは、保守しづらくなります。

だからこそ第6回では、

> **理解した定型処理は、部品にして再利用する**

という実務的な発想を導入しました。
