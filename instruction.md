# custom micro instructions for kyber_pke_enc
> **8 bit** for both cmd and status codes (larger to make my life easier)
> the code are represented in **hexadecimal**, even while I

# TYPE

## hash_type
- 0: idle
- 1: hash -> cbd
- 2: hash -> poly_bm

## cbd_type
- 0: idle
- 1: cbd -> ntt
- 2: 

# CMD
> command from "big control"

## input_ctrl_cmd
- 00: idle
- 01: to hash (randomness for CBD)
- 02: to polyvec_bm (public key t)
- 03: to buffer1 (symmetric key message)
- 04: to buffer0 (matrix A seed)

## hash_ctrl_cmd
- 00: idle
- 01: "hash and cbd you guys should talk and figure it out :)"
- 02: "hash and polybm you guys should talk and figure it out"

- 01: "hey input this!" input randomness from outside ()
- 02: "hey there's no more input, start doing cal"
- 03: "hey do the output"

> I think the full_in signal can purely be handled by hash FSM?
> The only explicit "start_cal" signal for this is `full_in` and the nonce will go with it, and nonce not even a latch
> A "do cal" signal is still needed because sometimes there's nothing to input bruh

> I need a reg noting which input should be active at the moment

## cbd_ctrl_cmd
- 00: idle
- 01: "hash and cbd you guys should talk and figure it out :)"
- 01: "hey input from hash now" input from hash
- 02: 

# STATUS
> status code from module controls (small control)

## input_ctrl_status
- 00: idle (the FSM state could be either idle or choose)
- 01: hash input stage
- 02: hash doing input
- 03: hash input done

- 11: ekt input stage
- 12: ekt input active
- 13: ekt input done

> I'm separating the fsm or hash and polyvec ekt because I don't wanna break it :')

## hash_ctrl_status
- 00: idle
- 01: "hey I can do input now"
- 02: "thanks I'm doing input now"
- 03: calculating
- 04: output ready
- 05: outputing...
- 06: I've finished the output!

- 10: hey I've finished the sequence for the command, tell me to do something else >:(
- 
> where the heck do I manage the sub sequence???

## cbd_ctrl_status
- 00: idle
- 01: "hey I can do input now"
- 02: "I'm doing input right now"
- 03: calculating
- 04: output ready
- 05: outputing...
- 06: I've finished the output!
 
 > keep the sequencing internal?
 > -> when the command is present, act on the sequence?
 
## ntt_ctrl_status
- 00: idle
- 01: "hey I can do input now"
- 02: "I'm doing input right now"
- 03: calculating
- 04: output ready
- 05: outputing...
- 06: I've finished the output!


## polyvec_basemul

- 00: idle
- 01: "hey I can do input now"
- 02: "I'm doing input right now"
- 03: calculating
- 04: output ready
- 05: outputing...
- 06: I've finished the output!