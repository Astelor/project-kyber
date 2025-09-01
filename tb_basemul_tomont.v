module tb_basemul_tomont;
parameter DEPTH = 8;
reg clk = 0;
reg reset = 0;
reg set = 0;

reg readin_a = 0;
reg readin_b = 0;
reg readout  = 0;
reg cal_en = 0;
reg full_in_a = 0;
reg full_in_b = 0;

reg [15:0] dina_1, dina_2;
reg [15:0] dinb_1, dinb_2;
wire [15:0] dout_1, dout_2;

reg [DEPTH-1:0] ina_index;
reg [DEPTH-1:0] inb_index;
wire [DEPTH-1:0] out_index;

wire readin_a_ok;
wire readin_b_ok;
wire done;

basemul_tomont #(DEPTH) bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  .readin_a(readin_a),
  .readin_b(readin_b),
  .readout(readout),
  .cal_en(cal_en),
  
  .full_in_a(full_in_a),
  .full_in_b(full_in_b),

  .basemul_dina_1(dina_1),
  .basemul_dina_2(dina_2),
  .ina_index(ina_index),

  .basemul_dinb_1(dinb_1),
  .basemul_dinb_2(dinb_2),
  .inb_index(inb_index),

  .basemul_dout_1(dout_1),
  .basemul_dout_2(dout_2),
  .out_index(out_index),
  
  .readin_a_ok(readin_a_ok),
  .readin_b_ok(readin_b_ok),
  .done(done)
);

reg [15:0] mem [ (1<<DEPTH)-1 :0];

always begin
#5 clk = ~clk;
end

initial begin
  // randomized input data
  //$readmemh("D:/!Github_coding/project-kyber/test/test-invntt-in.hex", mem);
  // not randomized input data
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  #15 reset <= 1;
  #5 reset <= 0;
  set <= 1;
  readin_a <= 1;
  #100 readin_b <= 1;
  //readout <= 1;
  #100
  $stop
  ;
end
reg [DEPTH:0] indexa = 0;
reg [DEPTH:0] indexb = 0;

parameter TEST_OFFSET_A = 0;
parameter TEST_OFFSET_B = 0;

always @(posedge clk) begin
  if(readin_a_ok && readin_a) begin
    indexa <= indexa + 2;
    ina_index <= indexa;
    dina_1 <= mem[indexa] + TEST_OFFSET_A;
    dina_2 <= mem[indexa+1] + TEST_OFFSET_A;
  end
  if(readin_b_ok && readin_b) begin
    indexb <= indexb + 2;
    inb_index <= indexb;
    dinb_1 <= mem[indexb] + TEST_OFFSET_B;
    dinb_2 <= mem[indexb+1] + TEST_OFFSET_B;
  end
  if(indexa == (1<<DEPTH)) begin
    //indexa <= 0;
    //readin_a <= 0;
    full_in_a <= 1;
  end
  else begin
    full_in_a <= 0;
  end
  if(indexb == (1<<DEPTH)) begin
    //indexb <= 0;
    //readin_b <= 0;
    full_in_b <= 1;
  end
  else begin
    full_in_b <= 0;
  end
  /*
  if(done) begin
    $stop;
  end
  */
end
endmodule