module tb_invntt;
parameter DEPTH = 8;
reg clk = 0;
reg set = 0;
reg reset = 0;

reg readin = 0, readout = 0, cal_en = 0;
reg full_in = 0;
wire done;

reg [15:0] din_1, din_2;
reg [DEPTH-1:0] in_index = 0;
wire [15:0] dout_1, dout_2;
wire [DEPTH-1:0] out_index;

wire readin_ok;

invntt #(DEPTH) bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  .readin(readin),
  .readout(readout),
  .cal_en(cal_en),
  .full_in(full_in),

  .invntt_din_1(din_1),
  .invntt_din_2(din_2),
  .in_index(in_index),

  .invntt_dout_1(dout_1),
  .invntt_dout_2(dout_2),
  .out_index(out_index),

  .readin_ok(readin_ok),
  .done(done)
);

reg [15:0] mem [ (1<<DEPTH)-1 :0];

always begin
  #5 clk = ~clk;
end

initial begin
  // randomized input data
  $readmemh("D:/!Github_coding/project-kyber/test/test-invntt-in.hex", mem);
  // not randomized input data
  //$readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  #10 reset <= 1;
  #5  reset <= 0;
      set <= 1;
      readin <= 1;
  #10 cal_en <= 1;
      readout <= 1;
  /*
  #10 cal_en <= 0;
  */
  #100
  $stop
  ;
end

reg [DEPTH-1:0] index = 0;

always @(posedge clk) begin
  if(readin_ok && readin) begin
    index <= index + 2;
    in_index <= index;
    din_1 <= mem[index+1];
    din_2 <= mem[index];
  end
  else begin
    index <= 0;
  end
  if(index == (1<<DEPTH) - 2) begin
    //readin <= 0;
    full_in <= 1;
  end
  else begin
    full_in <= 0;
  end
  if(done) begin
    $stop;
  end
end

endmodule