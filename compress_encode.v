/*
This is a "pass through" module, data in data out, no ram block
*/

module compress_encode #(parameter DD = 4)(
  input clk,
  input set,
  input reset,
  input readin,
  input [15:0] din1,
  input [15:0] din2,
  // input in_index,
  output wire [15:0] dout1,
  output wire [15:0] dout2,
  // output reg [7:0] out_index, // this should just increment?
  output wire readout_ok // TODO: I need to use parameter to manage all these status things
);

// wire [15:0] comp_dout;
wire [DD - 1:0] comp_dout [0:1];
wire comp_readout_ok [0:1];

wire [15:0] din[0:1];
assign din[0] = din1;
assign din[1] = din2;

`define DEF_COMP(n) \
  .clk(clk), \
  .set(set), \
  .reset(reset), \
  .readin(readin), \
  .din(din[n]), \
  .dout(comp_dout[n]), \
  .readout_ok(comp_readout_ok[n])

`define DEF_ENCODE \
  .clk(clk), \
  .set(set), \
  .reset(reset), \
  .readin(comp_readout_ok[0] & comp_readout_ok[1]), \
  .din1(comp_dout[0]), \
  .din2(comp_dout[1]), \
  .dout1(dout1), \
  .dout2(dout2), \
  .readout_ok(readout_ok)

// reg [15:0] encode4_dout_1;

generate
  case (DD)
    4 : begin : GEN_COMP
      compress #(.DD(4), .ROUND(1665), .DIV(80635), .RR(28), .REG_SIZE(32)) comp1(`DEF_COMP(0));
      compress #(.DD(4), .ROUND(1665), .DIV(80635), .RR(28), .REG_SIZE(32)) comp2(`DEF_COMP(1));
      
      encode_4 encode(`DEF_ENCODE);
    end
    // 5 : begin : GEN_COMP
    //   compress #(.DD(5), .ROUND(1664), .DIV(40318), .RR(27), .REG_SIZE(32)) comp(`DEF_COMP);
    // end
    10 : begin : GEN_COMP
      compress #(.DD(10), .ROUND(1665), .DIV(1290167), .RR(32), .REG_SIZE(64)) comp1(`DEF_COMP(0));
      compress #(.DD(10), .ROUND(1665), .DIV(1290167), .RR(32), .REG_SIZE(64)) comp2(`DEF_COMP(1));
      encode_10 encode(`DEF_ENCODE);
    end
    // 11 : begin : GEN_COMP
    //   compress #(.DD(11), .ROUND(1664), .DIV(645084), .RR(31), .REG_SIZE(64)) comp(`DEF_COMP);
    // end
    default: begin
      // ??
    end
  endcase
endgenerate


endmodule


module compress #(parameter DD = 4,
                  parameter ROUND = 1665,
                  parameter DIV = 80635,
                  parameter RR = 28,
                  parameter REG_SIZE = 32)(
  input clk,
  input set,
  input reset,
  // input [7:0] in_index,
  input readin,
  input [15:0] din,
  // output reg [7:0] out_index,
  output wire [DD - 1:0] dout,
  output wire readout_ok
);

wire [15:0] barr_a;
wire signed [15:0] barr_t;

barrett_reduce barr(
  .clk(clk),
  .set(set),
  .a(barr_a),
  .t(barr_t)
);

localparam MASK = (1 << DD) - 1;
reg [REG_SIZE:0] x1, x2, x3, x4, x5;
reg unsigned [DD-1:0] x6;
reg c1,c2,c3,c4,c5,c6,c7;

assign dout = x6;
assign readout_ok = c7;

assign barr_a = din;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    // I suppose it's not necessary to init them?
    x1 <= 0;
    x2 <= 0;
    x3 <= 0;
    x4 <= 0;
    x5 <= 0;
    x6 <= 0;
  end
  else if(set) begin
    // $display("[%t] %d %d", $time, (barr_t >>> 15), barr_t);
    x1 <= barr_t + ((barr_t >>> 15) & 3329);
    x2 <= x1 << DD;
    x3 <= x2 + ROUND;
    x4 <= x3 * DIV;
    x5 <= x4 >> RR;
    x6 <= x5 & MASK;
  end
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    c1 <= 0;
    c2 <= 0;
    c3 <= 0;
    c4 <= 0;
    c5 <= 0;
    c6 <= 0;
    c7 <= 0;
  end
  else if(set) begin
    c1 <= readin;
    c2 <= c1;
    c3 <= c2;
    c4 <= c3;
    c5 <= c4;
    c6 <= c5;
    c7 <= c6;
  end
end

endmodule

/*
def compress(num: int, d: int, r: int) -> int:
    x = num
    x1 = x + ((x >> 15) & 3329) # add 3329 if num is negative
    # multiply by 2^d
    x2 = x1 << d
    # round the x
    x3 = x2 + 1665 #(3329/2)
    # division by invariant multiplication
    x4 = x3 * 80635 # 2^28 / 3329
    x5 = x4 >> r
    x6 = x5 & ((1 << d) - 1)
    return x
*/


module encode_4(
  input clk,
  input set,
  input reset,
  input readin, // just making sure the data is valid >:)
  // input readout, // readout
  input [3:0] din1,
  input [3:0] din2,
  output wire [15:0] dout1,
  output wire [15:0] dout2,
  output reg readout_ok
);

/*
[0][1][2][3] -> dout
*/

reg [1:0] counter;
reg [15:0] buffer1, buffer2;
reg [3:0] buf1,buf2,buf3,buf4,buf5,buf6,buf7,buf8;
reg c1,c2;//,c3,c4;

assign dout1 = buffer1;
assign dout2 = buffer2;

always @(posedge clk) begin
  if(reset) begin
    c1 <= 0;
    // c2 <= 0;
    // c3 <= 0;
    // c4 <= 0;
  end
  else if(set) begin
    c1 <= readin;
    c2 <= c1;
    // c3 <= c2;
    // c4 <= c3;
  end
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    counter <= 0;
    buf1 <= 0;
    buf2 <= 0;
    buf3 <= 0;
    buf4 <= 0;

    buf5 <= 0;
    buf6 <= 0;
    buf7 <= 0;
    buf8 <= 0;
    readout_ok <= 0;
  end
  else if(set) begin
    if(readin) begin
      counter <= counter + 1;
      buf1 <= din2;
      buf2 <= din1;

      buf3 <= buf1;
      buf4 <= buf2;

      buf5 <= buf3;
      buf6 <= buf4;

      buf7 <= buf5;
      buf8 <= buf6;

      /*
      2   3   0   1
      [1] [2] [3] [4] -> buffer
      0   1   2   3
      [3] [4] [1] [2]
      */
      if(counter == 0 & c2 == 1) begin
        buffer1 <= ((buf8) | (buf7 << 4) | (buf6 << 8) | (buf5 << 12));
        buffer2 <= ((buf4) | (buf3 << 4) | (buf2 << 8) | (buf1 << 12));
        readout_ok <= 1;
      end
      else begin
        readout_ok <= 0;
      end
    end
    else begin
      readout_ok <= 0;
    end
  end
end

endmodule

module encode_10(
  input clk,
  input set,
  input reset,
  input readin,
  input [9:0] din1,
  input [9:0] din2,

  output wire [15:0] dout1,
  output wire [15:0] dout2,
  output reg readout_ok
);

/*
 10 6
[0][1]
 4  10 2
[1][2][3]
 8  8
[3][4]
 2  10 4
[4][5][6]
 6 10
[6][7]
*/

reg [2:0] counter;
reg [15:0] buffer1, buffer2;
reg [9:0] buf1,buf2,buf3,buf4,buf5;
reg c1,c2,c3;

assign dout1 = buffer1;
assign dout2 = buffer2;

always @(posedge clk) begin
  if(reset) begin
    c1 <= 0;
    // c2 <= 0;
    // c3 <= 0;
  end
  else if(set) begin
    c1 <= readin;
    c2 <= c1;
    c3 <= c2;
  end
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    counter <= 0;
    buf1 <= 0;
    buf2 <= 0;
    buf3 <= 0;
    buf4 <= 0;
    buf5 <= 0;
    readout_ok <= 0;
  end
  else if(set) begin
    if(readin) begin
      counter <= counter + 1;
      buf1 <= din2;
      buf2 <= din1;

      buf3 <= buf1;
      buf4 <= buf2;

      buf5 <= buf3;
      //  10 6   4  10 2
      // [0][1] [1][2][3]
      if(counter == 2) begin
        buffer1 <= (buf4 >> 0) | ((buf3 & 6'h3f) << 10);
        buffer2 <= (buf3 >> 6) | (buf2 << 4) | ((buf1 & 2'h3) << 14);
        readout_ok <= 1;
      end
      //  8  8   2  10 4
      // [3][4] [4][5][6]
      else if(counter == 4) begin
        buffer1 <= (buf5 >> 2) | ((buf4 & 8'hff) << 8);
        buffer2 <= (buf4 >> 8) | (buf3 << 2) | ((buf2 & 4'hf) << 12);
        readout_ok <= 1;
      end
      //  6 10   10 6
      // [6][7] [8][9]
      else if(counter == 5) begin
        buffer1 <= (buf4 >> 4) | ( buf3 << 6);
        buffer2 <= (buf2 >> 0) | ((buf1 & 6'h3f) << 10);
        readout_ok <= 1;
      end
      //  4  10 2   8  8
      // [9][0][1] [1][2]
      else if(counter == 7) begin
        buffer1 <= (buf5 >> 6) | (buf4 << 4) | ((buf3 & 2'h3) << 14);
        buffer2 <= (buf3 >> 2) | ((buf2 & 8'hff) << 8);
        readout_ok <= 1;
      end
      //  2  10 4   6  10
      // [2][3][4] [4][5]
      else if(counter == 0 && c2 == 1) begin
        buffer1 <= (buf4 >> 8) | (buf3 << 2) | ((buf2 & 4'hf) << 12);
        buffer2 <= (buf2 >> 4) | (buf1 << 6);
        readout_ok <= 1;
      end
      else begin
        readout_ok <= 0;
      end
    end
    else begin
      readout_ok <= 0;
    end
  end
end

endmodule