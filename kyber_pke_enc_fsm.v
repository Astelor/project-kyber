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
  // OUTPUT =======
  // -- OUTSIDE
  output reg done // to outside
);

localparam IDLE        = 1;
localparam HASH_CBD    = 2; 
localparam STAGE       = 3;
localparam POLYVEC_EKT = 4;

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
          next_state = STAGE;
        else
          next_state = HASH_CBD;
      end
      STAGE : begin
        if(input_ctrl_status == 4'h0)
          next_state = POLYVEC_EKT;
        else
          next_state = STAGE;
      end
      POLYVEC_EKT : begin
        next_state = POLYVEC_EKT;
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

      end
      HASH_CBD : begin
        input_cmd(1);
        hash_cmd(1);
        cbd_cmd(1);
        ntt_cmd(1);
        polyvec_cmd(1);
      end
      STAGE : begin 
        // when hash finished the output (check status), call for the next input
        input_cmd(0); // reset the input fsm
      end
      POLYVEC_EKT : begin
        input_cmd(2); 
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

  input [7:0] input_ctrl_cmd,
  output reg [7:0] input_ctrl_status
);

localparam IDLE               = 1;
localparam CHOOSE             = 2;
localparam HASH_INPUT_STAGE   = 3;
localparam HASH_INPUT_READY   = 4; // pulse
localparam HASH_INPUT_ACTIVE  = 5;
localparam HASH_INPUT_DONE    = 6;

localparam EKT_INPUT_STAGE    = 11;
localparam EKT_INPUT_READY    = 12; // pulse
localparam EKT_INPUT_ACTIVE   = 13;
localparam EKT_INPUT_DONE     = 14;
// i don't think it needs a handshake? it's indexed


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
          default: next_state = CHOOSE; 
        endcase
      end
      // HASH =====
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
      // EKT ======
      EKT_INPUT_STAGE : begin
        // if() 
        // there's no conflict here,
        // so I think polyvec doesn't need an explicit flag 
        // to signal the input fsm
        next_state = EKT_INPUT_READY;
      end
      EKT_INPUT_READY : begin
        next_state = EKT_INPUT_ACTIVE;
      end
      EKT_INPUT_ACTIVE :begin
        next_state = EKT_INPUT_ACTIVE;
      end
      EKT_INPUT_DONE : begin
        // do I need to have polyvec do a status code??
        // or can I just have it use the ful_in signal?
        // it's a bit redundant to give polyvec two concurrent fsms
        // simply for the use of two inputs
        // or is it necessary? 
        next_state = EKT_INPUT_DONE;
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
  output reg hash_readout,
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

reg [7:0] curr_state;
reg [7:0] next_state;

reg [3:0] seq; // internal sequence

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
        if(hash_readin_ok) //wait until the module initilize
          next_state = READY_INPUT;
        else
          next_state = IDLE;
      end
      READY_INPUT : begin
        if((input_ctrl_status == 8'h1) &
           (hash_ctrl_cmd     == 8'h1)) // do input please
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
        next_state = CALCULATE;
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
        if(seq >= 3) begin
          next_state = SEQUENCE_DONE;
        end
        else if(hash_ctrl_cmd == 1)
          next_state = START_CAL;
        else
          next_state = OUTPUT_DONE;
      end
      SEQUENCE_DONE : begin
        next_state = SEQUENCE_DONE;
      end
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
    hash_readout   = 0;
    // hash_type   = 0;
    counter_ctrl   = 0;
    
    seq = 0;
  end
  else if(set) begin
    case (curr_state)
      IDLE : begin
        status(0);
        hash_s_set = 1; // readin_ok flag is behind a set flag bruhhhh
        hash_s_full_in = 0;
        hash_s_readin = 0;
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
      CALCULATE : begin
        hash_s_full_in = 0; // pulse low
        status(3);
        hash_s_readin = 0;
      end
      OUTPUT_READY : begin
        status(4);
      end
      OUTPUT : begin
        status(5);
        hash_readout = 1;
        counter_ctrl = 1;
      end
      OUTPUT_DONE : begin
        status(6);
        hash_readout = 0;
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

  input [7:0] counter, // 0~255
  output reg counter_ctrl,

  // BIG CONTROL
  input [7:0] ntt_ctrl_status,
  input [7:0] hash_ctrl_status,
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

reg [7:0] curr_state;
reg [7:0] next_state;

reg [3:0] seq; // internal sequence

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
          next_state = READY_INPUT;
        else
          next_state = IDLE;
      end
      READY_INPUT : begin
        if((hash_ctrl_status == 8'h5) & 
           (cbd_ctrl_cmd     == 8'h1)) // hash output ready
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
        if((ntt_ctrl_status == 8'h1) //||
           )//(ntt_ctrl_status == 8'h6) ) // NTT output ready
          next_state = OUTPUT;
        else
          next_state = OUTPUT_READY;
      end
      OUTPUT : begin
        if(cbd_ok_out == 0) // can be the counter too :>
          next_state = OUTPUT_DONE;
        else
          next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        if(seq >= 3) begin
          next_state = SEQUENCE_DONE;
        end
        else if(cbd_ctrl_cmd == 1)
          next_state = IDLE;
        else
          next_state = OUTPUT_DONE;
      end
      SEQUENCE_DONE : begin
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
    cbd_s_set    = 0;
    cbd_s_readin = 0;
    cbd_readout  = 0;
    counter_ctrl = 0;
    seq          = 0;
  end
  else if(set) begin
    case (curr_state)
      IDLE : begin
        status(0);
        cbd_s_set = 1;
      end
      READY_INPUT : begin
        status(1);
      end
      INPUT : begin
        status(2);
        cbd_s_readin = 1;
      end
      START_CAL : begin
        seq = seq + 1;
      end
      CALCULATE : begin
        cbd_s_readin = 0;
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
  output reg ntt_readout,
  
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
        else if(ntt_ctrl_cmd == 1)
          // TODO: this should include a condition that finish the sequence
          next_state = IDLE;
        else
          next_state = OUTPUT_DONE;
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
    ntt_readout  = 0;
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
        ntt_readout  = 1;
        counter_ctrl = 1;
      end
      OUTPUT_DONE : begin
        status(6);
        ntt_readout  = 0;
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
  output reg polyvec_readout,
  output reg polyvec_s_cal_en,

  output reg polyvec_s_readin_a,
  output reg polyvec_s_readin_b,
  output reg polyvec_full_in_a,
  output reg polyvec_full_in_b,


  // BIG CONTROL
  input [7:0]      ntt_ctrl_status,
  input [7:0]      polyvec_ctrl_cmd,
  output reg [7:0] polyvec_ctrl_status
);

localparam IDLE          = 1;
localparam READY_INPUT   = 2;
localparam INPUT_1       = 3;
localparam INPUT_2       = 4;
localparam START_CAL     = 5;
localparam CALCULATE     = 6;
localparam OUTPUT_READY  = 7;
localparam OUTPUT        = 8;
localparam OUTPUT_DONE   = 9;
localparam SEQUENCE_DONE = 10;

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

// can I have two fsms for A and B each?
// POLYVEC NEXT STATE
always @(*) begin
  if(set) begin
    case(curr_state)
      IDLE : begin // TODO: for matrix A it needs a choosen stage like input
        if(polyvec_readin_a_ok)
          next_state = READY_INPUT;
        else
          next_state = IDLE;
      end
      READY_INPUT : begin
        if(/*(ntt_ctrl_status  == 8'h4) & */
           (polyvec_ctrl_cmd == 8'h1)  ) // NTT output ready
          next_state = INPUT_1;
        else
          next_state = READY_INPUT;
      end
      INPUT_1 : begin
        if(ntt_ctrl_status == 8'h10)
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
        next_state = CALCULATE;
      end
      CALCULATE : begin
        if(polyvec_done)
          next_state = OUTPUT_READY;
        else
          next_state = CALCULATE;
      end
      OUTPUT_READY : begin
        next_state = OUTPUT_READY;
        // should lock memory bank a immediately with full_in_a
      end
      OUTPUT : begin
        next_state = OUTPUT;
      end
      OUTPUT_DONE : begin
        next_state = OUTPUT_DONE;
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

// POLYVEC FLAG
always @(*) begin
  if(reset) begin
    status(0);
    polyvec_s_set      = 0;
    polyvec_readout    = 0;
    polyvec_s_cal_en   = 0;
    polyvec_s_readin_a = 0;
    polyvec_s_readin_b = 0;
    polyvec_full_in_a  = 0;
    polyvec_full_in_b  = 0;
    // reset flags here
  end
  else if(set) begin
    case(curr_state) 
      IDLE : begin
        status(0);
        polyvec_s_set = 1;
        // flags go here
      end
      READY_INPUT : begin
        status(1);
        polyvec_s_readin_b = 1; // full_in where??
        polyvec_full_in_b  = 1;
      end
      INPUT_1 : begin
        status(2);
        polyvec_s_readin_a = 1;
      end
      INPUT_2 : begin
        polyvec_full_in_a = 1;
      end
      START_CAL : begin
        polyvec_full_in_a = 0;
        polyvec_full_in_b = 0;
        polyvec_s_cal_en  = 1;
      end
      CALCULATE : begin
        status(3);
        polyvec_s_cal_en  = 0;
      end
      OUTPUT_READY : begin
        status(4);
      end
      OUTPUT : begin
        status(5);
      end
      OUTPUT_DONE : begin
        status(6);
      end
      SEQUENCE_DONE : begin
        status(8'h10);
        // polyvec_full_in_a = 1;
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