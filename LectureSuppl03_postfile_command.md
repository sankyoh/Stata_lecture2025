# `postfile` とは？

`postfile` は、**計算した結果を1行ずつ貯めて「結果格納用データセット（.dta）」を作る**ための仕組みです。  
例えば、回帰を何本も回して「推定値・CI・p値」を集めたいときに、`postfile` で結果表を良い感じに作ることが出来ます。

イメージはこうです：

> **結果を記録するノート（= 結果格納用データセット）を開く → 1行ずつ書く → 閉じる → そのノートをデータとして使う**

---

## 1. 基本の流れ

1) **ハンドルを用意**する（書き込み先の仮の名前）
2) `postfile` で **結果格納用データセットを定義する**（列定義＋保存先指定）
3) `post` で **1行ずつ書き込む**
4) `postclose` で **閉じる**（ここで保存が確定）

---

## 2. 「ハンドル」とは何か（なぜ必要？）

`postfile` はファイルに直接書くのではなく、まず **ハンドル（handle）** を通じて書き込みます。  
ハンドルは、

> **「この postfile への書き込み口（書込み先の仮の名前）」**

だと思ってください。

同じdoファイルの中で、複数の `postfile` を使い分けたい場合にも、  
ハンドルがあると混ざりません。

ここではハンドル名を、
```
tempname `holder'
```
で定義しました。
tempnameで定義しておくと、名前の重複が発生しないので、postfileを使い分けるときに便利です。
Stataは重複が無いように適当な名前を作り、ローカルマクロ`holder'に格納してくれます。
「前に使ったハンドル名って何だったっけ…？」という悩みがなくなります。

---

## 3. `using results` の意味・意義

`using results` は、

> **「書き込んだ結果を保存する“出力ファイル名（.dta）”」（最終出力先の名前）**

を指定します。

- `using results` と書けば、`results.dta`（通常は）というファイルが作られます
- 実務では上書きやパス問題があるので、`tempfile` を併用することが多いです。

tempnameと同じく、tempfile xxxと指定すると、Stataは`xxx'を「重複が無いように」作ってくれます。
postfileを重複して動かすときに、「前に作ったファイル名何だったっけ…？」という悩みがなくなります。

**意義**：  
`postfile` はメモリ上だけの表ではなく、**あとで `use` できる“Stataデータセット”として残る**のが強いです。  
つまり、作った表をさらに加工してExcel出力したり、別の表と結合したりできます。

---

## 4. 具体例

- ハンドルは `tempname holder` で作った `` `holder' ``
- 保存先は、｀tempfile resuts'で作った `` `results' ``を使う

という形で示します。

### やりたいこと
「`x` の平均と標準偏差」を結果として1行だけ書き込み、あとで `use` して見る。

~~~stata
*----------------------------------------------
* postfile の最小例：平均とSDを1行だけ保存する
*----------------------------------------------


* 1) ハンドル（書き込み用の仮の名前）とファイル名を作る
tempname holder
tempfile results

* 2) 結果用データセットを開く（列名と型を定義）
postfile `holder' ///
    str20 item ///　1つめの格納先変数 item(文字列)
    double mean /// 2つめの格納先変数 mean(double型の実数)
    double sd ///   3つめの格納先変数 sd(double型の実数)
    using `results', replace

* 3) 計算（ここでは summarize の r() を利用）
sysuse auto, clear

local vars price length weight mpg
foreach x of local vars {
  quietly summarize `x'
  local m = r(mean)
  local s = r(sd)

  * 4) 1行書き込む（post）
  post `holder' ("`x'") (`m') (`s')

}

* 5) 閉じる（保存確定）
postclose `holder'

* 6) 作られた結果データセットを開いて確認
use `results', clear
list
~~~

この実行結果は、例えばこんな形になります：

- `item` が `"x"`
- `mean` が `x` の平均
- `sd` が `x` の標準偏差

このあと、`export excel`を行うと、Excelとして出力することが可能です。

---

## 5. よくある実務上のコツ

### (A) `using results` は temp で安全にするのが定番
固定ファイル名 `results.dta` だと、作業フォルダ次第で「どこに出来た？」が起きます。  
実務では次が安全です：

~~~stata
tempfile results
postfile `holder' ... using `results', replace
...
postclose `holder'
use `results', clear
~~~

- 一時ファイルなので、パス問題・上書き事故を減らせます

### (B) `postclose` を忘れると保存されない
`postclose` を忘れると、最後の書き込みが確定しません。  
「結果が空だった」事故の代表原因です。

---

## まとめ

- `postfile` は **結果を行単位で貯めて “結果データセット” を作る道具**
- **ハンドル**は「書き込み口（宛先）」で、複数postfileの区別にも使える
- `using results` は「保存先のデータセット名」を指定する（後で `use` できるのが強い）
- 流れは `postfile → post → postclose → use` が基本
