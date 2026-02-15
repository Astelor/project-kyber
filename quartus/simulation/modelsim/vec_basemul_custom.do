add wave sim:tb_polyvec_basemul_acc_mont/bruh/*

#add wave sim:tb_polyvec_basemul_acc_mont/bruh/polybm/*
#add wave sim:tb_polyvec_basemul_acc_mont/bruh/polybm/rama/mem
#add wave sim:tb_polyvec_basemul_acc_mont/bruh/polybm/ramb/mem
#add wave sim:tb_polyvec_basemul_acc_mont/bruh/polybm/ramc/mem

add wave {sim:tb_polyvec_basemul_acc_mont/bruh/GENRAM[0]/ram_a/mem}
add wave {sim:tb_polyvec_basemul_acc_mont/bruh/GENRAM[0]/ram_b/mem}

add wave {sim:tb_polyvec_basemul_acc_mont/bruh/GENRAM[1]/ram_a/mem}
add wave {sim:tb_polyvec_basemul_acc_mont/bruh/GENRAM[1]/ram_b/mem}

add wave {sim:tb_polyvec_basemul_acc_mont/bruh/GENRAM[2]/ram_a/mem}
add wave {sim:tb_polyvec_basemul_acc_mont/bruh/GENRAM[2]/ram_b/mem}

#add wave sim:tb_polyvec_basemul_acc_mont/bruh/fsm/*
add wave {sim:tb_polyvec_basemul_acc_mont/bruh/GENRAM[0]/RAMC/ram_c/mem}
add wave {sim:tb_polyvec_basemul_acc_mont/bruh/GENRAM[1]/RAMC/ram_c/mem}


restart
run -all