// capture program drop collect_result
program define collect_result, rclass
    version 18.0

    /*
      使い方：
        regress y x
        collect_result, expv(x)

        logistic y x
        collect_result, expv(x) eform

      返り値（r()）：
        r(Nstr) : e(N) を文字列化したもの
        r(val)  : 推定値と95%CIを整形した文字列
        r(p)    : p値を整形した文字列
    */

    syntax, EXPv(name) [EFORM]

    * N
    local Nstr = trim(string(e(N), "%9.0f"))

    * lincom用オプション
    local eformopt
    if "`eform'" != "" {
        local eformopt "eform"
    }

    * 推定値・95%CI・p値を取得
    lincom `expv', `eformopt'

    local est = r(estimate)
    local lb  = r(lb)
    local ub  = r(ub)
    local pv  = r(p)

    * 表示用の文字列に整形
    local valstr = ///
        trim(string(`est', "%9.2f")) + ///
        " (" + ///
        trim(string(`lb', "%9.2f")) + ", " + ///
        trim(string(`ub', "%9.2f")) + ")"

    local pstr = cond(`pv' < 0.001, "<0.001", trim(string(`pv', "%6.3f")))

    * r() に返す
    return local Nstr `"`Nstr'"'
    return local val  `"`valstr'"'
    return local p    `"`pstr'"'
end