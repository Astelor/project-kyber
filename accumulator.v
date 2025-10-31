/*
A special accumulator that contains a memory block
*/
module accumulator(
  input clk,
  input set,
  input reset,

  input  [ 3:0] cmd,  // command to choose things :>
  // 0 nothing
  // 1 acc no addition, write in memory
  // 2 acc yes addition, pull data from memory, perform addition with input data, and write it back
  // 3 output the data in the memory
  // TODO: does it need a command to clear the memory?
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

wire [3:0] ctrl;
wire ram_a_s_we, ram_b_s_we;

accumulator_fsm fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  
  .ctrl(ctrl),
  .ram_a_s_we(ram_a_s_we),
  .ram_b_s_we(ram_b_s_we),
  .cmd(cmd), // from outside
  .status(status) // to outside
);

// MODULES END ================================== 

// LOCAL REG BEGIN ==============================
reg [15:0] data_a_t;
reg [15:0] data_b_t;
reg [ 6:0] addr_a_t;
reg [ 6:0] addr_b_t;
reg [ 6:0] counter;
reg [ 6:0] counter_t_1;
reg [ 6:0] counter_t_2;
// LOCAL REG END ================================

// ASSGIN BEGIN =================================
assign ram_a_we_2 = ram_a_s_we; 
assign ram_b_we_2 = ram_b_s_we; 
assign ram_a_we_1 = 0;
assign ram_b_we_1 = 0;

// ASSGIN END ===================================

always @(*) begin
  if(set && ctrl == 2) begin
    adder_a_data_1 = ram_a_dout_1;
    adder_b_data_1 = ram_b_dout_1;
  end
  else begin
    adder_a_data_1 = 0;
    adder_b_data_1 = 0;
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
      1 : begin
        // no add
        ram_a_addr_2 <= addr_a;
        ram_b_addr_2 <= addr_b;
        ram_a_din_2  <= data_a;
        ram_b_din_2  <= data_b;
      end 
      2 : begin
        // yes add
        // RAM
        ram_a_addr_1   <= addr_a;
        ram_b_addr_1   <= addr_b;
        ram_a_addr_2   <= adder_a_addr_out;
        ram_b_addr_2   <= adder_b_addr_out;
        ram_a_din_2    <= adder_a_data_out;
        ram_b_din_2    <= adder_b_data_out;
        
        // ADDER
        adder_a_addr   <= addr_a_t;
        adder_b_addr   <= addr_b_t;
        // adder_a_data_1 <= ram_a_dout_1;
        // adder_b_data_1 <= ram_b_dout_1;
        adder_a_data_2 <= data_a_t;
        adder_b_data_2 <= data_b_t;
      end
      3 : begin
        // output memory
        counter      <= counter + 7'd1;
        ram_a_addr_1 <= counter;
        ram_b_addr_1 <= counter;

        addr_out     <= counter_t_2; // TODO: this is delayed
        data_a_out   <= ram_a_dout_1;
        data_b_out   <= ram_b_dout_1;
      end
      default: begin
        
      end 
    endcase
  end
  else begin
    
  end
end

// data propagation to account for RAM read delay
always @(posedge clk) begin
  data_a_t    <= data_a;
  data_b_t    <= data_b;
  addr_a_t    <= addr_a;
  addr_b_t    <= addr_b;
  counter_t_1 <= counter;
  counter_t_2 <= counter_t_1;
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

module accumulator_fsm (
  input clk,
  input set,
  input reset,

  output reg [3:0] ctrl,
  output reg ram_a_s_we,
  output reg ram_b_s_we,
  input [3:0] cmd, 
  output reg [3:0] status
);

localparam IDLE     = 1;
// localparam MODE_0   = 2;
localparam MODE_1   = 3;
localparam MODE_2   = 4;
localparam MODE_2_0 = 6;
localparam MODE_2_1 = 7;
localparam MODE_2_2 = 8;
localparam MODE_2_3 = 9;
localparam MODE_3   = 5;

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
          default: next_state = IDLE;
        endcase
      end
      // MODE_0 : begin
      //   if(cmd != 0)
      //     next_state = IDLE;
      //   else
      //     next_state = MODE_0;
      // end
      // MODE 1
      MODE_1 : begin
        if(cmd != 1)
          next_state = IDLE;
        else
          next_state = MODE_1;
      end
      // MODE 2
      MODE_2 : begin
        next_state = MODE_2_0;
      end
      MODE_2_0 : begin
        next_state = MODE_2_1;
      end
      MODE_2_1 : begin
        if(cmd != 2)
          next_state = MODE_2_2;
        else
          next_state = MODE_2_1;
      end
      MODE_2_2 : begin
        next_state = MODE_2_3;
      end
      MODE_2_3 : begin
        next_state = IDLE;
      end
      // MODE 3
      MODE_3 : begin
        if(cmd != 3)
          next_state = IDLE;
        else
          next_state = MODE_3;
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
    ram_a_s_we <= 0;
    ram_b_s_we <= 0;
  end
  else if(set) begin
    case(curr_state) 
      IDLE : begin
        status_task(0);
        ctrl_task(0);
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
      end
      MODE_2_0 : begin
        // ?
      end
      MODE_2_1 : begin
        ram_a_s_we <= 1;
        ram_b_s_we <= 1;
      end
      MODE_2_2 : begin
        // ?
      end
      MODE_2_3 : begin
        // ?
      end
      // MODE 3
      MODE_3 : begin
        status_task(3);
        ctrl_task(3);
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