# big integers and floats: pass as strings
function mlput(ml,n::BigInt)
    mlputnext(ml,MLTKINT)
    mlput(ml,string(n))
end
mlget(ml,::Type{BigInt}) = BigInt(mlget(ml,String))

function mlput(ml,x::BigFloat)
    mlputnext(ml,MLTKREAL)
    mlput(ml,string(x))
end
mlget(ml, ::Type{BigFloat}) = BigFloat(split(mlget(ml,String),'`')[1])
                                             
const symbolsub = {
             :+ => :Plus,
             :- => :Subtratc,
             :* => :Times,
             :/ => :Divide,
             :^ => :Power,
             :> => :Greater,
             :>= => :GreaterEqual,
             :< => :Less,
             :<= => :LessEqual,
             }


# Expressions
function mlput(ml, ex::Expr)
    if ex.head == :call
        fn = ex.args[1]
        mlputfunction(ml, get(symbolsub, fn, fn), length(ex.args)-1)
        for arg = ex.args[2:]
            mlput(ml, arg)
        end
    elseif ex.head == :comparison
        fn = ex.args[2]
        mlputfunction(ml, get(symbolsub, fn, fn), (length(ex.args) + 1) >> 1)
        mlput(ml, ex.args[1])
        for i = 2:2:length(ex.args)
            if ex.args[i] == fn
                mlput(ml, ex.args[i+1])
            else
                error("comparison operators should all be the same")
            end
        end
    elseif ex.head == :vcat || ex.head == :cell1d
        mlputfunction(ml, :List, length(ex.args))
        for arg = ex.args
            mlput(ml, arg)
        end
    elseif ex.head == :(=)
        mlputfunction(ml, :Set, length(ex.args))
        for arg = ex.args
            mlput(ml, arg)
        end
    elseif ex.head == :(=>)
        mlputfunction(ml, :Rule, length(ex.args))
        for arg = ex.args
            mlput(ml, arg)
        end
    end
end

function mlget(ml, ::Type{Expr})
    f, n = mlgetfunction(ml)
    args = [mlget(ml) for i = 1:n]
    Expr(:call,f,args...)
end
# automatrically figure out which type to get
mlget(ml) = mlget(ml, tokens[mlgetnext(ml)])
    