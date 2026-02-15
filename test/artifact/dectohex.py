def tohex(val, nbits):
    return hex((val + (1 << nbits)) % (1 << nbits))

# change the file name 
# for the data needed to be converted in to HEX
with open("test-invntt-out-no-mult.txt","r") as file:
    with open("test-invntt-out-no-mult.hex","w") as write:
        line = 1
        while(line):
            line = file.readline();
            hexx = tohex(int(line),16)
            #print(hexx)
            print(f"{hexx}", file = write)