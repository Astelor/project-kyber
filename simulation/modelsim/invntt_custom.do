configure wave -namecolwidth 350
configure wave -valuecolwidth 150
wave zoom range 0ps 200ps

add wave sim:tb_invntt/bruh/*
add wave sim:tb_invntt/bruh/fsm/*
add wave sim:tb_invntt/bruh/ram1/mem
add wave sim:tb_invntt/bruh/ram2/mem

radix -unsigned

restart
run -all