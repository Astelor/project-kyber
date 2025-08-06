module tb_ntt;

reg clk = 0;
reg set = 0;
reg reset = 0;
wire done;

ntt ntt1(
  .clk(clk),
  .set(set),
  .reset(reset),
  .done(done)
);

always begin
  #5 clk = ~clk;
end

initial begin
  #10 reset <= 1;
  #5 reset <= 0;
  #5 set <= 1;

  #100
  $stop
  ;
end
/*
always begin
  if(done) begin
    $stop
    ;
  end
end
*/
endmodule