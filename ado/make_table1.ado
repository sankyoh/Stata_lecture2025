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
    if !regexm(lower("`outfile'"), "\.xlsx$") {
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
