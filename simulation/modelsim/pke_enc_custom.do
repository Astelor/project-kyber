#transcript on
# WAVE WIDGET CONFIG
configure wave -namecolwidth 350
configure wave -valuecolwidth 90
wave zoom range 0ps 2500ps

# ADD WAVE ==============================================
add wave sim:tb_kyber_pke_enc/*
add wave -divider "BRUHHHHHHHH"
add wave sim:tb_kyber_pke_enc/bruh/*
add wave -divider "BIG FSM"
add wave sim:tb_kyber_pke_enc/bruh/fsm/*
add wave -divider "INPUT FSM"
add wave sim:tb_kyber_pke_enc/bruh/input_fsm/*
add wave -divider "HASH FSM"
add wave sim:tb_kyber_pke_enc/bruh/hash_fsm/*
add wave -divider "CBD FSM"
add wave sim:tb_kyber_pke_enc/bruh/cbd_fsm/*
add wave -divider "NTT FSM"
add wave sim:tb_kyber_pke_enc/bruh/ntt_fsm/*
add wave -divider "POLYVEC FSM"
add wave sim:tb_kyber_pke_enc/bruh/polyvec_fsm/*

add wave -divider "HASH MODULE"
#add wave sim:tb_kyber_pke_enc/bruh/hash/*
add wave sim:tb_kyber_pke_enc/bruh/hash/ram_a/mem
add wave -divider "=== hash digest"
add wave {sim:tb_kyber_pke_enc/bruh/hash/GENRAM[0]/ram_b/mem}
add wave {sim:tb_kyber_pke_enc/bruh/hash/GENRAM[1]/ram_b/mem}
add wave {sim:tb_kyber_pke_enc/bruh/hash/GENRAM[2]/ram_b/mem}
add wave {sim:tb_kyber_pke_enc/bruh/hash/GENRAM[3]/ram_b/mem}

add wave -divider "CBD MODULE"
#add wave sim:tb_kyber_pke_enc/bruh/cbd/*
add wave sim:tb_kyber_pke_enc/bruh/cbd/ram1/mem

add wave -divider "NTT MODULE"
#add wave sim:tb_kyber_pke_enc/bruh/ntt/*
add wave sim:tb_kyber_pke_enc/bruh/ntt/ram1/mem
add wave sim:tb_kyber_pke_enc/bruh/ntt/ram2/mem

add wave -divider "POLYVEC MODULE"
add wave -divider "=== RAM A & B, k = 0" 
add wave -color magenta {sim:tb_kyber_pke_enc/bruh/polyvec/GENRAM[0]/ram_a/mem}
add wave -color magenta {sim:tb_kyber_pke_enc/bruh/polyvec/GENRAM[0]/ram_b/mem}
add wave -divider "=== RAM A & B, k = 1"
add wave -color orange {sim:tb_kyber_pke_enc/bruh/polyvec/GENRAM[1]/ram_a/mem}
add wave -color orange {sim:tb_kyber_pke_enc/bruh/polyvec/GENRAM[1]/ram_b/mem}
add wave -divider "=== RAM A & B, k = 2"
add wave -color #ebef00 {sim:tb_kyber_pke_enc/bruh/polyvec/GENRAM[2]/ram_a/mem}
add wave -color #ebef00 {sim:tb_kyber_pke_enc/bruh/polyvec/GENRAM[2]/ram_b/mem}
add wave -divider "=== RAM C "
add wave -color #00ffff {sim:tb_kyber_pke_enc/bruh/polyvec/GENRAM[0]/RAMC/ram_c/mem}
add wave -color #00ffff {sim:tb_kyber_pke_enc/bruh/polyvec/GENRAM[1]/RAMC/ram_c/mem}


add wave -height 30 -divider "MODULE INNARDS"
add wave sim:tb_kyber_pke_enc/bruh/hash/*
#add wave sim:tb_kyber_pke_enc/bruh/polyvec/*

radix -unsigned

# RADIX ===================================
# -- BRUHHHHHHHH

radix signal sim:tb_kyber_pke_enc/bruh/kyber_din "h"

radix signal sim:tb_kyber_pke_enc/bruh/hash_din "h"
radix signal sim:tb_kyber_pke_enc/bruh/hash_dout_1 "h"
radix signal sim:tb_kyber_pke_enc/bruh/hash_dout_2 "h"

radix signal sim:tb_kyber_pke_enc/bruh/cbd_din_1 "h"
radix signal sim:tb_kyber_pke_enc/bruh/cbd_din_2 "h"
radix signal sim:tb_kyber_pke_enc/bruh/cbd_dout_1 "d"
radix signal sim:tb_kyber_pke_enc/bruh/cbd_dout_2 "d"

radix signal sim:tb_kyber_pke_enc/bruh/ntt_din_1 "d"
radix signal sim:tb_kyber_pke_enc/bruh/ntt_din_2 "d"
radix signal sim:tb_kyber_pke_enc/bruh/ntt_dout_1 "d"
radix signal sim:tb_kyber_pke_enc/bruh/ntt_dout_2 "d"

radix signal sim:tb_kyber_pke_enc/bruh/barr1_a "d"
radix signal sim:tb_kyber_pke_enc/bruh/barr1_t "d"
radix signal sim:tb_kyber_pke_enc/bruh/barr2_a "d"
radix signal sim:tb_kyber_pke_enc/bruh/barr2_t "d"

radix signal sim:tb_kyber_pke_enc/bruh/polyvec_din_a_1 "d"
radix signal sim:tb_kyber_pke_enc/bruh/polyvec_din_a_2 "d"

# -- HASH
radix signal sim:tb_kyber_pke_enc/bruh/hash/hash_din "h"
radix signal sim:tb_kyber_pke_enc/bruh/hash/hash_dout_1 "h"
radix signal sim:tb_kyber_pke_enc/bruh/hash/hash_dout_2 "h"

# -- CBD
radix signal sim:tb_kyber_pke_enc/bruh/cbd/cbd_din_1 "h"
radix signal sim:tb_kyber_pke_enc/bruh/cbd/cbd_din_2 "h"
radix signal sim:tb_kyber_pke_enc/bruh/cbd/cbd_dout_1 "d"
radix signal sim:tb_kyber_pke_enc/bruh/cbd/cbd_dout_2 "d"
radix signal sim:tb_kyber_pke_enc/bruh/cbd/ram1/mem "h"

# -- NTT
radix signal sim:tb_kyber_pke_enc/bruh/ntt/ntt_din_1 "d"
radix signal sim:tb_kyber_pke_enc/bruh/ntt/ntt_din_2 "d"
radix signal sim:tb_kyber_pke_enc/bruh/ntt/ntt_dout_1 "d"
radix signal sim:tb_kyber_pke_enc/bruh/ntt/ntt_dout_2 "d"
radix signal sim:tb_kyber_pke_enc/bruh/ntt/ram1/mem "d"
radix signal sim:tb_kyber_pke_enc/bruh/ntt/ram2/mem "d"


# FSM
radix define States {
  8'h1 "IDLE",
  8'h2 "READY_INPUT",
  8'h3 "INPUT",        -color gold
  8'h4 "START_CAL",
  8'h5 "CALCULATE",
  8'h6 "OUTPUT_READY",
  8'h7 "OUTPUT",       -color #fc00b9
  8'h8 "OUTPUT_DONE",
  8'h9 "SEQUENCE_DONE",
  8'hx "X",
  -default hex
}

radix define BIG_States {
  8'h1 "IDLE",
  8'h2 "HASH_CBD",
  8'h3 "STAGE",
  8'h4 "POLYVEC_EKT",
  8'hx "X",
  -default hex
}

radix define INPUT_States {
  8'h
}

radix signal sim:tb_kyber_pke_enc/bruh/fsm/curr_state "BIG_States"
radix signal sim:tb_kyber_pke_enc/bruh/fsm/next_state "BIG_States"

radix signal sim:tb_kyber_pke_enc/bruh/hash_fsm/curr_state "States"
radix signal sim:tb_kyber_pke_enc/bruh/hash_fsm/next_state "States"

radix signal sim:tb_kyber_pke_enc/bruh/cbd_fsm/curr_state "States"
radix signal sim:tb_kyber_pke_enc/bruh/cbd_fsm/next_state "States"

radix signal sim:tb_kyber_pke_enc/bruh/ntt_fsm/curr_state "States"
radix signal sim:tb_kyber_pke_enc/bruh/ntt_fsm/next_state "States"

radix signal sim:tb_kyber_pke_enc/bruh/polyvec_fsm/curr_state "States"
radix signal sim:tb_kyber_pke_enc/bruh/polyvec_fsm/next_state "States"

restart
run -all

#add wave -divider "== hash"    -position before sim:tb_kyber_pke_enc/bruh/hash_set
#add wave -divider "== ntt"     -position before sim:tb_kyber_pke_enc/bruh/ntt_set
#add wave -divider "== cbd"     -position before sim:tb_kyber_pke_enc/bruh/cbd_set
#add wave -divider "== polyvec" -position before sim:tb_kyber_pke_enc/bruh/polyvec_set