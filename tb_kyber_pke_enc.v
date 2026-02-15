module tb_kyber_pke_enc;

// SYSTEM
reg clk = 0;
reg set = 0;
reg reset = 0;

// INPUT
reg readin = 0;
reg readout = 0;
reg full_in = 0;
reg [3:0] data_type;
reg [7:0] din;
reg [15:0] in_index; // for k = 3, index only to 9 bits

// OUTPUT
wire readin_ok;
wire done;
wire [3:0] input_type;
wire [15:0] kyber_dout_1;
wire [15:0] kyber_dout_2;
wire [15:0] kyber_out_index;

kyber_pke_enc bruh(
  .clk(clk),
  .set(set),
  .reset(reset),
  // INPUT
  .readin(readin),
  .readout(readout),
  .full_in(full_in),
  .data_type(data_type), // which data input you are doing 
  .kyber_din(din),
  .kyber_in_index(in_index),
  // OUTPUT
  .input_type(input_type), // which data input you should do
  .readin_ok(readin_ok),
  .kyber_dout_1(kyber_dout_1),
  .kyber_dout_2(kyber_dout_2),
  .kyber_out_index(kyber_out_index),
  .done(done)
);

always begin
  #5 clk = ~clk;
end

reg [15:0] c_mem [543:0]; // output: 80*2*3+32*2


reg [7:0] rand [31:0]; // randomness
reg [7:0] seed [31:0]; // p seed
reg [7:0] ekt [(384*3)-1:0]; // for public key t
reg [7:0] msg [31:0]; // secret message key
// TODO: design a test data that compresses the 0~(256*3 - 1) to ekt
// so that the end result to polyvec b port is ordered number
// for testing
initial begin
  $readmemh("D:/!Github_coding/project-kyber/test/sim_input/encryption_key.hex", ekt);
  $readmemh("D:/!Github_coding/project-kyber/test/sim_input/r_randomness.hex", rand);
  $readmemh("D:/!Github_coding/project-kyber/test/sim_input/message.hex", msg);
  $readmemh("D:/!Github_coding/project-kyber/test/sim_input/p_seed.hex", seed);


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
  // if(readout) begin
    c_mem[(kyber_out_index << 1) + 0] <= kyber_dout_1;
    c_mem[(kyber_out_index << 1) + 1] <= kyber_dout_2;
  // end
  case (input_type)
    1 : begin // randomness R for
      data_type <= 1;
      if(readin_ok /*& readin*/) begin
        readin <= 1;
        index <= index + 1;
        in_index <= index;
        din <= rand[index]; 
                    //$random & 'hff;
      end
      if(index == ( 1 << 5)) begin
        full_in <= 1;
        // readin <= 0;
      end
      else begin
        full_in <= 0;
      end
    end
    2 : begin
      data_type <= 2;
      if(readin_ok /*& readin*/) begin
        readin <= 1;
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
    3 : begin
      
      data_type <= 3;
      if(readin_ok /*& readin*/) begin
        readin <= 1;
        index <= index + 1;
        in_index <= index;
        din <= msg[index];
      end
      if(index == (1 << 5) - 1 ) begin // TODO: this difference is kinda bad?
        full_in <= 1;
      end
      else begin
        full_in <= 0;
      end
    end
    4 : begin // seed
      data_type <= 4;
      if(readin_ok /*& readin*/) begin
        readin <= 1;
        index <= index + 1;
        in_index <= index;
        din <= seed[index];
      end
      if(index == (1 << 5) - 1 ) begin // TODO: this difference is kinda bad?
        full_in <= 1;
      end
      else begin
        full_in <= 0;
      end
    end
    default: begin
      // nothing
      data_type <= 0;
      index <= 0;
      readin <= 0;
    end 
  endcase
end


endmodule