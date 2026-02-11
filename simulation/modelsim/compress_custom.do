configure wave -namecolwidth 350
configure wave -valuecolwidth 150
wave zoom range 0ps 320ps

add wave -divider "TESTBENCH"
add wave sim:tb_compress_encode/*
add wave -divider "MODULE"
add wave sim:tb_compress_encode/bruh/*
add wave -divider "COMPRESS MODULE 1"
add wave {sim:tb_compress_encode/bruh/GEN_COMP/comp1/*}
add wave -divider "COMPRESS MODULE 2"
add wave {sim:tb_compress_encode/bruh/GEN_COMP/comp2/*}
add wave -divider "ENCODE MODULE"
add wave {sim:tb_compress_encode/bruh/GEN_COMP/encode/*}
radix -hex

restart
run -all