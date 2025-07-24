module ntt ( // now this thing must have a clock
  input clk,
  input reset,
  input set
  // uh input?
);
`define ITEMS 16
reg signed [15:0] zetas [127:0];
reg signed [15:0] poly [`ITEMS:0]; // [255:0]
// TODO: make actual RAM
initial begin
  $readmemh("D:/!Github_coding/project-kyber/zeta.hex", zetas); // read the zetas in
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", poly);
end

reg set0, set1, set2, set3;
reg  signed [15:0] f_len, f, ff, b; 
wire signed [15:0] tt, rr1, rr2;

fqmul fq1(
  .clk(clk),
  //.set(set1),
  .a(f_len), // f[j+len]
  .b(b),
  .t(tt)
);

ct_butfly ct1(
  .clk(clk),
  .set(set1),
  .f(ff), // f[j]
  .t(tt),
  .r1(rr1),
  .r2(rr2)
);

/*index control*****************************************/
parameter N = `ITEMS; // when N = 8, there's data hazard
reg [15:0] len = N/2, k = 1, i = 0, start = 0; // put it in initial construct
reg [15:0] lenn1 = 'dz, lenn2 = 'dz, lenn3 = 'dz;
always @(posedge clk) begin // TODO: idk why but the logic feels weird
  if(len - 1 && set0) begin
    if(i < start + len - 1) begin // I think this is the problem where the index is off by one
      i <= i + 1;
    end
    else begin
      k <= k + 1;
      if(start + len * 2 < N ) begin
        start <= i + len + 1;
        i <= i + len + 1;
      end
      else begin
        start <= 0;
        i <= 0;
        len <= len >> 1;
      end
    end
  end
end

/*data reading tasks************************************/
always @(posedge clk) begin // it takes 3 clocks to finish the computation
  // need set (enable) signal here to stop it from doing cal
  if(len -1 && set0) begin
    f_len <= poly[i+len];
    f <= poly[i];
    b <= zetas[k];
  end
end

/*set and reset control*********************************/
always @(posedge clk) begin
  if(set) begin
    set0 <= 1;
  end
end

/*propagation tasks*************************************/
// TODO: should probably make it into a buffer, since only the last stage (ii3, lenn3, set3)is used
reg [15:0] ii1 = 'dz ,ii2 = 'dz, ii3 = 'dz;
always @(posedge clk) begin
  ff <= f;
end

always @(posedge clk) begin
  ii1 <= i;
  ii2 <= ii1;
  ii3 <= ii2;
end

always @(posedge clk) begin
  set1 <= set0;
  set2 <= set1;
  set3 <= set2;
end

always @(posedge clk) begin
  lenn1 <= len;
  lenn2 <= lenn1;
  lenn3 <= lenn2;
end

/*RAM write back******************************************/
reg signed [15:0] rt1, rt2; 
always @(posedge clk) begin // I guess I need to design a state machine
  if(lenn3 - 1 && set3) begin // line the thing up, or use a regsiter so it can write back to mmeory in time or smth
    poly[ii3+lenn3] <= rr1; // the 3 one is correct, now it causes hazard and becomes annoying
    poly[ii3] <= rr2;
    rt1 <= rr1;
    rt2 <= rr2;
  end
end

endmodule

/*test for 8 `items only**********************************/

/*
module ntt_layer1( // test for 8 `items
  input clk,
  //input reset,
  input set
);

// what's stopping me from summoning multiple multipliers :>
// your RAM, literally

endmodule

module ntt_layer2(
  input clk,
  //input reset
  input set
);

endmodule

module poly_ram ( // temporary module  
  input clk,
  input reset, // reset the module
  input set, // enable the module
  input write, // write enabled
  input  wire [15:0] a, // write data
  output reg  [15:0] t  // read data
);

always @(posedge clk) begin


end
endmodule
*/

/*
*************************************************
* Name:        ntt
*
* Description: Inplace number-theoretic transform (NTT) in Rq.
*              input is in standard order, output is in bitreversed order
*
* Arguments:   - int16_t r[256]: pointer to input/output vector of elements of Zq
**************************************************
void ntt(int16_t r[256]) {
  unsigned int len, start, j, k;
  int16_t t, zeta;

  k = 1;
  for(len = 128; len >= 2; len >>= 1) {
    for(start = 0; start < 256; start = j + len) {
      zeta = zetas[k++];
      for(j = start; j < start + len; j++) {
        t = fqmul(zeta, r[j + len]);
        r[j + len] = r[j] - t;
        r[j] = r[j] + t;
      }
    }
  }
}
*/