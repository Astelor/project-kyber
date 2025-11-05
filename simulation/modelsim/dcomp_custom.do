configure wave -namecolwidth 350
configure wave -valuecolwidth 100
wave zoom range 0ps 320ps

add wave *
add wave -divider "MODULE"
add wave sim:tb_decompress1/bruh/*
add wave sim:tb_decompress1/bruh/ram/mem
add wave -divider "FSM"
add wave sim:tb_decompress1/bruh/fsm/*

radix -hex

radix define FSM_States {
    1 "IDLE",         -color gold
    2 "INPUT",        -color blue
    3 "READY",        
    4 "DRAW",         -color green
    5 "OUTPUT_READY", 
    6 "OUTPUT_0",     
    7 "OUTPUT_1",     
    8 "OUTPUT_2",     
    9 "OUTPUT_3",  
    10 "OUTPUT_4",
    x "X",
    -default dec
}

radix signal sim:tb_decompress1/bruh/fsm/curr_state "FSM_States"
radix signal sim:tb_decompress1/bruh/fsm/next_state "FSM_States"

#radix signal sim:tb_decompress1/bruh/cal_r[0] "d" -showbase
#radix signal sim:tb_decompress1/bruh/cal_r[1] "d" -showbase
#radix signal sim:tb_decompress1/bruh/cal_r[2] "d" -showbase
#radix signal sim:tb_decompress1/bruh/cal_r[3] "d" -showbase
#radix signal sim:tb_decompress1/bruh/cal_r[4] "d" -showbase
#radix signal sim:tb_decompress1/bruh/cal_r[5] "d" -showbase
#radix signal sim:tb_decompress1/bruh/cal_r[6] "d" -showbase
#radix signal sim:tb_decompress1/bruh/cal_r[7] "d" -showbase

restart
run -all