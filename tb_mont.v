module tb_mont;

reg clk;
reg reset;
reg set;

reg signed [31:0] data_in;
wire signed [15:0] data_out;

montgomery_reduce p1(
  .clk(clk),
  .reset(reset),
  .set(set),
  .a(data_in),
  .t(data_out)
);

always begin 
  #5 clk = ~clk;
end

// system
integer file_desc;
integer file_stat;
reg file_en;

parameter inputtime = 10;

initial begin
  $display("[%0t] starting simulation...", $time);
  clk = 0;
  set = 1;
  file_desc = $fopen("D:/!Github_coding/project-kyber/test/small-mont.txt", "r");
  $display("[%0t] file opened", $time);
  /*
  #4 // for input timing
             data_in = 1; // so the delay goes before the statement
  #inputtime data_in = 1044;
  #inputtime data_in = -1044;
  #inputtime data_in = 65537;
  #inputtime data_in = 65538; // okay now how tf do I port C and verilog calculation together?
  #inputtime data_in = -2147483648;
  #inputtime data_in = 2147483647;
  $stop;
  */
end

// AST: how the heck do I write a dedicated memory >:(
reg signed [31:0] data_ref; // reference output data for test file 
always @(posedge clk) begin
  if(file_desc) begin // file opened sucessfully
    if($feof(file_desc)) begin
      $fclose(file_desc);
      $display("[%0t] job done", $time);
      $stop;
    end
    file_stat = $fscanf(file_desc, "%d %d\n", data_in, data_ref);
  end
end

always @(posedge clk) begin
  #2 // timing
  if(data_out != data_ref) begin
    $display("[%0t] a: %0d, t: %0d, ref: %0d", $time, data_in, data_out, data_ref);
  end
end

endmodule