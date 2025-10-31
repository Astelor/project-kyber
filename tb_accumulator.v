module tb_accumulator;

reg clk = 0;
reg set = 0;
reg reset = 0;
reg  [ 3:0] cmd;
reg  [ 6:0] addr_a, addr_b;
reg  [15:0] data_a, data_b;
wire [ 6:0] addr_out; 
wire [15:0] data_a_out, data_b_out;
wire [ 3:0] status;

accumulator bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  .cmd(cmd),
  .addr_a(addr_a),
  .addr_b(addr_b),
  .data_a(data_a),
  .data_b(data_b),
  // OUTPUT
  .addr_out(addr_out),
  .data_a_out(data_a_out),
  .data_b_out(data_b_out),
  .status(status)
);

always begin
  #5 clk = ~clk;
end

reg [7:0] mem [127:0];

initial begin
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  #15 reset <= 1;
  #5 reset <= 0;
  #5 set <= 1;
  command(1);
  $stop
  ;
end


reg [7:0] index = 0;
parameter TEST_OFFSET = 0;

always @(posedge clk) begin
  if(cmd == 1 && status == 1) begin
    index <= index + 1;
    addr_a <= index;
    addr_b <= index;
    data_a <= mem[index] + 5; 
                       //$random & 'hff;
    data_b <= mem[index] + 7;
  end
  if(cmd == 2 && status == 2) begin
    index <= index + 1;
    addr_a <= index;
    addr_b <= index;
    data_a <= mem[index] + 1; 
    data_b <= mem[index] + 1; 
  end
  if(status == 0 ) begin
    index <= 0;
  end
  if(index == 127) begin
    command(0);
    index <= 0;
  end
end

task command(input [3:0] cmdd);
begin
  cmd <= cmdd;
end
endtask


endmodule