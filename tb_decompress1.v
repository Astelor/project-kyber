module tb_decompress1;

// SYSTEM

reg clk = 0;
reg set = 0;
reg reset = 0;

// INPUT
reg readin;
reg readout = 0;
reg full_in;
reg [7:0]  decomp_din;
reg [7:0]  in_index;

// OUTPUT
wire [15:0] decomp_dout_1;
wire [15:0] decomp_dout_2;
wire [7:0]  out_index;
wire readin_ok;
wire readout_ok;
wire done;

always begin
  #5 clk = ~clk;
end

decompress1 bruh(
  .clk(clk),
  .set(set),
  .reset(reset),

  .readin        (readin),
  .readout       (readout),
  .full_in       (full_in),
  .decomp_din    (decomp_din),
  .in_index      (in_index),

  .decomp_dout_1 (decomp_dout_1),
  .decomp_dout_2 (decomp_dout_2),
  .out_index     (out_index),
  .readin_ok     (readin_ok),
  .readout_ok    (readout_ok)
);

reg [7:0] msg [31:0]; // secret message key
reg flag = 0;

initial begin
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", msg);
  #15 reset <= 1;
  #5 reset <= 0;
  #5 set <= 1;
  readin <= 0;
  #10 readin <= 1;

  $stop
  ;
end

reg [15:0] index = 0;
parameter OFFSET = 0;

always @(posedge clk) begin
  if(readin & readin_ok) begin
    index <= index + 1;
    in_index <= index;
    decomp_din <= msg[index] + 5;
                  //($random & (8'hff << 2)) >> 2;
                  // 8'h66;
    // if(index & 1) begin
    //   decomp_din <= 8'h53;
    // end
    // else begin
    //   decomp_din <= 8'h9C;
    // end
  end
  // this difference in combinational and sequenctial logic 
  // will be the end of me :')
  if(index == (1 << 5) - 1) begin
    full_in <= 1;
    index <= 0;
  end
  else begin
    full_in <= 0;
  end
  if(readout_ok) begin
    readout <= ($random & (1 << OFFSET)) >> OFFSET;
    // readout <= 1;
  end

end


endmodule