module tb_decode12;

reg clk   = 0;
reg set   = 0;
reg reset = 0;

reg readin;
reg [7:0] din;
reg [15:0] in_index;

wire [15:0] dout_1;
wire [15:0] dout_2;
wire [15:0] out_index;

decode12 bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  .readin(readin),
  .din(din),
  .in_index(in_index),
  .dout_1(dout_1),
  .dout_2(dout_2),
  .out_index(out_index)
);

always begin
  #5 clk = ~clk;
end

reg [7:0] ekt [(1152-1):0];

initial begin
  $readmemh("D:/!Github_coding/project-kyber/quartus/ekt_test.hex", ekt);
  #15 reset <= 1;
  #5 reset <= 0;
  set <= 1;
  readin <= 1;
  $stop
  ;
end
reg [15:0] index;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    readin   <= 0;
    index    <= 0;
    in_index <= 0;
    din      <= 0;
  end
  else if(set & readin) begin
    din <= ekt[index]; // $random & 8'hff;
            // din + 1;
    index <= index + 1;
    in_index <= index;
  end
end

endmodule