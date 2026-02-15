module decompress1_cal(
  input clk,
  input set,
  //input reset,
  
  input wire b,
  output reg [15:0] r
);

reg [15:0] temp1;
always @(posedge clk)begin
  if(set)begin
    temp1 = (~b) + 1;
    r = temp1 & 1665;
  end
end

endmodule