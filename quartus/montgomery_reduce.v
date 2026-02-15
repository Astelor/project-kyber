module montgomery_reduce ( // combinational, purely driven by input, let's see what happens :P
  input clk, // AST: if it's purely combinational, do I even need a clock here?
  //input reset, // YES because of the realistic timing constraints :NotLikeThis:
  input set,
  input  wire signed [31:0] a,
  output reg  signed [15:0] t
);

reg signed [31:0] temp32;
reg signed [15:0] temp16;

always @(posedge clk) begin // AST: there must be some other way to drive the submodules >:(
  if(set) begin
    temp32 = a;
    temp16 = (temp32 * -3327) &16'hFFFF;
    temp32 = temp16 * 13'sd3329;
    t = (a - temp32) >> 16;
  end
  //$display("[%0t] input:%0d, output: %0d", $time, a, t);
end

/*
always @(posedge reset) begin // AST: I don't think resetting it is necessary
  t = 16'hzzzz; // AST: do I reset it to z or x ?
end
// worst case we just drive a high impedance to clear everything if needed?
*/

endmodule