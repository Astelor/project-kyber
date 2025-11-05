// DEPTH = 4 for 2^4 = 16 for testing
// DEPTH = 6 for 2^6 = 64 for further testing
// DEPTH = 8 for 2^8 = 256 for full range
module invntt #(parameter DEPTH = 8)(
  // SYSTEM
  input clk,
  input set,
  input reset,
  // FSM
  input readin,
  input readout,
  input cal_en,
  input full_in, // I guess? manage index ref externally
  // INPUT TO RAM
  input wire signed [15:0] invntt_din_1,
  input wire signed [15:0] invntt_din_2,
  input wire [DEPTH-1:0] in_index,

  // OUTPUT TO OUTSIDE
  output reg signed [15:0] invntt_dout_1,
  output reg signed [15:0] invntt_dout_2,
  output reg [DEPTH-1:0] out_index,
  output reg valid_out, // a flag noting the correct data (data_out matches the index)
  // misc
  output wire readin_ok,
  output wire done
); 

wire ram1_we;
wire ram2_we;
reg [DEPTH-1:0] ram1_addr_1, ram1_addr_2;
reg [DEPTH-1:0] ram2_addr_1, ram2_addr_2;
reg [15:0] ram1_din_1, ram1_din_2;
reg [15:0] ram2_din_1, ram2_din_2;
wire [15:0] ram1_dout_1, ram1_dout_2;
wire [15:0] ram2_dout_1, ram2_dout_2;

reg signed [15:0] f1, f2;
wire signed [15:0] r1, r2;

wire signed [15:0] zeta; // zeta data
reg [6:0] zeta_k_1, zeta_k_2; // zeta index

wire [15:0] special_zeta = (zeta_k_2 == 1) ? 1441 : -1044;

wire wr_ctrl, rd_ctrl;
wire layer;

reg full_out;

invntt_fsm #(DEPTH) fsm(
  .clk(clk),
  .set(set),
  .reset(reset),
  .readin(readin),
  .readout(readout),
  .cal_en(cal_en),
  .full_in(full_in),
  .full_out(full_out),

  .rd_ctrl(rd_ctrl),
  .wr_ctrl(wr_ctrl),
  .ram1_we(ram1_we),
  .ram2_we(ram2_we),
  .layer_type(layer),
  
  .readin_ok(readin_ok),

  .done(done)
);

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

invntt_cal cal1(
  .clk(clk),
  .set(set),
  .f1(f1),
  .f2(f2),
  .zeta1(zeta),
  .zeta2(special_zeta),
  .r1(r1),
  .r2(r2)
);

// TODO: you only need one
zeta_rom #(1) rom1(
  .clk(clk),
  .addr(zeta_k_2),
  .data_out(zeta)
);

reg [DEPTH-1:0] index;
reg [DEPTH-1:0] len;
reg [6:0] k;

reg [DEPTH-1:0] out_index_t_1;
reg [DEPTH-1:0] out_index_t_2;

reg valid_out_t_1;
reg valid_out_t_2;

reg [DEPTH-1:0] wr_index;
reg [DEPTH-1:0] wr_len;

wire [DEPTH-1:0] addr1 = index + len;
wire [DEPTH-1:0] addr2 = index;

wire [DEPTH-1:0] wr_addr1 = wr_index + wr_len;
wire [DEPTH-1:0] wr_addr2 = wr_index;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    index <= 0;
    len <= 2; // inverse ntt
    wr_index <= 0;
    wr_len <= 2;
    k <= 127;
    full_out <= 0;
    valid_out_t_1 <= 0;
  end
  else if (set) begin
    // calculation
    if(done == 0 && readin_ok == 0) begin
      if(rd_ctrl) begin
        // TODO: it's THIS thing that's causing the spaghetti!
        if((len & (index + 1)) == len) begin
          index <= index + 1 + len;
          k <= k - 1;
          if((index + len + 1) == 1 << DEPTH) begin
            len <= len << 1;
          end
        end
        else begin
          index <= index + 1;
        end
      end
      if(wr_ctrl) begin
        if((wr_len & (wr_index + 1)) == wr_len) begin
          wr_index <= wr_index + 1 + wr_len;
          if((wr_index + wr_len + 1) == 1 << DEPTH) begin
            wr_len <= wr_len << 1;
          end
        end 
        else begin
          wr_index <= wr_index + 1;
        end
      end
    end
    else if(done == 1 && readout == 1) begin
      if(out_index_t_1 >= (1<<DEPTH)-2 ) begin
        full_out <= 1;
        valid_out_t_1 <= 0;
      end
      else begin
        wr_index <= wr_index + 2;
        if(full_out == 0)
          valid_out_t_1 <= 1; // this lines up with the valid data, which is output data with its index aligned
      end
    end
    else if(done == 0 && readin_ok == 1) begin
      index <= 0;
      len <= 2; // inverse ntt
      k <= 127;
      wr_index <= 0;
      wr_len <= 2;
      full_out <= 0;
    end
  end
  else begin
    // do nothing :>
  end
end

always @(posedge clk) begin
  zeta_k_1 <= k;
  zeta_k_2 <= zeta_k_1;
  
  out_index_t_1 <= wr_index;
  out_index_t_2 <= out_index_t_1;

  valid_out_t_2 <= valid_out_t_1;
  valid_out <= valid_out_t_2;
end

// RAM
always @(posedge clk) begin
  if(set) begin
    // readin
    if(done == 0 && readin_ok == 1) begin
      if(readin == 1 && ((in_index & 'b1) == 0)) begin
        //$display("wtf?");
        ram1_addr_1 <= in_index + 1;
        ram1_addr_2 <= in_index + 0;
        ram1_din_1 <= invntt_din_1;
        ram1_din_2 <= invntt_din_2;
      end
    end
    // calculation
    else if(done == 0 && readin_ok == 0) begin
      if(layer == 1) begin // odd
        // RAM1 read
        ram1_addr_1 <= addr1;
        ram1_addr_2 <= addr2;
        f1 <= ram1_dout_1;
        f2 <= ram1_dout_2;
      end
      else begin
        // RAM1 write
        ram1_addr_1 <= wr_addr1;
        ram1_addr_2 <= wr_addr2;
        ram1_din_1 <= r1;
        ram1_din_2 <= r2;
      end
      if (layer == 0) begin // even
        // RAM2 read
        ram2_addr_1 <= addr1;
        ram2_addr_2 <= addr2;
        f1 <= ram2_dout_1;
        f2 <= ram2_dout_2;
      end
      else begin
        // RAM2 write
        ram2_addr_1 <= wr_addr1;
        ram2_addr_2 <= wr_addr2;
        ram2_din_1 <= r1;
        ram2_din_2 <= r2;
      end
    end
    // readout
    else if(done == 1 && readout == 1)begin
      ram2_addr_1 <= wr_index + 1; // why the heck is the address reversed???
      ram2_addr_2 <= wr_index + 0;
      invntt_dout_1 <= ram2_dout_1;
      invntt_dout_2 <= ram2_dout_2;
      out_index <= out_index_t_2;//(wr_index - 'sd4);
    end
  end
end

endmodule

/*
// : This one is the clean index loop
//    the state is still something to work on
//    but it's the best I can conjure for now
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
*/

