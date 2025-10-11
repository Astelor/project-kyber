import sys
from time import sleep
from hashlib import shake_256
import string

fd1 = open("./hash.flag","r") # shake_full_in
fd3 = open("./test-hash_stub.txt","r") # the memory

def func(ch: str) -> bool:
    return ch not in string.hexdigits

k = 0
anim = ['-','\\','|','/']
flag = 0
flag2 = 0
gest = "it_nothing"
counter = 0
fd2 = open("./hash2.flag","w") # shake_done
fd2.write(str(flag2))
fd2.close()
while 1:
    temp = fd1.read()
    fd1.seek(0)
    # cleansing the flag
    if(temp == '0' or temp == '1'):
        flag = int(temp)&1
    
    if(flag == 1 and flag2 == 0):
        temp1 = fd3.read() # data will be in hex
        fd3.seek(0)
        temp1 = temp1.replace('\n','')
        #print(temp1)
        #print(func(temp1))
        if(func(temp1)):
            mem0 = open("./mem0_hash_stub.hex","w") # the completed hash
            mem1 = open("./mem1_hash_stub.hex","w") # the completed hash
            mem2 = open("./mem2_hash_stub.hex","w") # the completed hash
            mem3 = open("./mem3_hash_stub.hex","w") # the completed hash
            temp1 = bytes.fromhex(temp1)
            h1 = shake_256(temp1)
            gest = h1.digest(64*2).hex() # in bytes
            #gest = gest.hex() # in hex
            # put them in memory banks 32*4 
            for i in range(len(gest)>>3):
                mem0.write(gest[i*8     ]) 
                mem0.write(gest[i*8 + 1 ])
                mem0.write("\n")

                mem1.write(gest[i*8     +2])
                mem1.write(gest[i*8 + 1 +2])
                mem1.write("\n")

                mem2.write(gest[i*8     +4])
                mem2.write(gest[i*8 + 1 +4])
                mem2.write("\n")

                mem3.write(gest[i*8     +6])
                mem3.write(gest[i*8 + 1 +6])
                mem3.write("\n")
            
            flag2 = int(1)

            fd2 = open("./hash2.flag","w") # shake_done
            fd2.write(str(flag2))
            fd2.close()
            
            mem0.close()
            mem1.close()
            mem2.close()
            mem3.close()

            counter = counter + 1
            sys.stdout.write("\n")
            sys.stdout.write("[+] message:\n");
            sys.stdout.write("%s\n" % (temp1.hex()));
            sys.stdout.write("[+] hash:\n");
            for r in range(len(gest)):
                if(r%16==0):
                    sys.stdout.write("%3d " % (r>>4))

                sys.stdout.write("%s" % (gest[r]))
                if(r & 0x7 == 7):
                    sys.stdout.write(" ")
                if(r & 0xf == 15):
                    sys.stdout.write("\n")
        #else: 
            
    if(flag == 0 and flag2 == 1):
        flag2 = 0
        fd2 = open("./hash2.flag","w") # shake_done
        fd2.write(str(flag2))
        fd2.close()
    
    sys.stdout.write('\r')
    sys.stdout.write("_[%s] hash stubbing [+] flag1 = %s. flag2 = %s. hash snippet: %s [%2d]" % (anim[k], flag, flag2 ,gest[0:10], counter))
    k = (k + 1)%len(anim)

    sleep(0.25)
