# initialize/deinitialize
function mlinitialize()
    ccall((:MLInitialize,:mathlink), MLEnv, (Ptr{Uint8},), C_NULL)
end

function mldeinitialize(env::MLEnv)
    if env.ptr != C_NULL
        ccall((:MLDeinitialize,:mathlink), None, (MLEnv,), env)
        env.ptr = C_NULL
    end
end

# open/close application
function mlopen{T<:String}(env::MLEnv, argv::Vector{T})
    erra = Array(Cint,1)
    ml = ccall((:MLOpenArgcArgv,:mathlink), MLink, (MLEnv, Cint, Ptr{Ptr{Uint8}}, Ptr{Cint}), env, length(argv), argv, erra)
    if erra[1] != MLEOK
        error("Could not start MathLink ",erra[1])
    end
    return ml
end
function mlopen(env::MLEnv, str::String)
    erra = Array(Cint,1)
    ml = ccall((:MLOpenString,:mathlink), MLink, (MLEnv, Ptr{Uint8}, Ptr{Cint}), env, str, erra)
    if erra[1] != MLEOK
        error("Could not start MathLink ",erra[1])
    end
    return ml
end

# by default, open local kernel
mlopen(env::MLEnv) = mlopen(env,["-linkname",mathematica_exec_path*" -mathlink","-linkmode","launch"])

function mlclose(ml::MLink)
    if ml.ptr != C_NULL
        ccall((:MLClose,:mathlink), None, (MLink,), ml)
        ml.ptr = C_NULL
    end
end


mlactivate(ml::MLink) = ccall((:MLActivate,:mathlink), MLRTN, (MLink,), ml) != MLRTN_ERR
mlready(ml::MLink) = ccall((:MLReady,:mathlink), MLRTN, (MLink,), ml) != MLRTN_ERR



# error handling
macro mlerr(expr)
    quote
        if $(esc(expr)) == MLRTN_ERR
            error("MathLink error ", mlerrormessage(ml))
        end
    end
end

mlerror(ml::MLink) = ccall((:MLError,:mathlink), MLERR, (MLink,), ml)
mlerrormessage(ml::MLink) = bytestring(ccall((:MLErrorMessage,:mathlink), Ptr{Uint8}, (MLink,), ml))
mlclearerror(ml::MLink) = ccall((:MLReady,:mathlink), MLRTN, (MLink,), ml) != MLRTN_ERR


function mlflush(ml::MLink)
    @mlerr ccall((:MLFlush,:mathlink), MLRTN, (MLink,), ml)
end



mlendpacket(ml::MLink) = ccall((:MLEndPacket,:mathlink), None, (MLink,), ml)

mlnewpacket(ml::MLink) = ccall((:MLNewPacket,:mathlink), None, (MLink,), ml)
mlnextpacket(ml::MLink) = ccall((:MLNextPacket,:mathlink), MLPKT, (MLink,), ml)

mlgetnext(ml::MLink) = ccall((:MLGetNext,:mathlink), MLTKN, (MLink,), ml)

function mlputnext(ml::MLink,t)
    @mlerr ccall((:MLPutNext,:mathlink), MLRTN, (MLink, MLTKN), ml, t)
end



# put and get for different types

# strings
function mlput(ml::MLink,s::ASCIIString)
    @mlerr ccall((:MLPutByteString,:mathlink), MLRTN, (MLink, Ptr{Uint8}, Cint), ml, s.data, length(s.data))
end
function mlput(ml::MLink,s::UTF8String)
    @mlerr ccall((:MLPutUTF8String,:mathlink), MLRTN, (MLink, Ptr{Uint8}, Cint), ml, s.data, length(s.data))
end

# correctly handle utf8 symbols: we can't dispatch on type
function mlputsymbol(ml::MLink,s::ASCIIString)
    @mlerr ccall((:MLPutByteSymbol,:mathlink), MLRTN, (MLink, Ptr{Uint8}, Cint), ml, s.data, length(s.data))
end
function mlputsymbol(ml::MLink,s::UTF8String)
    @mlerr ccall((:MLPutUTF8Symbol,:mathlink), MLRTN, (MLink, Ptr{Uint8}, Cint), ml, s.data, length(s.data))
end
mlput(ml,s::Symbol) = mlputsymbol(ml,string(s))


function mlget(ml::MLink,::Type{ASCIIString})
    stra = Array(Ptr{Uint8},1)
    @mlerr ccall((:MLGetString,:mathlink), MLRTN, (MLink, Ptr{Ptr{Uint8}}), ml, stra)
    str = bytestring(stra[1])
    ccall((:MLReleaseByteString,:mathlink), None, (MLink, Ptr{Uint8}), ml, stra[1])
    return str
end

function mlget(ml::MLink,::Type{UTF8String})
    stra = Array(Ptr{Uint8},1)
    lb = Array(Cint,1)
    lc = Array(Cint,1)
    @mlerr ccall((:MLGetUTF8String,:mathlink), MLRTN, (MLink, Ptr{Ptr{Uint8}},Ptr{Cint},Ptr{Cint}), ml, stra, lb, lc)
    str = utf8(copy(pointer_to_array(stra[1],int(lb[1]))))
    ccall((:MLReleaseUTF8String,:mathlink), None, (MLink, Ptr{Uint8}, Cint), ml, stra[1], lb[1])
    return str
end
mlget(ml::MLink,::Type{String}) = mlget(ml::MLink,UTF8String)

# by default, use utf8 strings
function mlget(ml::MLink,::Type{Symbol})
    stra = Array(Ptr{Uint8},1)
    lb = Array(Cint,1)
    lc = Array(Cint,1)
    @mlerr ccall((:MLGetUTF8Symbol,:mathlink), MLRTN, (MLink, Ptr{Ptr{Uint8}},Ptr{Cint},Ptr{Cint}), ml, stra, lb, lc)
    str = utf8(copy(pointer_to_array(stra[1],int(lb[1]))))
    ccall((:MLReleaseUTF8Symbol,:mathlink), None, (MLink, Ptr{Uint8}, Cint), ml, stra[1], lb[1])
    return symbol(str)
end



for T in (:Integer16,:Integer32,:Integer64,:Real32,:Real64)
    @eval begin
        function mlput(ml::MLink,n::$T) 
            @mlerr ccall(($(string(:MLPut,T)),:mathlink), MLRTN, (MLink, $T), ml, n)
        end
        function mlget(ml::MLink,::Type{$T}) 
            na = Array($T,1)    
            @mlerr ccall(($(string(:MLGet,T)),:mathlink), MLRTN, (MLink, Ptr{$T}), ml, na)
            return na[1]
        end

        function mlput{N}(ml::MLink, a::MLArray{$T,N})
            @mlerr ccall(($(string(:MLPut,T,:Array)),:mathlink), MLRTN, 
                         (MLink, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Uint8}}, Cint),
                         ml, a.arrptr, a.dimptr, a.headptr, N)
        end
        function mlget(ml::MLink, ::Type{MLArray{$T}})
            arra = Array(Ptr{$T},1)
            dima = Array(Ptr{Cint},1)
            heada = Array(Ptr{Ptr{Uint8}},1)
            na = Array(Cint,1)    
            @mlerr ccall(($(string(:MLGet,T,:Array)),:mathlink), MLRTN, 
                     (MLink, Ptr{Ptr{$T}}, Ptr{Ptr{Cint}}, Ptr{Ptr{Ptr{Uint8}}}, Ptr{Cint}), 
                     ml, aa, la, ha, nda)
            MLArray{$T,int(na[1])}(arra[1],dima[1],heada[1])
        end
        function mlrelease{N}(ml::MLink, a::MLArray{$T,N})
            ccall(($(string(:MLRelease,T,:Array)),:mathlink), None, 
                  (MLink, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Uint8}}, Cint), 
                  ml, a.arrptr, a.dimptr, a.headptr, N)
        end

    end
end

function mlput{T<:MLReals,N}(ml::MLink, a::Array{T,N})
    mlput(ml,convert(MLArray{T},Array{T,N}))
end
function mlget{T<:MLReals}(ml::MLink, ::Type{Array{T}})
    ma = mlget(ml,MLArray{T})
    a = copy(convert(Array{T},ma))
    mlrelease(ml,ma)
    a
end



# default representation
mlget(ml::MLink,::Type{Integer}) = mlget(ml,Int)
mlget(ml::MLink,::Type{Real}) = mlget(ml,Real64)
mlget(ml::MLink,::Type{FloatingPoint}) = mlget(ml,Real64)




# functions
function mlput(ml::MLink,f::MLFunction)
    @mlerr ccall((:MLPutFunction,:mathlink), MLRTN, (MLink, Ptr{Uint8}, Cint), ml, f.name, f.nargs) 
end

function mlget(ml::MLink,::Type{MLFunction})
    stra = Array(Ptr{Uint8},1)
    na = Array(Cint, 1)
    @mlerr ccall((:MLGetFunction,:mathlink), MLRTN, (MLink, Ptr{Ptr{Uint8}}, Ptr{Cint}), ml, stra, na) 

    str = bytestring(stra[1])
    ccall((:MLReleaseSymbol,:mathlink), None, (MLink, Ptr{Uint8}), ml, stra[1])
    MLFunction(symbol(str), na[1])
end

function mlcheckfunction(ml::MLink,fname) 
    na = Array(Cint, 1)
    @mlerr ccall((:MLCheckFunction,:mathlink), MLRTN, (MLink, Ptr{Uint8}, Ptr{Cint}), ml, string(fname), na)
    na[1]
end


# loopbacks
