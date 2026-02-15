module ct_butfly(
  input clk,
  input set,
  input wire signed [15:0] f, // my own naming is going to come back and bite me for sure
  input wire signed [15:0] t, // t = zeta*f[j+len]
  output reg signed [15:0] r1, // = f[j+len]
  output reg signed [15:0] r2 // = f[j]
);

always @(posedge clk) begin
  if(set) begin
    r1 <= f - t;
    r2 <= f + t;
  end
end

endmodule