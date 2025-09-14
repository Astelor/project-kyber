module tb_hash_stub;

// INPUT
reg clk = 0;
reg set = 0;
reg reset = 0;

reg readin = 0;
reg readout = 0;

reg full_in = 0;
reg [7:0] nonce = 123;
reg [7:0] hash_din;
reg [7:0] in_index;
// OUTPUT
wire [31:0] hash_dout_1;
wire [31:0] hash_dout_2;
wire [4:0] out_index;

wire readin_ok;
wire done;

hash_stub bruh(
  .clk(clk),
  .set(set),
  .reset(reset),

  .readin(readin),
  .readout(readout),
  .full_in(full_in),
  .nonce(nonce),
  
  .hash_din(hash_din),
  .in_index(in_index),

  .hash_dout_1(hash_dout_1),
  .hash_dout_2(hash_dout_2),
  .out_index(out_index),  
  
  .readin_ok(readin_ok),
  .done(done)
);

always begin
#5 clk = ~clk;  
end

reg [7:0] mem [35:0];

initial begin
  // randomized input data
  //$readmemh("D:/!Github_coding/project-kyber/test/test-invntt-in.hex", mem);
  // not randomized input data
  
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  
  #15 reset <= 1;
  #5 reset <= 0;
  set <= 1;
  readin <= 1;
  readout <= 1;
  //#100 full_in <= 1;
  //#10  full_in <= 0;

  $stop
  ;
end

reg [5:0] index = 0;
parameter TEST_OFFSET = 0;

always @(posedge clk) begin
  if(readin_ok && readin) begin
    index <= index + 1;
    in_index <= index;
    hash_din <= //mem[index] + 2; 
                $random & 'hff;
  end
  if(index == (1<<5)) begin
    index <= 0;
    //readin_a <= 0;
    full_in <= 1;
  end
  else begin
    full_in <= 0;
  end
  /*
  if(done) begin
  end
  */
end

endmodule