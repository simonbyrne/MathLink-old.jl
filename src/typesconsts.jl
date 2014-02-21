type MLEnv
    ptr::Ptr{Void}
end
type MLink
    ptr::Ptr{Void}
end
type MLMark
    ptr::Ptr{Void}
end


typealias MLPKT Cint
typealias MLERR Cint
typealias MLRTN Cint
typealias MLTKN Cint



type MLFunction
    name::Symbol
    nargs::Cint
    function MLFunction(name,nargs) 
        new(symbol(name),convert(Cint,nargs))
    end
end



# MathLink type names
typealias Integer16 Int16
typealias Integer32 Int32
typealias Integer64 Int64
typealias Real32 Float32
typealias Real64 Float64
# typealias Real128 Float128
typealias MLReals Union(Integer16,Integer32,Integer64,Real32,Real64)

type MLArray{T<:MLReals,N}
    arrptr::Ptr{T}
    dimptr::Ptr{Cint}
    headptr::Ptr{Ptr{Uint8}}
end

# convert between MLArray and julia Array

# Note: this does NOT copy the data, so resulting array should not be modified, or used after mlrelease
function convert{T,N}(::Type{Array{T}},ma::MLArray{T,N})
    dims = tuple(Int[unsafe_load(ma.dimptr,i) for i = N:-1:1]...)
    pointer_to_array(ma.arrptr,dims)
end
function convert{T,N}(::Type{MLArray{T}},a::Array{T,N})
    s = size(a)
    dims = Cint[s[i] for i = ndims(a):-1:1]
    MLArray{T,N}(pointer(a),point(dims),C_NULL)
end



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
                convert(MLTKN,'F') => MLFunction, # function
                ]                
