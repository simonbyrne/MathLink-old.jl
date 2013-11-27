mlinitialize() = ccall(mathlink_fn(:MLInitialize), MLENV, (Ptr{Uint8},), C_NULL)
mldeinitialize(env::MLENV) = ccall(mathlink_fn(:MLDeinitialize), None, (MLENV,), env)

function mlopen{T<:String}(env, argv::Vector{T})
    erra = Array(Cint,1)
    ml = ccall(mathlink_fn(:MLOpenArgcArgv), MLINK, (MLENV, Cint, Ptr{Ptr{Uint8}}, Ptr{Cint}), env, length(argv), argv, erra)
    if erra[1] != MLEOK
        error("Could not start MathLink ",erra[1])
    end
    return ml
end
function mlopen(env, str::String)
    erra = Array(Cint,1)
    ml = ccall(mathlink_fn(:MLOpenString), MLINK, (MLENV, Ptr{Uint8}, Ptr{Cint}), env, str, erra)
    if erra[1] != MLEOK
        error("Could not start MathLink ",erra[1])
    end
    return ml
end

# by default, open local kernel
mlopen(e) = mlopen(e,["-linkname",mathematica_exec_path*" -mathlink","-linkmode","launch"])


mlclose(ml) = ccall(mathlink_fn(:MLClose), None, (MLINK,), ml)

mlactivate(ml) = ccall(mathlink_fn(:MLActivate), MLRTN, (MLINK,), ml) != MLRTN_ERR

mlready(ml) = ccall(mathlink_fn(:MLReady), MLRTN, (MLINK,), ml) != MLRTN_ERR

function mlflush(ml)
    if ccall(mathlink_fn(:MLFlush), MLRTN, (MLINK,), ml) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end



mlendpacket(ml) = ccall(mathlink_fn(:MLEndPacket), None, (MLINK,), ml)

mlnewpacket(ml) = ccall(mathlink_fn(:MLNewPacket), None, (MLINK,), ml)
mlnextpacket(ml) = ccall(mathlink_fn(:MLNextPacket), MLPKT, (MLINK,), ml)

mlgetnext(ml) = ccall(mathlink_fn(:MLGetNext), MLTKN, (MLINK,), ml)
function mlputnext(ml,t)
    if ccall(mathlink_fn(:MLPutNext), MLRTN, (MLINK, MLTKN), ml, t) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end




mlerror(ml) = ccall(mathlink_fn(:MLError), MLERR, (MLINK,), ml)





# put and get for different types

# strings
function mlput(ml,s::ASCIIString)
    if ccall(mathlink_fn(:MLPutByteString), MLRTN, (MLINK, Ptr{Uint8}, Cint), ml, s.data, length(s.data)) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end
function mlput(ml,s::UTF8String)
    if ccall(mathlink_fn(:MLPutUTF8String), MLRTN, (MLINK, Ptr{Uint8}, Cint), ml, s.data, length(s.data)) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end

function mlputsymbol(ml,s::ASCIIString)
    if ccall(mathlink_fn(:MLPutByteSymbol), MLRTN, (MLINK, Ptr{Uint8}, Cint), ml, s.data, length(s.data)) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end
function mlputsymbol(ml,s::UTF8String)
    if ccall(mathlink_fn(:MLPutUTF8Symbol), MLRTN, (MLINK, Ptr{Uint8}, Cint), ml, s.data, length(s.data)) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end
mlput(ml,s::Symbol) = mlputsymbol(ml,string(s))



function mlget(ml,::Type{ASCIIString})
    stra = Array(Ptr{Uint8},1)
    if ccall(mathlink_fn(:MLGetString), MLRTN, (MLINK, Ptr{Ptr{Uint8}}), ml, stra) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    str = bytestring(stra[1])
    ccall(mathlink_fn(:MLReleaseByteString), None, (MLINK, Ptr{Uint8}), ml, stra[1])
    return str
end

function mlget(ml,::Type{UTF8String})
    stra = Array(Ptr{Uint8},1)
    lb = Array(Cint,1)
    lc = Array(Cint,1)
    if ccall(mathlink_fn(:MLGetUTF8String), MLRTN, (MLINK, Ptr{Ptr{Uint8}},Ptr{Cint},Ptr{Cint}), ml, stra, lb, lc) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    str = utf8(pointer_to_array(stra[1],int(lb[1])))
    finalizer(str.data, a -> ccall(mathlink_fn(:MLReleaseUTF8String), None, (MLINK, Ptr{Uint8}, Cint), ml, stra[1],lb[1]))
    return str
end
mlget(ml,::Type{String}) = mlget(ml,UTF8String)

function mlget(ml,::Type{Symbol})
    stra = Array(Ptr{Uint8},1)
    lb = Array(Cint,1)
    lc = Array(Cint,1)
    if ccall(mathlink_fn(:MLGetUTF8Symbol), MLRTN, (MLINK, Ptr{Ptr{Uint8}},Ptr{Cint},Ptr{Cint}), ml, stra, lb, lc) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    str = utf8(pointer_to_array(stra[1],int(lb[1])))
    finalizer(str.data, a -> ccall(mathlink_fn(:MLReleaseUTF8Symbol), None, (MLINK, Ptr{Uint8}, Cint), ml, stra[1],lb[1]))
    return symbol(str)
end



for T in (:Integer16,:Integer32,:Integer64,:Real32,:Real64)
    @eval begin
        function mlput(ml,n::$T) 
            if ccall(mathlink_fn($(string(:MLPut,T))), MLRTN, (MLINK, $T), ml, n) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
        end
        function mlget(ml,::Type{$T}) 
            na = Array($T,1)    
            if ccall(mathlink_fn($(string(:MLGet,T))), MLRTN, (MLINK, Ptr{$T}), ml, na) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
            return na[1]
        end

        function mlput(ml, a::Array{$T,1})
            if ccall(mathlink_fn($(string(:MLPut,T,:List))), MLRTN, (MLINK, Ptr{$T}, Cint), ml, a, length(a)) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
        end
        function mlget(ml, ::Type{Array{$T,1}})
            aa = Array(Ptr{$T},1)
            la = Array(Cint,1)    
            if ccall(mathlink_fn($(string(:MLGet,T,:List))), MLRTN, (MLINK, Ptr{Ptr{$T}}, Ptr{Cint}), ml, aa, la) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
            a = pointer_to_array(aa[1],int(la[1]))
            finalizer(a, a -> ccall(mathlink_fn($(string(:MLRelease,T,:List))), None, (MLINK, Ptr{$T}, Cint), ml, aa[1], la[1]))
            return a
        end
        
        function mlput{N}(ml, a::Array{$T,N})
            s = size(a)
            dims = Cint[s[i] for i = ndims(a):-1:1]
            if ccall(mathlink_fn($(string(:MLPut,T,:Array))), MLRTN, 
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
            if ccall(mathlink_fn($(string(:MLGet,T,:Array))), MLRTN, 
                     (MLINK, Ptr{Ptr{$T}}, Ptr{Ptr{Cint}}, Ptr{Ptr{Ptr{Uint8}}}, Ptr{Cint}), 
                     ml, aa, la, ha, nda) == MLRTN_ERR
                error("MathLink error ", mlerror(ml))
            end
            dims = tuple(Int[unsafe_load(la[1],i) for i = nda[1]:-1:1]...)
            a = pointer_to_array(aa[1],dims)
            finalizer(a, a -> ccall(mathlink_fn($(string(:MLRelease,T,:Array))), None, 
                                    (MLINK, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Uint8}}, Cint), 
                                    ml, aa[1], la[1], ha[1], nda[1]))
            return a
        end
    end
end

# default representation
mlget(ml,::Type{Integer}) = mlget(ml,Int)
mlget(ml,::Type{Real}) = mlget(ml,Real64)
mlget(ml,::Type{FloatingPoint}) = mlget(ml,Real64)




# functions
function mlput(ml,f::MLFunction)
    if ccall(mathlink_fn(:MLPutFunction), MLRTN, (MLINK, Ptr{Uint8}, Cint), ml, f.name, f.nargs) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
end

function mlget(ml,::Type{MLFunction})
    stra = Array(Ptr{Uint8},1)
    na = Array(Cint, 1)
    if ccall(mathlink_fn(:MLGetFunction), MLRTN, (MLINK, Ptr{Ptr{Uint8}}, Ptr{Cint}), ml, stra, na) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    str = bytestring(stra[1])
    ccall(mathlink_fn(:MLReleaseSymbol), None, (MLINK, Ptr{Uint8}), ml, stra[1])
    return MLFunction(symbol(str), na[1])
end



function mlcheckfunction(ml,fname) 
    na = Array(Cint, 1)
    if ccall(mathlink_fn(:MLCheckFunction), MLRTN, (MLINK, Ptr{Uint8}, Ptr{Cint}), ml, fname, na) == MLRTN_ERR
        error("MathLink error ", mlerror(ml))
    end
    na[1]
end
