module poly_ram #(parameter DEPTH = 32)( // special RAM tailored for NTT? double port!
  input clk,
  //input reset, // reset to what though
  input r1_en,
  input r2_en,
  input w1_en,
  input w2_en,
  input wire [15:0] r1_addr, // no explicit check for the module for race conditions (? 
  input wire [15:0] r2_addr, 
  input wire [15:0] w1_addr, // I still think there should be a check for this, maybe later
  input wire [15:0] w2_addr,
  input wire /*signed?*/ [15:0] d1_in, 
  input wire /*signed?*/ [15:0] d2_in, 
  output reg /*sigend?*/ [15:0] d1_out, 
  output reg /*sigend?*/ [15:0] d2_out  
);

// TODO: is tht possible to make mass concurrent w like flash?

reg [15:0] mem [DEPTH - 1:0]; // do I just uh

initial begin
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
end

/*r********************************************/
always @(posedge clk) begin
  if(r1_en) begin
    d1_out <= mem[r1_addr];
  end
  if(r2_en) begin
    d2_out <= mem[r2_addr];
  end
end

/*w********************************************/
always @(posedge clk) begin
  if(w1_en) begin
    mem[w1_addr] <= d1_in;
  end
  if(w2_en) begin
    mem[w2_addr] <= d2_in;
  end
end

endmodule