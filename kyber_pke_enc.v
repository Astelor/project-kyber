/*
this thing should be the top level sytem design but I suck at Verilog programming

*/
module kyber_pke_enc(
  input clk,
  input set,
  input reset,
  input readin,
  input full_in,
  input [7:0]  kyber_din,
  input [15:0] kyber_in_index,
  
  input [3:0] data_type, // indicate what input data it is
  output [3:0] input_type, // it's a handshake to ensure the data is what it should be
    // 0: nothing, 
    // 1: randomness r, 
    // 2: (byte array encoded) public key t, 
    // 3: public key matrix A, 
    // 4: message m
    // or should I just port them all in in one go?
  output readin_ok, // big controll
  output done // controlled by FSM
);

parameter KYBER_K = 3;
// MODULE INSTANCE BEGIN ======================//
// HASH STUB ======
// - INPUT
wire        hash_set;
wire        hash_readin, hash_readout;
reg         hash_full_in;
reg  [7:0]  hash_nonce;
reg  [7:0]  hash_din;
reg  [7:0]  hash_in_index;
// - OUTPUT
wire [31:0] hash_dout_1, hash_dout_2;
wire [4:0]  hash_out_index;
wire        hash_readin_ok;
wire        hash_done;

hash_stub hash(
  // SYSTEM
  .clk(clk),
  .set(hash_set),
  .reset(reset),
  // INPUT
  .readin     (hash_readin),
  .readout    (hash_readout),
  .full_in    (hash_full_in),

  .nonce      (hash_nonce),
  .hash_din   (hash_din),
  .in_index   (hash_in_index),
  // OUTUPT
  .hash_dout_1(hash_dout_1),
  .hash_dout_2(hash_dout_2),
  .out_index  (hash_out_index),
  .readin_ok  (hash_readin_ok),
  .done       (hash_done)
);

// CBD ======================
// - INPUT
wire        cbd_set;
wire        cbd_readin, cbd_readout;
wire [31:0] cbd_din_1,  cbd_din_2;
// - OUTPUT
wire        cbd_ok_in,  cbd_ok_out;
wire [15:0] cbd_dout_1, cbd_dout_2;

cbd cbd(
  // SYSTEM
  .clk       (clk),
  .set       (cbd_set),
  .reset     (reset),
  // INPUT
  .readin    (cbd_readin),
  .readout   (cbd_readout),

  .cbd_din_1 (cbd_din_1),
  .cbd_din_2 (cbd_din_2),
  //OUTPUT
  .cbd_dout_1(cbd_dout_1),
  .cbd_dout_2(cbd_dout_2),
  .ok_out    (cbd_ok_out),
  .ok_in     (cbd_ok_in)
);

// NTT ======================
// - INPUT
wire        ntt_set;
reg         ntt_readin;
wire        ntt_readout;
wire        ntt_cal_en;
reg  [15:0] ntt_din_1,  ntt_din_2;
reg  [7:0]  ntt_in_index;
// - OUTPUT
wire [15:0] ntt_dout_1, ntt_dout_2;
wire [7:0]  ntt_out_index;
wire        ntt_done;

ntt #(8) ntt( // (no write during read for this module)
  .clk(clk),
  .set(ntt_set), // does it need a custom set signal?
  .reset(reset),
  // INPUT
  .readin    (ntt_readin),
  .readout   (ntt_readout),
  .cal_en    (ntt_cal_en),
  .ntt_din_1 (ntt_din_1),
  .ntt_din_2 (ntt_din_2),
  .in_index  (ntt_in_index),
  // OUTPUT
  .ntt_dout_1(ntt_dout_1),
  .ntt_dout_2(ntt_dout_2),
  .out_index (ntt_out_index),
  .done      (ntt_done)
);

// BARRETT REDUCE ===========
wire        barr1_set;
wire [15:0] barr1_a;
wire [15:0] barr1_t;

wire        barr2_set;
wire [15:0] barr2_a;
wire [15:0] barr2_t;

barrett_reduce barr1(
  .clk(clk),
  .set(barr1_set),
  .a  (barr1_a),
  .t  (barr1_t)
);

barrett_reduce barr2(
  .clk(clk),
  .set(barr2_set),
  .a  (barr2_a),
  .t  (barr2_t)
);

// DECODE 12 ================
wire dec12_set;
reg  dec12_readin;
reg  [7:0] dec12_din;
reg  [15:0] dec12_in_index; // only need up to 9 bits for k = 3
wire [15:0] dec12_dout_1;
wire [15:0] dec12_dout_2;
wire dec12_output_ok;
wire [15:0] dec12_out_index;

decode12 dec12(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT 
  .readin   (dec12_readin),
  .din      (dec12_din),
  .in_index (dec12_in_index),
  // OUTPUT 
  .output_ok(dec12_output_ok), 
  .dout_1   (dec12_dout_1),
  .dout_2   (dec12_dout_2),
  .out_index(dec12_out_index)
);


// POLYVEC_BASEMUL ==========
wire polyvec_set;
wire polyvec_readin_a;
reg  polyvec_readin_b;

wire polyvec_readout;
wire polyvec_cal_en;

wire polyvec_full_in_a;
reg  polyvec_full_in_b;

wire [15:0] polyvec_din_a_1;
wire [15:0] polyvec_din_a_2;
wire [7:0]  polyvec_ina_index;
wire [3:0]  polyvec_ina_k;

reg  [15:0] polyvec_din_b_1;
reg  [15:0] polyvec_din_b_2;
reg  [7:0]  polyvec_inb_index;
reg  [3:0]  polyvec_inb_k;

wire [15:0] polyvec_dout_1;
wire [15:0] polyvec_dout_2;
wire [7:0]  polyvec_out_index;

wire polyvec_readin_a_ok;
wire polyvec_readin_b_ok;
wire polyvec_done;


polyvec_basemul_acc_mont polyvec(
  .clk(clk),
  .set(polyvec_set),
  .reset(reset),

  .readin_a       (polyvec_readin_a),
  .readin_b       (polyvec_readin_b),
  .readout        (polyvec_readout),
  .cal_en         (polyvec_cal_en),

  .full_in_a      (polyvec_full_in_a),
  .full_in_b      (polyvec_full_in_b),
  // INPUT TO RAM A
  .polyvec_din_a_1(polyvec_din_a_1),
  .polyvec_din_a_2(polyvec_din_a_2),
  .ina_index      (polyvec_ina_index),
  .ina_k          (polyvec_ina_k),
  // INPUT TO RAM B
  .polyvec_din_b_1(polyvec_din_b_1),
  .polyvec_din_b_2(polyvec_din_b_2),
  .inb_index      (polyvec_inb_index),
  .inb_k          (polyvec_inb_k),

  // OUTPUT TO OUTSIDE
  .polyvec_dout_1 (polyvec_dout_1),
  .polyvec_dout_2 (polyvec_dout_2),
  .out_index      (polyvec_out_index),

  .readin_a_ok(polyvec_readin_a_ok),
  .readin_b_ok(polyvec_readin_b_ok),

  .done(polyvec_done)
);

// INVNTT ===================
wire invntt_set;
wire invntt_readin;
wire invntt_readout;
wire invntt_cal_en;
wire invntt_full_in;

wire [15:0] invntt_din_1;
wire [15:0] invntt_din_2;
wire [7:0]  invntt_in_index;

wire [15:0] invntt_dout_1;
wire [15:0] invntt_dout_2;
wire [7:0]  invntt_out_index;
wire invntt_valid_out;

wire invntt_readin_ok;
wire invntt_done;

invntt invntt(
  .clk(clk),
  .set(invntt_set),
  .reset(reset),
  // INPUT
  .readin       (invntt_readin),
  .readout      (invntt_readout),
  .cal_en       (invntt_cal_en),
  .full_in      (invntt_full_in),
  
  .invntt_din_1 (invntt_din_1),
  .invntt_din_2 (invntt_din_2),
  .in_index     (invntt_in_index),
  // OUTPUT
  .invntt_dout_1(invntt_dout_1),
  .invntt_dout_2(invntt_dout_2),
  .out_index    (invntt_out_index),
  .valid_out    (invntt_valid_out),
  .readin_ok    (invntt_readin_ok),
  .done         (invntt_done)
);

// DECOMPRESS1 ==============
// - INPUT
wire decomp_set;
reg  decomp_readin;
wire decomp_readout;
reg  decomp_full_in;
reg  [7:0] decomp_din;
reg  [7:0] decomp_in_index;
// - OUTPUT
wire [15:0] decomp_dout_1;
wire [15:0] decomp_dout_2;
wire [7:0] decomp_out_index;
wire decomp_readin_ok;
wire decomp_readout_ok;

decompress1 decomp(
  .clk  (clk),
  .set  (decomp_set),
  .reset(reset),
  // INPUT
  .readin        (decomp_readin),
  .readout       (decomp_readout),
  .full_in       (decomp_full_in),
  .decomp_din    (decomp_din),
  .in_index      (decomp_in_index),
  // OUTPUT
  .decomp_dout_1 (decomp_dout_1),
  .decomp_dout_2 (decomp_dout_2),
  .out_index     (decomp_out_index),
  .readin_ok     (decomp_readin_ok),
  .readout_ok    (decomp_readout_ok)
);

// MATRIX HASH STUB
// INPUT
wire        matrix_hash_set;
wire        matrix_hash_readin;
wire        matrix_hash_readout;
reg         matrix_hash_full_in;
reg  [ 7:0] matrix_hash_nonce1;
reg  [ 7:0] matrix_hash_nonce2;
reg  [ 7:0] matrix_hash_din;
reg  [ 7:0] matrix_hash_in_index;
// OUTPUT
wire [15:0] matrix_hash_dout_1;
wire [15:0] matrix_hash_dout_2;
wire [ 7:0] matrix_hash_out_index;
wire        matrix_hash_readin_ok;
wire        matrix_hash_done;

matrix_hash_stub matrix_hash(
  .clk(clk),
  .set(matrix_hash_set),
  .reset(reset),

  // INPUT
  .readin            (matrix_hash_readin),
  .readout           (matrix_hash_readout),
  .full_in           (matrix_hash_full_in),
  .nonce1            (matrix_hash_nonce1),
  .nonce2            (matrix_hash_nonce2),
  
  .matrix_hash_din   (matrix_hash_din),
  .in_index          (matrix_hash_in_index),
  // OUTPUT
  .matrix_hash_dout_1(matrix_hash_dout_1),
  .matrix_hash_dout_2(matrix_hash_dout_2),
  .out_index         (matrix_hash_out_index),  
  
  .readin_ok(matrix_hash_readin_ok),
  .done(matrix_hash_done)
);


// // RAM 1, vector
// wire        ram1_we_1   [0:2], ram1_we_2   [0:2];
// wire [7:0]  ram1_addr_1 [0:2], ram1_addr_2 [0:2];
// wire [15:0] ram1_din_1  [0:2], ram1_din_2  [0:2];
// wire [15:0] ram1_dout_1 [0:2], ram1_dout_2 [0:2];

// genvar i;
// generate
//   for(i = 0; i < 3; i = i + 1) begin : GENRAM
//     dual_ram #(8, 16) ram1(
//       .clk(clk),
//       .we_1  (ram1_we_1   [i]),
//       .we_2  (ram1_we_2   [i]),
//       .addr_1(ram1_addr_1 [i]),
//       .addr_2(ram1_addr_2 [i]),
//       .din_1 (ram1_din_1  [i]),
//       .din_2 (ram1_din_2  [i]),
//       .dout_1(ram1_dout_1 [i]),
//       .dout_2(ram1_dout_2 [i])
//     );
//   end
// endgenerate

// // RAM 2, polynomial
// reg         ram2_we_1,   ram2_we_2;
// reg  [7:0]  ram2_addr_1, ram2_addr_2;
// reg  [15:0] ram2_din_1,  ram2_din_2;
// wire [15:0] ram2_dout_1, ram2_dout_2;

// dual_ram #(8, 16) ram2(
//   .clk(clk),
//   .we_1  (ram2_we_1),
//   .we_2  (ram2_we_2),
//   .addr_1(ram2_addr_1),
//   .addr_2(ram2_addr_2),
//   .din_1 (ram2_din_1),
//   .din_2 (ram2_din_2),
//   .dout_1(ram2_dout_1),
//   .dout_2(ram2_dout_2)
// );

wire        accu2_set;
wire [ 3:0] accu2_cmd;
reg         accu2_readin;
wire        accu2_readout;
reg  [ 6:0] accu2_addr_a, accu2_addr_b;
reg  [15:0] accu2_data_a, accu2_data_b;
wire [ 6:0] accu2_addr_out;
wire [15:0] accu2_data_a_out, accu2_data_b_out;
wire [ 3:0] accu2_status;

accumulator accu2(
  .clk(clk),
  .set(accu2_set),
  .reset(reset),
  // INPUT
  .cmd       (accu2_cmd),
  .readin    (accu2_readin),
  .readout   (accu2_readout),
  .addr_a    (accu2_addr_a),
  .addr_b    (accu2_addr_b),
  .data_a    (accu2_data_a),
  .data_b    (accu2_data_b),
  // OUTPUT
  .addr_out  (accu2_addr_out),
  .data_a_out(accu2_data_a_out),
  .data_b_out(accu2_data_b_out),
  .status    (accu2_status)
);

// MODULE INSTANCE END ========================//


// FSM INSTANCE BEGIN :> ======================//

// BIG CONTROL ==============
wire [7:0] input_ctrl_status;
wire [7:0] input_ctrl_cmd;

wire [7:0] hash_ctrl_status;
wire [7:0] hash_ctrl_cmd;

wire [7:0] cbd_ctrl_status;
wire [7:0] cbd_ctrl_cmd;

wire [7:0] ntt_ctrl_status;
wire [7:0] ntt_ctrl_cmd;

wire [7:0] polyvec_ctrl_status;
wire [7:0] polyvec_ctrl_cmd;

wire [7:0] invntt_ctrl_status;
wire [7:0] invntt_ctrl_cmd;

wire [7:0] decomp_ctrl_status;
wire [7:0] decomp_ctrl_cmd;

wire [7:0] matrix_hash_ctrl_status;
wire [7:0] matrix_hash_ctrl_cmd;

// wire [7:0] mem1_ctrl_status;
// wire [7:0] mem1_ctrl_cmd;

wire [7:0] accu2_ctrl_status;
wire [7:0] accu2_ctrl_cmd;

kyber_pke_enc_fsm fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  // -- INTERNAL
  .input_ctrl_status      (input_ctrl_status),
  .hash_ctrl_status       (hash_ctrl_status),
  .cbd_ctrl_status        (cbd_ctrl_status),
  .ntt_ctrl_status        (ntt_ctrl_status),
  .polyvec_ctrl_status    (polyvec_ctrl_status),
  .invntt_ctrl_status     (invntt_ctrl_status),
  .decomp_ctrl_status     (decomp_ctrl_status),
  .matrix_hash_ctrl_status(matrix_hash_ctrl_status),
  // .mem1_ctrl_status       (mem1_ctrl_status),
  .accu2_ctrl_status       (accu2_ctrl_status),
  // OUTPUT
  // -- INTERNAL
  .input_ctrl_cmd         (input_ctrl_cmd),
  .hash_ctrl_cmd          (hash_ctrl_cmd),
  .cbd_ctrl_cmd           (cbd_ctrl_cmd),
  .ntt_ctrl_cmd           (ntt_ctrl_cmd),
  .polyvec_ctrl_cmd       (polyvec_ctrl_cmd),
  .invntt_ctrl_cmd        (invntt_ctrl_cmd),
  .decomp_ctrl_cmd        (decomp_ctrl_cmd),
  .matrix_hash_ctrl_cmd   (matrix_hash_ctrl_cmd),
  // .mem1_ctrl_cmd          (mem1_ctrl_cmd),
  .accu2_ctrl_cmd          (accu2_ctrl_cmd),
  // -- OUTSIDE
  .done(done)
);

// INPUT CONTROL ============
wire readin_ok_fsm;

kyber_pke_enc_input_fsm input_fsm(
  .clk(clk),
  .set(set),
  .reset(reset),

  .full_in                (full_in), // outside
  .readin_ok_fsm          (readin_ok_fsm),
  .input_type             (input_type), // output to outside 

  .hash_ctrl_status       (hash_ctrl_status), // input
  .polyvec_ctrl_status    (polyvec_ctrl_status),
  .decomp_ctrl_status     (decomp_ctrl_status),
  .matrix_hash_ctrl_status(matrix_hash_ctrl_status),
  .input_ctrl_cmd         (input_ctrl_cmd), // input
  .input_ctrl_status      (input_ctrl_status) // output
);


// HASH CONTROL =============
// note: hash_s_<flag> = it comboes with another signal
wire hash_s_set;
wire hash_s_full_in; // this does combo with another signal
wire hash_s_readin;
wire hash_s_readout;
// wire hash_s_nonce;
// wire [3:0] hash_type;
wire hash_counter_ctrl;
reg [7:0] hash_counter;

kyber_pke_enc_hash_fsm hash_fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  .hash_readin_ok  (hash_readin_ok),
  .hash_done       (hash_done),
  // OUTPUT
  .hash_s_set      (hash_s_set),
  .hash_s_full_in  (hash_s_full_in), // TODO: I don't think this signal was used?
  .hash_s_readin   (hash_s_readin),
  .hash_s_readout  (hash_s_readout), 
  // .hash_type       (hash_type),
  .counter_ctrl    (hash_counter_ctrl),
  .counter         (hash_counter),
  // .hash_nonce      (hash_s_nonce),
  // BIG CONTROL
  .input_ctrl_status(input_ctrl_status),
  .cbd_ctrl_status  (cbd_ctrl_status),
  .hash_ctrl_cmd    (hash_ctrl_cmd),
  .hash_ctrl_status (hash_ctrl_status)
);

// CBD CONTROL ==============
wire cbd_s_set;
// wire cbd_s_readin;

wire cbd_counter_ctrl;
reg [7:0] cbd_counter;
wire cbd_s_cal_pulse;
wire [3:0] cbd_type;

kyber_pke_enc_cbd_fsm cbd_fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  .cbd_ok_in       (cbd_ok_in),
  .cbd_ok_out      (cbd_ok_out),
  // OUTPUT
  .cbd_s_set       (cbd_s_set),
  .cbd_s_readin    (cbd_readin),
  .cbd_readout     (cbd_readout),

  .counter_ctrl    (cbd_counter_ctrl),
  .counter         (cbd_counter),
  .cbd_s_cal_pulse (cbd_s_cal_pulse),
  .cbd_type        (cbd_type),
  // BIG CONTROL
  .hash_ctrl_status(hash_ctrl_status),
  .ntt_ctrl_status (ntt_ctrl_status),
  .accu2_ctrl_status(accu2_ctrl_status),
  .cbd_ctrl_cmd    (cbd_ctrl_cmd),
  .cbd_ctrl_status (cbd_ctrl_status)
);

// NTT CONTROL ==============
wire ntt_s_set;
wire ntt_s_readin;
wire ntt_s_readout;
wire ntt_s_cal_en;
wire [3:0] ntt_seq;

wire ntt_counter_ctrl;
reg [7:0] ntt_counter;

kyber_pke_enc_ntt_fsm ntt_fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  .ntt_done           (ntt_done),
  // OUTPUT
  .ntt_s_set          (ntt_s_set),
  .ntt_s_readin       (ntt_s_readin),
  .ntt_s_cal_en       (ntt_s_cal_en),
  .ntt_s_readout      (ntt_s_readout),
  .cbd_counter        (cbd_counter), // counter for everyone!

  .counter_ctrl       (ntt_counter_ctrl),
  .counter            (ntt_counter),
  // SOMETHING SOMETHING
  .ntt_seq            (ntt_seq),

  // BIG CONTROL
  .cbd_ctrl_status    (cbd_ctrl_status),
  .polyvec_ctrl_status(polyvec_ctrl_status),
  .ntt_ctrl_cmd       (ntt_ctrl_cmd),
  .ntt_ctrl_status    (ntt_ctrl_status)
);

// POLYVEC CONTROL ==========
wire polyvec_s_set;
wire polyvec_s_readout;
wire polyvec_s_readin_a;
wire polyvec_s_readin_b;
// wire [3:0] polyvec_seq;
wire polyvec_s_full_in_a;
wire polyvec_s_full_in_b;

wire polyvec_counter_ctrl;
reg [7:0] polyvec_counter;

kyber_pke_enc_polyvec_fsm polyvec_fsm(
  .clk(clk),
  .set(set),  
  .reset(reset),
  // INPUT
  .polyvec_done       (polyvec_done),
  .polyvec_readin_a_ok(polyvec_readin_a_ok),
  .polyvec_readin_b_ok(polyvec_readin_b_ok),
  // OUTPUT
  .polyvec_s_set      (polyvec_s_set),
  .polyvec_s_readout  (polyvec_s_readout), // directly to outside
  .polyvec_s_cal_en   (polyvec_cal_en), // TODO: comply it into the same format?

  .polyvec_s_readin_a (polyvec_s_readin_a),
  .polyvec_s_readin_b (polyvec_s_readin_b),
  .polyvec_full_in_a  (polyvec_s_full_in_a),
  .polyvec_full_in_b  (polyvec_s_full_in_b),
  
  // SOMETHING SOMETHING...
  .counter_ctrl       (polyvec_counter_ctrl),
  .counter            (polyvec_counter),
  // .seq                (polyvec_seq),
  // BIG CONTROL
  .ntt_ctrl_status        (ntt_ctrl_status),
  .invntt_ctrl_status     (invntt_ctrl_status),
  .matrix_hash_ctrl_status(matrix_hash_ctrl_status),
  .polyvec_ctrl_cmd       (polyvec_ctrl_cmd),
  .polyvec_ctrl_status    (polyvec_ctrl_status)
);

// INVNTT CONTROL ===========
wire invntt_s_set;
wire invntt_s_readin;
wire invntt_s_readout;
wire invntt_s_cal_en;
wire invntt_s_full_in;

kyber_pke_enc_invntt_fsm invntt_fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  
  // INPUT
  .invntt_readin_ok   (invntt_readin_ok),
  .invntt_done        (invntt_done),
  // OUTPUT
  .invntt_s_set       (invntt_s_set),
  .invntt_s_readin    (invntt_s_readin),
  .invntt_s_readout   (invntt_s_readout),
  .invntt_s_cal_en    (invntt_s_cal_en),
  .invntt_s_full_in   (invntt_s_full_in),

  .polyvec_ctrl_status(polyvec_ctrl_status),
  .accu2_ctrl_status  (accu2_ctrl_status),
  .invntt_ctrl_cmd    (invntt_ctrl_cmd),
  .invntt_ctrl_status (invntt_ctrl_status)
);


// DECOMP CONTROL ===========
// TODO: this thing doesn't have a RAM
//        is it okay to pass it through and not store it?
//        heh?? I guess???
// no I don't think so?
wire decomp_s_set;
wire decomp_s_readin;
wire decomp_s_readout;
// wire decomp_s_full_in;

kyber_pke_enc_decomp_fsm decomp_fsm(
  .clk(clk),
  .set(set),
  .reset(reset),

  // INPUT
  .decomp_readin_ok  (decomp_readin_ok),
  .decomp_readout_ok (decomp_readout_ok),
  // OUTPUT
  .decomp_s_set      (decomp_s_set),
  .decomp_s_readin   (decomp_s_readin),
  .decomp_s_readout  (decomp_s_readout),
  // .decomp_s_full_in  (decomp_s_full_in), // TODO: this signal is not used
  
  .input_ctrl_status (input_ctrl_status),
  .accu2_ctrl_status (accu2_ctrl_status),
  .decomp_ctrl_cmd   (decomp_ctrl_cmd),
  .decomp_ctrl_status(decomp_ctrl_status)
);

// MATRIX HASH CONTROL
wire matrix_hash_s_set;
wire matrix_hash_s_full_in;
wire matrix_hash_s_readin;
wire matrix_hash_s_readout;

wire matrix_hash_counter_ctrl;
reg [7:0] matrix_hash_counter;
kyber_pke_enc_matrix_hash_fsm matrix_hash_fsm(
  .clk(clk),
  .set(set),
  .reset(reset),

  // INPUT 
  .matrix_hash_readin_ok  (matrix_hash_readin_ok),
  .matrix_hash_done       (matrix_hash_done),
  
  // OUTPUT
  .matrix_hash_s_set      (matrix_hash_s_set),
  .matrix_hash_s_full_in  (matrix_hash_s_full_in),
  .matrix_hash_s_readin   (matrix_hash_s_readin),
  .matrix_hash_s_readout  (matrix_hash_s_readout),

  .counter_ctrl           (matrix_hash_counter_ctrl),
  .counter                (matrix_hash_counter),
  .input_ctrl_status      (input_ctrl_status),
  .polyvec_ctrl_status    (polyvec_ctrl_status),
  .matrix_hash_ctrl_cmd   (matrix_hash_ctrl_cmd),
  .matrix_hash_ctrl_status(matrix_hash_ctrl_status)
);

// kyber_pke_enc_mem1_fsm mem1_fsm(
//   .clk(clk),
//   .set(set),
//   .reset(reset),
//   // .ram1_we_1(),
//   // .ram1_we_2(),

//   .mem1_ctrl_cmd   (mem1_ctrl_cmd),
//   .mem1_ctrl_status(mem1_ctrl_status)
// );

// MEM 2 CONTROL 
wire [3:0] accu2_s_cmd;
wire accu2_s_readin;
wire accu2_s_readout;
wire [3:0] accu2_s_type;

kyber_pke_enc_accu2_fsm accu2_fsm( 
  .clk(clk),
  .set(set),
  .reset(reset),
  
  .accu2_status        (accu2_status),

  .accu2_s_cmd         (accu2_s_cmd),
  .accu2_s_readin      (accu2_s_readin),
  .accu2_s_readout     (accu2_s_readout),
  .accu2_s_type        (accu2_s_type),

  .cbd_type            (cbd_type),
  .cbd_counter         (cbd_counter),

  .decomp_ctrl_status  (decomp_ctrl_status),
  .cbd_ctrl_status     (cbd_ctrl_status),
  .invntt_ctrl_status  (invntt_ctrl_status),
  .accu2_ctrl_cmd      (accu2_ctrl_cmd),
  .accu2_ctrl_status   (accu2_ctrl_status)
);
// FSM INSTANCE END ===========================//

// LOCAL REG BEGIN ============================//
reg readin_ok_r;
reg [7:0] matrix_hash_nonce;
// LOCAL REG END ==============================//

// ASSIGN BEGIN ===============================//
// -- OUTSIDE
assign readin_ok = readin_ok_r;
// -- HASH
assign hash_set      = set & hash_s_set;
assign hash_readin   = readin & hash_s_readin & readin_ok_r; // >:(
assign hash_readout  = hash_s_readout;
// -- CBD
assign cbd_set    = set & cbd_s_set;
assign cbd_din_1  = hash_dout_1; // TODO: this needs a selector for other hash usage :>
assign cbd_din_2  = hash_dout_2;

// -- NTT
assign ntt_set      = set & ntt_s_set;
// assign ntt_readin   = cbd_readout & ntt_s_readin;
// assign ntt_din_1    = cbd_dout_2; // TODO: why the heck is the input swapped?
// assign ntt_din_2    = cbd_dout_1;
// assign ntt_in_index = (cbd_counter - 4) << 1; // is the power of 2 :)
assign ntt_cal_en  = ntt_s_cal_en;
assign ntt_readout = ntt_s_readout;

// -- BARRETT REDUCE
assign barr1_set = set;
assign barr2_set = set;
assign barr1_a   = ntt_dout_1;
assign barr2_a   = ntt_dout_2;

// -- DECODE12
assign dec12_set = 1; // TODO: does this need a case?

// -- POLYVEC
assign polyvec_set       = set & polyvec_s_set;
assign polyvec_readin_a  = ntt_readout & polyvec_s_readin_a;
assign polyvec_readout   = polyvec_s_readout;
assign polyvec_ina_k     = ntt_seq - 1;
assign polyvec_din_a_1   = barr1_t;
assign polyvec_din_a_2   = barr2_t;
assign polyvec_ina_index = ntt_out_index - 2;
assign polyvec_full_in_a = polyvec_s_full_in_a;

// -- INVNTT
assign invntt_set      = set & invntt_s_set;
assign invntt_readin   = polyvec_readout & invntt_s_readin; 
assign invntt_readout  = invntt_s_readout;
assign invntt_din_1    = polyvec_dout_2; // invntt input only pipe to polyvec for now
assign invntt_din_2    = polyvec_dout_1; 
// TODO: for ntt, invntt din_1 = f[j+len], 
// when I wrote the testbench I literally tested it around it
assign invntt_in_index = polyvec_out_index << 1; // does it implicitly reject odd numbered index??
assign invntt_cal_en   = invntt_s_cal_en;
assign invntt_full_in  = invntt_s_full_in;

// -- DECOMP
assign decomp_set     = decomp_s_set; // TODO: does this need a case?
assign decomp_readout = decomp_s_readout;

// -- MATRIX HASH
assign matrix_hash_set     = set & matrix_hash_s_set;
assign matrix_hash_readin  = readin & matrix_hash_s_readin & readin_ok_r; 
assign matrix_hash_readout = matrix_hash_s_readout;

// -- ACCUMULATOR 2
assign accu2_set = set;
assign accu2_cmd = accu2_s_cmd;
// assign accu2_readin = accu2_s_readin;
assign accu2_readout = accu2_s_readout;

// ASSIGN END =================================//

// ALWAYS BLOCK BEGIN =========================//

always @(*) begin
  case (input_type) // controlled by INPUT FSM
    1 : begin
      if (input_type == data_type) begin
        hash_full_in  = /*hash_s_full_in &*/ full_in;
        hash_din      = kyber_din;
        hash_in_index = kyber_in_index;
      end
    end
    2 : begin // only let it do input when command is present
      if (input_type == data_type) begin
        dec12_din      = kyber_din;
        dec12_in_index = kyber_in_index;
        dec12_readin   = readin & readin_ok_r;
      end
        hash_full_in  = hash_s_full_in;
        hash_din      = 0;
        hash_in_index = 0;

        // NOTE: POLYVEC A is from NTT
        polyvec_din_b_1   = dec12_dout_1; 
        polyvec_din_b_2   = dec12_dout_2; // do it with an fsm because it sucks
        polyvec_readin_b  = dec12_output_ok & polyvec_s_readin_b & readin_ok_r;
        polyvec_inb_k     = (dec12_out_index & 16'h180) >> 7;
        polyvec_inb_index = dec12_out_index << 1;
        polyvec_full_in_b = full_in & polyvec_s_full_in_b;
    end
    3 : begin // message
      if (input_type == data_type) begin
        decomp_full_in  = full_in;
        decomp_din      = kyber_din;
        decomp_in_index = kyber_in_index;
        decomp_readin   = readin & readin_ok_r; // does this need a case
      end
    end
    4 : begin // seed
      if(input_type == data_type) begin
        matrix_hash_full_in  = full_in;
        matrix_hash_din      = kyber_din;
        matrix_hash_in_index = kyber_in_index;
      end
    end
    default: begin
      // TODO:  set up the other case, 
      //   or check if having the wire floating is acceptable
      // HASH
      hash_full_in  = hash_s_full_in;
      hash_din      = 0;
      hash_in_index = 0;
      // DEC12
      
      // dec12_din      = 0;
      // dec12_in_index = 0;
      // dec12_readin   = 0;

      // POLYVEC
      polyvec_full_in_b = 0;

      // DECOMP
      decomp_readin   = 0;
      decomp_full_in  = 0;
      decomp_din      = 0;
      decomp_in_index = 0;
    end
  endcase
  case (cbd_type)
    1 : begin // CBD -> NTT
      ntt_readin   = cbd_readout & ntt_s_readin;
      ntt_din_1    = cbd_dout_2; // TODO: why the heck is the input swapped?
      ntt_din_2    = cbd_dout_1;
      ntt_in_index = (cbd_counter - 4) << 1; // is the power of 2 :)
    end
    2 : begin // from cbd to memory 2 (error 2 + mu)
      
    end
    default : begin
      
    end
  endcase
  case (accu2_s_type) // memory type, determining what goes where 
    1 : begin  // decompressed (upcaled) message -> memory 2
      accu2_readin = accu2_s_readin;
      accu2_addr_a = decomp_out_index;
      accu2_addr_b = decomp_out_index;
      accu2_data_a = decomp_dout_1;
      accu2_data_b = decomp_dout_2;
    end
    2 : begin // [cbd error 2] + [decompressed (upscaled) message] -> memory 2
      accu2_readin = accu2_s_readin;
      accu2_addr_a = (cbd_counter - 4) & 7'h7f;
      accu2_addr_b = (cbd_counter - 4) & 7'h7f;
      accu2_data_a = cbd_dout_1;
      accu2_data_b = cbd_dout_2;
    end
    3 : begin
      accu2_readin = accu2_s_readin & invntt_valid_out;
      accu2_addr_a = invntt_out_index >> 1;
      accu2_addr_b = invntt_out_index >> 1;
      accu2_data_a = invntt_dout_1;
      accu2_data_b = invntt_dout_2;
    end
    default : begin
      accu2_readin = accu2_s_readin;
      // accu2_addr_a = 0;
      // accu2_addr_b = 0;
      // accu2_data_a = 0;
      // accu2_data_b = 0;
    end
  endcase

  // TODO: this is specifically to comply with the specs
  matrix_hash_nonce1 = matrix_hash_nonce % KYBER_K;
  matrix_hash_nonce2 = matrix_hash_nonce / KYBER_K;

end

// readn_ok_r = (reset) ? 0 : (readin_ok_r | readin_ok_fsm) & (~full_in);
// better readin_ok_r "latch" like that of decompress1 module >:)
always @(posedge clk or posedge reset) begin
  if(reset) begin
    readin_ok_r <= 0;
  end
  else if(set) begin
    if(readin_ok_fsm)
      readin_ok_r <= 1;
    else if(full_in)
      readin_ok_r <= 0;
  end
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    hash_nonce          <= 0; // is this a good idea? (no)
    hash_counter        <= 0;
    
    cbd_counter         <= 0;
    ntt_counter         <= 0;
    polyvec_counter     <= 0;

    matrix_hash_nonce   <= 0;
    matrix_hash_counter <= 0;
    // matrix_hash_nonce1  <= 0; // 8'hab;
    // matrix_hash_nonce2  <= 0; // 8'hfd;
  end
  else if(set) begin
    if(hash_s_full_in) begin
      hash_counter <= 0;
      hash_nonce   <= hash_nonce + 1; // surely this is fine :>
    end
    if(matrix_hash_s_full_in) begin
      matrix_hash_counter <= 0;
      matrix_hash_nonce   <= matrix_hash_nonce + 1; 
    end

    if(hash_counter_ctrl) begin // used for hash output
      hash_counter <= hash_counter + 1;
    end
    if(ntt_s_cal_en) begin // surely this is fine
      ntt_counter <= 0; // is this fine?
    end
    if(cbd_s_cal_pulse) begin // NOTE: this is specifically for resetting cbd_counter
      cbd_counter <= 0; // no this is not >:(
    end
    if(polyvec_cal_en) begin
      polyvec_counter <= 0;
    end
    if(cbd_counter_ctrl) begin // used for cbd output 
      cbd_counter <= cbd_counter + 1;
    end
    if(ntt_counter_ctrl) begin
      ntt_counter <= ntt_counter + 1;
    end
    if(polyvec_counter_ctrl) begin
      polyvec_counter <= polyvec_counter + 1;
    end
    if(matrix_hash_counter_ctrl) begin
      matrix_hash_counter <= matrix_hash_counter + 1;
    end
  end
end

// ALWAYS BLOCK END ===========================//
endmodule
