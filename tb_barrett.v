module tb_barrett;

reg clk;
reg set;
reg signed [15:0] data_in, a;
wire signed [15:0] data_out;

barrett_reduce barr1(
  .clk(clk),
  .set(set),
  .a(data_in),
  .t(data_out)
);

always begin
  #5 clk = ~clk;
end

integer i;
integer file_desc;
integer file_stat;
reg file_en;

initial begin
  clk <= 0;
  set <= 0;
  file_en <= 0;
  //file_desc <= $fopen("D:/!Github_coding/project-kyber/test/test-barrett.txt")
  /*for (i = 0; i < 10; i = i + 1) begin
    #10 
    data_in <= $random();
    a <= data_in;
    //if(data_out != a%3329) begin
      $display("[%0t] data_in: %0d, data_out: %0d, a%%q: %0d",$time, a, data_out, a%3329);
    //end
  end*/
  #5
  #10 set <= 1; data_in <= -26227;
  #10 data_in <=  30000;
  #10
  $stop;
end

endmodule