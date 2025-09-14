module barrett_reduce(
  input clk,
  input set,
  input wire signed [15:0] a,
  output reg signed [15:0] t
);

reg signed [15:0] temp16;
reg signed [31:0] temp32;

always @(posedge clk) begin
  if(set) begin // longest line in the pipeline ok
    temp32 = (a * 16'sd20159) + (1<<25);
    temp16 = temp32 >>> 26; // arithmetic shift
    t = temp16 * 13'sd3329;
    t = a - t;
  end
end

endmodule