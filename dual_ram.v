// true dual port RAM
module dual_ram #(parameter DEPTH = 8)(
  input clk,
  input wire we_1, // write enable
  input wire we_2,
  input wire [DEPTH-1:0] addr_1,
  input wire [DEPTH-1:0] addr_2,
  input wire [15:0] din_1, 
  input wire [15:0] din_2,
  output reg [15:0] dout_1,
  output reg [15:0] dout_2
);
//parameter DEPTH = 8; // 2^8 = 256 depth = 8
reg [15:0] mem [ (1<<DEPTH)-1 :0];

initial begin
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  //$readmemh("D:/!Github_coding/project-kyber/zeta.hex", zetas);
end

// PORT 1
always @(posedge clk) begin
  if(we_1) begin
    mem[addr_1] <= din_1;
    dout_1 <= din_1; // dual port RAM synthesize requirement
  end else begin
    dout_1 <= mem[addr_1];
  end
end

// PORT 2
always @(posedge clk) begin
  if(we_2) begin
    mem[addr_2] <= din_2;
    dout_2 <= din_2;
  end else begin
    dout_2 <= mem[addr_2];
  end
end

endmodule