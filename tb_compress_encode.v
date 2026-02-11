module tb_compress_encode;

reg clk = 0;
reg set = 0;
reg reset = 0;
reg [15:0] din1;
reg [15:0] din2;
reg readin;

wire [15:0] dout1;
wire [15:0] dout2;
wire readout_ok;
always begin
  #5 clk = ~clk;
end

compress_encode #(10) bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  .readin(readin),
  .din1(din1),
  .din2(din2),
  .dout1(dout1),
  .dout2(dout2),
  .readout_ok(readout_ok)
);

initial begin
  #15 reset <= 1;
  #5 reset <= 0;
  #5 set <= 1;
  $stop;
end

localparam CONST = 3;
reg [7:0] counter = 0;

always @(posedge clk) begin
  if(set) begin
    if($random & 1) begin
      counter <= counter + 2;
      din1 <= //$random & 3329;
            counter*CONST;
      din2 <= //$random & 3329;
            (counter+1)*CONST;
      readin <= 1;
    end
    else begin
      din1 <= 'hz;
      din2 <= 'hz;
      readin <= 0;
    end
  end
end
endmodule