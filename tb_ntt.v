module tb_ntt;
parameter DEPTH = 4;
reg clk = 0;
reg set = 0;
reg reset = 0;
wire done;
reg readout = 0;
reg readin = 0;
reg cal_en = 0;
wire [15:0] dout_1, dout_2;
wire [DEPTH-1:0] out_index;
reg [15:0] din_1, din_2;
reg [DEPTH-1:0] in_index = 0;

ntt #(DEPTH) ntt1(
  .clk(clk),
  .set(set),
  .reset(reset),
  .ntt_din_1(din_1),
  .ntt_din_2(din_2),
  .in_index(in_index),
  .readin(readin),
  .readout(readout),
  .cal_en(cal_en),
  .done(done),
  .ntt_dout_1(dout_1),
  .ntt_dout_2(dout_2),
  .out_index(out_index)
);

reg [15:0] mem [ (1<<DEPTH)-1 :0];

always begin
  #5 clk = ~clk;
end

initial begin
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  #10 reset <= 1;
  #5 reset <= 0;
  #5 set <= 1;
    //readout <= 1;
  #100
  //$stop
  ;
end
always @(posedge clk) begin
  if(done) begin
    $stop
    ;
  end
end
reg [DEPTH-1:0] index = 0;
always @(posedge clk) begin
  if(readin) begin
    index <= index + 2;
    in_index <= index;
    din_1 <= mem[index+1];
    din_2 <= mem[index];
  end
end

endmodule