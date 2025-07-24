module fqmul ( 
  input clk,
  //input reset,
  //input set,
  input  wire signed [15:0] a,
  input  wire signed [15:0] b,
  output wire signed [15:0] t
); // returns a*b*R^(-1) mod q

/*
*       +---------------------------+
* (a,b)-|-> [multiplier] -> [mont] -|-> (a*b*R^(-1) mod q)
*       +---------------------------+
* something like that
*/

wire signed [31:0] temp32;
//reg signed [15:0] temp16; // not used

multiplier mult1 (
  //.set(set), // imma leave it here and fix it when there's a problem.
  .clk(clk),
  .a(a),
  .b(b),
  .t(temp32)
);

montgomery_reduce mont1 ( // AST: i wonder if the instances are per module or unique
  .a(temp32), // I think this one needs a clock too
  .t(t) 
);      

endmodule

module multiplier (
  input clk,
  //input set,
  input  wire signed [15:0] a,
  input  wire signed [15:0] b,
  output reg signed [31:0] t
);

always @(posedge clk) begin
  t <= a * b; // blocking or non-blocking?
end

endmodule