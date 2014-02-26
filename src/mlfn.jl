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
function mlputnext(ml::MLink,t)
    @mlerr ccall((:MLPutNext,:mathlink), MLRTN, (MLink, MLTKN), ml, t)
end

mlgetnext(ml::MLink) = ccall((:MLGetNext,:mathlink), MLTKN, (MLink,), ml)
mlgettype(ml::MLink) = ccall((:MLGetType,:mathlink), MLTKN, (MLink,), ml)


# undocumented: similar to mlgetnext/mlgettype, except returns appropriate binary type
# if available (e.g. Int32, Int64, Float64). Otherwise returns standard
# tokens.
function mlgetnextraw(ml::MLink)
    ccall((:MLGetNextRaw,:mathlink), MLTKN, (MLink,), ml)
end
function mlgetrawtype(ml::MLink)
    ccall((:MLGetRawType,:mathlink), MLTKN, (MLink,), ml)
end



# put and get for different types

# strings and symbols refs
for S in (:String,:Symbol)
    L = symbol(string(:ML,S,:Ref))
    
    @eval begin
        # MLGet*String calls are all different
        function mlget(ml::MLink,::Type{$L{ASCIIString}})
            stra = Array(Ptr{Uint8},1)
            lba = Array(Cint,1)
            @mlerr ccall(($(string(:MLGetByte,S)),:mathlink), MLRTN,
                         (MLink, Ptr{Ptr{Uint8}}, Ptr{Cint}, Clong),
                         ml, stra, lba, zero(Clong))
            return $L{ASCIIString,Uint8}(stra[1],lba[1])
        end
        function mlget(ml::MLink,::Type{$L{UTF8String}})
            stra = Array(Ptr{Uint8},1)
            lba = Array(Cint,1)
            @mlerr ccall(($(string(:MLGetUTF8,S)),:mathlink), MLRTN,
                         (MLink, Ptr{Ptr{Uint8}}, Ptr{Cint}, Ptr{Cint}),
                         ml, stra, lba, &zero(Cint))
            return $L{UTF8String,Uint8}(stra[1],lba[1])
        end
        function mlget(ml::MLink,::Type{$L{UTF16String}})
            stra = Array(Ptr{Uint16},1)
            lba = Array(Cint,1)
            @mlerr ccall(($(string(:MLGetUTF16,S)),:mathlink), MLRTN,
                         (MLink, Ptr{Ptr{Uint16}}, Ptr{Cint}, Ptr{Cint}),
                         ml, stra, lba, &zero(Cint))
            return $L{UTF16String,Uint16}(stra[1],lba[1])
        end
        function mlget(ml::MLink,::Type{$L{UTF32String}})
            stra = Array(Ptr{Char},1)
            lba = Array(Cint,1)
            @mlerr ccall(($(string(:MLGetUTF32,S)),:mathlink), MLRTN,
                         (MLink, Ptr{Ptr{Char}}, Ptr{Cint}),
                         ml, stra, lba)
            return $L{UTF32String,Char}(stra[1],lba[1])
        end
    end

    for (M,T,U) in ((:Byte,:ASCIIString,:Uint8),(:UTF8,:UTF8String,:Uint8),
                    (:UTF16,:UTF16String,:Uint16),(:UTF32,:UTF32String,:Char))
        @eval begin
            function mlput(ml::MLink,s::$(symbol(string(:ML,S,:Ref))){$T,$U})
                @mlerr ccall(($(string(:MLPut,M,S)),:mathlink), MLRTN, 
                             (MLink, Ptr{$U}, Cint), ml, s.strptr, s.len)
            end

            function mlrelease(ml::MLink, s::$(symbol(string(:ML,S,:Ref))){$T,$U})
                ccall(($(string(:MLRelease,M,S)),:mathlink), None,
                      (MLink, Ptr{$U}, Cint), ml, s.strptr, s.len)
            end
        end
    end
end

# string and symbols: these clean up after themselves
function mlget{T<:MLStrings}(ml::MLink,::Type{T})
    msr = mlget(ml,MLStringRef{T})
    str = T(copy(convert(Array,msr)))
    mlrelease(ml,msr)
    str
end
function mlput(ml::MLink,str::MLStrings)
    mlput(ml,convert(MLStringRef,str))
end

function mlget(ml::MLink,::Type{Symbol})
    msr = mlget(ml,MLSymbolRef{UTF8String})
    sym = symbol(UTF8String(copy(convert(Array,msr))))
    mlrelease(ml,msr)
    sym
end
function mlput(ml::MLink,s::Symbol)
    mlput(ml,convert(MLSymbolRef,string(s)))
end


# numeric types
for (M,T) in ((:Integer16,:Int16),(:Integer32,:Int32),(:Integer64,:Int64),
              (:Real32,:Float32),(:Real64,:Float64))
    @eval begin
        function mlput(ml::MLink,n::$T) 
            @mlerr ccall(($(string(:MLPut,M)),:mathlink), MLRTN, (MLink, $T), ml, n)
        end
        function mlget(ml::MLink,::Type{$T}) 
            na = Array($T,1)    
            @mlerr ccall(($(string(:MLGet,M)),:mathlink), MLRTN, (MLink, Ptr{$T}), ml, na)
            return na[1]
        end
    end
end

# numeric arrays refs (including bytes)
for (M,T) in ((:Integer16,:Int16),(:Integer32,:Int32),(:Integer64,:Int64),
              (:Real32,:Float32),(:Real64,:Float64),(:Byte,:Uint8))
    @eval begin
        # Methods for moving arrays
        function mlput{N}(ml::MLink, a::MLArrayRef{$T,N})
            @mlerr ccall(($(string(:MLPut,M,:Array)),:mathlink), MLRTN, 
                         (MLink, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Uint8}}, Cint),
                         ml, a.arrptr, a.dimptr, a.headptr, N)
        end
        function mlget(ml::MLink, ::Type{MLArrayRef{$T}})
            arra = Array(Ptr{$T},1)
            dima = Array(Ptr{Cint},1)
            heada = Array(Ptr{Ptr{Uint8}},1)
            na = Array(Cint,1)    
            @mlerr ccall(($(string(:MLGet,M,:Array)),:mathlink), MLRTN, 
                     (MLink, Ptr{Ptr{$T}}, Ptr{Ptr{Cint}}, Ptr{Ptr{Ptr{Uint8}}}, Ptr{Cint}), 
                     ml, arra, dima, heada, na)
            MLArrayRef{$T,int(na[1])}(arra[1],dima[1],heada[1])
        end
        function mlrelease{N}(ml::MLink, a::MLArrayRef{$T,N})
            ccall(($(string(:MLRelease,M,:Array)),:mathlink), None, 
                  (MLink, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Uint8}}, Cint), 
                  ml, a.arrptr, a.dimptr, a.headptr, N)
        end
    end
end

# numeric arrays: copy and automatic cleanup
function mlput{T<:Union(MLReals,Uint8),N}(ml::MLink, a::Array{T,N})
    mlput(ml,convert(MLArrayRef{T},Array{T,N}))
end
function mlget{T<:Union(MLReals,Uint8)}(ml::MLink, ::Type{Array{T}})
    ma = mlget(ml,MLArrayRef{T})
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

