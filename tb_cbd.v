module tb_cbd;

reg clk = 0;
reg set = 0;
reg reset = 0;
reg [31:0] din_1, din_2;
reg readin, readout;
wire ok_in, ok_out;
wire signed [15:0] dout_1, dout_2;

cbd cbd1(
  .clk(clk),
  .set(set),
  .reset(reset),
  .cbd_din_1(din_1),
  .cbd_din_2(din_2),
  .readin(readin),
  .readout(readout),
  .cbd_dout_1(dout_1),
  .cbd_dout_2(dout_2),
  .ok_in(ok_in),
  .ok_out(ok_out)
);

always begin
  #5 clk = ~clk;
end

integer file_desc;
integer file_stat;

initial begin
  #10 reset <= 1;
  #5  reset <= 0;
  file_desc <= $fopen("D:/!Github_coding/project-kyber/test/test-cbd2-dual.txt", "r");
  set <= 1;
end

reg [31:0] data_ref1; // reference output data for test file 
reg [31:0] data_ref2; // reference output data for test file 
always @(posedge clk) begin
  if(readin && file_desc) begin // file opened sucessfully
    if($feof(file_desc)) begin
      $fclose(file_desc);
      $display("[%0t] job done", $time);
      $stop;
      readin <= 0;
    end
    file_stat <= $fscanf(file_desc, "%d %d %d %d\n", din_1, data_ref1, din_2, data_ref2);
    //file_stat <= $fscanf(file_desc, "%d %d\n", din_1, din_2);
  end
  if(set && ok_out) begin
    readout <= 1;
  end
end

endmodule