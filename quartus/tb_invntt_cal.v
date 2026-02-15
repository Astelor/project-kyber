module tb_invntt_cal;

reg clk = 0;
reg set = 0;
reg signed [15:0] f1, f2, zeta;
wire signed [15:0] r1, r2;

invntt_cal cal(
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
  #10 set <= 1;
  #5  feed(1,2,-758);
  #10 feed(3,4,-758);
  #10 feed(5,7,-758);
  #100
  $stop
  ;
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