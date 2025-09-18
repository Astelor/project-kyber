/*
this thing should be the top level sytem design but I suck at Verilog programming

*/
module kyber_pke_enc #(parameter DEPTH = 8)(
  input clk,
  input set,
  input reset,
  input readin,
  input full_in,
  input [7:0] kyber_din,
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

// CBD ============
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

// NTT ============
// - INPUT
wire             ntt_set;
wire             ntt_readin, ntt_readout;
wire             ntt_cal_en;
wire [15:0]      ntt_din_1,  ntt_din_2;
wire [DEPTH-1:0] ntt_in_index;
// - OUTPUT
wire [15:0]      ntt_dout_1, ntt_dout_2;
wire [DEPTH-1:0] ntt_out_index;
wire             ntt_done;

ntt #(DEPTH) ntt( // (no write during read for this module)
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

// MEMORY

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

kyber_pke_enc_fsm fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  // -- INTERNAL
  .input_ctrl_status  (input_ctrl_status),
  .hash_ctrl_status   (hash_ctrl_status),
  .cbd_ctrl_status    (cbd_ctrl_status),
  .ntt_ctrl_status    (ntt_ctrl_status),
  .polyvec_ctrl_status(polyvec_ctrl_status),
  // OUTPUT
  // -- INTERNAL
  .input_ctrl_cmd     (input_ctrl_cmd),
  .hash_ctrl_cmd      (hash_ctrl_cmd),
  .cbd_ctrl_cmd       (cbd_ctrl_cmd),
  .ntt_ctrl_cmd       (ntt_ctrl_cmd),
  .polyvec_ctrl_cmd   (polyvec_ctrl_cmd),
  
  // -- OUTSIDE
  .done(done)
);

// INPUT CONTROL
wire readin_ok_fsm;
reg [7:0] stage_0;
reg [7:0] stage_1; // managed by the input FSM?
reg [7:0] stage_2;
reg [7:0] stage_3;
reg [7:0] stage_4;

kyber_pke_enc_input_fsm input_fsm(
  .clk(clk),
  .set(set),
  .reset(reset),

  .full_in          (full_in), // outside
  .readin_ok_fsm    (readin_ok_fsm),
  .input_type       (input_type), // to outside 

  .hash_ctrl_status (hash_ctrl_status),
  .input_ctrl_cmd   (input_ctrl_cmd),
  .input_ctrl_status(input_ctrl_status)
);


// HASH CONTROL =============
// note: hash_s_<flag> = it comboes with another signal
wire hash_s_set;
wire hash_s_full_in; // this does combo with another signal
wire hash_s_readin;
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
  .hash_s_full_in  (hash_s_full_in),
  .hash_s_readin   (hash_s_readin),
  .hash_readout    (hash_readout),
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
  // BIG CONTROL
  .hash_ctrl_status(hash_ctrl_status),
  .ntt_ctrl_status (ntt_ctrl_status),
  .cbd_ctrl_cmd    (cbd_ctrl_cmd),
  .cbd_ctrl_status (cbd_ctrl_status)
);

// NTT CONTROL
wire ntt_s_set;
wire ntt_s_readin;
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
  .ntt_s_cal_en       (ntt_cal_en),
  .ntt_readout        (ntt_readout),
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


// POLYVEC CONTROL

wire polyvec_s_set;
wire polyvec_s_readin_a;
wire polyvec_s_readin_b;
// wire [3:0] polyvec_seq;
wire polyvec_s_full_in_a;
wire polyvec_s_full_in_b;

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
  .polyvec_readout    (polyvec_readout),
  .polyvec_s_cal_en   (polyvec_cal_en),

  .polyvec_s_readin_a (polyvec_s_readin_a),
  .polyvec_s_readin_b (polyvec_s_readin_b),
  .polyvec_full_in_a  (polyvec_s_full_in_a),
  .polyvec_full_in_b  (polyvec_s_full_in_b),
  // SOMETHING SOMETHING...
  // .seq                (polyvec_seq),
  // BIG CONTROL
  .ntt_ctrl_status    (ntt_ctrl_status),
  .polyvec_ctrl_cmd   (polyvec_ctrl_cmd),
  .polyvec_ctrl_status(polyvec_ctrl_status)
);

// FSM INSTANCE END ===========================//

// LOCAL REG BEGIN ============================//
reg readin_ok_r;
// LOCAL REG END ==============================//

// ASSIGN BEGIN ===============================//
// -- OUTSIDE
assign readin_ok = readin_ok_r;
// -- HASH
assign hash_set      = set & hash_s_set;
assign hash_readin   = readin & hash_s_readin & readin_ok_r; // >:(

// -- CBD
assign cbd_set    = set & cbd_s_set;
assign cbd_din_1  = hash_dout_1; // TODO: this needs a selector for other hash usage :>
assign cbd_din_2  = hash_dout_2;

// -- NTT
assign ntt_set      = set & ntt_s_set;
assign ntt_readin   = cbd_readout & ntt_s_readin;
assign ntt_din_1    = cbd_dout_2; // TODO: why the heck is the input swapped?
assign ntt_din_2    = cbd_dout_1;
assign ntt_in_index = (cbd_counter - 4) << 1; // is the power of 2 :)

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
assign polyvec_ina_k     = ntt_seq - 1;
assign polyvec_din_a_1   = barr1_t;
assign polyvec_din_a_2   = barr2_t;
assign polyvec_ina_index = ntt_out_index - 2;
assign polyvec_full_in_a = polyvec_s_full_in_a;

// ASSIGN END =================================//

// ALWAYS BLOCK BEGIN =========================//

always @(*) begin
  if(input_type == data_type) begin
    case (input_type) // controlled by INPUT FSM
      1 : begin
        hash_full_in  = /*hash_s_full_in &*/ full_in;
        hash_din      = kyber_din;
        hash_in_index = kyber_in_index;
      end
      2 : begin // only let it do input when command is present
        hash_full_in  = hash_s_full_in;
        hash_din      = 0;
        hash_in_index = 0;
        
        dec12_din      = kyber_din;
        dec12_in_index = kyber_in_index;
        dec12_readin   = readin & readin_ok_r;

        polyvec_din_b_1   = dec12_dout_1; 
        polyvec_din_b_2   = dec12_dout_2; // do it with an fsm because it sucks
        polyvec_readin_b  = dec12_output_ok & polyvec_s_readin_b & readin_ok_r;
        polyvec_inb_k     = (dec12_out_index & 16'h180) >> 7;
        polyvec_inb_index = dec12_out_index << 1;
        polyvec_full_in_b = full_in & polyvec_s_full_in_b;
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
      end
    endcase
  end

  readin_ok_r = (reset) ? 0 : (readin_ok_r | readin_ok_fsm) & (~full_in);
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    hash_nonce   <= 0; // is this a good idea? (no)
    hash_counter <= 0;
    cbd_counter  <= 0;
    ntt_counter  <= 0;
  end
  else if(set) begin
    if(hash_full_in) begin
      hash_counter <= 0;
      hash_nonce <= hash_nonce + 1; // surely this is fine :>
    end
    if(hash_counter_ctrl) begin // used for hash output
      hash_counter <= hash_counter + 1;
    end
    if(ntt_cal_en) begin // surely this is fine
      cbd_counter <= 0;
      ntt_counter <= 0; // is this fine?
    end
    if(cbd_counter_ctrl) begin // used for cbd output 
      cbd_counter <= cbd_counter + 1;
    end
    if(ntt_counter_ctrl) begin
      ntt_counter <= ntt_counter + 1;
    end
  end
end

// ALWAYS BLOCK END ===========================//
endmodule

module input_stage(
  input clk,
  input set,
  input reset,
  input readin,
  input [7:0] din,
  
  output [15:0] dout_1,
  output [15:0] dout_2,
  output ready
);

reg [7:0] stage [0:3]; 
reg [2:0] counter;
always @(posedge clk) begin
  if(reset) begin
    stage[0] <= 0;
    stage[1] <= 0;
    stage[2] <= 0;
    stage[3] <= 0;
    counter <= 0;
  end
  else if(set & readin) begin
    counter <= counter + 1;
    stage[counter] <= din;
    //if()
  end
end

endmodule