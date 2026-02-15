module basemul(
  input clk,
  input set,
  //input wire signed [15:0] r1, // address to where the output should be
  //input wire signed [15:0] r0, // either handled externally or pass it here?
  input wire signed [15:0] a1,
  input wire signed [15:0] a0,
  input wire signed [15:0] b1,
  input wire signed [15:0] b0,
  input wire signed [15:0] zeta,
  output reg signed [15:0] t1,
  output reg signed [15:0] t0
);

wire signed [15:0] f1, f2, g1, g2;
reg signed [15:0] ff1, gg1, gg2, ggg2;
reg signed [15:0] aa0, bb0, bb1, bbb1; // surely I can just keep one b1
wire signed [15:0] temp;

fqmul fq1(
  .clk(clk),
  .set(set),
  .a(a1),
  .b(zeta),
  .t(temp)
);

fqmul fq2(
  .clk(clk),
  .set(set),
  .a(a1),
  .b(b0),
  .t(g2)
);

fqmul fq3(
  .clk(clk),
  .set(set),
  .a(aa0),
  .b(bb0),
  .t(f1)
);

fqmul fq4(
  .clk(clk),
  .set(set),
  .a(aa0),
  .b(bb1),
  .t(g1)
);

fqmul fq5(
  .clk(clk),
  .set(set),
  .a(temp),
  .b(bbb1),
  .t(f2)
);

//5
always @(posedge clk) begin
  if(set) begin
    t0 <= ff1 + f2;
    t1 <= ggg2 + gg1;
  end
end

/*data propagation :>*****************************/
always @(posedge clk) begin
  aa0 <= a0;
  bb0 <= b0;
  bb1 <= b1;
  bbb1 <= bb1;
end

always @(posedge clk) begin
  ff1 <= f1;
  gg1 <= g1;
  gg2 <= g2;
  ggg2 <= gg2;
end

endmodule

/*
*************************************************
* Name:        basemul
*
* Description: Multiplication of polynomials in Zq[X]/(X^2-zeta)
*              used for multiplication of elements in Rq in NTT domain
*
* Arguments:   - int16_t r[2]: pointer to the output polynomial
*              - const int16_t a[2]: pointer to the first factor
*              - const int16_t b[2]: pointer to the second factor
*              - int16_t zeta: integer defining the reduction polynomial
**************************************************
void basemul(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta)
{
  r[0]  = fqmul(a[1], b[1]); 
  r[0]  = fqmul(r[0], zeta);
  r[0] += fqmul(a[0], b[0]); a0*b0 + a1*b1*zeta
  r[1]  = fqmul(a[0], b[1]);
  r[1] += fqmul(a[1], b[0]); a0*b1 + a1*b0
}
*/