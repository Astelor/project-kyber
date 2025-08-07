module tb_basemul;

reg clk;
reg set;

reg signed [15:0] a1, a0, b1, b0, zeta;
wire signed [15:0] t1, t0;

basemul bm1(
  .clk(clk),
  .set(set),
  .a1(a1),
  .a0(a0),
  .b1(b1),
  .b0(b0),
  .zeta(zeta),
  .t1(t1),
  .t0(t0)
);

always begin
  #5 clk = ~clk;
end

initial begin
  clk <= 0;
  set <= 0;
  #5
  set <= 1;
      feed(1,2,3,4,789);
  #10 feed(5,6,7,8,321);
  #10 feed(1,2,3,4,789);
  #10 feed(5,6,7,8,321);
  #10 feed(1,2,3,4,789);
  #10 feed(5,6,7,8,321);
  
  #50
  
  $stop;
end

task feed (
  input [15:0] aa1,aa0,bb1,bb0,zetaa
);
  begin
    a1 <= aa1;
    a0 <= aa0;
    b1 <= bb1;
    b0 <= bb0;
    zeta <= zetaa;
  end
endtask

endmodule