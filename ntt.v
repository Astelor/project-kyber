module ntt #(parameter DEPTH = 4)(
  input clk,
  input set,
  input reset,
  input wire [15:0] ntt_din_1,
  input wire [15:0] ntt_din_2,
  input wire [DEPTH-1:0] in_index,
  input readin, // reading in the data to RAM1
  input readout, // reading out the data from RAM2
  input cal_en,
  output reg done,
  output reg [15:0] ntt_dout_1, // i+1
  output reg [15:0] ntt_dout_2, // i+0
  output reg [DEPTH-1:0] out_index
  // need signal for outputting data to RAM
);
//parameter DEPTH = 4; // 2^8 = 256 depth = 8

reg ram1_we;
reg ram2_we;
reg [DEPTH-1:0] ram1_addr_1, ram1_addr_2;
reg [DEPTH-1:0] ram2_addr_1, ram2_addr_2;
reg [15:0] ram1_din_1, ram1_din_2;
reg [15:0] ram2_din_1, ram2_din_2;
wire [15:0] ram1_dout_1, ram1_dout_2;
wire [15:0] ram2_dout_1, ram2_dout_2;

reg signed [15:0] f1, f2;
wire signed [15:0] r1, r2;

wire signed [15:0] zeta;
reg [6:0] zeta_k_1, zeta_k_2;

dual_ram #(DEPTH, 16) ram1(
  .clk(clk),
  .we_1(ram1_we),
  .we_2(ram1_we),
  .addr_1(ram1_addr_1),
  .addr_2(ram1_addr_2),
  .din_1(ram1_din_1),
  .din_2(ram1_din_2),
  .dout_1(ram1_dout_1),
  .dout_2(ram1_dout_2)
);

dual_ram #(DEPTH, 16) ram2(
  .clk(clk),
  .we_1(ram2_we),
  .we_2(ram2_we),
  .addr_1(ram2_addr_1),
  .addr_2(ram2_addr_2),
  .din_1(ram2_din_1),
  .din_2(ram2_din_2),
  .dout_1(ram2_dout_1),
  .dout_2(ram2_dout_2)
);

ntt_cal cal1(
  .clk(clk),
  .set(set),
  .f1(f1),
  .f2(f2),
  .zeta(zeta),
  .r1(r1),
  .r2(r2)
);

zeta_rom rom1(
  .clk(clk),
  .addr(zeta_k_2),
  .data_out(zeta)
);

reg [DEPTH-1:0] index;
reg [DEPTH-1:0] len;
reg [6:0] k; // zeta index

reg [DEPTH-1:0] wr_index;
reg [DEPTH-1:0] wr_len;

wire [DEPTH-1:0] addr1 = index + len;
wire [DEPTH-1:0] addr2 = index;

wire [DEPTH-1:0] wr_addr1 = wr_index + wr_len;
wire [DEPTH-1:0] wr_addr2 = wr_index;

reg [7:0] timer;
reg wr_ctrl;
reg rd_ctrl;
reg [1:0] layer; // TODO: [2:0] for DEPTH = 8, [1:0] for DEPTH = 4

reg readout_ctrl;
reg stale; // flag to indicate that the data has been processed

always @(posedge clk or posedge reset) begin
  // reset the index
  if(reset) begin
    index <= 0;
    len <= (1<< (DEPTH -1));
    k <= 1;
    
    wr_index <= 0;
    wr_len <= (1<< (DEPTH -1));
    
    timer <= 0;
    wr_ctrl <= 0;
    rd_ctrl <= 0;
    layer <= 1;
    stale <= 1;
    
    done <= 1; // reset done to 1 for input flag perposes
    readout_ctrl <= 0;
  end else if(set && done && cal_en && stale && !readin && !readout) begin
    stale <= 0;
    done <= 0;
    index <= 0;
    readout_ctrl <= 0;
  // NTT is not done, start doing NTT
  end else if(set && !done && !readin && !stale) begin
    if(wr_ctrl == 0) begin // TODO: I'm not sure about putting this under else if 
      timer <= timer + 1;
    end 
    if(timer >= 5) begin
      wr_ctrl <= 1;
      timer <= 0;
    end
    // read index
    if(len > 1 && rd_ctrl == 0) begin
      if((len & (index + 1)) == len) begin
        index <= index + 1 + len;
        k <= k + 1; // TODO: handling to one time zeta rom read
        if((index + len + 1) == 1 << DEPTH) begin
          len <= len >> 1;
          // flags
          rd_ctrl <= 1;
        end
      end else begin
        index <= index + 1;
      end
    end
    // write index
    if(layer == 0) begin
      done <= 1;
      stale <= 1; // the data has been processed
    end
    if(wr_len > 1 && wr_ctrl) begin
      if((wr_len & (wr_index + 1)) == wr_len) begin
        wr_index <= wr_index + 1 + wr_len;
        if((wr_index + wr_len + 1) == 1 << DEPTH) begin
          wr_len <= wr_len >> 1;
          // flags
          rd_ctrl <= 0;
          wr_ctrl <= 0;
          layer <= layer + 1;
        end
      end else begin
        wr_index <= wr_index + 1;
      end
    end
  // NTT done, readout = 1
  end else if(set && done && readout) begin
    index <= index + 2;
    if(!readout_ctrl) begin // delay for RAM readout for correct timing 
      timer <= timer + 1;
    end
    if(timer >= 1) begin
      readout_ctrl <= 1;
    end
  end else begin
    // no op :>
  end
end

always @(posedge clk) begin
  zeta_k_1 <= k;
  zeta_k_2 <= zeta_k_1;
end 

// RAM
always @(posedge clk) begin
  if(set) begin
    // input poly to RAM1 for NTT operation
    // allow iff no cal is present, and the data is stale
    if(done && readin && stale) begin
      ram1_we <= 1; 
      //index <= in_index;
      if(in_index & 'b1 == 0) begin
        // ensure the index is not an odd number
        ram1_addr_1 <= in_index + 1;
        ram1_addr_2 <= in_index;
        ram1_din_1 <= ntt_din_1;
        ram1_din_2 <= ntt_din_2;
      end
    end 
    // doing the NTT
    if(!done && !readin && !readout) begin
      // RAM1 read
      if((layer & 'b1) == 1) begin
        ram1_we <= 0;
        ram1_addr_1 <= addr1;
        ram1_addr_2 <= addr2;
        f1 <= ram1_dout_1;
        f2 <= ram1_dout_2;
      // RAM1 write
      end else begin
        if(wr_ctrl) begin
          ram1_we <= 1;
        end
        ram1_addr_1 <= wr_addr1;
        ram1_addr_2 <= wr_addr2;
        ram1_din_1 <= r1;
        ram1_din_2 <= r2;
      end
      // RAM2 read
      if((layer & 'b1) == 0) begin
        ram2_we <= 0;
        ram2_addr_1 <= addr1;
        ram2_addr_2 <= addr2;
        f1 <= ram2_dout_1;
        f2 <= ram2_dout_2;
      // RAM2 write
      end else begin
        if(wr_ctrl) begin
          ram2_we <= 1;
        end
        ram2_addr_1 <= wr_addr1;
        ram2_addr_2 <= wr_addr2;
        ram2_din_1 <= r1;
        ram2_din_2 <= r2;
      end
    end
    // NTT done, output RAM2 result
    if (done && readout) begin
      ram2_we <= 0;
      ram2_addr_1 <= addr1; // len == 1
      ram2_addr_2 <= addr2;
      if(readout_ctrl) begin
        out_index <= addr2 - 4; // some index is better than no index I guess?
        ntt_dout_1 <= ram2_dout_1;
        ntt_dout_2 <= ram2_dout_2;
      end
    end else begin
      // no op
      // done == 1 and readout == 0
      // done == 1 and readin == 1
      // do I force a reset before reading in anything?
      // do I permit reading in while reading out? -> this can do
      // use write index for the reading in
      // use read index for the reading out
    end
  end
end

endmodule