#while {1} {
    while {[examine -radix unsigned sim:/tb_kyber_pke_enc/done] != 1} {
        echo "$now"
        onbreak resume {
        }
        run 1500ps
        after 50
    }
    if {[examine -radix unsigned sim:/tb_kyber_pke_enc/done] == 1} {
        force sim:tb_kyber_pke_enc/bruh/readout 1
        after 50
        run 10000ps
        after 50
        do save_mem.do
        echo "$now done execute save_mem.do"
        #restart -force
    }
#}