# This is a modelsim macro file
# use "do pke_enc_custom.do" in modelsim CLI to execute the macro
transcript off
#== WAVE WIDGET CONFIG ====================================
configure wave -namecolwidth 400
configure wave -valuecolwidth 150
wave zoom range 0ps 2500ps

#== ADD WAVE ================================================
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

add wave -divider "INVNTT FSM"
add wave sim:tb_kyber_pke_enc/bruh/invntt_fsm/*

add wave -divider "DECOMPRESS FSM"
add wave sim:tb_kyber_pke_enc/bruh/decomp_fsm/*

add wave -divider "MATRIX"
add wave sim:tb_kyber_pke_enc/bruh/matrix_hash_fsm/*

add wave -divider "MEMORY 1 FSM"
add wave sim:tb_kyber_pke_enc/bruh/accu1_fsm/*

add wave -divider "MEMORY 2 FSM"
add wave sim:tb_kyber_pke_enc/bruh/accu2_fsm/*

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

#== POLYVEC MEMORY ==========================================
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

add wave -divider "INVNTT MODULE"
add wave sim:tb_kyber_pke_enc/bruh/invntt/ram1/mem
add wave sim:tb_kyber_pke_enc/bruh/invntt/ram2/mem

add wave -divider "DECOMPRESS MODULE"
add wave sim:tb_kyber_pke_enc/bruh/decomp/ram/mem

add wave -divider "MATRIX HASH"
add wave sim:tb_kyber_pke_enc/bruh/matrix_hash/ram_a/mem
add wave sim:tb_kyber_pke_enc/bruh/matrix_hash/ram_b/mem

# note: ram_a and ram_b are for even indexed data and odd indexed data
# note: this is the memory block in accumulator module
add wave -divider "MEMORY 1"
add wave -color magenta {sim:tb_kyber_pke_enc/bruh/GENACC[0]/accu1/ram_a/mem}
add wave -color magenta {sim:tb_kyber_pke_enc/bruh/GENACC[0]/accu1/ram_b/mem}
add wave -color orange  {sim:tb_kyber_pke_enc/bruh/GENACC[1]/accu1/ram_a/mem}
add wave -color orange  {sim:tb_kyber_pke_enc/bruh/GENACC[1]/accu1/ram_b/mem}
add wave -color #00ffff {sim:tb_kyber_pke_enc/bruh/GENACC[2]/accu1/ram_a/mem}
add wave -color #00ffff {sim:tb_kyber_pke_enc/bruh/GENACC[2]/accu1/ram_b/mem}

add wave -divider "MEMORY 2"
add wave -color gold sim:tb_kyber_pke_enc/bruh/accu2/ram_a/mem
add wave -color gold sim:tb_kyber_pke_enc/bruh/accu2/ram_b/mem

#== OTPUT CHECK =============================================

add wave -divider "OUTPUT"
add wave sim:tb_kyber_pke_enc/bruh/readout
add wave sim:tb_kyber_pke_enc/bruh/kyber_out_index
add wave sim:tb_kyber_pke_enc/bruh/kyber_dout_1
add wave sim:tb_kyber_pke_enc/bruh/kyber_dout_2


#== QUICK STATE CHECK =======================================
# this is for the ease of checking because everything's so far away

add wave -divider "BIG"

add wave sim:tb_kyber_pke_enc/bruh/fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/fsm/next_state

add wave -divider "INPUT"
add wave sim:tb_kyber_pke_enc/bruh/input_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/input_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/input_type
add wave sim:tb_kyber_pke_enc/bruh/input_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/input_fsm/next_state

add wave -divider "HASH"
add wave sim:tb_kyber_pke_enc/bruh/hash_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/hash_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/hash_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/hash_fsm/next_state

add wave -divider "CBD"
add wave sim:tb_kyber_pke_enc/bruh/cbd_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/cbd_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/cbd_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/cbd_fsm/next_state

add wave -divider "NTT"
add wave sim:tb_kyber_pke_enc/bruh/ntt_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/ntt_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/ntt_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/ntt_fsm/next_state

add wave -divider "POLYVEC"
add wave sim:tb_kyber_pke_enc/bruh/polyvec_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/polyvec_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/polyvec_a_s_type
add wave sim:tb_kyber_pke_enc/bruh/polyvec_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/polyvec_fsm/next_state

add wave -divider "INVNTT"
add wave sim:tb_kyber_pke_enc/bruh/invntt_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/invntt_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/invntt_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/invntt_fsm/next_state

add wave -divider "DECOMP"
add wave sim:tb_kyber_pke_enc/bruh/decomp_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/decomp_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/decomp_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/decomp_fsm/next_state

add wave -divider "MEM 1"
add wave sim:tb_kyber_pke_enc/bruh/accu1_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/accu1_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/accu1_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/accu1_fsm/next_state

add wave -divider "MEM 2"
add wave sim:tb_kyber_pke_enc/bruh/accu2_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/accu2_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/accu2_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/accu2_fsm/next_state

add wave -divider "MATRIX HASH"
add wave sim:tb_kyber_pke_enc/bruh/matrix_hash_ctrl_cmd
add wave sim:tb_kyber_pke_enc/bruh/matrix_hash_ctrl_status
add wave sim:tb_kyber_pke_enc/bruh/matrix_hash_fsm/curr_state
add wave sim:tb_kyber_pke_enc/bruh/matrix_hash_fsm/next_state


#== QUICK MODULE INNER WORKING VIEWER =======================
add wave -height 30 -divider "MODULE INNARDS"

#add wave -divider "HASH"
#add wave sim:tb_kyber_pke_enc/bruh/hash/*

#add wave -divider "DEC12"
#add wave sim:tb_kyber_pke_enc/bruh/dec12/*

add wave -divider "POLYVEC"
add wave sim:tb_kyber_pke_enc/bruh/polyvec/*
#add wave sim:tb_kyber_pke_enc/bruh/decomp/*
#add wave sim:tb_kyber_pke_enc/bruh/matrix_hash/* 

add wave -height 30 -divider "MODULE INNARDS 1"
add wave {sim:tb_kyber_pke_enc/bruh/GENACC[0]/accu1/*}
add wave {sim:tb_kyber_pke_enc/bruh/GENACC[1]/accu1/*}
add wave {sim:tb_kyber_pke_enc/bruh/GENACC[2]/accu1/*}

add wave -height 30 -divider "MODULE INNARDS 2"
add wave sim:tb_kyber_pke_enc/bruh/accu2/*

#== RADIX ===================================================
radix -unsigned
# -- BRUHHHHHHHH

radix signal sim:tb_kyber_pke_enc/bruh/kyber_dout_1 "h"
radix signal sim:tb_kyber_pke_enc/bruh/kyber_dout_2 "h"

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
radix signal sim:tb_kyber_pke_enc/bruh/hash/ram_a/mem "h"
radix signal sim:tb_kyber_pke_enc/bruh/hash/hash_din "h"
radix signal sim:tb_kyber_pke_enc/bruh/hash/hash_dout_1 "h"
radix signal sim:tb_kyber_pke_enc/bruh/hash/hash_dout_2 "h"
radix signal {sim:tb_kyber_pke_enc/bruh/hash/GENRAM[0]/ram_b/mem} "h" 
radix signal {sim:tb_kyber_pke_enc/bruh/hash/GENRAM[1]/ram_b/mem} "h" 
radix signal {sim:tb_kyber_pke_enc/bruh/hash/GENRAM[2]/ram_b/mem} "h" 
radix signal {sim:tb_kyber_pke_enc/bruh/hash/GENRAM[3]/ram_b/mem} "h" 


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

# -- DEC12
radix signal sim:tb_kyber_pke_enc/bruh/dec12/din "h"
radix signal sim:tb_kyber_pke_enc/bruh/dec12/stage  "h" -showbase  
radix signal sim:tb_kyber_pke_enc/bruh/dec12/dout_1 "h" -showbase  
radix signal sim:tb_kyber_pke_enc/bruh/dec12/dout_2 "h" -showbase  
radix signal sim:tb_kyber_pke_enc/bruh/dec12/temp_1 "h" -showbase  
radix signal sim:tb_kyber_pke_enc/bruh/dec12/temp_2 "h" -showbase  

#== LARGE RADIX DEFINE BLOCK ================================
# FSM
radix define States {
  8'h1 "IDLE",
  8'h2 "READY_INPUT",
  8'h3 "INPUT",        -color blue
  8'h4 "START_CAL",
  8'h5 "CALCULATE",
  8'h6 "OUTPUT_READY",
  8'h7 "OUTPUT",       -color magenta
  8'h8 "OUTPUT_DONE",
  8'h9 "SEQUENCE_DONE",-color red
  8'd10 "CHOOSE",      -color gold 
  8'hx "X",
  -default hex
}

radix define BIG_States {
  8'd1  "IDLE",
  8'd2  "HASH_CBD",
  8'd3  "STAGE_0",
  8'd4  "POLYVEC_EKT",
  8'd5  "STAGE_1",
  8'd6  "MESSAGE",
  8'd7  "STAGE_2",
  8'd8  "SEED",
  8'd9  "STAGE_3",
  8'd10 "HASH_CBD_2_STAGE",
  8'd11 "HASH_CBD_2",
  8'd12 "CBD_E2_STAGE",
  8'd13 "CBD_E2",
  8'd14 "HASH_CBD_1_STAGE",
  8'd15 "HASH_CBD_1",
  8'd16 "CBD_E1_STAGE",
  8'd17 "CBD_E1",
  8'd18 "POLYVEC_MAT_STAGE",
  8'd19 "POLYVEC_MAT",
  8'd20 "INTT_2_STAGE",
  8'd21 "INTT_2",
  8'hx "X",
  -default hex
}

radix define INPUT_States {
  8'd1 "IDLE",
  8'd2 "CHOOSE", -color gold
  8'd3 "HASH_INPUT_STAGE",
  8'd4 "HASH_INPUT_READY",
  8'd5 "HASH_INPUT_ACTIVE",
  8'd6 "HASH_INPUT_DONE",
  
  8'd11 "EKT_INPUT_STAGE",
  8'd12 "EKT_INPUT_READY",
  8'd13 "EKT_INPUT_ACTIVE",
  8'd14 "EKT_INPUT_DONE",
  
  8'd21 "MSG_INPUT_STAGE",
  8'd22 "MSG_INPUT_READY",
  8'd23 "MSG_INPUT_ACTIVE",
  8'd24 "MSG_INPUT_DONE",

  8'd31 "SEED_INPUT_STAGE",
  8'd32 "SEED_INPUT_READY",
  8'd33 "SEED_INPUT_ACTIVE",
  8'd34 "SEED_INPUT_DONE",

  8'hx  "X"
}

radix define POLYVEC_States {
  8'd1  "IDLE",
  8'd12 "CHOOSE",
  8'd2  "READY_INPUT",
  8'd11 "INPUT_0",
  8'd3  "INPUT_1",        -color gold
  8'd4  "INPUT_2",        -color blue
  8'd5  "START_CAL",
  8'd6  "CALCULATE",
  8'd7  "OUTPUT_READY",
  8'd8  "OUTPUT",         -color magenta
  8'd9  "OUTPUT_DONE",
  8'd10 "SEQUENCE_DONE",  -color red
  8'd13 "MAT_STAGE",
  8'd14 "MAT_INPUT_READY",
  8'd15 "MAT_INPUT",
  8'd16 "MAT_START_CAL_STAGE",
  8'hx  "X",
  -default hex
}

radix define DECOMP_States {
  8'h1  "IDLE",
  8'h2  "READY_INPUT",
  8'h3  "INPUT",         -color blue
  8'h5  "CALCULATE",
  8'h6  "OUTPUT_READY",
  8'h7  "OUTPUT",        -color magenta
  8'h8  "OUTPUT_DONE",
  8'h9  "SEQUENCE_DONE", -color red
  8'd10 "OUTPUT_STAGE",
  8'hx "X",
  -default hex
}

radix define MEM1_States {
  8'd1 "IDLE",
  
  8'd10 "STAGE_2",
  8'd7 "CBD_READY",
  8'd8 "CBD_READY_1",
  8'd9 "CBD_INPUT", -color blue
  
  8'd11 "STAGE_3",

  8'd2 "STAGE_0",
  8'd3 "INTT_READY",
  8'd4 "INTT_INPUT",
  8'd5 "STAGE_1",
  8'd6 "SEQUENCE_DONE",
  
  8'd12 "COMPRESS_START",
  8'd13 "COMPRESS_DONE",

  8'd14 "START_OUTPUT",
  8'd15 "OUTPUT_READY",
  8'd16 "OUTPUT",
  8'd17 "OUTPUT_DONE",
  8'd18 "ALL_DONE",
  
  8'hx "X",
}

radix define MEM2_States {
  8'd1  "IDLE",
  8'd9  "MESSAGE_STAGE",
  8'd2  "MESSAGE_READY",
  8'd3  "MESSAGE_INPUT",
  8'd4  "STAGE_0",
  8'd5  "E2_READY",
  8'd6  "E2_INPUT",
  8'd7  "STAGE_1",
  8'd8  "E2_READY_1"
  8'd10 "INTT_READY",
  8'd11 "INTT_INPUT",
  8'd12 "STAGE_2",
  8'd13 "COMPRESS_START",
  8'd14 "COMPRESS_DONE",
  8'd15 "OUTPUT_READY",
  8'd16 "OUTPUT",
  8'd17 "OUTPUT_DONE",
  8'hx "X",
}

radix define MATRIX_States {
  8'h1 "IDLE",
  8'h2 "READY_INPUT",
  8'h3 "INPUT",        -color blue
  8'h4 "START_CAL",
  8'h5 "CALCULATE",
  8'h6 "OUTPUT_READY",
  8'h7 "OUTPUT",       -color magenta
  8'h8 "OUTPUT_DONE",
  8'h9 "SEQUENCE_DONE",-color red
  8'd10 "CHOOSE",      -color gold 
  8'd11 "START_CAL_STAGE",
  8'd12 "SEQUENCE_STAGE",
  8'hx "X",
  -default hex
}

radix define INVNTT_States {
  8'h1 "IDLE",
  8'h2 "READY_INPUT",
  8'h3 "INPUT",        -color blue
  8'h4 "START_CAL",
  8'h5 "CALCULATE",
  8'h6 "OUTPUT_READY",
  8'h7 "OUTPUT",       -color magenta
  8'h8 "OUTPUT_DONE",
  8'h9 "SEQUENCE_DONE",-color red
  8'd10 "START_CAL_2", 
  8'd11 "CHOOSE", -color gold 
  8'hx "X",
  -default hex
}

#== CURR AND NEXT STATE RADIX SETTING =======================

radix signal sim:tb_kyber_pke_enc/bruh/fsm/curr_state "BIG_States"
radix signal sim:tb_kyber_pke_enc/bruh/fsm/next_state "BIG_States"

radix signal sim:tb_kyber_pke_enc/bruh/input_fsm/curr_state "INPUT_States"
radix signal sim:tb_kyber_pke_enc/bruh/input_fsm/next_state "INPUT_States"

radix signal sim:tb_kyber_pke_enc/bruh/hash_fsm/curr_state "States"
radix signal sim:tb_kyber_pke_enc/bruh/hash_fsm/next_state "States"

radix signal sim:tb_kyber_pke_enc/bruh/cbd_fsm/curr_state "States"
radix signal sim:tb_kyber_pke_enc/bruh/cbd_fsm/next_state "States"

radix signal sim:tb_kyber_pke_enc/bruh/ntt_fsm/curr_state "States"
radix signal sim:tb_kyber_pke_enc/bruh/ntt_fsm/next_state "States"

radix signal sim:tb_kyber_pke_enc/bruh/polyvec_fsm/curr_state "POLYVEC_States"
radix signal sim:tb_kyber_pke_enc/bruh/polyvec_fsm/next_state "POLYVEC_States"

radix signal sim:tb_kyber_pke_enc/bruh/invntt_fsm/curr_state "INVNTT_States"
radix signal sim:tb_kyber_pke_enc/bruh/invntt_fsm/next_state "INVNTT_States"

radix signal sim:tb_kyber_pke_enc/bruh/decomp_fsm/curr_state "DECOMP_States"
radix signal sim:tb_kyber_pke_enc/bruh/decomp_fsm/next_state "DECOMP_States"

radix signal sim:tb_kyber_pke_enc/bruh/matrix_hash_fsm/curr_state "MATRIX_States"
radix signal sim:tb_kyber_pke_enc/bruh/matrix_hash_fsm/next_state "MATRIX_States"

radix signal sim:tb_kyber_pke_enc/bruh/accu1_fsm/curr_state "MEM1_States"
radix signal sim:tb_kyber_pke_enc/bruh/accu1_fsm/next_state "MEM1_States"

radix signal sim:tb_kyber_pke_enc/bruh/accu2_fsm/curr_state "MEM2_States"
radix signal sim:tb_kyber_pke_enc/bruh/accu2_fsm/next_state "MEM2_States"

restart
run -all

# note: things that does not work?
#add wave -divider "== hash"    -position before sim:tb_kyber_pke_enc/bruh/hash_set
#add wave -divider "== ntt"     -position before sim:tb_kyber_pke_enc/bruh/ntt_set
#add wave -divider "== cbd"     -position before sim:tb_kyber_pke_enc/bruh/cbd_set
#add wave -divider "== polyvec" -position before sim:tb_kyber_pke_enc/bruh/polyvec_set