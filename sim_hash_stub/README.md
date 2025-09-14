# HASH STUB

This is the hash module stub for centered binomial distribution module (CBD) for simulation.

```
[randomness]->[hash module]->[hash stub]->[CBD]
```

![hash_stub_gif](/attachments/hash_stub_good.gif)

# HOW TO USE IT

1. In this directory: execute `Python3 script.py`
2. Run the simulation in modelsim
3. For more verbosity, you can execute `watch -n 0.5 xxd -c 32 test-hash_stub.txt` and `watch -n 0.5 xxd hash.flag` in different panels to see the Verilog module in action.

# HOW IT WORKS

There are two **flags** stored as files, one (`hash.flag`) written by the Verilog module, one (`hash2.flag`) written by the Python script. There's one text file (`test-hash_stub.txt`) written by the Verilog module that stores the message, also called the randomness, for the hash stub Python script to read. When the Python script finished processing the hash digest, it stores the digest to `mem<i>_hash_stub.hex`, writes to the `hash2.flag` to signal the Verilog module that the digest is ready, then the Verilog module "reads" `mem<i>_hash_stub.hex` files to the corresponding RAMs' memory using system tasks.

The Python script is a while-loop that actively checks the `hash.flag` and computes the hash digest using message from `test-hash_stub.txt`. If the `hash.flag` is 1, it computes the digest and sets `hash2.flag` to 1. If the `hash.flag` is 0, and the `hash2.flag` is 1, it sets the `hash2.flag` to 0, effectively resetting the flag.

The order stored in the `mem<i>_hash_stub.hex` file is: 

$$\text{digest}_{B}\in \text{Byte}^{128},\,\text{mem}_i[k]=\text{digest}_{B}[\text{k}*4+ i], k\in[0,31], i\in[0,3] $$

