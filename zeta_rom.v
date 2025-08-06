module zeta_rom (
  input clk,
  input wire [6:0] addr,
  output reg signed [15:0] data_out
);

reg signed [15:0] zetas [127:0];

initial begin
  $readmemh("D:/!Github_coding/project-kyber/zeta.hex", zetas);
end

always @(posedge clk) begin
  data_out <= zetas[addr];
end

endmodule