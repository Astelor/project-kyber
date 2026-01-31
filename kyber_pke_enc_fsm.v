module kyber_pke_enc_fsm(
  input clk,
  input set,
  input reset,

  // INPUT ========
  // -- INTERNAL
  // MODULE COMMAND AND CONTROL
  output reg [7:0] input_ctrl_cmd,
  input [7:0]      input_ctrl_status,

  output reg [7:0] hash_ctrl_cmd,
  input [7:0]      hash_ctrl_status,

  output reg [7:0] cbd_ctrl_cmd,
  input [7:0]      cbd_ctrl_status,

  output reg [7:0] ntt_ctrl_cmd,
  input [7:0]      ntt_ctrl_status,

  output reg [7:0] polyvec_ctrl_cmd,
  input [7:0]      polyvec_ctrl_status,

  output reg [7:0] invntt_ctrl_cmd,
  input [7:0]      invntt_ctrl_status,

  output reg [7:0] decomp_ctrl_cmd,
  input [7:0]      decomp_ctrl_status,

  output reg [7:0] matrix_hash_ctrl_cmd,
  input [7:0]      matrix_hash_ctrl_status,
  
  output reg [7:0] accu1_ctrl_cmd,
  input [7:0]      accu1_ctrl_status,

  output reg [7:0] accu2_ctrl_cmd,
  input [7:0]      accu2_ctrl_status,
  // OUTPUT =======
  // -- OUTSIDE
  output reg done // to outside
);

localparam IDLE             =  1;

localparam HASH_CBD         =  2;

localparam STAGE_0          =  3;
localparam POLYVEC_EKT      =  4;
localparam STAGE_1          =  5;
localparam MESSAGE          =  6;
localparam STAGE_2          =  7;
localparam SEED             =  8;
localparam STAGE_3          =  9;

localparam HASH_CBD_2_STAGE = 10; // for e2
localparam HASH_CBD_2       = 11;

localparam CBD_E2_STAGE     = 12;
localparam CBD_E2           = 13;

localparam HASH_CBD_1_STAGE = 14; // for e1
localparam HASH_CBD_1       = 15;

localparam CBD_E1_STAGE     = 16;
localparam CBD_E1           = 17;

localparam POLYVEC_MAT_STAGE = 18;
localparam POLYVEC_MAT       = 19; // matrix A

localparam INTT_2_STAGE    = 20; 
localparam INTT_2          = 21;

reg [7:0] curr_state;
reg [7:0] next_state;
always @(posedge clk or posedge reset) begin
  if (reset) begin
    curr_state <= IDLE;
  end
  else if(set) begin
    curr_state <= next_state;
  end
end
// BIG CONTROL NEXT STATE
always @(*) begin
  if(set) begin
    case (curr_state)
      IDLE : begin
        if( (hash_ctrl_status  == 8'h0 ) &
            (cbd_ctrl_status   == 8'h0 ) &
            (input_ctrl_status == 8'h0 )) // input ok
          next_state = HASH_CBD;
        else
          next_state = IDLE; // [randomness outside] -> hash module
      end
      HASH_CBD : begin
        if(input_ctrl_status == 8'h3) // input done
          next_state = STAGE_0;
        else
          next_state = HASH_CBD;
      end
      STAGE_0 : begin
        if(input_ctrl_status == 4'h0)
          next_state = POLYVEC_EKT;
        else
          next_state = STAGE_0;
      end
      POLYVEC_EKT : begin
        if(input_ctrl_status == 8'h13) // ekt_input_done
          next_state = STAGE_1;
        else
          next_state = POLYVEC_EKT;
      end
      STAGE_1 : begin
        if(input_ctrl_status == 8'h0) // what the hell is this for??
          next_state = MESSAGE;
        else
          next_state = STAGE_1;
      end
      MESSAGE : begin // message -> upscale -> buffer
        if(input_ctrl_status == 8'h23) // msg_input_done
          next_state = STAGE_2;
        else
          next_state = MESSAGE;
      end
      STAGE_2 : begin
        if(input_ctrl_status == 8'h0) // input done, input back to init
          next_state = SEED;
        else
          next_state = STAGE_2;
      end
      SEED : begin // seed -> matrix hash stub
        if(input_ctrl_status == 8'h33) // seed_input_done
          next_state = STAGE_3;
        else
          next_state = SEED;
      end
      STAGE_3 : begin // wait for hash_stub to complete sequence 1
        if(hash_ctrl_status == 8'h10)
          next_state = HASH_CBD_2_STAGE;
        else
          next_state = STAGE_3;
      end
      HASH_CBD_2_STAGE : begin // wait for hash_stub to reinitialize
        if(hash_ctrl_status == 8'h0)
          next_state = HASH_CBD_2;
        else
          next_state = HASH_CBD_2_STAGE;
      end
      HASH_CBD_2 : begin // wait for cbd to complete sequence 1 (hash command 2)
        if(cbd_ctrl_status == 8'h10) // cbd status = 8'h10 = sequence done
          next_state = CBD_E2_STAGE;
        else
          next_state = HASH_CBD_2;
      end
      CBD_E2_STAGE : begin // reset cbd from sequence 1 (cbd command 0)
        next_state = CBD_E2;
      end
      CBD_E2 : begin // (cbd command 2)
        if(cbd_ctrl_status == 8'h10) // cbd status = 8'h10 = sequence done
          next_state = HASH_CBD_1_STAGE;
        else
          next_state = CBD_E2;
      end
      HASH_CBD_1_STAGE : begin // wait for hash_stub to reinitialize
        if(hash_ctrl_status == 8'h0)
          next_state = HASH_CBD_1;
        else
          next_state = HASH_CBD_1_STAGE;
      end
      HASH_CBD_1 : begin // wait for cbd to complete sequence 1 (hash command 2)
        if(cbd_ctrl_status == 8'h10) // cbd status = 8'h10 = sequence done
          next_state = CBD_E1_STAGE;
        else
          next_state = HASH_CBD_1;
      end
      CBD_E1_STAGE : begin
        // if(cbd_ctrl_status == 8'h0) // TODO: there's something wrong with the hash->cbd module when it's the first sequence, this is a band-aid
          next_state = CBD_E1;
        // else
        //   next_state = CBD_E1_STAGE;
      end
      CBD_E1 : begin
        if(polyvec_ctrl_status == 8'h10) // sequence done
          next_state = POLYVEC_MAT_STAGE;
        else
          next_state = CBD_E1;
      end
      POLYVEC_MAT_STAGE : begin
        next_state = POLYVEC_MAT;
      end
      POLYVEC_MAT : begin
        if(invntt_ctrl_status == 8'h10)
          next_state = INTT_2_STAGE;
        else
          next_state = POLYVEC_MAT;
      end
      INTT_2_STAGE : begin // for accu1
        next_state = INTT_2;
      end
      INTT_2 : begin
        next_state = INTT_2;
      end
      default:
        $display("forbidden state");
    endcase
  end
end
// BIG CONTROL STATE FLAG
always @(*) begin
  if(reset) begin

    input_cmd(0);
    hash_cmd(0);
    cbd_cmd(0);
    ntt_cmd(0);
    polyvec_cmd(0);
    invntt_cmd(0);
    decomp_cmd(0);
    accu2_cmd(0);

    done = 0;
  end
  else if(set) begin
    case (curr_state)
      IDLE : begin
        input_cmd(0);
        hash_cmd(0);
        cbd_cmd(0);
        ntt_cmd(0);
        polyvec_cmd(0);
        invntt_cmd(0);
        decomp_cmd(0);
        accu1_cmd(0);
        accu2_cmd(0);
        matrix_hash_cmd(0);

      end
      HASH_CBD : begin
        input_cmd(1);
        hash_cmd(1);
        cbd_cmd(1);
        ntt_cmd(1);
        polyvec_cmd(1);
        invntt_cmd(1);
        accu1_cmd(1); // the accumulator_1 would be waiting anyway

      end
      // INPUT ==============
      STAGE_0 : begin
        // when hash finished the output (check status), call for the next input
        input_cmd(0); // reset the input fsm
      end
      POLYVEC_EKT : begin
        input_cmd(2);
      end
      STAGE_1 : begin
        input_cmd(0);
      end
      MESSAGE : begin
        input_cmd(3);
      end
      STAGE_2 : begin
        input_cmd(0);
        decomp_cmd(1);
        accu2_cmd(1);
      end
      SEED : begin
        input_cmd(4);
        matrix_hash_cmd(1);
      end
      STAGE_3 : begin
        input_cmd(0);
      end
      // HASH E2 COMMAND ====
      HASH_CBD_2_STAGE : begin
        hash_cmd(0);
      end
      HASH_CBD_2 : begin // for e2 (to be added with upscaled message)
        hash_cmd(2);
      end
      CBD_E2_STAGE : begin
        cbd_cmd(0);
      end
      CBD_E2 : begin
        cbd_cmd(2);
      end
      // HASH E1 COMMAND ====
      HASH_CBD_1_STAGE : begin
        hash_cmd(0);
      end
      HASH_CBD_1 : begin // for e2 (to be added with upscaled message)
        // accu1_cmd(1);
        hash_cmd(3);
      end
      CBD_E1_STAGE : begin
        cbd_cmd(0);
      end
      CBD_E1 : begin
        cbd_cmd(3);
      end
      POLYVEC_MAT_STAGE : begin
        polyvec_cmd(0);
      end
      POLYVEC_MAT : begin
        polyvec_cmd(2);
      end
      INTT_2_STAGE : begin
        invntt_cmd(0);
      end
      INTT_2 : begin
        invntt_cmd(2);
      end
    endcase
  end
end

task input_cmd(input [7:0] cmd);
begin
  input_ctrl_cmd = cmd;
end
endtask

task hash_cmd(input [7:0] cmd);
begin
  hash_ctrl_cmd = cmd;
end
endtask

task cbd_cmd(input [7:0] cmd);
begin
  cbd_ctrl_cmd = cmd;
end
endtask

task ntt_cmd(input [7:0] cmd);
begin
  ntt_ctrl_cmd = cmd;
end
endtask

task polyvec_cmd(input [7:0] cmd);
begin
  polyvec_ctrl_cmd = cmd;
end
endtask

task invntt_cmd(input [7:0] cmd);
begin
  invntt_ctrl_cmd = cmd;
end
endtask

task decomp_cmd(input [7:0] cmd);
begin
  decomp_ctrl_cmd = cmd;
end
endtask

task matrix_hash_cmd(input [7:0] cmd);
begin
  matrix_hash_ctrl_cmd = cmd;
end
endtask

task accu1_cmd(input [7:0] cmd);
begin
  accu1_ctrl_cmd = cmd;
end
endtask

task accu2_cmd(input [7:0] cmd);
begin
  accu2_ctrl_cmd = cmd;
end
endtask

endmodule

// INPUT FSM
module kyber_pke_enc_input_fsm(
  input clk,
  input set,
  input reset,

  input full_in,
  output reg readin_ok_fsm,
  output reg [3:0] input_type,

  input [7:0] hash_ctrl_status,
  input [7:0] polyvec_ctrl_status,
  input [7:0] decomp_ctrl_status,
  input [7:0] matrix_hash_ctrl_status,
  input [7:0] input_ctrl_cmd,
  output reg [7:0] input_ctrl_status
);

localparam IDLE               =  1;
localparam CHOOSE             =  2;
localparam HASH_INPUT_STAGE   =  3;
localparam HASH_INPUT_READY   =  4; // pulse
localparam HASH_INPUT_ACTIVE  =  5;
localparam HASH_INPUT_DONE    =  6;

localparam EKT_INPUT_STAGE    = 11;
localparam EKT_INPUT_READY    = 12; // pulse
localparam EKT_INPUT_ACTIVE   = 13;
localparam EKT_INPUT_DONE     = 14;

localparam MSG_INPUT_STAGE    = 21;
localparam MSG_INPUT_READY    = 22; // pulse
localparam MSG_INPUT_ACTIVE   = 23;
localparam MSG_INPUT_DONE     = 24;
// i don't think it needs a handshake? it's indexed

// SEED for the public key matrix generation
localparam SEED_INPUT_STAGE   = 31;
localparam SEED_INPUT_READY   = 32; // pulse
localparam SEED_INPUT_ACTIVE  = 33;
localparam SEED_INPUT_DONE    = 34;

reg [7:0] curr_state;
reg [7:0] next_state;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    curr_state <= IDLE;
  end
  else if(set) begin
    curr_state <= next_state;
  end
end

// INPUT CONTROL NEXT STATE
always @(*) begin
  if(set) begin
    case (curr_state)
      IDLE : begin
        if(input_ctrl_cmd == 0) // only choose when cmd resetted
          next_state = CHOOSE;
        else
          next_state = IDLE;
      end
      CHOOSE : begin
        case (input_ctrl_cmd)
          0 : next_state = CHOOSE;
          1 : next_state = HASH_INPUT_STAGE;
          2 : next_state = EKT_INPUT_STAGE;
          3 : next_state = MSG_INPUT_STAGE;
          4 : next_state = SEED_INPUT_STAGE;
          default: next_state = CHOOSE;
        endcase
      end
      // HASH =========================
      HASH_INPUT_STAGE : begin
        if(hash_ctrl_status == 8'h1)
          next_state = HASH_INPUT_READY;
        else
          next_state = HASH_INPUT_STAGE;
      end
      HASH_INPUT_READY : begin
        next_state = HASH_INPUT_ACTIVE;
      end
      HASH_INPUT_ACTIVE : begin
        if(full_in)
          next_state = HASH_INPUT_DONE;
        else
          next_state = HASH_INPUT_ACTIVE;
      end
      HASH_INPUT_DONE : begin
        if(hash_ctrl_status == 8'h3) // hash input is done
          next_state = IDLE;
        else
          next_state = HASH_INPUT_DONE;
      end
      // EKT ==========================
      EKT_INPUT_STAGE : begin
        if(polyvec_ctrl_status == 1)
        // there's no conflict here,
        // so I think polyvec doesn't need an explicit flag
        // to signal the input fsm
        // TODO: so does it need one?
          next_state = EKT_INPUT_READY;
        else
          next_state = EKT_INPUT_STAGE;
      end
      EKT_INPUT_READY : begin
        next_state = EKT_INPUT_ACTIVE;
      end
      EKT_INPUT_ACTIVE :begin
        if(polyvec_ctrl_status == 2)           
          next_state = EKT_INPUT_DONE;
        else
          next_state = EKT_INPUT_ACTIVE;
      end
      EKT_INPUT_DONE : begin
        // do I need to have polyvec do a status code??
        // or can I just have it use the ful_in signal?
        // it's a bit redundant to give polyvec two concurrent fsms
        // simply for the use of two inputs
        // or is it necessary?
        if(input_ctrl_cmd == 0)
          next_state = IDLE; // ?
        else
          next_state = EKT_INPUT_DONE;
      end
      // MESSAGE ======================
      MSG_INPUT_STAGE : begin
        // no conflict here :)
        if(decomp_ctrl_status == 1) // INPUT
          next_state = MSG_INPUT_READY;
        else
          next_state = MSG_INPUT_STAGE;
      end
      MSG_INPUT_READY : begin
        next_state = MSG_INPUT_ACTIVE;
      end
      MSG_INPUT_ACTIVE : begin
        if(decomp_ctrl_status == 2) // OUTPUT STAGE
          next_state = MSG_INPUT_DONE;
        else
          next_state = MSG_INPUT_ACTIVE;
      end
      MSG_INPUT_DONE : begin
        if(input_ctrl_cmd == 0)
          next_state = IDLE;
        else
          next_state = MSG_INPUT_DONE;
      end
      // SEED =========================
      SEED_INPUT_STAGE : begin
        if(matrix_hash_ctrl_status == 1)
          next_state = SEED_INPUT_READY;
        else
          next_state = SEED_INPUT_STAGE;
      end
      SEED_INPUT_READY : begin
        next_state = SEED_INPUT_ACTIVE;
      end
      SEED_INPUT_ACTIVE : begin
        if(full_in)
          next_state = SEED_INPUT_DONE;
        else
          next_state = SEED_INPUT_ACTIVE;
      end
      SEED_INPUT_DONE : begin
        if(input_ctrl_cmd == 0)
          next_state = IDLE;
        else
          next_state = SEED_INPUT_DONE;
      end
      default:
        $display("forbidden state");
    endcase
  end
end

// INPUT FLAG
always @(*) begin
  if(reset) begin
    status(0);
    type(0);
    readin_ok_fsm = 0;
  end
  else if(set) begin
    case (curr_state)
      IDLE : begin
        status(0);
        type(0);
      end
      // HASH ===============
      HASH_INPUT_STAGE : begin
        status(1);
        type(1);
      end
      HASH_INPUT_READY : begin
        readin_ok_fsm = 1; // pulse high
      end
      HASH_INPUT_ACTIVE : begin
        status(2);
        readin_ok_fsm = 0; // pulse low
      end
      HASH_INPUT_DONE : begin
        status(3);
        // type(0); // no more input :>
      end
      // EKT ================
      EKT_INPUT_STAGE : begin
        status(8'h11);
        type(2);
      end
      EKT_INPUT_READY : begin
        readin_ok_fsm = 1; // pulse high
      end
      EKT_INPUT_ACTIVE :begin
        status(8'h12);
        readin_ok_fsm = 0; // pulse low
      end
      EKT_INPUT_DONE : begin
        status(8'h13);
      end
      // MSG ================
      MSG_INPUT_STAGE : begin
        status(8'h21);
        type(3);
      end
      MSG_INPUT_READY : begin
        readin_ok_fsm = 1; // pulse high
      end
      MSG_INPUT_ACTIVE : begin
        status(8'h22);
        readin_ok_fsm = 0; // pulse low
      end
      MSG_INPUT_DONE : begin
        status(8'h23);
      end
      // SEED ===============
      SEED_INPUT_STAGE : begin
        status(8'h31);
        type(4);
      end
      SEED_INPUT_READY : begin
        readin_ok_fsm = 1; // pulse high
      end
      SEED_INPUT_ACTIVE : begin
        status(8'h32);
        readin_ok_fsm = 0; // pulse low
      end
      SEED_INPUT_DONE : begin
        status(8'h33);
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  input_ctrl_status = st;
end
endtask

task type(input [3:0] tp);
begin
  input_type = tp;
end
endtask

endmodule

// HASH FSM
module kyber_pke_enc_hash_fsm(
// Controlls all the signals for hash module
  input clk,
  input set,
  input reset,

  // INPUT
  // -- FROM MODULE
  input hash_readin_ok,
  input hash_done,
  // OUTPUT
  // -- TO MODULE (note: these are masks/selectors)
  output reg hash_s_set,
  output reg hash_s_full_in,
  output reg hash_s_readin,
  output reg hash_s_readout,
  // output reg [3:0] hash_type,
  output reg counter_ctrl,
  input [7:0] counter,
  // output reg hash_nonce,
  // BIG CONTROL
  input [7:0] input_ctrl_status,
  input [7:0] cbd_ctrl_status,
  input [7:0] hash_ctrl_cmd,
  output reg [7:0] hash_ctrl_status
);

// HASH STATES
localparam IDLE          = 1;
localparam READY_INPUT   = 2;
localparam INPUT         = 3;
localparam START_CAL     = 4;
localparam CALCULATE     = 5;
localparam OUTPUT_READY  = 6;
localparam OUTPUT        = 7;
localparam OUTPUT_DONE   = 8;
localparam SEQUENCE_DONE = 9;

localparam CHOOSE        = 10;
localparam STAGE_0       = 11;

reg [7:0] curr_state;
reg [7:0] next_state;

reg [3:0] seq; // internal sequence
reg [3:0] seq_type;
// NEXT STATE
always @(posedge clk or posedge reset) begin
  if (reset) begin
    curr_state <= IDLE;
  end
  else if(set) begin
    curr_state <= next_state;
  end
end

// HASH NEXT STATE
always @(*) begin
  if(set) begin
    case (curr_state)
      IDLE : begin
        if(hash_readin_ok /*& (hash_ctrl_cmd == 8'h0)*/)
          // wait until the module re-initilize
          next_state = CHOOSE;
        else
          next_state = IDLE;
      end
      CHOOSE : begin // sequence type chooser
        case (hash_ctrl_cmd)
          8'h1 : begin
            next_state = READY_INPUT;
          end
          8'h2 : begin
            next_state = START_CAL;
          end
          8'h3 : begin
            next_state = START_CAL; // for error1
          end
          default: begin
            next_state = CHOOSE;
          end
        endcase
      end
      READY_INPUT : begin
        if((input_ctrl_status == 8'h1) //&
           /*(hash_ctrl_cmd     == 8'h1)*/) // do input please
          next_state = INPUT;
        else
          next_state = READY_INPUT;
      end
      INPUT : begin
        if(input_ctrl_status == 8'h3) // done
          next_state = START_CAL;
        else
          next_state = INPUT;
      end
      START_CAL : begin
        // if(hash_done == 0)
        // TODO: full_in pulse is coupled with nounce, in order to implement this layer of detection it needs a refactor
          next_state = STAGE_0;
        // else
          // next_state = START_CAL;
      end
      STAGE_0 : begin // wait for hash_done to return to 0
        if(hash_done == 0)
          next_state = CALCULATE;
        else
          next_state = STAGE_0;
      end 
      CALCULATE : begin
        if(hash_done) // hash calculate is done
          next_state = OUTPUT_READY;
        else
          next_state = CALCULATE;
      end
      OUTPUT_READY : begin
        if(cbd_ctrl_status == 8'h1)
          next_state = OUTPUT;
        else
          next_state = OUTPUT_READY;
      end
      OUTPUT : begin
        if(counter == 16)
          next_state = OUTPUT_DONE;
        else
          next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        case (seq_type)
          8'h1 : begin
            if(seq >= 3)
              next_state = SEQUENCE_DONE;
            else
              next_state = START_CAL;
          end
          8'h2 : begin
            next_state = SEQUENCE_DONE;            
          end
          8'h3 : begin
            if(seq >= 3)
              next_state = SEQUENCE_DONE;
            else
              next_state = START_CAL;
          end
          default: begin
            next_state = OUTPUT_DONE;
          end 
        endcase
      end
      SEQUENCE_DONE : begin
        // waits for the command to return to 0
        if(hash_ctrl_cmd == 8'h0)
          next_state = IDLE;
        else
          next_state = SEQUENCE_DONE;
      end
      // SEQUENCE_DONE_2 : begin
      //   next_state = CHOOSE;
      // end
      // SEQUENCE_DONE_3 : begin
      //   if(hash_ctrl_cmd == 0)
      //     next_state = IDLE; 
      //   else
      //     next_state = SEQUENCE_DONE_3;
      // end
      default:
        $display("forbidden state");
    endcase
  end
end

// HASH STATE FLAG
always @(*) begin
  if(reset) begin
    status(0);

    hash_s_set     = 0;
    hash_s_full_in = 0;
    hash_s_readin  = 0;
    hash_s_readout   = 0;
    // hash_type   = 0;
    counter_ctrl   = 0;

    seq = 0;
    seq_type = 0;
  end
  else if(set) begin
    case (curr_state)
      IDLE : begin
        status(0);
        hash_s_set = 1; // readin_ok flag is behind a set flag bruhhhh
        hash_s_full_in = 0;
        hash_s_readin = 0;
        seq = 0;
      end
      CHOOSE : begin
        // shares status with IDLE?
        case (hash_ctrl_cmd)
          8'h1 : seq_type = 1;
          8'h2 : seq_type = 2;
          8'h3 : seq_type = 3;
        endcase
      end
      READY_INPUT : begin
        status(1);
      end
      INPUT : begin
        status(2);
        hash_s_readin = 1;
      end
      START_CAL : begin
        seq = seq + 1;
        hash_s_full_in = 1; // pulse high
      end
      STAGE_0 : begin
        hash_s_full_in = 0; // pulse low
      end
      CALCULATE : begin
        status(3);
        hash_s_readin = 0;
      end
      OUTPUT_READY : begin
        status(4);
      end
      OUTPUT : begin
        status(5);
        hash_s_readout = 1;
        counter_ctrl = 1;
      end
      OUTPUT_DONE : begin
        status(6);
        hash_s_readout = 0;
        counter_ctrl = 0;
      end
      SEQUENCE_DONE : begin
        status(8'h10);
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  hash_ctrl_status = st;
end
endtask

endmodule

// CBD FSM
module kyber_pke_enc_cbd_fsm(
  input clk,
  input set,
  input reset,

  // INPUT
  // -- FROM BIG CONTROL
  // -- FROM MODULE
  input cbd_ok_in,
  input cbd_ok_out,
  // OUTPUT
  // -- TO MODULES
  output reg cbd_s_set,
  output reg cbd_s_readin,
  output reg cbd_readout,

  output reg counter_ctrl,
  input [7:0] counter, // 0~255
  output reg cbd_s_cal_pulse,
  output [3:0] cbd_s_type, // 1 goes to ntt, 2 goes to memory 
  output [3:0] cbd_s_seq,

  // BIG CONTROL
  input [7:0] ntt_ctrl_status,
  input [7:0] hash_ctrl_status,
  input [7:0] accu1_ctrl_status,
  input [7:0] accu2_ctrl_status,
  input [7:0] cbd_ctrl_cmd,
  output reg [7:0] cbd_ctrl_status
);

localparam IDLE          = 1;
localparam READY_INPUT   = 2;
localparam INPUT         = 3;
localparam START_CAL     = 4;
localparam CALCULATE     = 5;
localparam OUTPUT_READY  = 6;
localparam OUTPUT        = 7;
localparam OUTPUT_DONE   = 8;
localparam SEQUENCE_DONE = 9;

localparam CHOOSE        = 10;

reg [7:0] curr_state;
reg [7:0] next_state;

reg [3:0] seq; // internal sequence
reg [3:0] seq_type;

assign cbd_s_type = seq_type;
assign cbd_s_seq = seq;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    curr_state <= IDLE;
  end
  else if(set) begin
    curr_state <= next_state;
  end
end

always @(*) begin
  if(set) begin
    case (curr_state)
      IDLE : begin
        if(cbd_ok_in)
          next_state = CHOOSE;
        else
          next_state = IDLE;
      end
      CHOOSE : begin
        case (cbd_ctrl_cmd)
          8'h1 : next_state = READY_INPUT; // y
          8'h2 : next_state = READY_INPUT; // e2
          8'h3 : next_state = READY_INPUT; // e1
          default: next_state = CHOOSE;
        endcase
      end
      READY_INPUT : begin
        if(hash_ctrl_status == 8'h5) // hash output ready
          next_state = INPUT;
        else
          next_state = READY_INPUT;
      end
      INPUT : begin
        if(hash_ctrl_status == 8'h6) // hash output is done
          next_state = START_CAL;
        else
          next_state = INPUT;
      end
      START_CAL : begin
        next_state = CALCULATE;
      end
      CALCULATE : begin
        if(cbd_ok_out)
          next_state = OUTPUT_READY;
        else
          next_state = CALCULATE;
      end
      OUTPUT_READY : begin
        case(seq_type)
          8'h1 : begin // y
            if(ntt_ctrl_status == 8'h1) // NTT input ready
              next_state = OUTPUT;
            else
              next_state = OUTPUT_READY;
          end
          8'h2 : begin // e2
            // TODO: to where?
            if(accu2_ctrl_status == 4) // E2_READY
              next_state = OUTPUT;
            else
              next_state = OUTPUT_READY;
          end
          8'h3 : begin // e1
            if(accu1_ctrl_status == 5) // E1 ready
              next_state = OUTPUT;
            else
              next_state = OUTPUT_READY;
          end
        endcase
      end
      OUTPUT : begin
        if(cbd_ok_out == 0) // can be the counter too :>
          next_state = OUTPUT_DONE;
        else
          next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        case (seq_type)
          8'h1 : begin // y
            if(seq >= 3)
              next_state = SEQUENCE_DONE;
            else
              next_state = READY_INPUT;
          end
          8'h2 : begin // e2
            next_state = SEQUENCE_DONE;
          end
          8'h3 : begin // e1
            if(seq >= 3)
              next_state = SEQUENCE_DONE;
            else
              next_state = READY_INPUT;
          end
          default: begin
            next_state = OUTPUT_DONE;
          end 
        endcase
      end
      SEQUENCE_DONE : begin
        if(cbd_ctrl_cmd == 0) // wait for BIG control to acknowledge this (by resetting it with commnad 0)
          next_state = IDLE;
        else
          next_state = SEQUENCE_DONE;
      end
      default:
        $display("forbidden state");
    endcase
  end
end

// CBD FLAG
always @(*) begin
  if(reset) begin
    status(0);
    cbd_s_set        = 0;
    cbd_s_readin     = 0;
    cbd_readout      = 0;
    counter_ctrl     = 0;
    cbd_s_cal_pulse  = 0;
    seq              = 0;
    seq_type         = 0;
  end
  else if(set) begin
    case (curr_state)
      IDLE : begin
        status(0);
        cbd_s_set = 1;
        seq_type = 0;
        seq = 0;
      end
      CHOOSE : begin
        case (cbd_ctrl_cmd)
          8'h1 : seq_type = 1;
          8'h2 : seq_type = 2;
          8'h3 : seq_type = 3;
        endcase
      end
      READY_INPUT : begin
        status(1);
      end
      INPUT : begin
        status(2);
        cbd_s_readin = 1;
      end
      START_CAL : begin
        seq = seq + 1; // TODO: maybe this one needs to be in a clocked loop
        cbd_s_cal_pulse = 1;
      end
      CALCULATE : begin
        cbd_s_readin    = 0;
        cbd_s_cal_pulse = 0;
        status(3);
      end
      OUTPUT_READY : begin
        status(4);
      end
      OUTPUT : begin
        status(5);
        cbd_readout  = 1;
        counter_ctrl = 1;
      end
      OUTPUT_DONE : begin
        status(6);
        cbd_readout  = 0;
        counter_ctrl = 0;
      end
      SEQUENCE_DONE : begin
        status(8'h10);
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  cbd_ctrl_status = st;
end
endtask

endmodule

// NTT FSM
module kyber_pke_enc_ntt_fsm(
  input clk,
  input set,
  input reset,
  // TODO why doesn't NTT has a readin_ok? >:(
  input ntt_done,

  output reg ntt_s_set,
  output reg ntt_s_readin,
  output reg ntt_s_cal_en, // this is like the full in thing ok
  output reg ntt_s_readout,

  input [7:0] cbd_counter,

  output reg counter_ctrl,
  input [7:0] counter,
  output [3:0] ntt_seq,

  input [7:0] cbd_ctrl_status,
  input [7:0] polyvec_ctrl_status,
  input [7:0] ntt_ctrl_cmd,
  output reg [7:0] ntt_ctrl_status
);

localparam IDLE          = 1;
localparam READY_INPUT   = 2;
localparam INPUT         = 3;
localparam START_CAL     = 4;
localparam CALCULATE     = 5;
localparam OUTPUT_READY  = 6;
localparam OUTPUT        = 7;
localparam OUTPUT_DONE   = 8;
localparam SEQUENCE_DONE = 9;

reg [7:0] curr_state;
reg [7:0] next_state;

reg [3:0] seq;

assign ntt_seq = seq;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= IDLE;
  end
  else if(set) begin
    curr_state <= next_state;
  end
end
// NTT NEXT STATE
always @(*) begin
  if(set) begin
    case (curr_state)
      IDLE : begin
        if(ntt_done == 1) // ntt init'd
          next_state = READY_INPUT;
        else
          next_state = IDLE;
      end
      READY_INPUT : begin
        if((cbd_ctrl_status == 8'h4) &
           (ntt_ctrl_cmd    == 8'h1)   ) // cbd output ready
          next_state = INPUT;
        else
          next_state = READY_INPUT;
      end
      INPUT : begin
        if(cbd_counter == 131/*cbd_ctrl_status == 8'h6*/)
          next_state = START_CAL;
        else
          next_state = INPUT;
      end
      START_CAL : begin
        next_state = CALCULATE;
      end
      CALCULATE : begin
        if(ntt_done)
          next_state = OUTPUT_READY;
        else
          next_state = CALCULATE;
      end
      OUTPUT_READY : begin
        if(polyvec_ctrl_status == 2)
          next_state = OUTPUT;
        else
          next_state = OUTPUT_READY;
      end
      OUTPUT : begin
        if(counter == 131)
          next_state = OUTPUT_DONE;
        else
          next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        if(seq >= 3) begin
          next_state = SEQUENCE_DONE;
        end
        // else if(ntt_ctrl_cmd == 1)
          // TODO: this should include a condition that finish the sequence
        else
          next_state = IDLE;
          // next_state = OUTPUT_DONE;
      end
      SEQUENCE_DONE : begin
        next_state = SEQUENCE_DONE;
      end
      default: begin
        $display("forbidden state");
      end
    endcase
  end
end
// NTT FLAG
always @(*) begin
  if(reset) begin
    status(0);
    ntt_s_set    = 0;
    ntt_s_readin = 0;
    ntt_s_cal_en = 0;
    ntt_s_readout  = 0;
    counter_ctrl = 0;
    seq          = 0;
  end
  else if(set) begin
    case (curr_state)
      IDLE : begin
        status(0);
        ntt_s_set = 1;
      end
      READY_INPUT : begin
        status(1);
      end
      INPUT : begin
        status(2);
        ntt_s_readin = 1;
      end
      START_CAL : begin
        ntt_s_readin = 0;
        ntt_s_cal_en = 1;
        seq = seq + 1;
      end
      CALCULATE : begin
        status(3);
        ntt_s_cal_en = 0;
      end
      OUTPUT_READY : begin
        status(4);
      end
      OUTPUT : begin
        status(5);
        ntt_s_readout  = 1;
        counter_ctrl = 1;
      end
      OUTPUT_DONE : begin
        status(6);
        ntt_s_readout  = 0;
        counter_ctrl = 0;
      end
      SEQUENCE_DONE : begin
        status(8'h10);
		  // ntt_s_set = 0;
      end
    endcase
  end
end


task status(input [7:0] st);
begin
  ntt_ctrl_status = st;
end
endtask

endmodule

// POLYVEC FSM
module kyber_pke_enc_polyvec_fsm(
  input clk,
  input set,
  input reset,

  // INPUT
  input polyvec_done,
  input polyvec_readin_a_ok,
  input polyvec_readin_b_ok,

  // OUTPUT
  output reg polyvec_s_set,
  output reg polyvec_s_readout,
  output reg polyvec_s_cal_en,

  output reg polyvec_s_readin_a,
  output reg polyvec_s_readin_b,
  output reg polyvec_s_full_in_a,
  output reg polyvec_s_full_in_b,

  output wire [3:0] polyvec_a_s_type, // for managing which type of data [polyvec_a (?)] is accepting
  output reg counter_ctrl,
  input [7:0] counter,
  output reg [3:0] seq,

  // BIG CONTROL
  input [7:0]      input_ctrl_status,
  input [7:0]      ntt_ctrl_status,
  input [7:0]      invntt_ctrl_status,
  input [7:0]      matrix_hash_ctrl_status,
  input [7:0]      polyvec_ctrl_cmd,
  output reg [7:0] polyvec_ctrl_status
);

localparam IDLE          = 1;
localparam READY_INPUT   = 2;
localparam INPUT_0       = 11;
localparam INPUT_1       = 3;
localparam INPUT_2       = 4;
localparam START_CAL     = 5;
localparam CALCULATE     = 6;
localparam OUTPUT_READY  = 7;
localparam OUTPUT        = 8;
localparam OUTPUT_DONE   = 9;
localparam SEQUENCE_DONE = 10;

localparam CHOOSE          = 12;

localparam MAT_STAGE           = 13;
localparam MAT_INPUT_READY     = 14;
localparam MAT_INPUT           = 15;
localparam MAT_START_CAL_STAGE = 16;

reg [7:0] curr_state;
reg [7:0] next_state;
reg [3:0] seq_type; // controlled by fsm command

assign polyvec_a_s_type = seq_type;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= IDLE;
  end
  else if (set) begin
    curr_state <= next_state;
  end
end

// can I have two fsms for A and B each?
// POLYVEC NEXT STATE
always @(*) begin
  if(set) begin
    case(curr_state)
      IDLE : begin // TODO: for matrix A it needs a choosen stage like input
        if(polyvec_readin_a_ok & polyvec_readin_b_ok)
          next_state = CHOOSE;
        else
          next_state = IDLE;
      end
      CHOOSE : begin
        case (polyvec_ctrl_cmd) // give it the command anyways
          1 : next_state = READY_INPUT;
          2 : next_state = MAT_STAGE;
          default: next_state = CHOOSE;
        endcase
      end
      READY_INPUT : begin
        if(/*(ntt_ctrl_status  == 8'h4) & */
           (input_ctrl_status == 8'h11)  ) // NTT output ready
          next_state = INPUT_0;
        else
          next_state = READY_INPUT;
      end
      INPUT_0 : begin
        if(polyvec_readin_b_ok == 0)
          next_state = INPUT_1;
        else
          next_state = INPUT_0; 
      end
      INPUT_1 : begin
        if(ntt_ctrl_status == 8'h10) // ntt output done
          next_state = INPUT_2;
        else
          next_state = INPUT_1;
      end
      INPUT_2 : begin
        if((polyvec_readin_a_ok == 0 ) &
           (polyvec_readin_b_ok == 0 )  ) // waits until both inputs are done
          next_state = START_CAL;
        else
          next_state = INPUT_2;
      end
      START_CAL : begin
        if(polyvec_done == 0)
          next_state = CALCULATE;
        else
          next_state = START_CAL;
      end
      CALCULATE : begin
        if(polyvec_done)
          next_state = OUTPUT_READY;
        else
          next_state = CALCULATE;
      end
      OUTPUT_READY : begin
        if(invntt_ctrl_status == 1) // ready input
          next_state = OUTPUT;
        else
          next_state = OUTPUT_READY;
        // should lock memory bank a immediately with full_in_a
      end
      OUTPUT : begin // use a counter here
        if(counter == 129) // TODO the polyvec output over shot by 2~3, perhaps fix?
          next_state = OUTPUT_DONE;
        else
          next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        case (seq_type)
          1 : begin
            next_state = SEQUENCE_DONE;
          end
          2 : begin
            if(seq >= 3)
              next_state = SEQUENCE_DONE;
            else
              next_state = MAT_STAGE;
          end
          default: next_state = OUTPUT_DONE;
        endcase
      end
      SEQUENCE_DONE : begin
        if(polyvec_ctrl_cmd == 0)
          next_state = IDLE;
        else
          next_state = SEQUENCE_DONE;
      end
      MAT_STAGE : begin
        if(polyvec_readin_a_ok == 0)
          next_state = MAT_INPUT_READY;
        else
          next_state = MAT_STAGE;
      end
      MAT_INPUT_READY : begin
        if(matrix_hash_ctrl_status == 8'h4) // output ready
          next_state = MAT_INPUT;
        else
          next_state = MAT_INPUT_READY;
      end
      MAT_INPUT : begin
        if(matrix_hash_ctrl_status == 8'h11) // sequence stage (the input has been done 3 times)
          next_state = MAT_START_CAL_STAGE;
        else
          next_state = MAT_INPUT;
      end
      MAT_START_CAL_STAGE : begin 
        next_state = START_CAL;
      end
      default: begin
        $display("forbidden state");
      end
    endcase
  end
end

// POLYVEC FLAG
always @(*) begin
  if(reset) begin
    status(0);
    // type(0);
    seq = 0;
    seq_type = 0;
    polyvec_s_set        = 0;
    polyvec_s_readout    = 0;
    polyvec_s_cal_en     = 0;
    polyvec_s_readin_a   = 0;
    polyvec_s_readin_b   = 0;
    polyvec_s_full_in_a  = 0;
    polyvec_s_full_in_b  = 0;
    counter_ctrl         = 0;
    // reset flags here
  end
  else if(set) begin
    case(curr_state)
      IDLE : begin
        status(0);
        // type(0);
        seq = 0;
        seq_type = 0;
        polyvec_s_set = 1;
        // flags go here
      end
      CHOOSE : begin
        case (polyvec_ctrl_cmd)
          1 : seq_type = 1; 
          2 : seq_type = 2;
          default : seq_type = 0;
        endcase
      end
      READY_INPUT : begin
        // type(1);
      end
      INPUT_0 : begin
        status(1);
        polyvec_s_readin_a = 1;
        polyvec_s_readin_b  = 1; // full_in where??
        polyvec_s_full_in_b = 1; // this is coupled with the external full_in signal
      end
      INPUT_1 : begin
        status(2);
      end
      INPUT_2 : begin
        polyvec_s_full_in_a = 1; // this waits on readin_a_ok, which is controlled by full_in 
      end
      START_CAL : begin
        polyvec_s_full_in_a = 0;
        polyvec_s_full_in_b = 0;
        polyvec_s_cal_en  = 1;
        seq = seq + 1;
      end
      CALCULATE : begin
        status(3);
        polyvec_s_cal_en  = 0;
        polyvec_s_readin_a = 0;
        polyvec_s_readin_b = 0;
      end
      OUTPUT_READY : begin
        status(4);
      end
      OUTPUT : begin
        status(5);
        polyvec_s_readout = 1;
        counter_ctrl = 1;
      end
      OUTPUT_DONE : begin
        status(6);
        polyvec_s_readout = 0;
        counter_ctrl = 0;
      end
      SEQUENCE_DONE : begin
        status(8'h10);
        // type(0);
        // polyvec_s_set = 0;
        // polyvec_full_in_a = 1;
      end
      MAT_STAGE : begin
        polyvec_s_full_in_a = 1; // set polyvec a input to full in
        polyvec_s_full_in_b = 0;
        status(8'h13);
      end
      MAT_INPUT_READY : begin
        status(8'h11);
        // type(2);
        polyvec_s_full_in_a = 0; // set polyvec b input to full in
      end
      MAT_INPUT : begin
        status(8'h12);
        polyvec_s_readin_b = 1;
      end
      MAT_START_CAL_STAGE : begin
        polyvec_s_full_in_b = 1;
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  polyvec_ctrl_status = st;
end
endtask

endmodule


// INVNTT FSM
module kyber_pke_enc_invntt_fsm(
  input clk,
  input set,
  input reset,

  // INPUT
  input invntt_readin_ok,
  input invntt_done,

  // OUTPUT
  output reg invntt_s_set,
  output reg invntt_s_readin,
  output reg invntt_s_readout,
  output reg invntt_s_cal_en,
  output reg invntt_s_full_in,
  output [3:0] invntt_s_type,
  output [3:0] invntt_s_seq,

  input [7:0] polyvec_ctrl_status,
  input [7:0] accu1_ctrl_status, // i guess i can keep a sequence number to go with it?
  // input [3:0] accu1_seq, // indicate which "accumulator1" it is currently talking to, it is controlled by seq here
  input [7:0] accu2_ctrl_status,
  input [7:0] invntt_ctrl_cmd,
  output reg [7:0] invntt_ctrl_status
);

localparam IDLE          = 1;
localparam READY_INPUT   = 2;
localparam INPUT         = 3;
localparam START_CAL     = 4;
localparam START_CAL_2   = 10; // because of full_in
localparam CALCULATE     = 5;
localparam OUTPUT_READY  = 6;
localparam OUTPUT        = 7;
localparam OUTPUT_DONE   = 8;
localparam SEQUENCE_DONE = 9;
localparam CHOOSE        = 11;

reg [7:0] curr_state;
reg [7:0] next_state;

reg [3:0] seq_type;
reg [3:0] seq; 

assign invntt_s_type = seq_type; // for accu1 or accu2 choosing
assign invntt_s_seq = seq;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= IDLE;
  end
  else if (set) begin
    curr_state <= next_state;
  end
end

// INVNTT NEXT STATE
always @(*) begin
  if(set) begin
    case(curr_state)
      IDLE : begin
        if(invntt_readin_ok) // module init successfull
          next_state = CHOOSE;
        else
          next_state = IDLE;
      end
      CHOOSE : begin
        case (invntt_ctrl_cmd)
          1 : next_state = READY_INPUT;
          2 : next_state = READY_INPUT;
          default: next_state = CHOOSE; 
        endcase
      end
      READY_INPUT : begin
        case (seq_type)
          1 : begin
            if(polyvec_ctrl_status == 8'h4)
              next_state = INPUT;
            else
              next_state = READY_INPUT;
          end
          2 : begin
            if(polyvec_ctrl_status == 8'h4)
              next_state = INPUT;
            else
              next_state = READY_INPUT;
          end
          default: next_state = READY_INPUT; // TODO: this should go to error handler
        endcase
      end
      INPUT : begin // status who and what? counter?
        if(polyvec_ctrl_status == 8'h6) // output done
          next_state = START_CAL;
        else
          next_state = INPUT;
      end
      START_CAL : begin
        next_state = START_CAL_2;
      end
      START_CAL_2 : begin
        next_state = CALCULATE;
      end
      CALCULATE : begin
        if(invntt_done)
          next_state = OUTPUT_READY;
        else
          next_state = CALCULATE;
      end
      OUTPUT_READY : begin // spear it with the next module
        case (seq_type)
          1 : begin
            if(accu2_ctrl_status == 7) // accu2 ready
              next_state = OUTPUT;
            else
              next_state = OUTPUT_READY;
          end
          2 : begin
            if(accu1_ctrl_status == 1) // accu1 ready
              next_state = OUTPUT;
            else
              next_state = OUTPUT_READY;
          end
          default: next_state = OUTPUT_READY; 
        endcase
      end
      OUTPUT : begin
        if(invntt_readin_ok == 1) // output done
          next_state = OUTPUT_DONE;
        else
          next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        case (seq_type)
          1 : begin
            next_state = SEQUENCE_DONE;
          end
          2 : begin
            // this goes to e1
            if(seq >= 3)
              next_state = SEQUENCE_DONE;
            else
              next_state = READY_INPUT;
          end
          default: next_state = OUTPUT_DONE; // TODO: this should goes to error handler (which does not exist yet) 
        endcase
      end
      SEQUENCE_DONE : begin
        if(invntt_ctrl_cmd == 0)
          next_state = IDLE;
        else
          next_state = SEQUENCE_DONE;
      end
      default: begin
        $display("forbidden state");
      end
    endcase
  end
end

// INVNTT FLAG
always @(*) begin
  if(reset) begin
    // reset flags here
    status(0);
    invntt_s_set     = 0;
    invntt_s_readin  = 0;
    invntt_s_readout = 0;
    invntt_s_cal_en  = 0;
    invntt_s_full_in = 0;
  end
  else if(set) begin
    case(curr_state)
      IDLE : begin
        // flags go here
        status(0);
        invntt_s_set = 1;
        seq_type = 0;
        seq = 0;
      end
      CHOOSE : begin
        case (invntt_ctrl_cmd)
          1 : seq_type = 1;
          2 : seq_type = 2;
        endcase
      end
      READY_INPUT : begin
        status(1);
      end
      INPUT : begin
        status(2);
        invntt_s_readin = 1;
      end
      START_CAL : begin
        invntt_s_readin  = 0;
        invntt_s_full_in = 1;
      end
      START_CAL_2 : begin
        invntt_s_cal_en  = 1;
        invntt_s_full_in = 0;
        seq = seq + 1;
      end
      CALCULATE : begin
        status(3);
        invntt_s_cal_en  = 0;
      end
      OUTPUT_READY : begin
        status(4);
      end
      OUTPUT : begin
        status(5);
        invntt_s_readout = 1;
      end
      OUTPUT_DONE : begin
        status(6);
        invntt_s_readout = 0;
      end
      SEQUENCE_DONE : begin
        status(8'h10);
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  invntt_ctrl_status = st;
end
endtask

endmodule

// I don't think this is necessary, we might need a dedicated control
// for the sequence of adding the polynomials together
// DECOMP FSM
module kyber_pke_enc_decomp_fsm(
  input clk,
  input set,
  input reset,
  
  // INPUT
  input decomp_readin_ok,
  input decomp_readout_ok,
  // OUTPUT 
  output reg decomp_s_set,
  output reg decomp_s_readin,
  output reg decomp_s_readout,
  // output reg decomp_s_full_in, // TODO: this signal is not used

  input [7:0] input_ctrl_status,
  input [7:0] accu2_ctrl_status,
  input [7:0] decomp_ctrl_cmd,
  output reg [7:0] decomp_ctrl_status
);

localparam IDLE          = 1;
// localparam READY_INPUT   = 2;
localparam INPUT         = 3;
// localparam START_CAL     = 4;
// localparam CALCULATE     = 5;
localparam OUTPUT_STAGE  = 10;
localparam OUTPUT_READY  = 6;
localparam OUTPUT        = 7;
localparam OUTPUT_DONE   = 8;
// localparam SEQUENCE_DONE = 9;

reg [7:0] curr_state;
reg [7:0] next_state;
always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= IDLE;
  end
  else if (set) begin
    curr_state <= next_state;
  end
end
// DECOMP NEXT STATE
always @(*) begin
  if(set) begin
    case(curr_state)
      IDLE : begin
        if(input_ctrl_status == 8'h21)
          next_state = INPUT;
        else
          next_state = IDLE;
      end
      INPUT : begin
        if(decomp_readout_ok)
          next_state = OUTPUT_STAGE;
        else
          next_state = INPUT;
      end
      OUTPUT_STAGE : begin
        if(decomp_ctrl_cmd == 1)
          next_state = OUTPUT_READY;
        else
          next_state = OUTPUT_STAGE;
      end
      OUTPUT_READY : begin
        if(accu2_ctrl_status == 1)
          next_state = OUTPUT;
        else
          next_state = OUTPUT_READY;
      end
      OUTPUT : begin
        if(decomp_readout_ok == 0)
          next_state = OUTPUT_DONE;
        else
          next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        next_state = OUTPUT_DONE;
      end
      default: begin
        $display("decomp: forbidden state");
      end
    endcase
  end
end
// DECOMP FLAG
always @(*) begin
  if(reset) begin
    status(0);
    decomp_s_set     = 0;
    decomp_s_readin  = 0;
    decomp_s_readout = 0;
  end
  else if(set) begin
    case(curr_state) 
      IDLE : begin
        status(0);
        decomp_s_set = 1;
      end
      INPUT : begin
        status(1);
        decomp_s_readin = 1;
      end
      OUTPUT_STAGE : begin
        status(2);
      end
      OUTPUT_READY : begin
        status(3);
        decomp_s_readin = 0;
      end
      OUTPUT : begin
        status(4);
        decomp_s_readout = 1;
      end
      OUTPUT_DONE : begin
        status(5);
        decomp_s_readout = 0;
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  decomp_ctrl_status = st;
end
endtask

endmodule

// MEMORY 1 FSM 
module kyber_pke_enc_accu1_fsm(
  input clk,
  input set,
  input reset,

  // INPUT -- from module
  input [3:0] accu1_status, // note: I can see why SystemVerilog is more useful when designing complex system now...
  // input [3:0] accu1_status_2,
  // input [3:0] accu1_status_3,
  
  // OUTPUT -- to module
  output reg [3:0] accu1_s_cmd, // used to determine what goes where in the main module
  output reg accu1_s_readin,
  output reg accu1_s_readout,
  
  // OUTPUT -- control assist
  output reg [3:0] accu1_s_type, // this controls which module's data it accepts
  output reg [3:0] accu1_s_seq, // this conrols which accu1_n is being controlled 

  // INPUT -- from control
  input [3:0] cbd_s_type,
  input [3:0] cbd_s_seq,
  input [7:0] cbd_counter,
  input [3:0] invntt_s_type,
  input [3:0] invntt_s_seq,

  // CONTROL CODES
  input [7:0] cbd_ctrl_status,
  input [7:0] invntt_ctrl_status,
  input [7:0] accu1_ctrl_cmd,
  output reg [7:0] accu1_ctrl_status
);

localparam IDLE          = 1;

localparam STAGE_2       = 10;
localparam CBD_READY     = 7;
localparam CBD_READY_1   = 8;
localparam CBD_INPUT     = 9;

localparam STAGE_3       = 11;

localparam STAGE_0       = 2;
localparam INTT_READY    = 3;
localparam INTT_INPUT    = 4;
localparam STAGE_1       = 5; // the spaghetti continues...
localparam SEQUENCE_DONE = 6;

// reg [3:0] seq;

reg [7:0] curr_state;
reg [7:0] next_state;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= IDLE;
  end
  else if (set) begin
    curr_state <= next_state;
  end
end

// MEMORY 1 NEXT STATE
always @(*) begin
  if(set) begin
    case(curr_state)
      IDLE : begin
        if(accu1_ctrl_cmd == 1)
          next_state = STAGE_2;
        else
          next_state = IDLE;
      end
      STAGE_2 : begin
        if(cbd_s_type == 3      &&
           cbd_ctrl_status == 4 &&
           accu1_status == 1      )
          next_state = CBD_READY;
        else
          next_state = STAGE_2;
      end
      CBD_READY : begin
        if(cbd_ctrl_status == 5)
          next_state = CBD_READY_1;
        else
          next_state  = CBD_READY;
      end
      CBD_READY_1 : begin
        if(cbd_counter == 3)
          next_state = CBD_INPUT;
        else
          next_state = CBD_READY_1;
      end
      CBD_INPUT : begin
        if(cbd_counter == 131)
          next_state = STAGE_3;
        else
          next_state = CBD_INPUT;
      end
      STAGE_3 : begin // this controls if the three sequence is done or not
        if(cbd_s_seq < 3)
          next_state = STAGE_2;
        else if(cbd_ctrl_status == 8'h10)
          next_state = STAGE_0;
        else
          next_state = STAGE_3;
      end
      STAGE_0 : begin
        if(accu1_status == 2 & invntt_s_type == 2) // wait... is it possible to have one control 3? or should i make 1 fsm for each
          next_state = INTT_READY; // it would probably be better to have one control 3, it scales better :P
        else
          next_state = STAGE_0;
      end
      INTT_READY : begin
        if(invntt_ctrl_status == 5)
          next_state = INTT_INPUT;
        else
          next_state = INTT_READY;
      end
      INTT_INPUT : begin
        if(invntt_ctrl_status == 6) // output done
          next_state = STAGE_1;
        else
          next_state = INTT_INPUT;
      end
      STAGE_1 : begin
        if(invntt_s_seq < 3)
          next_state = STAGE_0;
        else if(invntt_ctrl_status == 8'h10) // sequence done
          next_state = SEQUENCE_DONE;
        else
          next_state = STAGE_1;
      end
      SEQUENCE_DONE : begin
        next_state = SEQUENCE_DONE;
      end
      default: begin
        $display("forbidden state");
      end
    endcase
  end
end

// MEMORY 1 FLAG
always @(*) begin
  if(reset) begin
    // reset flags here
    status(0);
    command(0);
    type(0);
    readin(0);
    readout(0);
  end
  else if(set) begin
    case(curr_state) 
      IDLE : begin
        // flags go here
        status(0);
        command(0);
        type(0);
        readin(0);
        readout(0);
      end
      STAGE_2 : begin
        command(1);
        type(1);
      end
      CBD_READY : begin
        status(5);
      end
      CBD_READY_1 : begin
        
      end
      CBD_INPUT : begin
        status(6);
        readin(1);
      end
      STAGE_3 : begin
        readin(0);
      end
      STAGE_0 : begin
        command(2);
        readin(0);
        type(2);
      end
      INTT_READY : begin
        status(1);
      end
      INTT_INPUT : begin
        status(2);
        readin(1);
      end
      STAGE_1 : begin
        status(3);
        type(0);
        readin(0);
      end
      SEQUENCE_DONE : begin
        status(4);
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  accu1_ctrl_status = st;
end
endtask

task command(input [3:0] cmd);
begin
  accu1_s_cmd = cmd;
end
endtask

task type(input [3:0] tp);
begin
  accu1_s_type = tp;
end
endtask

task readin(input rd);
begin
  accu1_s_readin = rd;
end
endtask

task readout(input rd);
begin
  accu1_s_readout = rd;
end
endtask

endmodule

// MEMORY 2 FSM, TODO: do I change the name to accumulator?
module kyber_pke_enc_accu2_fsm(
  input clk,
  input set,
  input reset,

  input [3:0] accu2_status,

  output reg [3:0] accu2_s_cmd, // used to determine what goes where in the main module
  output reg accu2_s_readin,
  output reg accu2_s_readout,
  output reg [3:0] accu2_s_type,

  input [3:0] cbd_s_type,
  input [7:0] cbd_counter,

  input [7:0] decomp_ctrl_status,
  input [7:0] cbd_ctrl_status,
  input [7:0] invntt_ctrl_status,
  input [7:0] accu2_ctrl_cmd,
  output reg [7:0] accu2_ctrl_status
);

localparam IDLE          = 1;
localparam MESSAGE_STAGE = 9;
localparam MESSAGE_READY = 2;
localparam MESSAGE_INPUT = 3;
localparam STAGE_0       = 4;
localparam E2_READY      = 5;
localparam E2_INPUT      = 6;
localparam STAGE_1       = 7;
localparam E2_READY_1    = 8;
localparam INTT_READY    = 10;
localparam INTT_INPUT    = 11;
localparam STAGE_2       = 12;

reg [7:0] curr_state;
reg [7:0] next_state;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= IDLE;
  end
  else if (set) begin
    curr_state <= next_state;
  end
end

// MEMORY 2 NEXT STATE
always @(*) begin
  if(set) begin
    case(curr_state)
      IDLE : begin
        if(accu2_ctrl_cmd == 1)
          next_state = MESSAGE_STAGE;
        else
          next_state = IDLE;
      end
      MESSAGE_STAGE : begin
        if(accu2_status == 1)
          next_state = MESSAGE_READY;
        else
          next_state = MESSAGE_STAGE;
      end
      MESSAGE_READY : begin
        if(decomp_ctrl_status == 4) // output start
          next_state = MESSAGE_INPUT;
        else
          next_state = MESSAGE_READY;
      end
      MESSAGE_INPUT : begin
        if(decomp_ctrl_status == 5) // output done
          next_state = STAGE_0;
        else
          next_state = MESSAGE_INPUT;
      end
      STAGE_0 : begin 
        // finished message input, waiting for CBD error2
        // TODO: look for OUTPUT_READY and cbd_s_type
        if(cbd_s_type == 2        && // e2 is the type we want  
           cbd_ctrl_status == 4 && // cbd output ready
           accu2_status == 2     ) // accu2_status ready 
          next_state = E2_READY;
        else
        next_state = STAGE_0;
      end
      E2_READY : begin
        if(cbd_ctrl_status == 5) // cbd output
          next_state = E2_READY_1;
        else
          next_state = E2_READY;
      end
      E2_READY_1 : begin
        if(cbd_counter  == 3) // the start of output in cbd is not what we want
          next_state = E2_INPUT;
        else
          next_state = E2_READY_1;
      end
      E2_INPUT : begin // input from cbd(e2) -> memory (accu2)
        if(cbd_counter == 131)
          next_state = STAGE_1;
        else
          next_state = E2_INPUT;
      end
      STAGE_1 : begin
        if(invntt_ctrl_status == 4) // invntt output ready
          next_state = INTT_READY;
        else
          next_state = STAGE_1;
      end
      INTT_READY : begin
        if(invntt_ctrl_status == 5) // invntt output
          next_state = INTT_INPUT;
        else
          next_state = INTT_READY;
      end
      INTT_INPUT : begin
        if(invntt_ctrl_status == 6) // invntt output done
          next_state = STAGE_2;
        else
          next_state = INTT_INPUT;
      end
      STAGE_2 : begin
        next_state = STAGE_2;
      end
      // TODO: the next stage would to run it through compress and encode, turning it into ciphertext 2
      default: begin
        $display("forbidden state");
      end
    endcase
  end
end
// MEMORY 2 FLAG
always @(*) begin
  if(reset) begin
    status(0);
    type(0);
    readin(0);
    readout(0);
  end
  else if(set) begin
    case(curr_state) 
      IDLE : begin
        status(0);
        command(0);
        readin(0);
        readout(0);
      end
      MESSAGE_STAGE : begin
        command(1);
      end
      MESSAGE_READY : begin
        status(1);
      end
      MESSAGE_INPUT : begin
        status(2);
        readin(1);
        type(1);
      end
      STAGE_0 : begin
        status(3);
        command(2);
        type(0);
        readin(0);
      end
      E2_READY : begin
        status(4);
      end
      E2_READY_1 : begin
        // waiting...
      end
      E2_INPUT : begin
        status(5);
        type(2); // cbd
        readin(1);
      end
      STAGE_1 : begin
        status(6);
        // command(0);
        type(0);
        readin(0);
      end
      INTT_READY : begin
        status(7);
      end
      INTT_INPUT : begin
        status(8);
        type(3);
        readin(1);
      end
      STAGE_2 : begin
        status(9);
        type(0);
        readin(0);
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  accu2_ctrl_status = st;
end
endtask

task command(input [3:0] cmd);
begin
  accu2_s_cmd = cmd;
end
endtask

task type(input [3:0] tp);
begin
  accu2_s_type = tp;
end
endtask

task readin(input rd);
begin
  accu2_s_readin = rd;
end
endtask

task readout(input rd);
begin
  accu2_s_readout = rd;
end
endtask

endmodule


// MATRIX HASH FSM
module kyber_pke_enc_matrix_hash_fsm(
  input clk,
  input set,
  input reset,

  // INPUT
  input matrix_hash_readin_ok,
  input matrix_hash_done,

  // OUTPUT
  output reg matrix_hash_s_set,
  output reg matrix_hash_s_full_in,
  output reg matrix_hash_s_readin,
  output reg matrix_hash_s_readout,

  output reg counter_ctrl,
  input [7:0] counter,
  output [3:0] matrix_hash_seq,

  // BIG CONTROL
  input [7:0] input_ctrl_status,
  input [7:0] polyvec_ctrl_status, 
  input [7:0] matrix_hash_ctrl_cmd,
  output reg [7:0] matrix_hash_ctrl_status
);

localparam IDLE          = 1;
localparam READY_INPUT   = 2;
localparam INPUT         = 3;
localparam START_CAL     = 4;
localparam CALCULATE     = 5;
localparam OUTPUT_READY  = 6;
localparam OUTPUT        = 7;
localparam OUTPUT_DONE   = 8;
localparam SEQUENCE_DONE = 9;
localparam CHOOSE        = 10;
localparam START_CAL_STAGE = 11;
localparam SEQUENCE_STAGE  = 12;


reg [7:0] curr_state;
reg [7:0] next_state;
always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= IDLE;
  end
  else if (set) begin
    curr_state <= next_state;
  end
end

reg [3:0] seq; // internal sequence
reg [3:0] seq_type;

assign matrix_hash_seq = seq;

// MATRIX HASH NEXT STATE
always @(*) begin
  if(set) begin
    case (curr_state)
      IDLE : begin
        if(matrix_hash_readin_ok /*& (hash_ctrl_cmd == 8'h0)*/)
          // wait until the module re-initilize
          next_state = CHOOSE;
        else
          next_state = IDLE;
      end
      CHOOSE : begin // sequence type chooser
        case (matrix_hash_ctrl_cmd)
          8'h1 : begin // there is currently no other commands
            next_state = READY_INPUT;
          end
          // 8'h2 : begin
          //   next_state = START_CAL;
          // end
          // 8'h3 : begin
          //   next_state = START_CAL;
          // end
          default: begin
            next_state = CHOOSE;
          end
        endcase
      end
      READY_INPUT : begin
        if(input_ctrl_status == 8'h31) // do input please
          next_state = INPUT;
        else
          next_state = READY_INPUT;
      end
      INPUT : begin
        if(input_ctrl_status == 8'h33) // done
          next_state = START_CAL;
        else
          next_state = INPUT;
      end
      START_CAL : begin
        next_state = START_CAL_STAGE;
      end
      START_CAL_STAGE : begin
        if(matrix_hash_done == 0) // wait until the done flag returns to 0
          next_state = CALCULATE;
        else
          next_state = START_CAL_STAGE;
      end
      CALCULATE : begin
        if(matrix_hash_done) // hash calculate is done
          next_state = OUTPUT_READY;
        else
          next_state = CALCULATE;
      end
      OUTPUT_READY : begin
        if(polyvec_ctrl_status == 8'h12) // ready input
          next_state = OUTPUT;
        else
          next_state = OUTPUT_READY;
      end
      OUTPUT : begin
        if(counter == 128)
          next_state = OUTPUT_DONE;
        else
          next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        case (seq_type)
          8'h1 : begin // there is currently no other commands
            // TODO: this needs to wait for polyvec 
            // if(matrix_hash_done) begin 
              // ideally this should be controlled by a separate counter :P
              if(seq == 3 || seq == 6 || seq == 9) // it needs to be done for 9 times
                next_state = SEQUENCE_STAGE;            
              else
                next_state = START_CAL;
            // end
          end
          // 8'h2 : begin
          //   next_state = SEQUENCE_DONE;            
          // end 
          default: begin
            next_state = OUTPUT_DONE;
          end 
        endcase
      end
      SEQUENCE_STAGE : begin
        if(seq >= 9) begin
          next_state = SEQUENCE_DONE;
        end
        else begin
          if(polyvec_ctrl_status == 8'h13) // MAT_STAGE
            next_state = START_CAL;
          else
            next_state = SEQUENCE_STAGE;
        end
      end
      SEQUENCE_DONE : begin
        // waits for the command to return to 0
        if(matrix_hash_ctrl_cmd == 8'h0)
          next_state = IDLE;
        else
          next_state = SEQUENCE_DONE;
      end
      default:
        $display("forbidden state");
    endcase
  end
end

// MATRIX HASH STATE FLAG
always @(*) begin
  if(reset) begin
    status(0);

    matrix_hash_s_set     = 0;
    matrix_hash_s_full_in = 0;
    matrix_hash_s_readin  = 0;
    matrix_hash_s_readout = 0;

    counter_ctrl   = 0;
    seq = 0;
    type(0);

  end
  else if(set) begin
    case (curr_state)
      IDLE : begin
        status(0);
        matrix_hash_s_set = 1; // readin_ok flag is behind a set flag bruhhhh
        matrix_hash_s_full_in = 0;
        matrix_hash_s_readin = 0;
        seq_type = 0;
      end
      CHOOSE : begin
        case (matrix_hash_ctrl_cmd)
          8'h1 : seq_type = 1;
          // 8'h2 : seq_type = 2;
          // 8'h3 : seq_type = 3;
          default : seq_type = 0;
        endcase
      end
      READY_INPUT : begin
        status(1);
      end
      INPUT : begin
        status(2);
        matrix_hash_s_readin = 1;
      end
      START_CAL : begin
        seq = seq + 1;
        matrix_hash_s_full_in = 1; // pulse high
        matrix_hash_s_readin = 0;
      end
      START_CAL_STAGE : begin
        matrix_hash_s_full_in = 0; // pulse low
      end
      CALCULATE : begin
        status(3);
      end
      OUTPUT_READY : begin
        status(4);
      end
      OUTPUT : begin
        status(5);
        matrix_hash_s_readout = 1;
        counter_ctrl = 1;
      end
      OUTPUT_DONE : begin
        status(6);
        matrix_hash_s_readout = 0;
        counter_ctrl = 0;
      end
      SEQUENCE_STAGE : begin
        status(8'h11);
      end
      SEQUENCE_DONE : begin
        status(8'h10);
      end
    endcase
  end
end

task status(input [7:0] st);
begin
  matrix_hash_ctrl_status = st;
end
endtask

task type(input [7:0] tp);
begin
  seq_type = tp;
end
endtask

endmodule