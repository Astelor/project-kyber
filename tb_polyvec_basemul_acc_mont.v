module tb_polyvec_basemul_acc_mont;
parameter DEPTH = 8;

reg clk = 0;
reg reset = 0;
reg set = 0;

reg readin_a = 0;
reg readin_b = 0;
reg readout = 0;
reg cal_en = 0;
reg full_in_a = 0;
reg full_in_b = 0;

reg [15:0] din_a_1;
reg [15:0] din_a_2;
reg [DEPTH-1:0] ina_index;
reg [3:0] ina_k;

reg [15:0] din_b_1;
reg [15:0] din_b_2;
reg [DEPTH-1:0] inb_index;  
reg [3:0] inb_k;

// output should all be wires

wire [15:0] dout_1;
wire [15:0] dout_2;
wire [DEPTH-1:0] out_index;
wire done;

wire readin_a_ok;
wire readin_b_ok;

polyvec_basemul_acc_mont #(DEPTH) bruh(
  .clk(clk),
  .set(set),
  .reset(reset),

  .readin_a(readin_a),
  .readin_b(readin_b),
  .readout(readout),
  .cal_en(cal_en),

  .full_in_a(full_in_a),
  .full_in_b(full_in_b),

  .polyvec_din_a_1(din_a_1),
  .polyvec_din_a_2(din_a_2),
  .ina_index(ina_index),
  .ina_k(ina_k),

  .polyvec_din_b_1(din_b_1),
  .polyvec_din_b_2(din_b_2),
  .inb_index(inb_index),
  .inb_k(inb_k),

  .polyvec_dout_1(dout_1),
  .polyvec_dout_2(dout_2),
  .out_index(out_index),

  .readin_a_ok(readin_a_ok),
  .readin_b_ok(readin_b_ok),
  .done(done)
);

always begin
#5 clk = ~clk;
end

reg [15:0] mem [ (1<<DEPTH)-1 :0];

initial begin
  // randomized input data
  //$readmemh("D:/!Github_coding/project-kyber/test/test-invntt-in.hex", mem);
  // not randomized input data
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  #15 reset <= 1;
  #5 reset <= 0;
  set <= 1;
  readin_a <= 1;
  ina_k <= 0;
  inb_k <= 0;
  cal_en <= 1;
  readout <= 1;
  #100 readin_b <= 1;
  //readout <= 1;
  #100
  $stop
  ;
end
reg [DEPTH:0] indexa = 0;
reg [DEPTH:0] indexb = 0;

parameter TEST_OFFSET_A = 5;
parameter TEST_OFFSET_B = 11;
reg [3:0] offset = 0;

always @(posedge clk) begin
  if(readin_a_ok && readin_a) begin
    indexa <= indexa + 2;
    ina_index <= indexa;
    din_a_1 <= mem[indexa]   /*+ offset + TEST_OFFSET_A + ina_k*/;
    din_a_2 <= mem[indexa+1] /*+ offset + TEST_OFFSET_A + ina_k*/;
  end
  if(readin_b_ok && readin_b) begin
    indexb <= indexb + 2;
    inb_index <= indexb;
    din_b_1 <= mem[indexb]   /*+ offset + TEST_OFFSET_B + inb_k*/;
    din_b_2 <= mem[indexb+1] /*+ offset + TEST_OFFSET_B + inb_k*/;
  end
  if(indexa == (1<<DEPTH)) begin
    indexa <= 0;
    //readin_a <= 0;
    //full_in_a <= 1;
    if(ina_k >= 3) begin
      full_in_a <= 1;
      ina_k <= 0;
    end
    else begin
      ina_k <= ina_k + 1;
    end
  end
  else begin
    full_in_a <= 0;
  end
  if(indexb == (1<<DEPTH)) begin
    indexb <= 0;
    //readin_b <= 0;
    if(inb_k >= 3) begin
      full_in_b <= 1;
      inb_k <= 0;
      offset <= offset + 1;
    end
    else begin
      inb_k <= inb_k + 1;
    end
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