module hash_stub_fsm(
  input clk,
  input set,
  input reset,

  input full_in, // from external
  input [7:0] counter,
  input shake128_done,
  output reg iscal,
  
  output reg index_a_ctrl,
  output reg index_b_ctrl,
  output reg counter_ctrl,

  output reg ram_a_we_ok,
  output reg ram_b_we_ok,
  output reg shake128_full_in, // stub
  output reg pulse, // this is used for resetting counters
  output reg readin_ok, // pulse
  output reg done // to external
);

localparam LOAD_S0   = 7;

localparam STAT_S0   = 1;
localparam STAT_S0_1 = 2;
localparam STAT_S1   = 3;
localparam STAT_S2   = 4;
localparam STAT_S2_1 = 5;
localparam STAT_S3   = 6;

reg [7:0] next_state;
reg [7:0] curr_state;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= LOAD_S0;
  end
  else begin
    curr_state <= next_state;
  end
end

always @(*) begin
  if(set) begin
    case (curr_state)
      LOAD_S0 : begin
        next_state = STAT_S0;
      end
      STAT_S0 : begin
        if(full_in)
          next_state = STAT_S0_1;
        else
          next_state = STAT_S0;
      end 
      STAT_S0_1 : begin
        next_state = STAT_S1;
      end
      STAT_S1 : begin
        if(counter == 31) // the timing for ram_a -> stub logic (python script)
          next_state = STAT_S2;
        else
          next_state = STAT_S1;
      end
      STAT_S2 : begin
        next_state = STAT_S2_1;
      end
      STAT_S2_1 : begin 
        if(shake128_done) // the python script did the thing!
          next_state = STAT_S3;
        else
          next_state = STAT_S2_1;
      end
      STAT_S3 : begin
        next_state = LOAD_S0;
      end
      default : begin
        $display("forbidden state");
      end 
    endcase
  end
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    iscal <= 0;
    index_a_ctrl <= 0;
    index_b_ctrl <= 0;
    counter_ctrl <= 0;
    ram_a_we_ok  <= 0;
    ram_b_we_ok  <= 0; // not assigned in states
    readin_ok    <= 0;
    shake128_full_in <= 0;
    done <= 0;
    pulse <= 0;
  end
  else if(set) begin
    case (curr_state)
      LOAD_S0 : begin
        iscal <= 0;
        ram_a_we_ok <= 1;
        readin_ok <= 1;
      end
      STAT_S0 : begin
        readin_ok <= 0;
      end
      STAT_S0_1 : begin
        ram_a_we_ok <= 0;
        index_a_ctrl <= 1;
        index_b_ctrl <= 0;
        done <= 0;
        //pulse <= 1;
      end
      STAT_S1 : begin
        //pulse <= 0;
        counter_ctrl <= 1;
        iscal <= 1;
      end
      STAT_S2 : begin
        iscal <= 0;
        index_a_ctrl <= 0;
        counter_ctrl <= 0;
        pulse <= 1;
      end
      STAT_S2_1 : begin
        shake128_full_in <= 1;
        pulse <= 0;
      end
      STAT_S3 : begin
        shake128_full_in <= 0;
        index_b_ctrl <= 1;
        done <= 1;
      end
    endcase
  end
end

endmodule