module tb_ntt;
parameter DEPTH = 4;
reg clk = 0;
reg set = 0;
reg reset = 0;
wire done;
reg readout = 0;
wire [15:0] dout_1, dout_2;
wire out;

ntt ntt1(
  .clk(clk),
  .set(set),
  .reset(reset),
  .done(done),
  .readout(readout),
  .ntt_dout_1(dout_1),
  .ntt_dout_2(dout_2),
  .out(out)
);

always begin
  #5 clk = ~clk;
end

initial begin
  #10 reset <= 1;
  #5 reset <= 0;
  #5 set <= 1;
    //readout <= 1;
  #100
  //$stop
  ;
end

always @(posedge clk) begin
  if(done) begin
    $stop
    ;
  end
end
endmodule