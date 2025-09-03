module basemul_tomont_fsm #(parameter DEPTH = 8)(
  input clk,
  input set,
  input reset,
  /*
  input readin,
  */
  input readout,
  input cal_en,
  input full_in,
  //input full_out,
  input [DEPTH-1:0] counter,

  output reg iscal,
  output reg index_a_ctrl,
  output reg index_b_ctrl,
  output reg index_c_ctrl,
  output reg counter_ctrl,

  output reg rama_we_ok,
  output reg ramb_we_ok,
  output reg ramc_we_ok,

  output reg readin_a_ok,
  output reg readin_b_ok,
  output reg cal_pulse,
  output reg done
);

// STATES
localparam STAT_S0   = 1;
localparam STAT_S0_1 = 2;
localparam STAT_S1   = 3;
localparam STAT_S2   = 4;
localparam STAT_S2_1 = 5;
localparam STAT_S3   = 6;
localparam STAT_S3_1 = 7;

localparam COMP_S0 = 10;
localparam COMP_S1 = 11;
localparam COMP_S2 = 12;

reg [7:0] curr_state;
reg [7:0] next_state;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    curr_state <= STAT_S0;
  end
  else begin
    curr_state <= next_state;
  end
end

// next state
always @(*) begin
  if(set) begin
    case (curr_state)
      STAT_S0 : begin // readin signal pulse
        next_state = STAT_S0_1;
      end
      STAT_S0_1 : begin // no done flag
        if(full_in)
          next_state = STAT_S1;
        else
          next_state = STAT_S0_1;
      end
      STAT_S1 : begin
        if(cal_en)
          next_state = COMP_S0;
        else
          next_state = STAT_S1;
      end
      COMP_S0 : begin
        if(counter == 4)
          next_state = COMP_S1;
        else 
          next_state = COMP_S0;
      end
      COMP_S1 : begin
        if(counter == (1 << (DEPTH - 1)) - 2)
          next_state = COMP_S2;
        else
          next_state = COMP_S1;
      end
      COMP_S2 : begin 
        if(counter == (1 << (DEPTH - 1)) + 4)
          next_state = STAT_S2;
        else
          next_state = COMP_S2;
      end
      STAT_S2 : begin // readin signal pulse
        next_state = STAT_S2_1;
      end
      STAT_S2_1 : begin // yes done flag
        if(full_in)
          next_state = STAT_S3;
        else
          next_state = STAT_S2_1;
      end
      STAT_S3 : begin
        if(cal_en)
          next_state = STAT_S3_1;
        else
          next_state = STAT_S3;
      end
      STAT_S3_1 : begin
        next_state = COMP_S0;
      end
      default: begin
        $display("[%0t] forbidden state", $time);
      end 
    endcase
  end
end

// condition
always @(posedge clk or posedge reset) begin
  if(reset) begin
    iscal <= 0;
    done <= 0;
    index_a_ctrl <= 0;
    index_b_ctrl <= 0;
    index_c_ctrl <= 0;
    counter_ctrl <= 0;
    rama_we_ok <= 0;
    ramb_we_ok <= 0;
    ramc_we_ok <= 0;
    readin_a_ok <= 0;
    readin_b_ok <= 0;
    cal_pulse <= 0;
  end
  else if(set) begin
    case (curr_state)
      STAT_S0 : begin
        iscal <= 0;
        done <= 0;
        rama_we_ok <= 1;
        ramb_we_ok <= 1;
        readin_a_ok <= 1; // pulse
        readin_b_ok <= 1;

      end
      STAT_S0_1 : begin
        readin_a_ok <= 0; // pulse
        readin_b_ok <= 0;
      end
      STAT_S1 : begin
        rama_we_ok <= 0;
        ramb_we_ok <= 0;
        cal_pulse   <= 1; // clearing index_c/counter/k
      end
      COMP_S0 : begin
        iscal <= 1;
        index_a_ctrl <= 1;
        index_b_ctrl <= 1;
        index_c_ctrl <= 0;
        counter_ctrl <= 1;
        rama_we_ok <= 0;
        ramb_we_ok <= 0;
        ramc_we_ok <= 0;
        done <= 0;

        cal_pulse <= 0;
      end
      COMP_S1 : begin
        index_c_ctrl <= 1;
        ramc_we_ok <= 1;
      end
      COMP_S2 : begin
        index_a_ctrl <= 0;
        index_b_ctrl <= 0;
      end
      STAT_S2 : begin
        iscal <= 0;
        index_c_ctrl <= 1; // letting readout controll index_c
        counter_ctrl <= 0;

        rama_we_ok <= 1;
        ramb_we_ok <= 1;
        ramc_we_ok <= 0;

        readin_a_ok <= 1; // pulse
        readin_b_ok <= 1;

        done <= 1;        
      end
      STAT_S2_1 : begin
        readin_a_ok <= 0; // pulse
        readin_b_ok <= 0;
      end
      STAT_S3 : begin
        rama_we_ok <= 0;
        ramb_we_ok <= 0;
      end
      STAT_S3_1 : begin
        cal_pulse   <= 1; // clearing index_c/counter/k
        done <= 0;
      end
    endcase
  end
end
endmodule