module tb_kyber_pke_enc;

localparam DEPTH = 8; // surely this is not going to make my life harder
// SYSTEM
reg clk = 0;
reg set = 0;
reg reset = 0;

// INPUT
reg readin = 0;
reg full_in = 0;
reg [3:0] data_type;
reg [7:0] din;
reg [15:0] in_index; // for k = 3, index only to 9 bits

// OUTPUT
wire readin_ok;
wire done;
wire [3:0] input_type;

kyber_pke_enc #(DEPTH) bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  .readin(readin),
  .full_in(full_in),
  .data_type(data_type), // which data input you are doing 
  .kyber_din(din),
  .kyber_in_index(in_index),
  // OUTPUT
  .input_type(input_type), // which data input you should do
  .readin_ok(readin_ok),
  .done(done)
);

always begin
  #5 clk = ~clk;
end

reg [7:0] mem [255:0]; // match kyber_din
reg [7:0] ekt [(384*3)-1:0]; // for public key t
// TODO: design a test data that compresses the 0~(256*3 - 1) to ekt
// so that the end result to polyvec b port is ordered number
// for testing
initial begin
  $readmemh("D:/!Github_coding/project-kyber/poly_test.hex", mem);
  $readmemh("D:/!Github_coding/project-kyber/ekt_test.hex", ekt);
  data_type <= 0;
  #15 reset <= 1;
  #5 reset <= 0;
  #5 set <= 1;
  readin <= 0;
  #10 readin <= 1;
  $stop
  ;
end

reg [15:0] index = 0;

always @(posedge clk) begin
  case (input_type)
    1 : begin // randomness R for
      data_type <= 1;
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
        // readin <= 0;
      end
      else begin
        full_in <= 0;
      end
    end
    2 : begin
      data_type <= 2;
      if(readin_ok & readin) begin
        index <= index + 1;
        in_index <= index;
        din <= ekt[index];
      end
      if(index == (1153) ) begin
        // manage k type where? internally?
        full_in <= 1;
      end
      else begin
        full_in <= 0;
      end
    end
    default: begin
      // nothing
      index <= 0;
    end 
  endcase
end


endmodule