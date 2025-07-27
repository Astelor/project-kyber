module tb_ntt;

reg clk;
reg reset;
reg set;
wire done;

ntt ntt1(
  .clk(clk),
  .reset(reset),
  .set(set),
  .done(done)
);

always begin
  #5 clk = ~clk;
end

// system
integer file_desc;
integer file_stat;
reg file_en;

initial begin
  clk <= 0;
  set <= 0;
  file_en <= 0;
  file_desc <= $fopen("D:/!Github_coding/project-kyber/test/test-ntt.txt", "r");
  #4 set <= 1; // or I can probably make it posedge detect too
  #1 set <= 0;
  #31 file_en <= 1;
  #100
  $stop;
end

reg signed [15:0] r1_ref, r2_ref;
always @(posedge clk) begin
  if(file_en && file_desc) begin
    if($feof(file_desc)) begin
      $fclose(file_desc);
      $display("[%0t] job done", $time);
      $stop;
    end
    file_stat <= $fscanf(file_desc, "%d %d\n", r1_ref, r2_ref);
  end
end

integer i;
always @(posedge clk) begin
  if(done) begin
    for (i = 0; i < 256 ; i = i + 1) begin
      $write("%0d ", );
    end
    $stop;
  end
end

/*
// for file input
always @(posedge clk) begin

end
*/


endmodule