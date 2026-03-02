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

## `program define` の周辺でよく見る3つ（ついでに）

- `program define ...`：コマンド定義の開始
- `version 19.0`：このコマンドは Stata 19 の挙動で動く、と固定（再現性）
- `end`：定義の終わり

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

## まとめ

- `program` は **Stataで自分のコマンドを作る機能**
- `program define 名前 ... end` で定義する
- `.ado` に入れて PERSONAL に置くと、どのプロジェクトでもそのコマンドが使える
