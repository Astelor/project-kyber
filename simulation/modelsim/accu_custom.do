configure wave -namecolwidth 350
configure wave -valuecolwidth 100
wave zoom range 0ps 320ps

add wave -divider "BRUH (TESTBENCH)"
add wave sim:tb_accumulator/*
add wave -divider "MODULE"
add wave sim:tb_accumulator/bruh/*
add wave -divider "FSM"
add wave sim:tb_accumulator/bruh/fsm/*
add wave -divider "MEMORY"
add wave sim:tb_accumulator/bruh/ram_a/mem 
add wave sim:tb_accumulator/bruh/ram_b/mem 

radix -dec

radix signal sim:tb_accumulator/addr_a  "u" 
radix signal sim:tb_accumulator/addr_b  "u" 
radix signal sim:tb_accumulator/addr_out  "u" 
radix signal sim:tb_accumulator/bruh/addr_a "u"  
radix signal sim:tb_accumulator/bruh/addr_b "u"  
radix signal sim:tb_accumulator/bruh/addr_out "u"  

restart
run -all