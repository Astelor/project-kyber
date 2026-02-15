add wave sim:tb_hash_stub/bruh/*
add wave sim:tb_hash_stub/bruh/fsm/*

add wave sim:tb_hash_stub/bruh/ram_a/mem
add wave {sim:tb_hash_stub/bruh/GENRAM[0]/ram_b/mem}
add wave {sim:tb_hash_stub/bruh/GENRAM[1]/ram_b/mem}
add wave {sim:tb_hash_stub/bruh/GENRAM[2]/ram_b/mem}
add wave {sim:tb_hash_stub/bruh/GENRAM[3]/ram_b/mem}

restart
run -all