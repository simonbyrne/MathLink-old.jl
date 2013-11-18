macro mlput(ml,ex)
    if typeof(ex) == Expr
        if ex.head == :call
            Expr(:block,
                 :(mlputfunction($(esc(ml)),$(string(ex.args[1])),$(esc(length(ex.args)-1)))),
                 [:(@mlput $(esc(ml)) $(esc(u))) for u = ex.args[2:]]...)
        elseif ex.head == :vcat || ex.head == :cell1d
            Expr(:block,
                 :(mlputfunction($(esc(ml)),"List",$(esc(length(ex.args))))),
                 [:(@mlput $(esc(ml)) $(esc(u))) for u = ex.args[1:]]...)
        elseif ex.head == :(=)
            Expr(:block,
                 :(mlputfunction($(esc(ml)),"Set",$(esc(length(ex.args))))),
                 [:(@mlput $(esc(ml)) $(esc(u))) for u = ex.args[1:]]...)
        elseif ex.head == :(=>)
            Expr(:block,
                 :(mlputfunction($(esc(ml)),"Rule",$(esc(length(ex.args))))),
                 [:(@mlput $(esc(ml)) $(esc(u))) for u = ex.args[1:]]...)
        elseif ex.head == :quote
            :(mlput($(esc(ml)),$(esc(ex))))
        end
    else
        return :(mlput($(esc(ml)),$(esc(ex))))
    end
end