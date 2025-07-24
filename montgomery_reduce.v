module montgomery_reduce ( // combinational, purely driven by input, let's see what happens :P
  //input clk, // AST: if it's purely combinational, do I even need a clock here?
  //input reset,
  //input set,
  input  wire signed [31:0] a,
  output reg  signed [15:0] t
);

reg signed [31:0] temp32;
reg signed [15:0] temp16;

always @(*) begin // AST: there must be some other way to drive the submodules >:(
    temp32 = a;
    temp16 = (temp32 * -3327) &16'hFFFF;
    temp32 = temp16 * 13'sd3329;
    t = (a - temp32) >> 16;
    //$display("[%0t] input:%0d, output: %0d", $time, a, t);
end

/*
always @(posedge reset) begin // AST: I don't think resetting it is necessary
  t = 16'hzzzz; // AST: do I reset it to z or x ?
end
// worst case we just drive a high impedance to clear everything if needed?
*/

endmodule

/*
*************************************************
* Name:        montgomery_reduce
*
* Description: Montgomery reduction; given a 32-bit integer a, computes
*              16-bit integer congruent to a * R^-1 mod q, where R=2^16
*
* Arguments:   - int32_t a: input integer to be reduced;
*                           has to be in {-q2^15,...,q2^15-1}
*
* Returns:     integer in {(-q+1)/2,...,(q-1)/2} congruent to a * R^-1 modulo q.
**************************************************
int16_t montgomery_reduce(int32_t a)
{
  int16_t t;

  t = (int16_t)a*QINV;
  t = (a - (int32_t)t*KYBER_Q) >> 16;
  return t;
}
*/