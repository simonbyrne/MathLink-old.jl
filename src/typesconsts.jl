# define types and consts, based on mathlink.h

# MLENV object, created by mliniatilize
type MLEnv
    ptr::Ptr{Void}
end
# MLINK object, created by mlopen/mlloopbackopen
# TODO: should these be split into distinct types?
type MLink
    ptr::Ptr{Void}
end
# MLMARK object, created by mlcreatemark
type MLMark
    ptr::Ptr{Void}
end


# the "head" of a mathematica expression
# consists of a name and length
type MLFunction
    name::Symbol
    nargs::Cint
    function MLFunction(name,nargs) 
        new(symbol(name),convert(Cint,nargs))
    end
end


# MathLink type names
typealias MLReals Union(Int16,Int32,Int64,Float32,Float64) # Float128 also available
typealias MLArrays Union(MLReals,Uint8)

# for efficiently passing large numeric arrays, rather than building lots of MLFunctions
type MLArrayRef{T<:MLArrays,N}
    arrptr::Ptr{T}
    dimptr::Ptr{Cint}
    headptr::Ptr{Ptr{Uint8}}
end

# conversions between MLArrayRef and julia Array
# NOTE: this does NOT copy the data, so resulting array should not be
# modified, or used after mlrelease
function convert{T,N}(::Type{Array{T}},ma::MLArrayRef{T,N})
    dims = tuple(Int[unsafe_load(ma.dimptr,i) for i = N:-1:1]...)
    pointer_to_array(ma.arrptr,dims)
end
function convert{T,N}(::Type{MLArrayRef{T}},a::Array{T,N})
    s = size(a)
    dims = Cint[s[i] for i = ndims(a):-1:1]
    MLArray{T,N}(pointer(a),pointer(dims),C_NULL)
end

typealias MLStrings Union(ASCIIString,UTF8String,UTF16String,UTF32String)

abstract MLAbstractStringRef{T,U}
type MLStringRef{T<:MLStrings,U<:Union(Uint8,Uint16,Char)} <: MLAbstractStringRef{T,U}
    strptr::Ptr{U}
    len::Cint
end
type MLSymbolRef{T<:MLStrings,U<:Union(Uint8,Uint16,Char)} <: MLAbstractStringRef{T,U}
    strptr::Ptr{U}
    len::Cint
end

# conversions between MLStringRef and julia strings
# NOTE: this does NOT copy the data, so resulting array/string should not be
# modified, or used after mlrelease
function convert{T<:MLStrings,U}(::Type{Array},ms::MLAbstractStringRef{T,U})
    pointer_to_array(ms.strptr,int(ms.len))
end
function convert{T<:MLStrings,U}(::Type{T},ms::MLAbstractStringRef{T,U})
    T(convert(Array,ms))
end

function convert{T<:MLStrings,M<:MLAbstractStringRef}(::Type{M},str::T)
    M{T,eltype(str.data)}(str.data, convert(Cint,length(str.data)))
end



# function return values
typealias MLRTN Cint
const MLRTN_ERR = zero(MLRTN)


# error values, returned by mlerror
typealias MLERR Cint
const MLEOK = convert(MLERR,0)
# TODO: work with julia error handling


# packets
typealias MLPKT Cint 
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


# tokens: types of MathLink objects (see mlgetnext)
typealias MLTKN Cint

const MLTKERR = convert(MLTKN,0) # Error
const MLTKSTR = convert(MLTKN,'"') # String
const MLTKSYM = convert(MLTKN,'#') # Symbol
const MLTKREAL = convert(MLTKN,'*') # Approximate Real
const MLTKINT = convert(MLTKN,'+') # Integer
const MLTKFUNC = convert(MLTKN,'F') # Composite function

# used for mlgetnextraw (only Int32, Int64, Float64 seem to occur)
# there also exists bigendian versions, but we ignore those here.
const MLTK_Int16 = convert(MLTKN,226)
const MLTK_Uint16 = convert(MLTKN,227)
const MLTK_Int32 = convert(MLTKN,228)
const MLTK_Uint32 = convert(MLTKN,229)
const MLTK_Int64 = convert(MLTKN,230)
const MLTK_Uint64 = convert(MLTKN,231)

const MLTK_Float32 = convert(MLTKN,244)
const MLTK_Float64 = convert(MLTKN,246)
const MLTK_Float128 = convert(MLTKN,248) 

# used by mlget(ml) for automatic type inference
# NOTE: we map Int16/Int32 to Int
# TODO: would this be better as a parametric type?
const token_type = (MLTKN => DataType)[
                                       MLTKERR => ErrorException,
                                       MLTKSTR => String,
                                       MLTKSYM => Symbol,
                                       MLTKREAL => FloatingPoint,
                                       MLTKINT => Integer,
                                       MLTKFUNC => MLFunction,
                                       MLTK_Int16 => Int,
                                       MLTK_Uint16 => Uint,
                                       MLTK_Int32 => Int,
                                       MLTK_Uint32 => Uint,
                                       MLTK_Int64 => Int64,
                                       MLTK_Uint64 => Uint64,
                                       MLTK_Float32 => Float32,
                                       MLTK_Float64 => Float64,
                                       MLTK_Float128 => BigFloat,
                                       ]                
                                       
