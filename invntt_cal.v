module invntt_cal(
  input clk,
  input set,
  input wire signed [15:0] f1, // f[j+len]
  input wire signed [15:0] f2, // f[j]
  input wire signed [15:0] zeta1,
  input wire signed [15:0] zeta2, // = -1044 for normal, 1441 for last stage
  output wire signed [15:0] r1,
  output wire signed [15:0] r2
);

wire [15:0] A = f1 + f2;
wire [15:0] B = f1 - f2;
/*
wire [15:0] temp_r2;
barrett_reduce barr1(
  .clk(clk),
  .set(set),
  .a(A),
  .t(temp_r2) // to f2
);
*/
fqmul fq1(
  .clk(clk),
  .set(set),
  .a(zeta1),
  .b(B),
  .t(r1)
);

fqmul fq2(
  .clk(clk),
  .set(set),
  .a(zeta2),
  .b(A),
  .t(r2)
);
/*
always @(posedge clk) begin
  r2 <= temp_r2;
end
*/
endmodule 