module tb_poly_ram;

reg clk;
//reg reset;
reg r1_en, w1_en;
reg r2_en, w2_en;
reg [15:0] r1_addr, r2_addr;
reg [15:0] w1_addr, w2_addr;
reg [15:0] w1_d, w2_d;
wire [15:0] r1_d, r2_d;

poly_ram #(64) ram1( // dual port
  .clk(clk),
  //.reset(reset),
  .r1_en(r1_en),
  .r2_en(r2_en),
  .w1_en(w1_en),
  .w2_en(w2_en),
  .r1_addr(r1_addr),
  .r2_addr(r2_addr),
  .w1_addr(w1_addr),
  .w2_addr(w2_addr),
  .d1_in(w1_d),
  .d2_in(w2_d),
  .d1_out(r1_d),
  .d2_out(r2_d)
);

always begin
  #5 clk = ~clk;
end

integer i;
initial begin
  clk <= 0; r1_en <=0; w1_en <= 0;
  // interactive terminal d testing would be good here
  // delay, enable, r_addr, w_addr, w_d
  #5 w1_en <= 1;
  for (i = 0; i < 10; i = i + 1) begin
    #10 
    w1_addr <= i;
    w1_d <= i;
  end
  $stop;
end

endmodule