module ntt(
  input clk,
  input set,
  input reset,
  output reg done
  // need signal for outputting data to RAM
);
parameter DEPTH = 8; // 2^8 = 256 depth = 8

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

dual_ram #(DEPTH) ram1(
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

dual_ram #(DEPTH) ram2(
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
  .r2(r2) //TODO: I need to wire this straight to the data_in port on RAM
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
reg stall;
reg [2:0] layer;

always @(posedge clk) begin
  if(layer == DEPTH) begin
    done <= 1;
  end
end

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
    stall <= 0;
    layer <= 1;
  end else begin
    if(set && wr_ctrl == 0) begin
      timer <= timer + 1;
    end
    if (timer == 5) begin
      wr_ctrl <= 1;
      timer <= 0;
    end
    //index
    if(set && len > 1 && stall == 0) begin
      if((len & (index + 1)) == len) begin
        index <= index + 1 + len;
        k <= k + 1; // TODO: handling to one time zeta rom read
        if((index + len + 1) == 1<<DEPTH) begin
          len <= len >> 1;
          stall <= 1;
        end
      end else begin
        index <= index + 1;
      end
    end
    if(set && wr_len > 1 && wr_ctrl) begin
      if((wr_len & (wr_index + 1)) == wr_len) begin
        wr_index <= wr_index + 1 + wr_len;
        if((wr_index + wr_len + 1) == 1<<DEPTH) begin
          wr_len <= wr_len >> 1;
          stall <= 0;
          wr_ctrl <= 0;
          layer <= layer + 1;
        end
      end else begin
        wr_index <= wr_index + 1;
      end
    end
  end
end

always @(posedge clk) begin
  zeta_k_1 <= k;
  zeta_k_2 <= zeta_k_1;
end 

// RAM
always @(posedge clk) begin
  if(set) begin
    if((layer & 'b1) == 1) begin
      // read
      ram1_we <= 0;
      ram1_addr_1 <= addr1;
      ram1_addr_2 <= addr2;
      f1 <= ram1_dout_1;
      f2 <= ram1_dout_2;
    end else begin
      // write
      if(wr_ctrl) begin
        ram1_we <= 1;
      end
      ram1_addr_1 <= wr_addr1;
      ram1_addr_2 <= wr_addr2;
      ram1_din_1 <= r1;
      ram1_din_2 <= r2;
    end
    if((layer & 'b1) == 0) begin
      // read
      ram2_we <= 0;
      ram2_addr_1 <= addr1;
      ram2_addr_2 <= addr2;
      f1 <= ram2_dout_1;
      f2 <= ram2_dout_2;
    end else begin
      // write
      if(wr_ctrl) begin
        ram2_we <= 1;
      end
      ram2_addr_1 <= wr_addr1;
      ram2_addr_2 <= wr_addr2;
      ram2_din_1 <= r1;
      ram2_din_2 <= r2;
    end
  end
end

endmodule