/*
A special accumulator that contains a memory block.
It doesn't have much guardrails, it does what the input tells it to do. 
*/
module accumulator #(parameter DD = 4)(
  input clk,
  input set,
  input reset,

  input  [ 3:0] cmd,  // command to choose things :>
  // 0 nothing
  // 1 acc no addition, write in memory
  // 2 acc yes addition, pull data from memory, perform addition with input data, and write it back
  // 3 output the data in the memory
  // 4 compress and encode the data in memory, and write it back
  // TODO: does it need a command to clear the memory?
  input             readin, // because my design sucks
  input             readout,
  input      [ 6:0] addr_a,
  input      [ 6:0] addr_b,
  input      [15:0] data_a,
  input      [15:0] data_b,

  output reg [ 6:0] addr_out,
  output reg [15:0] data_a_out,
  output reg [15:0] data_b_out,
  
  output     [ 3:0] status // directly correspond to the command its executing 
);

// MODULES BEGIN ================================
wire        ram_a_we_1,   ram_a_we_2;
reg  [6:0]  ram_a_addr_1, ram_a_addr_2;
reg  [15:0] ram_a_din_1,  ram_a_din_2;
wire [15:0] ram_a_dout_1, ram_a_dout_2;

// EVEN NUMBER ADDRESS
dual_ram #(7, 16) ram_a(
  .clk(clk),
  .we_1  (ram_a_we_1),
  .we_2  (ram_a_we_2),
  .addr_1(ram_a_addr_1),
  .addr_2(ram_a_addr_2),
  .din_1 (ram_a_din_1), // TODO: not used
  .din_2 (ram_a_din_2),
  .dout_1(ram_a_dout_1),
  .dout_2(ram_a_dout_2)
);

// ODD NUMBER ADDRESS
wire        ram_b_we_1,   ram_b_we_2;
reg  [6:0]  ram_b_addr_1, ram_b_addr_2;
reg  [15:0] ram_b_din_1,  ram_b_din_2;
wire [15:0] ram_b_dout_1, ram_b_dout_2;

// ODD NUMBER ADDRESS
dual_ram #(7, 16) ram_b(
  .clk(clk),
  .we_1  (ram_b_we_1),
  .we_2  (ram_b_we_2),
  .addr_1(ram_b_addr_1),
  .addr_2(ram_b_addr_2),
  .din_1 (ram_b_din_1), // TODO: not used
  .din_2 (ram_b_din_2),
  .dout_1(ram_b_dout_1),
  .dout_2(ram_b_dout_2)
);

reg  [15:0] adder_a_data_1;
reg  [15:0] adder_a_data_2;
reg  [ 6:0] adder_a_addr;
wire [15:0] adder_a_data_out;
wire [ 6:0] adder_a_addr_out;

adder_special adder_a(
  .clk(clk),
  .set(set),
  .data_1  (adder_a_data_1),
  .data_2  (adder_a_data_2),
  .addr    (adder_a_addr),
  .data_out(adder_a_data_out),
  .addr_out(adder_a_addr_out)
);

reg  [15:0] adder_b_data_1;
reg  [15:0] adder_b_data_2;
reg  [ 6:0] adder_b_addr;
wire [15:0] adder_b_data_out;
wire [ 6:0] adder_b_addr_out;

adder_special adder_b(
  .clk(clk),
  .set(set),
  .data_1  (adder_b_data_1),
  .data_2  (adder_b_data_2),
  .addr    (adder_b_addr),
  .data_out(adder_b_data_out),
  .addr_out(adder_b_addr_out)
);

wire comp_readin;
wire comp_reset;
reg [15:0] comp_din1;
reg [15:0] comp_din2;

wire [15:0] comp_dout1;
wire [15:0] comp_dout2;
wire comp_readout_ok;

compress_encode #(DD) comp(
  .clk(clk),
  .set(set),
  .reset(comp_reset),
  .readin(comp_readin),
  .din1(comp_din1),
  .din2(comp_din2),
  .dout1(comp_dout1),
  .dout2(comp_dout2),
  .readout_ok(comp_readout_ok)
);

wire [3:0] ctrl;
wire ram_a_s_we, ram_b_s_we;
wire [6:0] counter_s;
wire [6:0] comp_counter_s;
wire comp_readout_ok_s;
wire comp_reset_s;
accumulator_fsm #(DD) fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  
  .cmd(cmd), // from outside
  .readin(readin), // from outside
  .ctrl(ctrl),
  .counter(counter_s),
  .comp_counter(comp_counter_s),
  .comp_readout_ok(comp_readout_ok_s),
  
  .ram_a_s_we(ram_a_s_we),
  .ram_b_s_we(ram_b_s_we),
  .comp_reset_s(comp_reset_s),
  .status(status) // to outside
);

// MODULES END ================================== 

// LOCAL REG BEGIN ==============================
// readin
reg readin_t;
reg readin_t_1;
// reg readin_t_2;
// data
reg [15:0] data_a_t;
reg [15:0] data_b_t;
// addr
reg [ 6:0] addr_a_t;
reg [ 6:0] addr_b_t;
// counter, it's only used for output
reg [ 6:0] counter;
reg [ 6:0] counter_t_1;
// reg [ 6:0] counter_t_2;

// ram regs
reg ram_a_we_2_r;
reg ram_b_we_2_r;

// comp readin
reg comp_readin_r;
reg [6:0] comp_counter;

// LOCAL REG END ================================

// ASSGIN BEGIN =================================
assign ram_a_we_2 = ram_a_we_2_r; //ram_a_s_we & readin_t_1; // the sequence delay for cmd 1 and 2 are different, this config works for cmd 1 but not 2. cmd 2 needs readin_t_2
assign ram_b_we_2 = ram_b_we_2_r; //ram_b_s_we & readin_t_1;
assign ram_a_we_1 = 0;
assign ram_b_we_1 = 0;

assign counter_s = counter;

assign comp_readin = comp_readin_r;
assign comp_counter_s = comp_counter;
assign comp_readout_ok_s = comp_readout_ok;
assign comp_reset = reset | comp_reset_s ;
// ASSGIN END ===================================

always @(*) begin
  if(set) begin
    // ADDER
    if(readin_t & ctrl == 1 | ctrl == 2) begin
      adder_a_addr   = addr_a_t;
      adder_b_addr   = addr_b_t;
      adder_a_data_1 = data_a_t;
      adder_b_data_1 = data_b_t;
    end
    else begin
      adder_a_addr   = 0;
      adder_b_addr   = 0;
      adder_a_data_1 = 0;
      adder_b_data_1 = 0;
    end

    if(ctrl == 2 & readin_t) begin
      adder_a_data_2 = ram_a_dout_1;
      adder_b_data_2 = ram_b_dout_1;
    end
    else begin
      adder_a_data_2 = 0;
      adder_b_data_2 = 0;
    end
    // RAM
    if(readin & ctrl == 2) begin
      ram_a_addr_1   = addr_a;
      ram_b_addr_1   = addr_b;
    end
    else if(ctrl == 3 | ctrl == 4) begin
      ram_a_addr_1 = counter;
      ram_b_addr_1 = counter;
    end
    else begin
      ram_a_addr_1 = 0;
      ram_b_addr_1 = 0;
    end

    if(readin_t_1 & ctrl == 1 | ctrl == 2) begin
      ram_a_addr_2   = adder_a_addr_out;
      ram_b_addr_2   = adder_b_addr_out;
      ram_a_din_2    = adder_a_data_out;
      ram_b_din_2    = adder_b_data_out;
    end
    else if(ctrl == 4) begin
      ram_a_addr_2 = comp_counter;
      ram_b_addr_2 = comp_counter;
      ram_a_din_2 = comp_dout1;
      ram_b_din_2 = comp_dout2;
    end
    else begin
      ram_a_addr_2 = 0;
      ram_b_addr_2 = 0;
      ram_a_din_2 = 0;
      ram_b_din_2 = 0;
    end
    // COMPRESS
    if(ctrl == 4) begin
      comp_din1 = ram_a_dout_1;
      comp_din2 = ram_b_dout_1;
    end
    else begin
      comp_din1 = 0;
      comp_din2 = 0;
    end
    // OUTPUT
    if(ctrl == 3) begin
      data_a_out   = ram_a_dout_1;
      data_b_out   = ram_b_dout_1;
      addr_out     = counter_t_1;
    end
    // else begin
    //   data_a_out = 0;
    //   data_b_out = 0;
    //   addr_out = 0;
    // end
    /* case (ctrl)
      // 0 : begin
        
      // end
      1 : begin // MODE 1 
        if(readin_t) begin
          adder_a_addr   = addr_a_t;
          adder_b_addr   = addr_b_t;
          adder_a_data_1 = data_a_t;
          adder_b_data_1 = data_b_t;
          adder_a_data_2 = 0;
          adder_b_data_2 = 0;
        end
        if(readin_t_1) begin
          ram_a_addr_2 = adder_a_addr_out;
          ram_b_addr_2 = adder_b_addr_out;

          ram_a_din_2  = adder_a_data_out;
          ram_b_din_2  = adder_b_data_out;
        end
      end
      2 : begin // MODE 2
        if(readin) begin
          ram_a_addr_1   = addr_a;
          ram_b_addr_1   = addr_b;
        end
        if(readin_t) begin
          adder_a_addr   = addr_a_t;
          adder_b_addr   = addr_b_t;
          adder_a_data_1 = data_a_t;
          adder_b_data_1 = data_b_t;
          adder_a_data_2 = ram_a_dout_1;
          adder_b_data_2 = ram_b_dout_1;
        end
        if(readin_t_1) begin
          ram_a_addr_2   = adder_a_addr_out;
          ram_b_addr_2   = adder_b_addr_out;
          ram_a_din_2    = adder_a_data_out;
          ram_b_din_2    = adder_b_data_out;
        end
      end
      3 : begin // MODE 3
        ram_a_addr_1 = counter;
        ram_b_addr_1 = counter;
        
        addr_out     = counter_t_1; // TODO: this is delayed
        
        data_a_out   = ram_a_dout_1;
        data_b_out   = ram_b_dout_1;
      end
      4 : begin // MODE 4
        ram_a_addr_1 = counter;
        ram_b_addr_1 = counter;
        
        comp_din1 = ram_a_dout_1;
        comp_din2 = ram_b_dout_1;
        
        ram_a_addr_2 = comp_counter;
        ram_b_addr_2 = comp_counter;
        
        ram_a_din_2 = comp_dout1;
        ram_b_din_2 = comp_dout2;
      end
      default : begin
        adder_a_data_1 = 0;
        adder_b_data_1 = 0;
      end
    endcase */
  end
end

// TODO: these condition chains have much to improve in the RTL level
always @(posedge clk or posedge reset) begin
  if(reset)begin
    counter <= 0;
  end
  else if(set) begin
    case (ctrl)
      0 : begin
        // idle
        counter <= 0; // TODO: does this need a specific unstable signal resistant thing?, maybe redundant.
      end
      3 : begin
        // output memory
        if(readout) begin
            counter <= counter + 7'd1;
        end
      end
      4 : begin
        // compress and encode
        counter <= counter + 7'd1;
      end
    endcase
  end
end

// NOTE: this one uses the special comp_reset that is combo'd with external reset
always @(posedge clk or posedge comp_reset) begin
  if(comp_reset) begin
    comp_counter <= 0;
  end
  else if(set) begin
    if(ctrl == 4 & comp_readout_ok == 1) begin
      comp_counter <= comp_counter + 7'd1;
    end
  end
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    comp_readin_r <= 0;
  end
  else if(set) begin
    if(ctrl == 4) begin
      comp_readin_r <= 1;
    end
    else begin
      comp_readin_r <= 0;
    end
  end
end

always @(*) begin
  if(set) begin
    if(ctrl == 1 | ctrl == 2 | ctrl == 3 )begin
      ram_a_we_2_r = ram_a_s_we & readin_t_1;
      ram_b_we_2_r = ram_b_s_we & readin_t_1;
    end
    else if (ctrl == 4) begin
      ram_a_we_2_r = ram_a_s_we & comp_readout_ok;
      ram_b_we_2_r = ram_b_s_we & comp_readout_ok;
    end
    else begin
      ram_a_we_2_r = 0;
      ram_b_we_2_r = 0;
    end
  end
end

// data propagation to account for RAM read delay
always @(posedge clk) begin
  // readin
  readin_t    <= readin;
  readin_t_1  <= readin_t;
  // readin_t_2  <= readin_t_1;
  // data
  data_a_t    <= data_a;
  data_b_t    <= data_b;
  // addr
  addr_a_t    <= addr_a;
  addr_b_t    <= addr_b;
  // counter
  counter_t_1 <= counter;
  // counter_t_2 <= counter_t_1;
end

endmodule

// synchronized adder, with address passed along
module adder_special(
  input clk,
  input set,
  // input reset,

  input [15:0] data_1,
  input [15:0] data_2,
  input [ 6:0] addr,

  output reg [15:0] data_out,
  output reg [ 6:0] addr_out
);

always @(posedge clk) begin
  if(set) begin
    data_out <= data_1 + data_2;
    addr_out <= addr;
  end
end

endmodule

/*
To make the module more stable, since it accepts commands and status
*/

module accumulator_fsm #(parameter DD = 4) (
  input clk,
  input set,
  input reset,

  input [3:0] cmd,
  input       readin,
  input [6:0] counter,
  input [6:0] comp_counter,
  input comp_readout_ok,

  output reg [3:0] ctrl,
  output reg       ram_a_s_we,
  output reg       ram_b_s_we,
  output reg       comp_reset_s,
  output reg [3:0] status
);

generate
  wire [6:0] DELAY;
  if(DD == 4) begin
    assign DELAY = 32;
  end
  else if(DD == 10) begin
    assign DELAY = 79;
  end
endgenerate

localparam IDLE   = 1;
localparam MODE_1 = 2;
localparam MODE_2 = 3;
localparam MODE_3 = 4;
localparam MODE_4 = 5;
localparam COMP_DONE = 6;
localparam OUTPUT_DONE = 7;

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

always @(*) begin
  if(set) begin
    case(curr_state)
      IDLE : begin
        case (cmd)
          // 0 :      next_state = MODE_0;
          1 : next_state = MODE_1;
          2 : next_state = MODE_2;
          3 : next_state = MODE_3;
          4 : next_state = MODE_4;
          default: next_state = IDLE;
        endcase
      end
      // MODE 1
      MODE_1 : begin
        if(cmd != 1)
          next_state = IDLE;
        else
          next_state = MODE_1;
      end
      // MODE 2
      MODE_2 : begin
        if(cmd != 2)
          next_state = IDLE;
        else
          next_state = MODE_2;
      end
      // MODE 3
      MODE_3 : begin
        if(cmd != 3)
          next_state = IDLE;
        else if(counter >= (DD*8-1))
          next_state = OUTPUT_DONE;
        else
          next_state = MODE_3;
      end
      OUTPUT_DONE : begin
        if(cmd != 3)
          next_state = IDLE;
        else
          next_state = OUTPUT_DONE;
      end
      MODE_4 : begin
        if(comp_counter == DELAY) //79 -> DD = 10. 32 -> DD = 4
          next_state = COMP_DONE;
        else
          next_state = MODE_4;
      end
      COMP_DONE : begin
        if(cmd != 4)
          next_state = IDLE;
        else
          next_state = COMP_DONE;
      end
      default: begin
        $display("forbidden state");
      end
    endcase
  end
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    // reset flags here
    status_task(0);
    ctrl_task(0);
    comp_reset_s <= 0;
    ram_a_s_we <= 0;
    ram_b_s_we <= 0;
  end
  else if(set) begin
    case(curr_state) 
      IDLE : begin
        status_task(0);
        ctrl_task(0);
        comp_reset_s <= 0;
        ram_a_s_we <= 0;
        ram_b_s_we <= 0;
      end
      // MODE 1
      MODE_1 : begin
        status_task(1);
        ctrl_task(1);
        ram_a_s_we <= 1;
        ram_b_s_we <= 1;
      end
      // MODE 2
      MODE_2 : begin
        status_task(2);
        ctrl_task(2);
        ram_a_s_we <= 1;
        ram_b_s_we <= 1;
      end
      // MODE 3
      MODE_3 : begin
        status_task(3);
        ctrl_task(3);
      end
      OUTPUT_DONE : begin
        status_task(6);
        ctrl_task(0);
      end
      // MODE 4
      MODE_4 : begin
        status_task(4);
        ctrl_task(4);
        ram_a_s_we <= 1;
        ram_b_s_we <= 1;
      end
      COMP_DONE : begin
        status_task(5);
        ctrl_task(0);
        comp_reset_s <= 1;
        ram_a_s_we <= 0;
        ram_b_s_we <= 0;
      end
    endcase
  end
end

task ctrl_task (input [3:0] tk);
begin
  ctrl <= tk;
end
endtask

task status_task (input [3:0] tk);
begin
  status <= tk;
end
endtask

endmodule