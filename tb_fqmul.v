module tb_fqmul;

reg clk;
//reg reset;
reg set;

reg  signed [15:0] data16_a;
reg  signed [15:0] data16_b;
wire signed [15:0] data16_out;

fqmul f1(
  .clk(clk),
  //.reset(reset),
  .set(set),
  .a(data16_a),
  .b(data16_b),
  .t(data16_out)
);

always begin
  #5 clk = ~clk;
end

initial begin
  clk <= 0;
  set <= 0;
  #5
  set <= 1;
  data16_a <= 5;
  data16_b <= 6;
  
  #10 feed(7,8);
  #10 feed(10,3); // surely it works :>
  $stop;
end

/*---task---*/

task feed (
  input [15:0] a,
  input [15:0] b
);
  begin
    data16_a <= a;
    data16_b <= b;
  end
endtask

endmodule