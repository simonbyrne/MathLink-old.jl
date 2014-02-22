# initialize/deinitialize
function mlinitialize()
    env = ccall((:MLInitialize,:mathlink), MLEnv, (Ptr{Uint8},), C_NULL)
    if env.ptr == C_NULL
        error("MathLink: could not initialize library")
    end
    env
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
        error("MathLink: Could not open link ",erra[1])
    end
    return ml
end
function mlopen(env::MLEnv, str::String)
    erra = Array(Cint,1)
    ml = ccall((:MLOpenString,:mathlink), MLink, (MLEnv, Ptr{Uint8}, Ptr{Cint}), env, str, erra)
    if erra[1] != MLEOK
        error("MathLink: Could not open link ",erra[1])
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
    
# error handling
macro mlerr(expr)
    quote
        if $(esc(expr)) == MLRTN_ERR
            error("MathLink: ", mlerrormessage(ml))
        end
    end
end

mlerror(ml::MLink) = ccall((:MLError,:mathlink), MLERR, (MLink,), ml)
mlerrormessage(ml::MLink) = bytestring(ccall((:MLErrorMessage,:mathlink), Ptr{Uint8}, (MLink,), ml))
mlclearerror(ml::MLink) = ccall((:MLReady,:mathlink), MLRTN, (MLink,), ml) != MLRTN_ERR

# packet handling
function mlflush(ml::MLink)
    @mlerr ccall((:MLFlush,:mathlink), MLRTN, (MLink,), ml)
end

mlready(ml::MLink) = ccall((:MLReady,:mathlink), MLRTN, (MLink,), ml) != MLRTN_ERR # true if data ready to be read


mlendpacket(ml::MLink) = ccall((:MLEndPacket,:mathlink), None, (MLink,), ml)

mlnewpacket(ml::MLink) = ccall((:MLNewPacket,:mathlink), None, (MLink,), ml)

function mlnextpacket(ml::MLink) 
    pkt = ccall((:MLNextPacket,:mathlink), MLPKT, (MLink,), ml)
    if pkt == ILLEGALPKT
        error("MathLink: Illegal packet")
    end
    pkt
end

# token handling
mlgetnext(ml::MLink) = ccall((:MLGetNext,:mathlink), MLTKN, (MLink,), ml)
function mlputnext(ml::MLink,t)
    @mlerr ccall((:MLPutNext,:mathlink), MLRTN, (MLink, MLTKN), ml, t)
end

# undocumented: similar to mlgetnext, except returns appropriate binary type
# if available (e.g. Int32, Int64, Float64). Otherwise returns standard
# tokens.
function mlgetnextraw(ml::MLink)
    ccall((:MLGetNextRaw,:mathlink), MLTKN, (MLink,), ml)
end


# put and get for different types

# strings and symbols
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
    @mlerr ccall((:MLGetUTF8String,:mathlink), MLRTN, (MLink, Ptr{Ptr{Uint8}},Ptr{Cint},Ptr{Cint}), ml, stra, lb, &zero(Cint))
    str = utf8(copy(pointer_to_array(stra[1],int(lb[1]))))
    ccall((:MLReleaseUTF8String,:mathlink), None, (MLink, Ptr{Uint8}, Cint), ml, stra[1], lb[1])
    return str
end
mlget(ml::MLink,::Type{String}) = mlget(ml::MLink,UTF8String)

# by default, use utf8 strings
function mlget(ml::MLink,::Type{Symbol})
    stra = Array(Ptr{Uint8},1)
    lb = Array(Cint,1)
    @mlerr ccall((:MLGetUTF8Symbol,:mathlink), MLRTN, (MLink, Ptr{Ptr{Uint8}},Ptr{Cint},Ptr{Cint}), ml, stra, lb, &zero(Cint))
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

        # Methods for moving arrays
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
                     ml, arra, dima, heada, na)
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

# formerly MLCheckFunction
function mltesthead(ml::MLink,fname) 
    na = Array(Cint, 1)
    @mlerr ccall((:MLTestHead,:mathlink), MLRTN, (MLink, Ptr{Uint8}, Ptr{Cint}), ml, string(fname), na)
    na[1]
end


# loopbacks
function mlloopbackopen(e::MLEnv)
    erra = Array(Cint,1)
    ml = ccall((:MLLoopbackOpen,:mathlink), MLink, (MLEnv, Ptr{Cint}), env, erra)
    if erra[1] != MLEOK
        error("MathLink: Could not open loopback link ",erra[1])
    end
    return ml
end

function mltransferexpression(dst::MLink,src::MLink)
    if ccall((:MLTransferExpression,:mathlink), MLRTN, (MLink, MLink), dst, src) == MLRTN_ERR
        error("MathLink: Could not transfer expression")
    end
end
function mltransfertoendofloopbacklink(dst::MLink,src::MLink)
    if ccall((:MLTransferToEndOfLoopbackLink,:mathlink), MLRTN, (MLink, MLink), dst, src) == MLRTN_ERR
        error("MathLink: Could not transfer expression")
    end
end

# marks
function mlcreatemark(ml::MLink)
    mk = ccall((:MLCreateMark,:mathlink), MLMark, (MLink,), ml)
    if mk.ptr == C_NULL
        error("MathLink: Could not create mark")
    end
    mk
end

function mlseektomark(ml::MLink,mk::MLMark,n::Integer)
    sk = ccall((:MLSeekToMark,:mathlink), MLMark, (MLink,MLMark,Cint), ml, mk, n)
    if sk.ptr == C_NULL
        error("MathLink: Could not seek mark")
    end
    sk
end
mlseektomark(ml::MLink,mk::MLMark) = mlseektomark(ml,mk,zero(Cint))

mldestroymark(ml::MLink,mk::MLMark) = ccall((:MLDestroyMark,:mathlink), None, (MLink, MLMark), ml, mk)



# misc
function mlgetlinkedenvidstring(ml::MLink)
    stra = Array(Ptr{Uint8},1)
    @mlerr ccall((:MLGetLinkedEnvIDString,:mathlink), MLRTN, (MLink, Ptr{Ptr{Uint8}}), ml, stra)
    str = bytestring(stra[1])
    ccall((:MLReleaseEnvIDString,:mathlink), None, (MLink, Ptr{Uint8}), ml, stra[1])
    return str
end
function mlsetenvidstring(e::MLEnv,s::ASCIIString)
    if ccall((:MLSetEnvIDString,:mathlink), MLRTN, (MLEnv, Ptr{Uint8}), e, bytestring(s)) == MLRTN_ERR
        error("MathLink: Could not set EnvID string")
    end
end

mllinkname(ml::MLink) = bytestring(ccall((:MLLinkName,:mathlink), Ptr{Uint8}, (MLink,), ml))
function mltolinkid(ml::MLink)
    id = ccall((:MLToLinkID,:mathlink), Clong, (MLink,), ml)
    if id == 0
        error("MathLink: Could not find link id")
    end
    id
end
function mlfromlinkid(e::MLEnv,id) 
    ml = ccall((:MLFromLinkID,:mathlink), MLink, (MLEnv,Clong), e, id)
    if ml.ptr == C_NULL
        error("MathLink: No MLink found")
    end
    ml
end

