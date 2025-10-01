module decompress1(
  input clk,
  input set,
  input reset,
  input readin, // KEY
  input readout, // UPSCALED
  input full_in,
  input [7:0] decomp_din,  // the output of hash modules are in BYTEs
  input [7:0] in_index,

  output reg  [15:0] decomp_dout_1,
  output reg  [15:0] decomp_dout_2,
  output reg  [7:0] out_index,

  output wire readin_ok,
  output wire readout_ok,
  output wire done
);  


// MODULE BEGIN ===============================//
// RAM
wire       ram_we_1  ;   
reg        ram_we_2  ;
reg  [4:0] ram_addr_1, ram_addr_2;
wire [7:0] ram_din_1 ; 
reg  [7:0] ram_din_2 ;
wire [7:0] ram_dout_1, ram_dout_2;
// (2^5)*8 = 256
dual_ram #(5, 8) ram(
  .clk(clk),
  .we_1  (ram_we_1),
  .we_2  (ram_we_2),
  .addr_1(ram_addr_1),
  .addr_2(ram_addr_2),
  .din_1 (ram_din_1),
  .din_2 (ram_din_2),
  .dout_1(ram_dout_1),
  .dout_2(ram_dout_2)
);

// CAL
wire        cal1_set;
reg         cal1_b;
wire [15:0] cal1_r;
decompress1_cal cal1(
  .clk(clk),
  .set(set),
  .b(cal1_b),
  .r(cal1_r)
);
wire        cal2_set;
reg         cal2_b;
wire [15:0] cal2_r;
decompress1_cal cal2(
  .clk(clk),
  .set(set),
  .b(cal2_b),
  .r(cal2_r)
);

// FSM
wire readin_ok_fsm;
wire ram_we_ok;
wire readout_ok_fsm;
wire [3:0] ctrl_status;
wire [7:0] counter_fsm;
wire counter_ctrl;

decompress1_fsm fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  .full_in      (full_in),
  .readout      (readout),
  .counter      (counter_fsm),

  // OUTPUT
  .counter_ctrl  (counter_ctrl),
  .ram_we_ok     (ram_we_ok),
  .readin_ok_fsm (readin_ok_fsm),
  .readout_ok_fsm(readout_ok_fsm),
  .ctrl_status   (ctrl_status),
  .done(done)
);

// MODULE END =================================//

// LOCAL REGS BEGIN ===========================//
reg readin_ok_r;
reg [7:0] counter;
reg [7:0] temp;
reg [7:0] out_index_temp;
// LOCAL REGS END =============================//

// ASSIGN BEGIN ===============================//
// OUTSIDE
assign readout_ok  = readout_ok_fsm;
assign readin_ok   = readin_ok_r;

// RAM
// port 1 read, port 2 write
assign ram_we_1   = 0;
assign ram_din_1  = 0;

// CAL
assign cal1_set = set & readout_ok_fsm;
assign cal2_set = set & readout_ok_fsm;

// FSM
assign counter_fsm = counter;

// ASSIGN END =================================//

// I have a feeling that making it combinational is problematic
always @(*) begin
  decomp_dout_1 = cal1_r;
  decomp_dout_2 = cal2_r;
end

parameter OFFSET = 1;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    counter    <=   0;
    ram_we_2   <= 'dz;
    ram_addr_2 <= 'dz;
    ram_din_2  <= 'dz;
  end
  else if (set) begin
    case (ctrl_status) 
      1 : begin
        ram_we_2   <= ram_we_ok & readin_ok;
        ram_addr_2 <= in_index;
        ram_din_2  <= decomp_din;
      end
      2 : begin // DRAW (not readout dependent)
        ram_addr_1 <= counter; // read
      end
      3 : begin // OUTPUT READY (not readout dependent)
        ram_we_2   <= 1; // this can also be set to 1 or ram_we_ok?
        ram_addr_2 <= counter - 1;
        ram_din_2  <= 0;
      end 
      4 : begin // output 0 (not readout dependent)
        ram_we_2 <= 0;
        temp     <= ram_dout_1;
      end
      5 : begin // output 1
        out_index_temp <= ((counter - OFFSET) << 2) + 0;
        cal_task(0);
      end
      6 : begin // output 2
        out_index_temp <= ((counter - OFFSET) << 2) + 1;
        cal_task(1);
      end
      7 : begin // output 3
        out_index_temp <= ((counter - OFFSET) << 2) + 2;
        cal_task(2);
      end
      8 : begin // output 4
        out_index_temp <= ((counter - OFFSET) << 2) + 3;
        cal_task(3);
      end
      default: begin
        // status is resetted to 0 in the FSM
        $display("default??");
      end 
    endcase
  end
end

task cal_task(input [3:0] tp);
begin
  cal1_b <= (( temp >> (0 + (tp << 1)) ) & 1);
  cal2_b <= (( temp >> (1 + (tp << 1)) ) & 1);
end
endtask

// a better readin_ok latch -> sequential
always @(posedge clk or posedge reset) begin
  if(reset) begin
    readin_ok_r <= 0;
  end
  else if(set) begin
    if(readin_ok_fsm) begin
      readin_ok_r <= 1;
    end
    else if(full_in) begin
      readin_ok_r <= 0;
    end
  end
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    counter <= 0;
    out_index_temp <= 0;
  end
  else if(set) begin
    out_index <= out_index_temp;
    if(readin_ok_fsm) begin
      counter <= 0;
    end
    else if(counter_ctrl) begin
      counter <= counter + 1;
    end
  end
end

endmodule

module decompress1_fsm(
  input clk,
  input set,
  input reset,
  
  // OUTSIDE
  input full_in,
  input readout,
  input [7:0] counter,
  output reg  counter_ctrl,
  output reg  readin_fsm,
  output reg  ram_we_ok,
  output reg  readin_ok_fsm,
  output reg  readout_ok_fsm,
  output reg [3:0] ctrl_status, // idk if it's actually needed :P
  output reg done // -> ??
);

localparam IDLE         = 1;
localparam INPUT        = 2;
localparam READY        = 3;
localparam DRAW         = 4;
localparam OUTPUT_READY = 5;
localparam OUTPUT_0     = 6;
localparam OUTPUT_1     = 7;
localparam OUTPUT_2     = 8;
localparam OUTPUT_3     = 9;
localparam OUTPUT_4     = 10;

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
        next_state = INPUT;
      end
      INPUT : begin
        if(full_in)
          next_state = READY;
        else
          next_state = INPUT;
      end
      READY : begin
        next_state = DRAW;
      end
      DRAW : begin
        // make it so that it only draw once?
        // so that it's not dependent on readout signal
        // if(readout)
        if(counter >= 32)
          next_state = IDLE;
        else  
          next_state = OUTPUT_READY;
      end
      OUTPUT_READY : begin 
        next_state = OUTPUT_0;
      end
      OUTPUT_0 : begin
        next_state = OUTPUT_1;
      end
      OUTPUT_1 : begin
        if(readout)
          next_state = OUTPUT_2;
        else
          next_state = OUTPUT_1;
      end
      OUTPUT_2 : begin
        if(readout)
          next_state = OUTPUT_3;
        else
          next_state = OUTPUT_2;
      end
      OUTPUT_3 : begin
        if(readout)
          next_state = OUTPUT_4;
        else
          next_state = OUTPUT_3;
      end
      OUTPUT_4 : begin
        if(readout)
          next_state = DRAW;
        else
          next_state = OUTPUT_4;
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
    status(0);
    readin_ok_fsm  <= 0;
    readin_fsm     <= 0;
    ram_we_ok      <= 0;
    readout_ok_fsm <= 0;
    done           <= 0;
  end
  else if(set) begin
    case(curr_state) 
      IDLE : begin
        status(1);
        readin_ok_fsm  <= 1; // pulse high
        readout_ok_fsm <= 0;
        counter_ctrl   <= 0;
      end
      INPUT: begin
        readin_ok_fsm <= 0; // pulse low
        ram_we_ok     <= 1;
        status(1);
      end
      READY : begin
        ram_we_ok      <= 0;
        readout_ok_fsm <= 1;
      end
      DRAW : begin
        status(2);
        counter_ctrl <= 1;
      end
      OUTPUT_READY : begin
        status(3);
        counter_ctrl <= 0; // increment by one
      end
      OUTPUT_0 : begin
        status(4);
      end
      OUTPUT_1 : begin
        status(5);
      end
      OUTPUT_2 : begin
        status(6);
      end
      OUTPUT_3 : begin
        status(7);
      end
      OUTPUT_4 : begin
        status(8);
      end
    endcase
  end
end

task status(input [3:0] st);
begin
  ctrl_status <= st;
end
endtask

endmodule