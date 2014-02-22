module MathLink

export mlinitialize, mldeinitialize, mlopen, mlclose, mlactivate,
mlerror, mlerrormessage, mlclearerror, mlflush, mlready,
mlnewpacket, mlendpacket, mlnextpacket, mlgetnext, mlputnext, mlgetnextraw,
mlput, mlget, MLFunction, mltesthead, @mlput,
mlloopbackopen, mltransferexpression, mltransfertoendofloopbacklink,
mlcreatemark, mlseektomark, mldestroymark,
mlgetlinkedenvidstring, mlsetenvidstring, mllinkname, mltolinkid, mlfromlinkid

import Base.convert

include("setup.jl")
include("typesconsts.jl")
include("mlfn.jl")
include("mlextra.jl")
include("macro.jl")

# module
end
