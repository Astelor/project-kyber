add wave *
add wave sim:tb_decode12/bruh/*

# WAVE WIDGET CONFIG
configure wave -namecolwidth 250
configure wave -valuecolwidth 90
wave zoom range 0ps 250ps

radix -hex

restart
run -all