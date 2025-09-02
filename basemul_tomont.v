/*
TODO: might pass a "ID" for calculation type (A*y or t*y etc), 
      making controller easier to manage where the output should go
*/
module basemul_tomont #(parameter DEPTH = 8)(
  // SYSTEM
  input clk,
  input set,
  input reset,
  // FSM
  input readin_a,
  input readin_b,
  input readout,
  input cal_en,
  input full_in_a, // I guess? manage index ref externally
  input full_in_b,
  // INPUT TO RAMa
  input wire signed [15:0] basemul_dina_1, // RAMa
  input wire signed [15:0] basemul_dina_2, // RAMa
  input wire [DEPTH-1:0] ina_index,
  // INPUT TO RAMb
  input wire signed [15:0] basemul_dinb_1, // RAMb
  input wire signed [15:0] basemul_dinb_2, // RAMb
  input wire [DEPTH-1:0] inb_index,

  // OUTPUT TO OUTSIDE
  output wire signed [15:0] basemul_dout_1,
  output wire signed [15:0] basemul_dout_2,
  output wire [DEPTH-1:0] out_index,

  // FLAGs
  output wire readin_a_ok,
  output wire readin_b_ok,
  output wire done
);

reg [DEPTH-1:0] counter; 
`define ZETA_THING (counter & 'b1)

wire rama_we;
wire ramb_we;
wire ramc_we;
reg [DEPTH-1:0] index_a;
reg [DEPTH-1:0] index_b;
reg [DEPTH-1:0] index_c;

// FSM ================================================================
wire iscal;
wire index_a_ctrl;
wire index_b_ctrl;
wire index_c_ctrl;
wire counter_ctrl;
wire rama_we_ok;
wire ramb_we_ok;
wire ramc_we_ok;

reg readin_a_ok_r;
reg readin_b_ok_r;

// wire -> assign addr1 = index, addr2 = index + offset
// RAM A ==============================================================
wire [DEPTH-1:0] rama_addr_1 = (iscal) ? index_a     : ina_index    , 
                 rama_addr_2 = (iscal) ? index_a + 1 : ina_index + 1; 
wire [15:0]      rama_din_1 = basemul_dina_1,
                 rama_din_2 = basemul_dina_2;
wire [15:0]      rama_dout_1, rama_dout_2;

// RAM B ==============================================================
wire [DEPTH-1:0] ramb_addr_1 = (iscal) ? index_b     : inb_index    , 
                 ramb_addr_2 = (iscal) ? index_b + 1 : inb_index + 1;
wire [15:0]      ramb_din_1 = basemul_dinb_1,
                 ramb_din_2 = basemul_dinb_2;
wire [15:0]      ramb_dout_1, ramb_dout_2;

wire signed [15:0] t0;
wire signed [15:0] t1;
wire signed [15:0] a0 = rama_dout_1;
wire signed [15:0] a1 = rama_dout_2;
wire signed [15:0] b0 = ramb_dout_1;
wire signed [15:0] b1 = ramb_dout_2;

wire signed [15:0] zeta;
wire signed [15:0] zeta_bm = `ZETA_THING ? zeta : -zeta;

wire set_bm = iscal;

reg  [6:0] k;
wire [6:0] zeta_k = 64 + k; // zeta index

// RAM C ==============================================================
wire [DEPTH-1:0] ramc_addr_1 = index_c    , 
                 ramc_addr_2 = index_c + 1;
wire [15:0]      ramc_din_1  = t0,
                 ramc_din_2  = t1;
wire [15:0]      ramc_dout_1, ramc_dout_2;

// TODO: forcing this "no leaking" by using readout flag maybe an overkill
assign basemul_dout_1 = (done & readout) ? ramc_dout_1 : 0;
assign basemul_dout_2 = (done & readout) ? ramc_dout_2 : 0;
assign out_index      = (done) ? index_c - 2 : 0;

/*
// TODO: RAM input will reflect on output, this can be further pipelined
assign basemul_dout_1 = ramc_dout_1;
assign basemul_dout_2 = ramc_dout_2;
assign out_index      = index_c - 2;
*/

dual_ram #(DEPTH, 16) rama(
  .clk(clk),
  .we_1  (rama_we),
  .we_2  (rama_we),
  .addr_1(rama_addr_1),
  .addr_2(rama_addr_2),
  .din_1 (rama_din_1),
  .din_2 (rama_din_2),
  .dout_1(rama_dout_1),
  .dout_2(rama_dout_2)
);

dual_ram #(DEPTH, 16) ramb(
  .clk(clk),
  .we_1  (ramb_we),
  .we_2  (ramb_we),
  .addr_1(ramb_addr_1),
  .addr_2(ramb_addr_2),
  .din_1 (ramb_din_1),
  .din_2 (ramb_din_2),
  .dout_1(ramb_dout_1),
  .dout_2(ramb_dout_2)
);

dual_ram #(DEPTH, 16) ramc(
  .clk(clk),
  .we_1  (ramc_we),
  .we_2  (ramc_we),
  .addr_1(ramc_addr_1),
  .addr_2(ramc_addr_2),
  .din_1 (ramc_din_1),
  .din_2 (ramc_din_2),
  .dout_1(ramc_dout_1),
  .dout_2(ramc_dout_2)
);

basemul bm1(
  .clk(clk),
  .set(set_bm),
  .a1(a1),
  .a0(a0),
  .b1(b1),
  .b0(b0),
  .zeta(zeta_bm),
  .t1(t1),
  .t0(t0)
);

// TODO: you only need one
zeta_rom #(0) rom1(
  .clk(clk),
  .addr(zeta_k),
  .data_out(zeta)
);

wire readin_a_ok_fsm;
wire readin_b_ok_fsm;
wire full_in_fsm = (~readin_a_ok_r) & (~readin_b_ok_r);
wire cal_pulse;
basemul_tomont_fsm #(DEPTH) fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  .readout(readout),
  .cal_en(cal_en),
  .full_in(full_in_fsm),
  .counter(counter),

  // OUTPUT
  .iscal(iscal),
  .index_a_ctrl(index_a_ctrl),
  .index_b_ctrl(index_b_ctrl),
  .index_c_ctrl(index_c_ctrl),
  .counter_ctrl(counter_ctrl),

  .rama_we_ok(rama_we_ok),
  .ramb_we_ok(ramb_we_ok),
  .ramc_we_ok(ramc_we_ok),

  .readin_a_ok(readin_a_ok_fsm), // pulse
  .readin_b_ok(readin_b_ok_fsm),
  .cal_pulse(cal_pulse),
  .done(done)
);

assign rama_we = rama_we_ok & (~iscal) & readin_a & readin_a_ok_r;
assign ramb_we = ramb_we_ok & (~iscal) & readin_b & readin_b_ok_r;
assign ramc_we = ramc_we_ok;

assign readin_a_ok = readin_a_ok_r;
assign readin_b_ok = readin_b_ok_r;

always @(*)begin
  readin_a_ok_r = (readin_a_ok_r | readin_a_ok_fsm) & (~full_in_a);
  readin_b_ok_r = (readin_b_ok_r | readin_b_ok_fsm) & (~full_in_b);
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    index_a <= 0;
    index_b <= 0;
    index_c <= 0;
    counter <= 0;
    k <= 0;
    //readin_a_ok_r <= 0;
    //readin_a_ok_r <= 0;
  end
  else if (set & iscal) begin
    if(index_a_ctrl) begin
      index_a <= index_a + 2;
    end
    if(index_b_ctrl) begin
      index_b <= index_b + 2;
    end
    if(index_c_ctrl) begin
      index_c <= index_c + 2;
    end
    if(counter_ctrl) begin
      counter <= counter + 1;
    end
    // TODO one index would suffice?
    if(index_a_ctrl & counter_ctrl & `ZETA_THING) begin
      k <= k + 1; // used only for the calculation
    end
  end
  else if(set & (~iscal) ) begin
    if(done & readout & index_c_ctrl) begin
      index_c <= index_c + 2;
    end
    // use the readin_a_ok_fsm pulse to reset the counter?
    if(cal_pulse)begin
      counter <= 0; // use the pulse to reset the counter?
      k <= 0; // k should reset itself if DEPTH = 8
      index_c <= 0;
    end
  end
end

endmodule