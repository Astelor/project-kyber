# SampleNTT stub
from Crypto.Hash import SHAKE256
# this version from Cryptodome is more of a sponge function

p = b'this is a test' # seed

h = SHAKE256.new() # XOF.Init()
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

print(a)