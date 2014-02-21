module MathLink

export mlinitialize, mldeinitialize, mlopen, mlclose, mlactivate,
mlcheckfunction, mlput, mlget, mlnewpacket, MLFunction,
mlendpacket, mlnextpacket, mlputnext, mlgetnext, mlerror, mlflush, mlready, @mlput

import Base.convert

include("setup.jl")
include("typesconsts.jl")
include("mlfn.jl")
include("mlextra.jl")
include("macro.jl")

# module
end
