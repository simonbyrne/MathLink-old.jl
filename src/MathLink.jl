module MathLink

export mlinitialize, mldeinitialize, mlopen, mlclose, mlputfunction, mlgetfunction, mlcheckfunction,
mlput, mlget, mlnewpacket, mlendpacket, mlnextpacket, mlputnext, mlgetnext, mlerror



typealias MLENV Ptr{Void}
typealias MLINK Ptr{Void}
typealias MLPKT Cint
typealias MLERR Cint
typealias MLRTN Cint
typealias MLTKN Cint

# MathLink type names
typealias Integer16 Int16
typealias Integer32 Int32
typealias Integer64 Int64
typealias Real32 Float32
typealias Real64 Float64
# typealias Real128 Float128

const MLRTN_ERR = zero(MLRTN)

const MLEOK = convert(MLERR,0)


const MLTKSTR = convert(MLTKN,'"') #=> String,
const MLTKSYM = convert(MLTKN,'#') #=> Symbol,
const MLTKREAL = convert(MLTKN,'*') #=> FloatingPoint,
const MLTKINT = convert(MLTKN,'+') #=> Integer,
const MLTKFUNC = convert(MLTKN,'F') #=> Function, #???


const ILLEGALPKT    = convert(MLPKT,   0)

const CALLPKT       = convert(MLPKT,   7)
const EVALUATEPKT   = convert(MLPKT,  13)
const RETURNPKT     = convert(MLPKT,   3)

const INPUTNAMEPKT  = convert(MLPKT,   8)
const ENTERTEXTPKT  = convert(MLPKT,  14)
const ENTEREXPRPKT  = convert(MLPKT,  15)
const OUTPUTNAMEPKT = convert(MLPKT,   9)
const RETURNTEXTPKT = convert(MLPKT,   4)
const RETURNEXPRPKT = convert(MLPKT,  16)

const DISPLAYPKT    = convert(MLPKT,  11)
const DISPLAYENDPKT = convert(MLPKT,  12)

const MESSAGEPKT    = convert(MLPKT,   5)
const TEXTPKT       = convert(MLPKT,   2)

const INPUTPKT      = convert(MLPKT,   1)
const INPUTSTRPKT   = convert(MLPKT,  21)
const MENUPKT       = convert(MLPKT,   6)
const SYNTAXPKT     = convert(MLPKT,  10)

const SUSPENDPKT    = convert(MLPKT,  17)
const RESUMEPKT     = convert(MLPKT,  18)

const BEGINDLGPKT   = convert(MLPKT,  19)
const ENDDLGPKT     = convert(MLPKT,  20)

const FIRSTUSERPKT  = convert(MLPKT, 128)
const LASTUSERPKT   = convert(MLPKT, 255)




const tokens = [
                convert(MLTKN,'"') => String,
                convert(MLTKN,'#') => Symbol,
                convert(MLTKN,'*') => FloatingPoint,
                convert(MLTKN,'+') => Integer,
                convert(MLTKN,'F') => Function, #???
                ]                






mlinitialize() = ccall((:MLInitialize,:mathlink), MLENV, (Ptr{Uint8},), C_NULL)
mldeinitialize(env::MLENV) = ccall((:MLDeinitialize,:mathlink), None, (MLENV,), env)

function mlopen(env, argv)
    argc = length(argv)
    erra = Array(Cint,1)
    ml = ccall((:MLOpenArgcArgv,:mathlink), MLINK, (MLENV, Cint, Ptr{Ptr{Uint8}}, Ptr{Cint}), env, argc, argv, erra)
    if erra[1] != MLEOK
        error("Could not start MathLink ",erra[1])
    end
    return ml
end
mlclose(ml) = ccall((:MLClose,:mathlink), None, (MLINK,), ml)


type MLFunction
    name::Symbol
    nargs::Cint
end



function mlput(ml,s::String)
    if ccall((:MLPutString,:mathlink), MLRTN, (MLINK, Ptr{Uint8}), ml, bytestring(s)) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end
function mlget(ml,::Type{String})
    stra = Array(Ptr{Uint8},1)
    if ccall((:MLGetString,:mathlink), MLRTN, (MLINK, Ptr{Ptr{Uint8}}), ml, stra) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    str = bytestring(stra[1])
    ccall((:MLReleaseString,:mathlink), None, (MLINK, Ptr{Uint8}), ml, stra[1])
    return str
end

function mlput(ml,s::Symbol)
    if ccall((:MLPutSymbol,:mathlink), MLRTN, (MLINK, Ptr{Uint8}), ml, string(s)) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end
function mlget(ml,::Type{Symbol})
    stra = Array(Ptr{Uint8},1)
    if ccall((:MLGetSymbol,:mathlink), MLRTN, (MLINK, Ptr{Ptr{Uint8}}), ml, stra) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    str = bytestring(stra[1])
    ccall((:MLReleaseSymbol,:mathlink), None, (MLINK, Ptr{Uint8}), ml, stra[1])
    return symbol(str)
end


for T in (:Integer16,:Integer32,:Integer64,:Real32,:Real64)
    @eval begin
        function mlput(ml,n::$T) 
            if ccall(($(string(:MLPut,T)),:mathlink), MLRTN, (MLINK, $T), ml, n) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
        end
        function mlget(ml,::Type{$T}) 
            na = Array($T,1)    
            if ccall(($(string(:MLGet,T)),:mathlink), MLRTN, (MLINK, Ptr{$T}), ml, na) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
            return na[1]
        end

        function mlput(ml, a::Array{$T,1})
            if ccall(($(string(:MLPut,T,:List)),:mathlink), MLRTN, (MLINK, Ptr{$T}, Cint), ml, a, length(a)) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
        end
        function mlget(ml, ::Type{Array{$T,1}})
            aa = Array(Ptr{$T},1)
            la = Array(Cint,1)    
            if ccall(($(string(:MLGet,T,:List)),:mathlink), MLRTN, (MLINK, Ptr{Ptr{$T}}, Ptr{Cint}), ml, aa, la) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
            a = Array($T,la[1])
            for i = 1:la[1]
                a[i] = unsafe_load(aa[1],i)
            end
            ccall(($(string(:MLRelease,T,:List)),:mathlink), None, (MLINK, Ptr{$T}, Cint), ml, aa[1], la[1])
            return a
        end
        
        function mlput{N}(ml, a::Array{$T,N})
            s = size(a)
            dims = Cint[s[i] for i = ndims(a):-1:1]
            if ccall(($(string(:MLPut,T,:Array)),:mathlink), MLRTN, 
                     (MLINK, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Uint8}}, Cint),
                     ml, a, dims, C_NULL, ndims(a)) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
        end
        function mlget(ml, ::Type{Array{$T}})
            aa = Array(Ptr{$T},1)
            la = Array(Ptr{Cint},1)
            ha = Array(Ptr{Ptr{Uint8}},1)
            nda = Array(Cint,1)    
            if ccall(($(string(:MLGet,T,:Array)),:mathlink), MLRTN, 
                     (MLINK, Ptr{Ptr{$T}}, Ptr{Ptr{Cint}}, Ptr{Ptr{Ptr{Uint8}}}, Ptr{Cint}), 
                     ml, aa, la, ha, nda) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
            dims = Int[unsafe_load(la[1],i) for i = nda[1]:-1:1]
            a = Array($T,dims...)
            for i = 1:prod(dims)
                a[i] = unsafe_load(aa[1],i)
            end
            ccall(($(string(:MLRelease,T,:Array)),:mathlink), None, 
                  (MLINK, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Uint8}}, Cint), 
                  ml, aa[1], la[1], ha[1], nda[1])
            return a
        end

    end
end

function mlputfunction(ml,fname,narg)    
    if ccall((:MLPutFunction,:mathlink), MLRTN, (MLINK, Ptr{Uint8}, Cint), ml, fname, narg) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end

# default representation
mlget(ml,::Type{Integer}) = mlget(ml,Int)
mlget(ml,::Type{Real}) = mlget(ml,Real64)
mlget(ml,::Type{FloatingPoint}) = mlget(ml,Real64)


# big integers: convert to strings
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



# functions
function mlgetfunction(ml)
    stra = Array(Ptr{Uint8},1)
    na = Array(Cint, 1)
    if ccall((:MLGetFunction,:mathlink), MLRTN, (MLINK, Ptr{Ptr{Uint8}}, Ptr{Cint}), ml, stra, na) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    str = bytestring(stra[1])
    ccall((:MLReleaseSymbol,:mathlink), None, (MLINK, Ptr{Uint8}), ml, stra[1])
    return str, na[1]
end

function mlcheckfunction(ml,fname) 
    na = Array(Cint, 1)
    if ccall((:MLCheckFunction,:mathlink), MLRTN, (MLINK, Ptr{Uint8}, Ptr{Cint}), ml, fname, na) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    na[1]
end




mlnewpacket(ml) = ccall((:MLNewPacket,:mathlink), None, (MLINK,), ml)
mlendpacket(ml) = ccall((:MLEndPacket,:mathlink), None, (MLINK,), ml)
mlnextpacket(ml) = ccall((:MLNextPacket,:mathlink), MLPKT, (MLINK,), ml)

mlgetnext(ml) = ccall((:MLGetNext,:mathlink), MLTKN, (MLINK,), ml)
function mlputnext(ml,t)
    if ccall((:MLPutNext,:mathlink), MLRTN, (MLINK, MLTKN), ml, t) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end


mlerror(ml) = ccall((:MLError,:mathlink), MLERR, (MLINK,), ml)


# module
end