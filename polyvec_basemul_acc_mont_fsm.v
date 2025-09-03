module polyvec_basemul_acc_mont_fsm #(parameter DEPTH = 8)(
  input clk,
  input set,
  input reset,

  input [DEPTH-1:0] counter,
  input bm_done,
  input full_in,
  input cal_en,

  output reg [2:0] k, 
  
  // control bm
  output reg bm_readin_a,
  output reg bm_readin_b,
  
  output reg bm_cal_en,
  output reg bm_full_in_a,
  output reg bm_full_in_b,
  output reg bm_readout,

  // control internal regs
  output reg index_a_ctrl,
  output reg index_b_ctrl,
  output reg index_c_ctrl,
  output reg counter_ctrl, 

  output reg ram_a_we_ok,
  output reg ram_b_we_ok,
  output reg ram_c_we_ok,

  output reg barr_redc,
  
  output reg readin_a_ok,
  output reg readin_b_ok,

  output reg isload,
  output reg done
);

// STATES
localparam STAT_S0   = 1;
localparam STAT_S0_1 = 2;
localparam STAT_S1   = 3;

localparam LOAD_S0   = 10;
localparam LOAD_S0_1 = 11;
localparam LOAD_S1   = 12;
localparam LOAD_S1_1 = 13;
localparam LOAD_S1_2 = 14; // RAM C is empty
localparam LOAD_S2   = 15;
localparam LOAD_S2_1 = 16;
localparam LOAD_S3   = 17;
localparam LOAD_S3_1 = 18;
localparam LOAD_S3_2 = 19;
localparam LOAD_S3_3 = 20;
localparam LOAD_S4   = 21;
localparam LOAD_S4_1 = 22;
localparam LOAD_S4_2 = 23;

localparam REDC_S0   = 30;
localparam REDC_S0_1 = 31;
localparam REDC_S0_2 = 32;

localparam DOUT_S0   = 40;
localparam DOUT_S0_1 = 41;
localparam DOUT_S0_2 = 42;

reg [7:0] curr_state;
reg [7:0] next_state;

always @(posedge clk or posedge reset) begin
  if(reset) 
    curr_state <= STAT_S0;
  else
    curr_state <= next_state; 
end

// next state
always @(*) begin
  if(set) begin
    case (curr_state)
      STAT_S0 : begin
        next_state = STAT_S0_1;
      end
      STAT_S0_1 : begin
        if(full_in)
          next_state = STAT_S1;
        else
          next_state = STAT_S0_1;
      end
      STAT_S1 : begin
        if(cal_en)
          next_state = LOAD_S0;
        else
          next_state = STAT_S1;
      end
      LOAD_S0 : begin // pulse
        next_state = LOAD_S0_1;
      end
      LOAD_S0_1 : begin
        if(counter == (1<<(DEPTH-1)) - 2)
          next_state = LOAD_S1;
        else
          next_state = LOAD_S0_1;
      end
      LOAD_S1 : begin // pulse
        next_state = LOAD_S1_1;
      end
      LOAD_S1_1 : begin
        if(~bm_done)
          next_state = LOAD_S1_2;
        else
          next_state = LOAD_S1_1;
      end
      LOAD_S1_2 : begin
        if(bm_done)
          next_state = LOAD_S2;
        else
          next_state = LOAD_S1_2;
      end
      LOAD_S2 : begin // pulse
        next_state = LOAD_S2_1;
      end
      LOAD_S2_1 : begin
        if(counter == (1<<(DEPTH - 1)) - 2)
          next_state = LOAD_S3;
        else
          next_state = LOAD_S2_1;
      end
      LOAD_S3 : begin
        next_state = LOAD_S3_1;
      end
      LOAD_S3_1 : begin
        next_state = LOAD_S3_2;
      end
      LOAD_S3_2 : begin
        if(~bm_done) // wait until the done flag returns to 0
          next_state = LOAD_S3_3;
        else
          next_state = LOAD_S3_2;
      end
      LOAD_S3_3 : begin // wait for bm_done
        if(bm_done)
          next_state = LOAD_S4;
        else
          next_state = LOAD_S3_3;
      end
      LOAD_S4 : begin
        next_state = LOAD_S4_1;
      end
      LOAD_S4_1 : begin
        next_state = LOAD_S4_2;
      end
      LOAD_S4_2 : begin
        if(counter == ( 1 << (DEPTH - 1) ) ) begin
          if(k >= 4 /*KYBER_K + 1*/)
            next_state = REDC_S0;
          else
            next_state = LOAD_S3;
        end
        else
          next_state = LOAD_S4_2;
      end
      REDC_S0 : begin
        next_state = REDC_S0_1;
      end
      REDC_S0_1 : begin
        if(counter == 1)
          next_state = REDC_S0_2;
        else
          next_state = REDC_S0_1;
      end
      REDC_S0_2 : begin
        if(counter == (1 << (DEPTH-1))) 
          next_state = DOUT_S0;
        else
          next_state = REDC_S0_2;
      end
      DOUT_S0 : begin
        next_state = DOUT_S0_1;
      end
      DOUT_S0_1 : begin
        next_state = STAT_S0;
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
    k <= 1;
    index_a_ctrl <= 0;
    index_b_ctrl <= 0;
    index_c_ctrl <= 0;
    
    bm_readin_a <= 0;
    bm_readin_b <= 0;

    bm_full_in_a <= 0;
    bm_full_in_b <= 0;
    ram_a_we_ok <= 0;
    ram_b_we_ok <= 0;
    ram_c_we_ok <= 0;
    barr_redc <= 0;
    isload <= 0;
    done <= 0;
  end
  else if(set) begin
    case (curr_state)
      STAT_S0 : begin
        //done <= 0; // ?
        isload <= 0;
        index_a_ctrl <= 0;
        index_b_ctrl <= 0;
        //index_c_ctrl <= 0;
        counter_ctrl <= 0;
        
        ram_a_we_ok <= 1;
        ram_b_we_ok <= 1;
        
        readin_a_ok <= 1; // pulse
        readin_b_ok <= 1;
      end
      STAT_S0_1 : begin
        readin_a_ok <= 0; // pulse
        readin_b_ok <= 0;
      end
      STAT_S1 : begin
        ram_a_we_ok <= 0;
        ram_b_we_ok <= 0;

      end
      LOAD_S0 : begin
        done <= 0;
        isload <= 1;
        index_a_ctrl <= 1;
        index_b_ctrl <= 1;
        k <= 1;
      end
      LOAD_S0_1 : begin // wait for counter
        bm_readin_a <= 1; // reading from RAM lags by one
        bm_readin_b <= 1;
        counter_ctrl <= 1;
      end 
      LOAD_S1 : begin
        index_a_ctrl <= 0;
        index_b_ctrl <= 0;
        counter_ctrl <= 0;
        bm_readin_a <= 0;
        bm_readin_b <= 0;

        bm_full_in_a <= 1; // pulse
        bm_full_in_b <= 1;
      end
      LOAD_S1_1 : begin
        bm_full_in_a <= 0; // pulse
        bm_full_in_b <= 0; 
        bm_cal_en <= 1; // pulse
      end
      LOAD_S1_2 : begin // wait for bm_done
        bm_cal_en <= 0; // pulse
      end
      LOAD_S2 : begin //pulse
        bm_readout <= 1;

        index_a_ctrl <= 1; // start index
        index_b_ctrl <= 1;
        //k <= k + 1;
        k <= 2;
      end
      LOAD_S2_1 : begin // wait for counter
        counter_ctrl <= 1;
        ram_c_we_ok <= 1;

        bm_readin_a <= 1; // reading from RAM lags by one
        bm_readin_b <= 1;
      end
      LOAD_S3 : begin
        index_a_ctrl <= 0; // stop index
        index_b_ctrl <= 0;
        index_c_ctrl <= 0;

        counter_ctrl <= 0;
        
        bm_readin_a <= 0;
        bm_readin_b <= 0;
        bm_readout <= 0;
        
        ram_c_we_ok <= 0;

        bm_full_in_a <= 1; //pulse
        bm_full_in_b <= 1;
      end
      LOAD_S3_1 : begin
        bm_full_in_a <= 0;
        bm_full_in_b <= 0;
        bm_cal_en <= 1; // pulse
      end
      LOAD_S3_2 : begin
        bm_cal_en <= 0; // pulse
      end
      LOAD_S3_3 : begin // wait for bm_done
        // no op
      end
      LOAD_S4 : begin // TODO: thing time add the value already in RAMC
        index_a_ctrl <= 1;
        index_b_ctrl <= 1;
        counter_ctrl <= 1;
        k <= k + 1;
      end
      LOAD_S4_1 : begin
        index_c_ctrl <= 1;
        bm_readin_a <= 1;
        bm_readin_b <= 1;
        bm_readout <= 1;

      end
      LOAD_S4_2 : begin
        ram_c_we_ok <= 1;
      end
      REDC_S0 : begin // REDUCTION FOR RAM C
        index_a_ctrl <= 0; // stop index
        index_b_ctrl <= 0;
        index_c_ctrl <= 0;
        counter_ctrl <= 0;
        
        bm_readin_a <= 0;
        bm_readin_b <= 0;
        bm_readout <= 0;

        ram_c_we_ok <= 0;
        
        bm_cal_en <= 1; // pulse, clear the flags :>
      end
      REDC_S0_1 : begin
        bm_cal_en <= 0;
        
        index_c_ctrl <= 1;
        counter_ctrl <= 1;

        barr_redc <= 1;
      end
      REDC_S0_2 : begin
        ram_c_we_ok <= 1;
        
      end
      DOUT_S0 : begin
        isload <= 0;
        barr_redc <= 0;
        ram_c_we_ok <= 0;
        index_c_ctrl <= 0;
        bm_cal_en <= 1; // pulse
      end
      DOUT_S0_1 : begin
        bm_cal_en <= 0; // pulse
        index_c_ctrl <= 1;
        done <= 1; // all done!
        
      end
    endcase
  end
end

endmodule