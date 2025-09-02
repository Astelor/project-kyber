module tb_polyvec_basemul_acc_mont;
parameter DEPTH = 5;

reg clk = 0;
reg reset = 0;
reg set = 0;

reg readout = 0;

// output should all be wires
wire [15:0] dout_1;
wire [15:0] dout_2;
wire [DEPTH-1:0] out_index;
wire done;

polyvec_basemul_acc_mont #(DEPTH) bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  .readout(readout),
  .polyvec_dout_1(dout_1),
  .polyvec_dout_2(dout_2),
  .out_index(out_index),
  .done(done)
);

always begin
#5 clk = ~clk;
end

initial begin
  #15 reset <= 1;
  #5 reset <= 0;
  set <= 1;
  readout <= 1;
  //readout <= 1;
  #100
  $stop
  ;
end
reg nomore = 0;
always @(posedge clk) begin
  /*
  if(done & (~nomore)) begin
    $stop;
  end 
  */
end
endmodule