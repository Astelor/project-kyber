module tb_rom;

reg clk = 0;
reg reset;
reg set; 

reg [15:0] data_in = 0;
wire [15:0] data_out;

zeta_rom rom1(
  .clk(clk),
  //.reset(reset),
  .set(set),
  .addr(data_in),
  .val(data_out)
);

always begin
  #5 clk = ~clk;
end

always @(posedge clk) begin
  data_in <= data_in + 1;
  //surely it works
  if(data_in >9) begin
    $stop;
  end
end

endmodule