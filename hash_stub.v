/*
TODO: do this with a shell script that links to reading and loading directly from a python script
I think it can be managed in the testbench via system commands

let's deal with the cbd hashes for now.. 

*/

module hash_stub(
  input clk,
  input set,
  input reset,

  input readin,
  input readout,
  input full_in, 
  input [7:0] nonce, // idk if I should manage this externally 
  input [7:0] hash_din, // serialized 1 byte at a time :>
  input [7:0] in_index, // is 0~255 index enough? or too many? 

  output [31:0] hash_dout_1, // to comply with the current version of cbd module
  output [31:0] hash_dout_2,
  output [5-1:0] out_index, // TODO: KEEP THIS FUNCTION
  
  output readin_ok,
  output done
);

localparam DEPTH = 5;
genvar i;
// MEMORY BANKS =======================
// RAM A (for input)
wire             ram_a_we_1,   ram_a_we_2;
wire [DEPTH-1:0] ram_a_addr_1, ram_a_addr_2; 
wire [7:0]       ram_a_din_1 , ram_a_din_2;
wire [7:0]       ram_a_dout_1, ram_a_dout_2;

// RAM B (for output)
wire             ram_b_we_1   [0:3], ram_b_we_2   [0:3];
wire [DEPTH-1:0] ram_b_addr_1 [0:3], ram_b_addr_2 [0:3]; 
wire [7:0]       ram_b_din_1  [0:3], ram_b_din_2  [0:3];
wire [7:0]       ram_b_dout_1 [0:3], ram_b_dout_2 [0:3];

dual_ram #(DEPTH, 8) ram_a(
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

generate
  for(i = 0 ; i < 4 ; i = i + 1) begin : GENRAM
    dual_ram #(DEPTH, 8) ram_b(
      .clk(clk),
      .we_1  (ram_b_we_1   [i]),
      .we_2  (ram_b_we_2   [i]),
      .addr_1(ram_b_addr_1 [i]),
      .addr_2(ram_b_addr_2 [i]),
      .din_1 (ram_b_din_1  [i]),
      .din_2 (ram_b_din_2  [i]),
      .dout_1(ram_b_dout_1 [i]),
      .dout_2(ram_b_dout_2 [i])
    );
  end
endgenerate

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
wire shake128_done = shake128_done_read - 'd48;
wire readin_ok_fsm;
wire pulse;

hash_stub_fsm fsm(
  .clk(clk),
  .set(set),
  .reset(reset),

  // INPUT
  .full_in(full_in), // from external
  .counter(counter_fsm),
  .shake128_done(shake128_done),
  // OUTPUT
  .iscal(iscal),
  .index_a_ctrl(index_a_ctrl),
  .index_b_ctrl(index_b_ctrl),
  .counter_ctrl(counter_ctrl),
  .ram_a_we_ok(ram_a_we_ok_fsm),
  .ram_b_we_ok(ram_b_we_ok_fsm),
  .shake128_full_in(shake128_full_in),
  .pulse(pulse),
  .readin_ok(readin_ok_fsm), // pulaw
  .done(done) // to external 
);

// INTERNAL REG BEGIN =========================//
reg [DEPTH-1:0] index_a;
reg [DEPTH-1:0] index_b;
reg [7:0] counter;
reg readin_ok_r;
// INTERNAL REG END ===========================//

// ASSIGN BEGIN ===============================//
// port 1 read, port 2 write
assign ram_a_we_1 = 0;
assign ram_a_we_2 = ram_a_we_ok_fsm & readin_ok_r;

assign ram_a_addr_1 = (iscal) ? index_a : 0 ;// yes cal
assign ram_a_addr_2 = (iscal) ? 0 : in_index; // no cal

assign ram_a_din_1 = 0; // read only
assign ram_a_din_2 = (readin_ok) ? hash_din : 0;

generate
  for(i = 0 ; i < 4 ; i = i + 1) begin : GENASSIGN
    assign ram_b_we_1[i] = ram_b_we_ok_fsm; // 0
    assign ram_b_we_2[i] = ram_b_we_ok_fsm; 
    assign ram_b_addr_1[i] = index_b;
    assign ram_b_addr_2[i] = index_b + 1;

    assign ram_b_din_1[i] = 0;
    assign ram_b_din_2[i] = 0;
  end
endgenerate
assign hash_dout_1 = (done & readout) ? 
                            ((ram_b_dout_1[0] << (8*3)) | 
                             (ram_b_dout_1[1] << (8*2)) | 
                             (ram_b_dout_1[2] << (8*1)) | 
                             (ram_b_dout_1[3] << (8*0))  ) : 0;
assign hash_dout_2 = (done & readout) ? 
                            ((ram_b_dout_2[0] << (8*3)) | 
                             (ram_b_dout_2[1] << (8*2)) | 
                             (ram_b_dout_2[2] << (8*1)) | 
                             (ram_b_dout_2[3] << (8*0))  ) : 0;
assign out_index = (done & readout) ? (index_b - 2)>>1 : 0;
assign counter_fsm = counter;

assign readin_ok = readin_ok_r;

// ASSIGN END =================================//
integer fd1;
integer fd2;
integer fd3;

// synthesis translate_off
initial begin
  fd1 = $fopen("D:/!Github_coding/project-kyber/sim_hash_stub/test-hash_stub.txt","w");
  fd2 = $fopen("D:/!Github_coding/project-kyber/sim_hash_stub/hash.flag","w");
  fd3 = $fopen("D:/!Github_coding/project-kyber/sim_hash_stub/hash2.flag","r");
end
// synthesis translate_on

always @(*) begin
  readin_ok_r = (readin_ok_r | readin_ok_fsm) & (~full_in);
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
    $fwrite(fd2,"%b", shake128_full_in);
    $rewind(fd2);
    $fread(shake128_done_read, fd3, 0, 1);
    $rewind(fd3);

    if(shake128_done) begin
      // synthesis translate_off
      GENRAM[0].ram_b.load_mem(0);
      GENRAM[1].ram_b.load_mem(1);
      GENRAM[2].ram_b.load_mem(2);
      GENRAM[3].ram_b.load_mem(3);
      // synthesis translate_on
    end
  end
end

// with the nonce in :>
wire [7:0] stub_mem = (counter == 32) ? nonce : ram_a_dout_1;
// stub logic, write the content of ram_a into a file
// TODO: you need the nonce!
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


