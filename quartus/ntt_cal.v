module ntt_cal(
  input clk,
  input set,
  input wire signed [15:0] f1, // f[j+len]
  input wire signed [15:0] f2, // f[j]
  input wire signed [15:0] zeta,
  output wire signed [15:0] r1,
  output wire signed [15:0] r2
);

wire signed [15:0] f1_zeta;
reg signed [15:0] f2_1, f2_2; // data propagation :>

fqmul fq1(
  .clk(clk),
  .set(set),
  .a(f1),
  .b(zeta),
  .t(f1_zeta)
);

ct_butfly ct1(
  .clk(clk),
  .set(set),
  .f(f2_2),
  .t(f1_zeta),
  .r1(r1),
  .r2(r2)
);

always @(posedge clk) begin
  f2_1 <= f2;
  f2_2 <= f2_1;
end

endmodule

