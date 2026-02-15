module tb_ntt_cal;

reg clk = 0;
reg set = 0;

reg signed [15:0] f1, f2, zeta;
wire signed [15:0] r1, r2; 


ntt_cal cal(
  .clk(clk),
  .set(set),
  .f1(f1),
  .f2(f2),
  .zeta(zeta),
  .r1(r1),
  .r2(r2)
);

always begin
  #5 clk = ~clk;
end

initial begin
  #15 set <= 1;
      feed(0,4,-758);
  #10 feed(1,5,-758);
  #10 feed(2,6,-758);
  #10 feed(3,7,-758);
  #50
  $stop;
end

task feed(
  input [15:0] ff1, ff2, zetaa
);
  begin
    f1 <= ff1;
    f2 <= ff2;
    zeta <= zetaa;
  end
endtask

endmodule