# `program` コマンドとは？

Stataの **`program`** は、

> **「自分専用のコマンド（関数みたいなもの）を作る仕組み」**

です。  
`program define` 〜 `end` で囲んだ中身が、1つの“コマンド”として登録されます。

---

## 基本の形

~~~stata
program define コマンド名
    // ここに処理を書く
end
~~~

これを実行すると、以後 Stata で

~~~stata
コマンド名
~~~

と打てば、その処理が動きます。

---

## adoファイルとの関係
adoファイル化の詳細は、[LectureSuppl02_Adofile.md](LectureSuppl02_Adofile.md)を参照。

- `make_table1.ado` の中に `program define make_table1 ... end` が書かれている
- そのファイルを PERSONAL などに置くと
- Stataが自動で読み込んで、**`make_table1` をコマンドとして使える**

つまり：

> **「program でコマンドを定義」し、  
> それを `.ado` に保存して“いつでも使えるようにする”**  
> というのが ado 化です。

---

## 簡単な具体例

「データの行数と変数数を表示する」コマンドを作ってみます。

~~~stata
* 自作コマンドの定義/同名のコマンドが既存だとエラーになるので、一旦cap program dropする。
cap program drop show_dims
program define show_dims
    version 18.0

    quietly count
    local N = r(N)

    quietly describe
    local K = r(k)

    di as text "N = `N', variables = `K'"
end

* 使ってみる
sysuse auto, clear
show_dims

* 違うデータセットでも使ってみる
webuse lbw, clear
show_dims
~~~

実行すると例として：

- N = 74, variables = 12
- N = 189, variables = 11

のように表示されます。

---

## show_dimsの有効範囲（スコープ）

show_dims みたいに doファイル内で program define したコマンドの「有効範囲（スコープ）」は、基本的に **その Stata セッション（起動してから終了するまで）**です。

### 1) どこで使える？
いったん program define show_dims ... end が実行されると、
その時点以降は

- コマンドウィンドウ
- 別の do ファイル
- do で呼んだ下位 do

など、同じ Stata セッション内ならどこでも show_dims を実行できます。

### 2) いつまで使える？

Stataを終了するまで有効です。
Stataを閉じて再起動すると、doファイルで定義しただけの show_dims は 消えます（再定義が必要）。

---

## まとめ

- `program` は **Stataで自分のコマンドを作る機能**
- `program define 名前 ... end` で定義する
- スコープに注意（Stataを終わらせると、再度定義しないと使えない）
- `.ado` に入れて PERSONAL に置くと、どのプロジェクトでもそのコマンドが使える
