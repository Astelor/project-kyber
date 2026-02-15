configure wave -namecolwidth 350
configure wave -valuecolwidth 100
wave zoom range 0ps 2500ps

add wave -divider "TESTBENCH"
add wave sim:tb_matrix_hash_stub/*
add wave -divider "MODULE INNARDS"
add wave sim:tb_matrix_hash_stub/bruh/*
add wave -divider "FSM CONTROLLLLLL"
add wave sim:tb_matrix_hash_stub/bruh/fsm/*

add wave -divider "MEMORY"
add wave sim:tb_matrix_hash_stub/bruh/ram_a/mem
add wave sim:tb_matrix_hash_stub/bruh/ram_b/mem

radix -unsigned

restart
run -all