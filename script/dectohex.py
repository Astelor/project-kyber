def tohex(val, nbits):
    return hex((val + (1 << nbits)) % (1 << nbits))


with open("zeta.txt", "r") as file:
    with open("dumpster_fire","w") as write:
        line = 1
        while(line):
            line = file.readline();
            hexx = tohex(int(line),16)
            #print(hexx)
            print(f"{hexx}", file = write)