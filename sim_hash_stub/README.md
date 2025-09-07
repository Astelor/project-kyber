# HASH STUB

This is the hash module stub for centered binomial distribution module (CBD) for simulation.

```
[randomness]->[hash module]->[hash stub]->[CBD]
```

![hash_stub_gif](/attachments/hash_stub_2025-09-07-025113-optimize1.gif)

> the gif might need to be optimized -> 99mb will load forever

# HOW TO USE IT
1. In this directory execute `python3 script.py`
2. run the simulation in modelsim
3. that's it

# HOW IT WORKS

There are two **flags** stored as files, one (`hash.flag`) written by the Verilog module, one (`hash2.flag`) written by the python script. There's one text file (`test-hash_stub.txt`) written by the Verilog module that stores the message, also called the randomness, for the hash stub python script to read. When the python script finished processing the hash digest, it stores the digest to `mem<i>_hash_stub.hex`, writes to the `hash2.flag` to signal the Verilog module that the digest is ready, then the Verilog module reads the `mem<i>_hash_stub.hex` to the corresponding RAMs using system tasks.

The python script is a while-loop that actively checks the `hash.flag` and computes the hash digest. If the `hash.flag` is 1, it computes the digest and sets `hash2.flag` to 1. If the `hash.flag` is 0, and the `hash2.flag` is 1, it sets the `hash2.flag` to 0, effectively resetting the flag.

The order stored in the `mem<i>_hash_stub.hex` file is: 

$$\text{digest}_{B}\in \text{Byte}^{128},\,\text{mem}_i[k]=\text{digest}_{B}[\text{k}*4+ i], k\in[0,31], i\in[0,3] $$

