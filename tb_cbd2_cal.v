module tb_cbd2_cal;

reg clk = 0;
reg set = 0;
reg [31:0] din;
wire [31:0] dout;

wire [3:0] d1 = (dout >> 0)  &'hf;
wire [3:0] d2 = (dout >> 4)  &'hf;
wire [3:0] d3 = (dout >> 8)  &'hf;
wire [3:0] d4 = (dout >> 12) &'hf;
wire [3:0] d5 = (dout >> 16) &'hf;
wire [3:0] d6 = (dout >> 20) &'hf;
wire [3:0] d7 = (dout >> 24) &'hf;
wire [3:0] d8 = (dout >> 28) &'hf;

cbd2_cal cbd2(
  .clk(clk),
  .set(set),
  .din(din),
  .dout(dout)
);

always begin
  #5 clk = ~clk;
end

integer file_desc;
integer file_stat;

initial begin
  #10 set <= 1;
  //din <= $random;
  file_desc <= $fopen("D:/!Github_coding/project-kyber/test/test-cbd2.txt", "r");
  #100
  $stop
  ;
end
/*
always @(posedge clk) begin
  if(set) begin
    din <= $random;
  end
end
*/
reg [31:0] data_ref; // reference output data for test file 
always @(posedge clk) begin
  if(file_desc) begin // file opened sucessfully
    if($feof(file_desc)) begin
      $fclose(file_desc);
      $display("[%0t] job done", $time);
      $stop;
    end
    file_stat <= $fscanf(file_desc, "%d %d\n", din, data_ref);
    //set <= 1; #1 set <= 0;
  end
end

endmodule