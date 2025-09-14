module tb_kyber_pke_enc;

localparam DEPTH = 8; // surely this is not going to make my life harder
// SYSTEM
reg clk = 0;
reg set = 0;
reg reset = 0;

// INPUT
reg readin;
reg full_in;
reg [7:0] din;
reg [7:0] in_index;

// OUTPUT
wire readin_ok;
wire done;

kyber_pke_enc #(DEPTH) bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  .readin(readin),
  .full_in(full_in),
  .kyber_din(din),
  .kyber_in_index(in_index),
  // OUTPUT
  .readin_ok(readin_ok),
  .done(done)
);

always begin
  #5 clk = ~clk;
end

reg [7:0] mem [255:0]; // match kyber_din

initial begin
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  
  #15 reset <= 1;
  #5 reset <= 0;
  #5 set <= 1;
  readin <= 0;
  #10 readin <= 1;
  $stop
  ;
end

reg [7:0] index = 0;

always @(posedge clk) begin
  if(readin_ok & readin) begin
    index <= index + 1;
    in_index <= index;
    din <= mem[index] + 2; 
                //$random & 'hff;
  end
  if(index == (1<<5)) begin
    //index <= 0;
    //readin_a <= 0;
    full_in <= 1;
  end
  else begin
    full_in <= 0;
  end
  /*
  if(done) begin
  end
  */
end


endmodule