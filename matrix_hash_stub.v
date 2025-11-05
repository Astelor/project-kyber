/*
This is the hash stub module specifically for matrix A generation

Since it's rather infeasible to cram two things together and try to make it work
during prototyping stage.
*/

module matrix_hash_stub(
  input clk,
  input set,
  input reset,

  input readin,
  input readout,
  input full_in,
  input [7:0] nonce1, // manage externally for module coherence
  input [7:0] nonce2, 
  input [7:0] matrix_hash_din,
  input [7:0] in_index,

  output [15:0] matrix_hash_dout_1, // goes into polyvec
  output [15:0] matrix_hash_dout_2,
  output [7:0]  out_index,

  output readin_ok,
  output done
);

// localparam DEPTH = 7; // 128 split in two
// genvar i;
// MEMORY BANKS =======================
// RAM A (for input)
wire       ram_a_we_1,   ram_a_we_2;
wire [4:0] ram_a_addr_1, ram_a_addr_2; 
wire [7:0] ram_a_din_1 , ram_a_din_2;
wire [7:0] ram_a_dout_1, ram_a_dout_2;

// RAM B (for output)
wire        ram_b_we_1  , ram_b_we_2  ;
wire [7:0]  ram_b_addr_1, ram_b_addr_2; 
wire [15:0] ram_b_din_1 , ram_b_din_2 ;
wire [15:0] ram_b_dout_1, ram_b_dout_2;

dual_ram #(5, 8) ram_a(
  .clk(clk),
  .we_1  (ram_a_we_1  ),
  .we_2  (ram_a_we_2  ),
  .addr_1(ram_a_addr_1),
  .addr_2(ram_a_addr_2),
  .din_1 (ram_a_din_1 ),
  .din_2 (ram_a_din_2 ),
  .dout_1(ram_a_dout_1),
  .dout_2(ram_a_dout_2)
);

dual_ram #(8, 16) ram_b( // two port output is possible
  .clk(clk),
  .we_1  (ram_b_we_1  ),
  .we_2  (ram_b_we_2  ),
  .addr_1(ram_b_addr_1),
  .addr_2(ram_b_addr_2),
  .din_1 (ram_b_din_1 ),
  .din_2 (ram_b_din_2 ),
  .dout_1(ram_b_dout_1),
  .dout_2(ram_b_dout_2)
);

// FSM
wire iscal;
wire index_a_ctrl;
wire index_b_ctrl;
wire counter_ctrl;
wire ram_a_we_ok_fsm;
wire ram_b_we_ok_fsm;
wire [7:0] counter_fsm;
wire shake128_full_in;
reg [7:0] shake128_done_read;
wire shake128_done = shake128_done_read - 'd48; // it's read as a character
wire readin_ok_fsm;
wire pulse;

matrix_hash_stub_fsm fsm(
  .clk(clk),
  .set(set),
  .reset(reset),

  // INPUT
  .full_in         (full_in), // from external
  .counter         (counter_fsm),
  .shake128_done   (shake128_done),
  // OUTPUT
  .iscal           (iscal),
  .index_a_ctrl    (index_a_ctrl),
  .index_b_ctrl    (index_b_ctrl),
  .counter_ctrl    (counter_ctrl),
  .ram_a_we_ok     (ram_a_we_ok_fsm),
  .ram_b_we_ok     (ram_b_we_ok_fsm),
  .shake128_full_in(shake128_full_in),
  .pulse           (pulse),
  .readin_ok       (readin_ok_fsm), // pulaw
  
  .done(done) // to external 
);
// INTERNAL REG BEGIN =========================//
reg [4:0] index_a;
reg [7:0] index_b;
reg [7:0] counter;
reg readin_ok_r;
reg [7:0] nonce1_r;
reg [7:0] nonce2_r;

// INTERNAL REG END ===========================//

// ASSIGN BEGIN ===============================//
assign ram_a_we_1 = 0;
assign ram_a_we_2 = ram_a_we_ok_fsm & readin_ok_r & readin;

assign ram_a_addr_1 = (iscal) ? index_a : 0;  // yes cal
assign ram_a_addr_2 = (iscal) ? 0 : in_index; // no cal

assign ram_a_din_1 = 0; // read only
assign ram_a_din_2 = (readin_ok) ? matrix_hash_din : 0;

// TODO: umm ram_b_din and ram_a_dout not having any function is intended as a stub

assign ram_b_we_1   = ram_b_we_ok_fsm;
assign ram_b_we_2   = ram_b_we_ok_fsm;
assign ram_b_addr_1 = index_b;
assign ram_b_addr_2 = index_b + 1;
assign ram_b_din_1  = 0;
assign ram_b_din_2  = 0;

assign matrix_hash_dout_1 = (done & readout) ? ram_b_dout_1 : 0;
assign matrix_hash_dout_2 = (done & readout) ? ram_b_dout_2 : 0;

assign out_index = (done & readout) ? (index_b - 2) >> 1: 0;
assign counter_fsm = counter;
assign readin_ok = readin_ok_r;

// ASSIGN END =================================//
integer fd1;
integer fd2;
integer fd3;

// synthesis translate_off
initial begin
  fd1 = $fopen("D:/!Github_coding/project-kyber/sim_hash_stub/test-matrix_hash_stub.txt","w");
  fd2 = $fopen("D:/!Github_coding/project-kyber/sim_hash_stub/matrix_hash.flag","w");
  fd3 = $fopen("D:/!Github_coding/project-kyber/sim_hash_stub/matrix_hash2.flag","r");
end
// synthesis translate_on

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
  // readin_ok_r = (reset) ? 0 : ((readin_ok_r | readin_ok_fsm) & (~full_in));
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    $rewind(fd1);
    $rewind(fd2);
    index_a <= 0;
    index_b <= 0;
    counter <= 0;
  end
  else if(set) begin
    if(index_a_ctrl) begin
      index_a <= index_a + 1;
    end
    if(counter_ctrl) begin
      counter <= counter + 1;
    end
    if(index_b_ctrl & done & readout) begin
      index_b <= index_b + 2;
    end
    if(pulse) begin
      $rewind(fd1);
      index_a <= 0;
      index_b <= 0;
      counter <= 0;
    end
    if(full_in) begin
      nonce1_r <= nonce1;
      nonce2_r <= nonce2;
    end
    $fwrite(fd2,"%b", shake128_full_in);
    $rewind(fd2);
    $fread(shake128_done_read, fd3, 0, 1); // read the flag into register
    $rewind(fd3);

    if(shake128_done) begin
      // synthesis translate_off
      ram_b.load_mem(4);
      // synthesis translate_on
    end
  end
end

// with the nonce in :>
reg [7:0] stub_mem;//= (counter == 32) ? nonce1 : ram_a_dout_1;
always @(*) begin
  if(set) begin
    if(counter == 32) begin
      stub_mem = nonce1_r;
    end
    else if(counter == 33) begin
      stub_mem = nonce2_r;
    end
    else begin
      stub_mem = ram_a_dout_1;
    end
  end
end
// stub logic, write the content of ram_a into a file
always @(posedge clk) begin
  if(set & iscal /*& (~pulse)*/) begin 
    $fwrite(fd1,"%h\n", stub_mem);
  end
end

task closefile;
  begin
    $fclose(fd1);
    $fclose(fd2);
    $fclose(fd3);
  end
endtask

endmodule


module matrix_hash_stub_fsm(
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
  else if (set) begin
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
        if(counter == 32) // the timing for ram_a -> stub logic (python script)
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