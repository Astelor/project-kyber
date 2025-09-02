/*
TODO: 
in ASSIGN, change the wires into regs, and convert the nested if-else, ternary operator into multiplexers (case) in always @(*)
use project-wide global param
*/

module polyvec_basemul_acc_mont #(parameter DEPTH = 8)(
  input clk,
  input set,
  input reset,
  
  input readin_a,
  input readin_b,
  input readout,
  input cal_en,

  input full_in_a,
  input full_in_b,
  // INPUT TO RAM A
  input wire signed [15:0] polyvec_din_a_1,
  input wire signed [15:0] polyvec_din_a_2,
  input wire [DEPTH-1:0] ina_index,
  // INPUT TO RAM B
  input wire signed [15:0] polyvec_din_b_1,
  input wire signed [15:0] polyvec_din_b_2,
  input wire [DEPTH-1:0] inb_index,
  // OUTPUT TO OUTSIDE
  output wire signed [15:0] polyvec_dout_1,
  output wire signed [15:0] polyvec_dout_2,
  output wire [DEPTH-1:0] out_index,
  output wire done
);

// MODULE WIRES begin ===================================//
// RAM A ====================
wire ram_a_we [0:2];

wire [DEPTH-1:0] ram_a_addr_1 [0:2], ram_a_addr_2 [0:2]; 
wire [15:0]      ram_a_din_1  [0:2], ram_a_din_2  [0:2];
wire [15:0]      ram_a_dout_1 [0:2], ram_a_dout_2 [0:2];

// RAM B ====================
wire ram_b_we [0:2];
wire [DEPTH-1:0] ram_b_addr_1 [0:2], ram_b_addr_2 [0:2]; 
wire [15:0]      ram_b_din_1  [0:2], ram_b_din_2  [0:2];
wire [15:0]      ram_b_dout_1 [0:2], ram_b_dout_2 [0:2];

// RAM C ====================
wire ram_c_we_1 [0:1];
wire ram_c_we_2 [0:1];

wire [DEPTH-2:0] ram_c_addr_1 [0:1], ram_c_addr_2 [0:1]; 
wire [15:0]      ram_c_din_1  [0:1], ram_c_din_2  [0:1];
wire [15:0]      ram_c_dout_1 [0:1], ram_c_dout_2 [0:1];

// BASEMUL ==================
wire bm_readin_a;
wire bm_readin_b;
wire bm_readout;
wire bm_cal_en;
wire bm_full_in_a;
wire bm_full_in_b;
// | INPUT TO RAMa
wire [15:0] bm_din_a_1;
wire [15:0] bm_din_a_2;
wire [DEPTH-1:0] bm_in_a_index;
// | INPUT TO RAMb
wire [15:0] bm_din_b_1;
wire [15:0] bm_din_b_2;
wire [DEPTH-1:0] bm_in_b_index;
// | OUTPUT
wire [15:0] bm_dout_1;
wire [15:0] bm_dout_2;
wire [DEPTH-1:0] bm_out_index;
// | FLAGs
wire bm_readin_a_ok;
wire bm_readin_b_ok;
wire bm_done;

// BARRETT REDUCTION ========
wire [15:0] barr1_a, barr2_a;
wire [15:0] barr1_t, barr2_t;

// MODULE WIRES end =====================================//

genvar i;
generate
  for (i = 0; i < 3 /*KYBER_K*/; i = i + 1) begin : GENRAM
    dual_ram #(DEPTH, 16) ram_a(
      .clk(clk),
      .we_1  (ram_a_we     [i]),
      .we_2  (ram_a_we     [i]),
      .addr_1(ram_a_addr_1 [i]),
      .addr_2(ram_a_addr_2 [i]),
      .din_1 (ram_a_din_1  [i]),
      .din_2 (ram_a_din_2  [i]),
      .dout_1(ram_a_dout_1 [i]),
      .dout_2(ram_a_dout_2 [i])
    );
    dual_ram #(DEPTH, 16) ram_b(
      .clk(clk),
      .we_1  (ram_b_we     [i]),
      .we_2  (ram_b_we     [i]),
      .addr_1(ram_b_addr_1 [i]),
      .addr_2(ram_b_addr_2 [i]),
      .din_1 (ram_b_din_1  [i]),
      .din_2 (ram_b_din_2  [i]),
      .dout_1(ram_b_dout_1 [i]),
      .dout_2(ram_b_dout_2 [i])
    );
    if(i < 2) begin : RAMC
      dual_ram #(DEPTH-1, 16) ram_c(
        .clk(clk),
        .we_1  (ram_c_we_1   [i]),
        .we_2  (ram_c_we_2   [i]),
        .addr_1(ram_c_addr_1 [i]),
        .addr_2(ram_c_addr_2 [i]),
        .din_1 (ram_c_din_1  [i]),
        .din_2 (ram_c_din_2  [i]),
        .dout_1(ram_c_dout_1 [i]),
        .dout_2(ram_c_dout_2 [i])
      );
    end
  end
endgenerate

basemul_tomont #(DEPTH) polybm(
  .clk(clk),
  .set(set),
  .reset(reset),

  .readin_a(bm_readin_a),
  .readin_b(bm_readin_b),
  .readout(bm_readout),
  .cal_en(bm_cal_en),
  
  .full_in_a(bm_full_in_a),
  .full_in_b(bm_full_in_b),

  .basemul_dina_1(bm_din_a_1),
  .basemul_dina_2(bm_din_a_2),
  .ina_index(bm_in_a_index),

  .basemul_dinb_1(bm_din_b_1),
  .basemul_dinb_2(bm_din_b_2),
  .inb_index(bm_in_b_index),

  .basemul_dout_1(bm_dout_1),
  .basemul_dout_2(bm_dout_2),
  .out_index(bm_out_index),
  
  .readin_a_ok(bm_readin_a_ok),
  .readin_b_ok(bm_readin_b_ok),
  .done(bm_done)
);

barrett_reduce barr1(
  .clk(clk),
  .set(set),
  .a(barr1_a),
  .t(barr1_t)
);

barrett_reduce barr2(
  .clk(clk),
  .set(set),
  .a(barr2_a),
  .t(barr2_t)
);

// LOCAL FSM 
wire [DEPTH-1:0] counter_fsm;
wire [2:0] k;

wire bm_readin_a_fsm;
wire bm_readin_b_fsm;

wire cal_en_fsm;
wire bm_full_in_a_fsm;
wire bm_full_in_b_fsm;
wire bm_readout_fsm;

wire index_a_ctrl;
wire index_b_ctrl;
wire index_c_ctrl;
wire counter_ctrl;

wire bm_readin_a_ok_fsm;
wire bm_readin_b_ok_fsm;

wire ram_a_we_ok_fsm;
wire ram_b_we_ok_fsm;
wire ram_c_we_ok_fsm;

wire barr_redc;

polyvec_basemul_acc_mont_fsm #(DEPTH) fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  
  .counter(counter_fsm),
  .bm_done(bm_done),
  
  // OUTPUT
  .k(k),
  .bm_readin_a(bm_readin_a_fsm),
  .bm_readin_b(bm_readin_b_fsm),
  
  .cal_en(cal_en_fsm),
  .bm_full_in_a(bm_full_in_a_fsm),
  .bm_full_in_b(bm_full_in_b_fsm),
  .bm_readout(bm_readout_fsm),

  .index_a_ctrl(index_a_ctrl),
  .index_b_ctrl(index_b_ctrl),
  .index_c_ctrl(index_c_ctrl),
  .counter_ctrl(counter_ctrl),
  
  .ram_a_we_ok(ram_a_we_ok_fsm),
  .ram_b_we_ok(ram_b_we_ok_fsm),
  .ram_c_we_ok(ram_c_we_ok_fsm),
  
  .barr_redc(barr_redc),

  .done(done)
);

// INTERNAL REGS begin ==================================//
reg [DEPTH-1:0] index_a;
reg [DEPTH-1:0] index_b;
reg [DEPTH-2:0] index_c; // 0~127
reg [DEPTH-1:0] counter;
reg readin_a_ok_r;
reg readin_b_ok_r; 

// RAM A ====================
reg [DEPTH-1:0] r_ram_a_addr_1 [0:2], r_ram_a_addr_2 [0:2]; 
reg [15:0]      r_ram_a_din_1  [0:2], r_ram_a_din_2  [0:2];
reg [15:0]      r_ram_a_dout_1 [0:2], r_ram_a_dout_2 [0:2];

// RAM B ====================
reg [DEPTH-1:0] r_ram_b_addr_1 [0:2], r_ram_b_addr_2 [0:2]; 
reg [15:0]      r_ram_b_din_1  [0:2], r_ram_b_din_2  [0:2];
reg [15:0]      r_ram_b_dout_1 [0:2], r_ram_b_dout_2 [0:2];

// BASEMUL ==================
// | INPUT TO RAMa
reg [15:0] r_bm_din_a_1;
reg [15:0] r_bm_din_a_2;
// | INPUT TO RAMb
reg [15:0] r_bm_din_b_1;
reg [15:0] r_bm_din_b_2;
// INTERNAL REGS end ====================================//

// ASSIGN begin =========================================//
assign bm_din_a_1 = r_bm_din_a_1;
assign bm_din_a_2 = r_bm_din_a_2;

assign bm_din_b_1 = r_bm_din_b_1;
assign bm_din_b_2 = r_bm_din_b_2;

generate // TODO: global param for KYBER_K
  for (i = 0; i < 3 /*KYBER_K*/; i = i + 1) begin : GENASSIGN
    // RAM A
    assign ram_a_addr_1[i] = r_ram_a_addr_1[i];
    assign ram_a_addr_2[i] = r_ram_a_addr_2[i];

    assign ram_b_addr_1[i] = r_ram_b_addr_1[i];
    assign ram_b_addr_2[i] = r_ram_b_addr_2[i];

    /*
    assign ram_a_addr_1[i] = (k == i + 1) ? index_a     : 'dz ,
           ram_a_addr_2[i] = (k == i + 1) ? index_a + 1 : 'dz ;
    // RAM B
    assign ram_b_addr_1[i] = (k == i + 1) ? index_b     : 'dz ,
           ram_b_addr_2[i] = (k == i + 1) ? index_b + 1 : 'dz ;
    // BASEMUL
    assign bm_din_a_1 = (k == i + 1) ? ram_a_dout_1[i] : 'dz ,
           bm_din_a_2 = (k == i + 1) ? ram_a_dout_2[i] : 'dz ;
    assign bm_din_b_1 = (k == i + 1) ? ram_b_dout_1[i] : 'dz ,
           bm_din_b_2 = (k == i + 1) ? ram_b_dout_2[i] : 'dz ;
    */
    assign ram_a_we[i] = ram_a_we_ok_fsm & readin_a; // modify for top level readin
    assign ram_b_we[i] = ram_b_we_ok_fsm & readin_b;
    
    // RAM C
    if(i < 2) begin : RAMC // RAM C is two no matter the KYBER_K
      // port 1 read, port 2 write
      assign ram_c_we_1[i]   = 0;
      assign ram_c_we_2[i]   = ram_c_we_ok_fsm;
      // port 1 read, port 2 write
      assign ram_c_addr_1[i] =  (index_c_ctrl  ) ? index_c : 'dz ; // read
      assign ram_c_addr_2[i] =  (barr_redc     ) ? index_c - 2 :
                                (bm_readout_fsm) ? bm_out_index >> 1 : 
                                                 'dz                 ; // write
    end
  end
endgenerate
// RAM C DIN
assign ram_c_din_2[0] = (barr_redc                ) ? barr1_t                     :
                        (bm_readout_fsm & (k <  3)) ? bm_dout_1                   :
                        (bm_readout_fsm & (k >= 3)) ? bm_dout_1 + ram_c_dout_1[0] :
                                                      'dz ; // 0
assign ram_c_din_2[1] = (barr_redc                ) ? barr2_t                     :
                        (bm_readout_fsm & (k <  3)) ? bm_dout_2                   :
                        (bm_readout_fsm & (k >= 3)) ? bm_dout_2 + ram_c_dout_1[1] : 
                                                      'dz ; // 1
assign barr1_a = (barr_redc) ? ram_c_dout_1[0] : 'dz;
assign barr2_a = (barr_redc) ? ram_c_dout_1[1] : 'dz;

// BASEMUL =================================
assign bm_in_a_index = index_a - 2;
assign bm_in_b_index = index_b - 2;

assign bm_readin_a = bm_readin_a_fsm;
assign bm_readin_b = bm_readin_b_fsm;

assign bm_full_in_a = bm_full_in_a_fsm;
assign bm_full_in_b = bm_full_in_b_fsm;

assign bm_cal_en = cal_en_fsm;
assign bm_readout = bm_readout_fsm;

assign counter_fsm = counter;

// INPUT/OUTPUT =============================
assign polyvec_dout_1 = (done & readout) ? ram_c_dout_1[0] : 'dz; 
assign polyvec_dout_2 = (done & readout) ? ram_c_dout_1[1] : 'dz;
assign out_index      = (done) ? index_c - 1 : 'dz; 


// ASSIGN end ===========================================//

reg [3:0] ii;

always @(*) begin
  //readin_a_ok_r = (readin_a_ok_r | readin_a_ok_fsm)
  case (k)
    1 : begin
      mytask(0);
    end 
    2 : begin
      mytask(1);
    end
    3 : begin
      mytask(2);
    end
    default: begin
      mytask(3);
    end 
  endcase
end

task mytask (input [3:0] kk);
  begin
    //generate
      for(ii = 0; ii < 3; ii = ii + 1) begin : K1
        if(ii == kk) begin
          r_ram_a_addr_1[ii] = index_a;
          r_ram_a_addr_2[ii] = index_a + 1;

          r_ram_b_addr_1[ii] = index_b;
          r_ram_b_addr_2[ii] = index_b + 1;

          r_bm_din_a_1 = ram_a_dout_1[ii];
          r_bm_din_a_2 = ram_a_dout_2[ii];

          r_bm_din_b_1 = ram_b_dout_1[ii];
          r_bm_din_b_2 = ram_b_dout_2[ii];
        end
        else begin
          r_ram_a_addr_1[ii] = 'dz;
          r_ram_a_addr_2[ii] = 'dz;

          r_ram_b_addr_1[ii] = 'dz;
          r_ram_b_addr_2[ii] = 'dz;

          r_bm_din_a_1 = 'dz;
          r_bm_din_a_2 = 'dz;

          r_bm_din_b_1 = 'dz;
          r_bm_din_b_2 = 'dz;
        end
      end
    //endgenerate
  end
endtask

always @(posedge clk or posedge reset) begin
  if(reset) begin
    index_a <= 0;
    index_b <= 0;
    index_c <= 0;
    counter <= 0;
  end
  else if(set) begin
    if(~done)  begin
      if(index_a_ctrl) begin
        index_a <= index_a + 2;
      end
      if(index_b_ctrl) begin
        index_b <= index_b + 2;
      end
      if(index_c_ctrl) begin
        index_c <= index_c + 1;
      end
      if(counter_ctrl) begin
        counter <= counter + 1;
      end
    end
    else begin
      if(readout & index_c_ctrl) begin
        index_c <= index_c + 1;
      end
    end
    if(cal_en_fsm) begin // pulse reset
      counter <= 0;
      index_a <= 0;
      index_b <= 0;
      index_c <= 0;
    end
  end

end
endmodule