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
/*
*************************************************
* Name:        barrett_reduce
*
* Description: Barrett reduction; given a 16-bit integer a, computes
*              centered representative congruent to a mod q in {-(q-1)/2,...,(q-1)/2}
*
* Arguments:   - int16_t a: input integer to be reduced
*
* Returns:     integer in {-(q-1)/2,...,(q-1)/2} congruent to a modulo q.
**************************************************s
int16_t barrett_reduce(int16_t a) {
  int16_t t;
  const int16_t v = ((1<<26) + KYBER_Q/2)/KYBER_Q;

  t  = ((int32_t)v*a + (1<<25)) >> 26;
  t *= KYBER_Q;
  return a - t;
}
// v = 20159
*/