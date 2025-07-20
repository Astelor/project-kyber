module montgomery_reduce(
  input clk,
  input reset,
  input set,
  input wire signed [31:0] a,
  output reg signed [15:0] t
);

reg signed [31:0] temp32;
reg signed [15:0] temp16;

always @(posedge clk) begin
  if(set) begin
    #1 // AST: the timing should be placed else where
    temp32 = a;
    temp16 = (temp32 * -3327) &16'hFFFF;
    temp32 = temp16 * 13'sd3329;
    t = (a - temp32) >> 16;
    //$display("[%0t] input:%0d, output: %0d", $time, a, t);
    // I guess I can write it here? if I just need to test the corectness
    //temp[15:0] = a - ( * 3329);
    
    //temp = (a - temp); //surely it works :)
    //t = (a - temp)>>16;
  end
  
  /*
  t <= temp;
  temp <= temp+1;
  */
end

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