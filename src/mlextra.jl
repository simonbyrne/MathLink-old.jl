# big integers and floats: pass as strings
function mlput(ml::MLink,n::BigInt)
    mlputnext(ml,MLTKINT)
    mlput(ml,string(n))
end
mlget(ml::MLink,::Type{BigInt}) = BigInt(mlget(ml,String))


function mlput(ml::MLink,x::BigFloat)
    mlputnext(ml,MLTKREAL)
    mlput(ml,string(x))
end

# a wrapper around a string for storing Mathematica arbitrary precision floats
type MLFloatStr
    str::ASCIIString
end

function mlput(ml::MLink,x::MLFloatStr)
    mlputnext(ml,MLTKREAL)
    mlput(ml,x.str)
end

function convert(::Type{BigFloat}, x::MLFloatStr)
    exp_ind = search(x.str,'*')
    prc_ind = search(x.str,'`')
    if exp_ind == 0
        bstr = prc_ind == 0 ? x.str : x.str[1:prc_ind-1]
    else
        sstr = prc_ind == 0 ? x.str[1:exp_ind-1] : x.str[1:prc_ind-1]
        estr = x.str[exp_ind+2:end]
        bstr = sstr*"e"*estr
    end
    BigFloat(bstr)
end

mlget(ml::MLink,::Type{MLFloatStr}) = MLFloatStr(mlget(ml,ASCIIString))
mlget(ml::MLink,::Type{BigFloat}) = convert(BigFloat,mlget(ml,MLFloatStr))



# default representation
mlget(ml::MLink,::Type{Integer}) = mlget(ml,BigInt)
mlget(ml::MLink,::Type{FloatingPoint}) = mlget(ml,BigFloat)

# automatically handle types
# NOTE: don't run this after mlgetnext/mlgetnexraw has already been run
mlget(ml::MLink) = mlget(ml, token_type[mlgetnextraw(ml)])




                                             
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
        mlput(ml, MLFunction(get(symbolsub, fn, fn), length(ex.args)-1))
        for arg = ex.args[2:end]
            mlput(ml, arg)
        end
    elseif ex.head == :comparison
        fn = ex.args[2]
        mlput(ml, MLFunction(get(symbolsub, fn, fn), (length(ex.args) + 1) >> 1))
        mlput(ml, ex.args[1])
        for i = 2:2:length(ex.args)
            if ex.args[i] == fn
                mlput(ml, ex.args[i+1])
            else
                error("comparison operators should all be the same")
            end
        end
    elseif ex.head == :vcat || ex.head == :cell1d
        mlput(ml, MLFunction(:List, length(ex.args)))
        for arg = ex.args
            mlput(ml, arg)
        end
    elseif ex.head == :(=)
        mlput(ml, MLFunction(:Set, length(ex.args)))
        for arg = ex.args
            mlput(ml, arg)
        end
    elseif ex.head == :(=>)
        mlput(ml, MLFunction(:Rule, length(ex.args)))
        for arg = ex.args
            mlput(ml, arg)
        end
    end
end

# automatically construct expression
function mlget(ml, ::Type{Expr})
    y = mlget(ml)
    if isa(y, MLFunction)
        args = [mlget(ml, Expr) for i = 1:y.nargs]
        return Expr(:call,y.name,args...)
    else
        return y
    end
end
    
