module MathLink

export mlinitialize, mldeinitialize, mlopen, mlclose, mlactivate,
mlputfunction, mlgetfunction, mlcheckfunction, mlput, mlget, mlnewpacket,
mlendpacket, mlnextpacket, mlputnext, mlgetnext, mlerror, mlflush, mlready, @mlput

include("setup.jl")
include("typesconsts.jl")
include("mlfn.jl")
include("mlextra.jl")
include("macro.jl")

# module
end