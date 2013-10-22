using MathLink

e = mlinitialize()
l = mlopen(e,["-linkname","MathKernel -mathlink"])

# skip input packet
p = mlnextpacket(l)
mlnewpacket(l)


# log(2.0)
mlputfunction(l,"Log",1)
mlput(l,2.0)

# check for next packet
p = mlnextpacket(l)

t = mlgetnext(l) # a real
mlget(l,Float64)

# log(2)
mlputfunction(l,"Log",1)
mlput(l,2)

# check for next packet
p = mlnextpacket(l)

t = mlgetnext(l) # a function
mlgetfunction(l)

t = mlgetnext(l) # an integer
mlget(l,Int)

# done
mlclose(l)
mldeinitialize(e)
