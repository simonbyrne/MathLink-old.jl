using MathLink

e = mlinitialize()
l = mlopen(e)
mlactivate(l)

# skip input packet
mlnextpacket(l) != MathLink.INPUTNAMEPKT && error("Unexpected MathLink packet")
mlnewpacket(l)


# factor(123456789)
mlputfunction(l,"EvaluatePacket",1)
mlputfunction(l,"FactorInteger",1)
mlput(l,123456789)
mlendpacket(l)

# check for next packet
p = mlnextpacket(l)

t = mlgetnext(l) # a function: this is a list of lists of integers
a = mlget(l,Array{Int}) # note: this is transposed from Mathematica output

# done
mlclose(l)
mldeinitialize(e)
