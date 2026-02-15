mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-ntt-ram1.txt sim:/tb_kyber_pke_enc/bruh/ntt/ram1/mem
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-ntt-ram2.txt sim:/tb_kyber_pke_enc/bruh/ntt/ram2/mem

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-polyvec-RAM_A-k_0.txt {sim:/tb_kyber_pke_enc/bruh/polyvec/GENRAM[0]/ram_a/mem}
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-polyvec-RAM_B-k_0.txt {sim:/tb_kyber_pke_enc/bruh/polyvec/GENRAM[0]/ram_b/mem}

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-polyvec-RAM_A-k_1.txt {sim:/tb_kyber_pke_enc/bruh/polyvec/GENRAM[1]/ram_a/mem}
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-polyvec-RAM_B-k_1.txt {sim:/tb_kyber_pke_enc/bruh/polyvec/GENRAM[1]/ram_b/mem}

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-polyvec-RAM_A-k_2.txt {sim:/tb_kyber_pke_enc/bruh/polyvec/GENRAM[2]/ram_a/mem}
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-polyvec-RAM_B-k_2.txt {sim:/tb_kyber_pke_enc/bruh/polyvec/GENRAM[2]/ram_b/mem}

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-polyvec-RAM_C-1.txt {sim:/tb_kyber_pke_enc/bruh/polyvec/GENRAM[0]/RAMC/ram_c/mem}
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-polyvec-RAM_C-2.txt {sim:/tb_kyber_pke_enc/bruh/polyvec/GENRAM[1]/RAMC/ram_c/mem}

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-invntt-ram1.txt sim:/tb_kyber_pke_enc/bruh/invntt/ram1/mem
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-invntt-ram2.txt sim:/tb_kyber_pke_enc/bruh/invntt/ram2/mem

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-accu1-ram_a-k_0.txt {sim:/tb_kyber_pke_enc/bruh/GENACC[0]/accu1/ram_a/mem}
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-accu1-ram_b-k_0.txt {sim:/tb_kyber_pke_enc/bruh/GENACC[0]/accu1/ram_b/mem}

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-accu1-ram_a-k_1.txt {sim:/tb_kyber_pke_enc/bruh/GENACC[1]/accu1/ram_a/mem}
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-accu1-ram_b-k_1.txt {sim:/tb_kyber_pke_enc/bruh/GENACC[1]/accu1/ram_b/mem}

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-accu1-ram_a-k_2.txt {sim:/tb_kyber_pke_enc/bruh/GENACC[2]/accu1/ram_a/mem}
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-accu1-ram_b-k_2.txt {sim:/tb_kyber_pke_enc/bruh/GENACC[2]/accu1/ram_b/mem}

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-accu2-ram_a.txt sim:/tb_kyber_pke_enc/bruh/accu2/ram_a/mem
mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-accu2-ram_b.txt sim:/tb_kyber_pke_enc/bruh/accu2/ram_b/mem 

mem save -wordsperline 1 -outfile /!Github_coding/project-kyber/test/sim_output/tb_kyber_pke_enc-c_mem.txt sim:/tb_kyber_pke_enc/c_mem