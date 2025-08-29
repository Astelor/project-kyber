module invntt_fsm #(parameter DEPTH = 8)(
  input clk,
  input set,
  input reset,
  input readin,
  input readout,
  input cal_en,
  input full_in,
  input full_out,

  output reg rd_ctrl,
  output reg wr_ctrl,
  //output reg doing_cal,
  output reg ram1_we,
  output reg ram2_we,
  output reg layer_type,
  
  output reg readin_ok,
  
  output reg done
);

// timings
parameter TIM_S0 = 4;
parameter TIM_S1 = (1 << (DEPTH-1)) - 8;
parameter TIM_S2 = 5;
parameter TIM_STATE_S4 = 1;

// one-hot encoding
// TODO: clean up the codes using one-hot encoding
// 9'b0_0000_0001
parameter STATE_S0     = 10'b00_0000_0001;
parameter STATE_S1     = 10'b00_0000_0010;
parameter STATE_S2     = 10'b00_0000_0100;
parameter STATE_S3     = 10'b00_0000_1000;
parameter STATE_S4     = 10'b00_0001_0000;
parameter COMPUTE_S0   = 10'b00_0010_0000;
parameter COMPUTE_S0_1 = 10'b00_0100_0000;
parameter COMPUTE_S1   = 10'b00_1000_0000;
parameter COMPUTE_S2   = 10'b01_0000_0000;
parameter COMPUTE_S2_1 = 10'b10_0000_0000;

reg [9:0] curr_state;
reg [9:0] next_state;

reg [7:0] timer; // reuse timer because why not :>
reg [2:0] layer; 

// current state
always @(posedge clk or posedge reset) begin
  if(reset) begin
    //curr_state <= STATE;
    curr_state <= STATE_S4;
  end 
  else begin
    curr_state <= next_state;
  end
end

// next state
always @(*) begin
  if(set) begin
    case(curr_state)
      COMPUTE_S0: begin
        if(timer == TIM_S0)
          next_state = COMPUTE_S0_1;
        else 
          next_state = COMPUTE_S0;
      end
      COMPUTE_S0_1: begin
        next_state = COMPUTE_S1;
      end
      COMPUTE_S1: begin
        if(timer == TIM_S1)
          next_state = COMPUTE_S2;
        else
          next_state = COMPUTE_S1;
      end
      COMPUTE_S2: begin
        if(timer == TIM_S2)
          next_state = COMPUTE_S2_1;
        else
          next_state = COMPUTE_S2;
      end
      COMPUTE_S2_1: begin
        if(layer == DEPTH)
          next_state = STATE_S2;
        else
          next_state = COMPUTE_S0;
      end
      STATE_S4: begin
        if(readin && timer == TIM_STATE_S4)
          next_state = STATE_S0;
        else
          next_state = STATE_S4;
      end
      STATE_S0: begin
        if(full_in)
          next_state = STATE_S1;
        else
          next_state = STATE_S0;
      end
      STATE_S1: begin
        if(cal_en)
          next_state = COMPUTE_S0;
        else
          next_state = STATE_S1;
      end
      STATE_S2: begin
        if(full_out)
          next_state = STATE_S4;
        else
          next_state = STATE_S2;
      end
      default: begin
        $display("forbidden state");
      end
    endcase
  end
end

// output
always @(posedge clk or posedge reset) begin
  if(reset) begin 
    // ideally it should not need a force reset for every computation
    // output flags
    /*
    rd_ctrl <= 0;
    wr_ctrl <= 0;

    ram1_we <= 0;
    ram2_we <= 0;
    
    done <= 0;
    */
    // internal regs
    timer <= 0;
    layer <= 1;
    //readin_ok <= 1;
  end
  else if(set) begin
    // layer =============================
    if(curr_state == COMPUTE_S1 | curr_state == COMPUTE_S2) begin
      if(layer & 'b1 == 1) begin // odd
        ram1_we <= 0;
        ram2_we <= 1;
        layer_type <= 1;
      end
      else begin
        ram1_we <= 1;
        ram2_we <= 0;
        layer_type <= 0;
      end
    end
    case(curr_state)
      COMPUTE_S0: begin
        rd_ctrl <= 1;
        wr_ctrl <= 0;

        ram1_we <= 0;
        ram2_we <= 0;
        // TODO: make the repetitive timer and layer logic into macro/function/task
        // timer =============================
        if(timer < TIM_S0) begin
          timer <= timer + 1;
        end
        else begin
          timer <= 0;
        end
        // layer =============================
        if(layer & 'b1 == 1) begin // odd
          layer_type <= 1;
        end
        else begin
          layer_type <= 0;
        end
      end
      COMPUTE_S0_1: begin
        rd_ctrl <= 1;
        wr_ctrl <= 1;
      end
      COMPUTE_S1: begin
        //rd_ctrl <= 1;
        //wr_ctrl <= 1;
        // timer =============================
        if(timer < TIM_S1) begin
          timer <= timer + 1;
        end
        else begin
          timer <= 0;
        end
      end
      COMPUTE_S2: begin
        rd_ctrl <= 0;
        wr_ctrl <= 1;
        // timer =============================
        if(timer < TIM_S2) begin
          timer <= timer + 1;
        end
        else begin
          layer <= layer + 1; // TODO: can I do this??
          timer <= 0;
        end
      end
      COMPUTE_S2_1: begin
        rd_ctrl <= 1;
        wr_ctrl <= 0;
      end
      // ===============================================
      STATE_S4: begin
        done <= 0;
        readin_ok <= 1;

        rd_ctrl <= 0;
        wr_ctrl <= 0;

        ram1_we <= 0;
        ram2_we <= 0;

        layer <= 1;
        // timer =============================
        if(timer < TIM_STATE_S4) begin
          timer <= timer + 1;
        end
        else begin
          timer <= 0;
        end
      end
      STATE_S0: begin
        done <= 0;
        readin_ok <= 1;

        ram1_we <= 1;
        ram2_we <= 0;
      end
      STATE_S1: begin
        done <= 0;
        readin_ok <= 0;
        
        ram1_we <= 0;
        ram2_we <= 0;
      end
      STATE_S2: begin
        done <= 1;
        readin_ok <= 0;

        rd_ctrl <= 0;
        wr_ctrl <= 0;

        ram1_we <= 0;
        ram2_we <= 0;
      end
      default: begin

      end
    endcase
  end
end


endmodule