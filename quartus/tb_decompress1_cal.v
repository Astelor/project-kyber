module tb_decompress1_cal;

reg clk = 0;
reg set = 0;

reg b;
wire [15:0] r;

decompress1_cal bruh(
  .clk(clk),
  .set(set),
  .b(b),
  .r(r)
);

always begin
#5 clk = ~clk;
end

initial begin
  #15 set <= 1;
  #100
  $stop
  ;
end

always @(posedge clk) begin
  b <= $random & 'b1;
end


endmodule