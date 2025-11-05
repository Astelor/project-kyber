# SampleNTT stub
import sys
from time import sleep
from Crypto.Hash import SHAKE128
# this version from Cryptodome is more of a sponge function
import string


#p = b'this is a test' # seed
def samplentt(p):
    h = SHAKE128.new() # XOF.Init()
    h.update(p) # XOF.Absorb
    q = 3329
    j = 0
    a = [0]*256 # output array
    while j < 256:
        temp = h.read(3) # XOF.Squeeze(3)
        d1 = temp[0] + (temp[1] & 0xf) << 8
        d2 = (temp[1] >> 4) + (temp[2] << 4)
        if d1 < q:
            a[j] = d1
            j = j + 1
        if (d2 < q) and (j < 256):
            a[j] = d2
            j = j + 1

    #print(a)
    return a

k = 0
anim = ['-','\\','|','/']

def func(ch: str) -> bool:
    return ch not in string.hexdigits

fd1 = open("./matrix_hash.flag","r") # shake_full_in
fd2 = open("./matrix_hash2.flag","w") # shake_done
fd3 = open("./test-matrix_hash_stub.txt","r") # the memory

flag = 0
flag2 = 0
# gest = "it_nothing"
counter = 0
matt = [0]*256

fd2.write(str(flag2))
fd2.close()

while 1:
    temp = fd1.read()
    fd1.seek(0)
    # cleansing the flag
    if(temp == '0' or temp == '1'):
        flag = int(temp)&1
    
    if(flag == 1 and flag2 == 0):
        seed = fd3.read() # data will be in hex
        fd3.seek(0)
        seed = seed.replace('\n','')
        #print(seed)
        #print(func(seed))
        if(func(seed)):
            mem  = open("./mem_matrix_hash_stub.hex","w") # the completed hash
            seed = bytes.fromhex(seed)
            matt = samplentt(seed)

            #gest = gest.hex() # in hex
            # put them in memory banks 32*4 
            for i in matt:
                mem.write(str(hex(i)[2:])) 
                mem.write("\n")

            flag2 = int(1)

            fd2 = open("./matrix_hash2.flag","w") # shake_done
            fd2.write(str(flag2))
            fd2.close()
            
            mem.close()

            counter = counter + 1
            sys.stdout.write("\n")
            sys.stdout.write("[+] message:\n");
            sys.stdout.write("%s\n" % (seed.hex()));
            sys.stdout.write("[+] hash:\n");
            for r in range(len(matt)):
                if(r%16==0):
                    sys.stdout.write("%3d: " % (r>>4))

                sys.stdout.write("%4s " % (matt[r]))
                # if(r & 0x7 == 7):
                #     sys.stdout.write(" ")
                if(r & 0xf == 15):
                    sys.stdout.write("\n")
            sys.stdout.write("")
        #else: 
            
    if(flag == 0 and flag2 == 1):
        flag2 = 0
        fd2 = open("./matrix_hash2.flag","w") # shake_done
        fd2.write(str(flag2))
        fd2.close()
    
    sys.stdout.write('\r')
    sys.stdout.write("_[%s] matrix hash stubbing [+] flag1 = %s. flag2 = %s. hash snippet: %s [%2d]" % (anim[k], flag, flag2 ,hex((matt[0]<<24)+(matt[1]<<12)+(matt[2])), counter))
    k = (k + 1)%len(anim)
    
    sleep(0.25)