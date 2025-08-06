module tb_dual_ram;

reg clk = 0;
reg reset = 0;
reg set = 0;
reg write = 0;
wire signed [15:0] d1, d2;
reg signed [15:0] di1, di2;
wire done;

dual_ram #(8) mem1(
  .clk(clk),
  .we_1(write),
  .we_2(write),
  .din_1(di1),
  .din_2(di2),
  .dout_1(d1),
  .dout_2(d2),
  .done(done)
);
/*
integer fd;
integer fs;
reg fe;
*/
always begin
  #5 clk = ~clk;
end

initial begin
  #10 reset <= 1;
  #5 set <= 1; reset <= 0;
  //fd <= $fopen("D:/!Github_coding/project-kyber/test/ntt-mem.txt", "w");
  
  #20 
  write <= 1;
  di1 <= 777;
  di2 <= 555;
  write <= 0;

  #100;
  //$stop; 
  
end
/*
always @(d2) begin
  if(fd) begin
    $fdisplay(fd, "%0d", d2);
  end
end
*/
always @(posedge clk) begin
  if(done) begin
    $stop;
  end
end
endmodule