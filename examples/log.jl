using MathLink

e = mlinitialize()

l = mlopen(e)
mlactivate(l)

# skip initial input packet
if mlnextpacket(l) != MathLink.INPUTNAMEPKT
    error("Unexpected MathLink packet")
end
mlnewpacket(l)


# 1) log(2.0)
mlput(l,MLFunction("EvaluatePacket",1))
mlput(l,MLFunction("Log",1))
mlput(l,2.0)
mlendpacket(l)

# check for next packet
p = mlnextpacket(l)

t = mlgetnext(l) # a real
mlget(l,Float64)


# 2) using expressions
@mlput l EvaluatePacket(Log(2.0))
mlendpacket(l)

p = mlnextpacket(l)

t = mlgetnext(l) # a real
mlget(l,Float64)

@mlput l EvaluatePacket(Sin(:Pi))
mlendpacket(l)

p = mlnextpacket(l)

t = mlgetnext(l) # a real
mlget(l,Float64)


# 3) log(2)
mlput(l,MLFunction("EvaluatePacket",1))
mlput(l,MLFunction("Log",1))
mlput(l,2)
mlendpacket(l)

# check for next packet
p = mlnextpacket(l)

t = mlgetnext(l) # a function
mlgetfunction(l)

t = mlgetnext(l) # an integer
mlget(l,Int)


# 4) we can pass expressions
mlput(l,:(EvaluatePacket(Log(2))))
mlendpacket(l)

p = mlnextpacket(l)
# automatically figure out types
mlget(l)

# 5) or use strings representing Mathematica expressions
mlput(l,:(EvaluatePacket(ToExpression("Factorial[30]"))))
mlendpacket(l)

p = mlnextpacket(l)
# occasionally need to specify return types.
mlget(l,BigInt)



mlput(l,:(EvaluatePacket(Integrate(Abs(x), x, Assumptions => x > 0))))
mlendpacket(l)

p = mlnextpacket(l)
mlget(l)

bg = big(1e-30)
@mlput l EvaluatePacket(Log(CDF(GammaDistribution(1,1),bg)))
mlendpacket(l)

p = mlnextpacket(l)
mlget(l)




# done
mlclose(l)
mldeinitialize(e)
