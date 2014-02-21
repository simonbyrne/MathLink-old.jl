using MathLink

e = mlinitialize()
l = mlopen(e)

mlactivate(l)

# skip initial input packet
if mlnextpacket(l) != MathLink.INPUTNAMEPKT
    error("Unexpected MathLink packet")
end
mlnewpacket(l)


mlput(l,MLFunction(:EvaluatePacket,1))
mlput(l,MLFunction(:Sin,1))
mlput(l,:Pi)
mlendpacket(l)

p = mlnextpacket(l)
mlget(l)


mlput(l,MLFunction(:EvaluatePacket,1))
mlput(l,MLFunction(:Sin,1))
mlput(l,:π)
mlendpacket(l)

p = mlnextpacket(l)
mlget(l,Expr)


mlput(l,MLFunction(:EvaluatePacket,1))
mlput(l,MLFunction(:ToExpression,1))
mlput(l,"Sin[π]")
mlendpacket(l)

p = mlnextpacket(l)
mlget(l,Expr)


mlput(l,MLFunction("Plot",2))
mlput(l,MLFunction("Sin",1))
mlput(l,:x)
mlput(l,MLFunction("List",3))
mlput(l,:x)
mlput(l,0)
mlput(l,2)

mlendpacket(l)

# check for next packet
p = mlnextpacket(l)

t = mlgetnext(l) # a real



# done
mlclose(l)
mldeinitialize(e)
