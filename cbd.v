module cbd( //
  input clk,
  input set,
  input reset,
  input wire readin,
  input wire readout,

  input wire [31:0] cbd_din_1,
  input wire [31:0] cbd_din_2,
  
  output reg signed [15:0] cbd_dout_1, // read data out in poly form
  output reg signed [15:0] cbd_dout_2,
  
  output reg ok_in,
  output reg ok_out
);

reg we_1, we_2;
reg [4:0] addr_1, addr_2;
reg [31:0] din_1, din_2;
wire [31:0] dout_1, dout_2;

reg [31:0] cal_din;
wire [31:0] cal_dout;

dual_ram #(5, 32) ram1(
  .clk(clk),
  .we_1(we_1),
  .we_2(we_2),
  .addr_1(addr_1),
  .addr_2(addr_2),
  .din_1(din_1),
  .din_2(din_2),
  .dout_1(dout_1),
  .dout_2(dout_2)
);

cbd2_cal cbd2_1(
  .clk(clk),
  .set(set),
  .din(cal_din),
  .dout(cal_dout)
);

reg [5:0] counter; // unsigned
reg [3:0] timer;
reg ready;
reg [1:0] grain;
reg [31:0] dout;
reg ctrl;
wire signed [3:0] temp1 = ((dout >> (grain*8  )) & 'hf);
wire signed [3:0] temp2 = ((dout >> (grain*8+4)) & 'hf);

always @(posedge clk or posedge reset) begin
  if(reset) begin
    addr_1 <= 'dz; addr_2 <= 'dz;
    din_1  <= 'dz; din_2  <= 'dz;
    we_1   <=   0; we_2   <=   0;

    ok_in  <=   1; ok_out <=   0;
    ready   <= 0;
    counter <= 0;
    timer   <= 0;
    grain   <= 0;
    ctrl    <= 0;
  // the hash is writing into RAM
  end else if(set && readin && !ready && ok_in) begin
    if(counter < 32) begin
      counter <= counter + 2;
      we_1 <= 1; we_2 <= 1;
      
      addr_1 <= counter;
      addr_2 <= counter + 1;
      din_1  <= cbd_din_1;
      din_2  <= cbd_din_2;
    end else begin
      /*
      addr_1 <= 'dz; addr_2 <= 'dz;
      din_1  <= 'dz; din_2  <= 'dz;
      */
      we_1   <=   0; we_2   <=   0;
      
      ok_in   <= 0; // no more data going in
      ready   <= 1; // the data is ready to process
      counter <= 0; // because data hazard
    end
  // the data is pulled from RAM, sampled, and written back to RAM
  end else if(set && ready && !ok_out) begin
    if(counter < 36) begin
      counter <= counter + 1; // read from port 1 and write to port 2
      we_1 <= 0;
      if(counter < 32) begin
        addr_1 <= counter;
      end
      if(timer > 1) begin
        cal_din <= dout_1;
      end
      if(timer < 4) begin
        timer <= timer + 1;
      end else begin
        we_2   <= 1;
        addr_2 <= counter - 4;
        din_2  <= cal_dout;
      end
    end else begin
      /*
      addr_1 <= 'dz; addr_2 <= 'dz;
      din_1  <= 'dz; din_2  <= 'dz;
      */
      /*we_1   <=   0;*/  we_2  <=   0;
      
      //cal_din   <= 'dz;
      ok_out    <=   1;
      counter   <=   0;
      timer     <=   0; // timer was used, make sense to reset it right?
    end
  // the data is processed in full, ready to output
  end else if(set && ready && ok_out && readout) begin
    if(timer < 3) begin
      timer <= timer + 1;
    end else begin
      timer <= 0;
    end
    if(ctrl) begin
      grain <= grain + 1;
      
      cbd_dout_1 <= temp1;
      cbd_dout_2 <= temp2;
    end
    if(counter < 33) begin
      if(timer == 0) begin
        counter <= counter + 1;
        addr_1  <= counter;
      end
      if(timer == 2) begin
        dout <= dout_1;
        ctrl <= 1;
      end
    end else begin
      if(timer == 2) begin
        /*
        addr_1 <= 'dz; addr_2 <= 'dz;
        din_1  <= 'dz; din_2  <= 'dz;
        */
        ok_in  <=   1; ok_out <=   0;
        
        ready   <= 0; // the data is now stale
        counter <= 0;
        timer   <= 0; // timer reset
        //grain   <= 0; // it resets itself here
        ctrl    <= 0;
      end
    end
  end else begin
    // no op :>
  end
end

/*
addr_1 <= 'dz; addr_2 <= 'dz;
din_1  <= 'dz; din_2  <= 'dz;
we_1   <=  0;  we_2   <=  0;
ready <= 0; // you have read the data in full, the data is now stale
counter <= 0;

// split the line
wire signed [15:0] d[0] = (dout >> 0 )  &'hf;
wire signed [15:0] d[1] = (dout >> 4 )  &'hf;
wire signed [15:0] d[2] = (dout >> 8 )  &'hf;
wire signed [15:0] d[3] = (dout >> 12)  &'hf;
wire signed [15:0] d[4] = (dout >> 16)  &'hf;
wire signed [15:0] d[5] = (dout >> 20)  &'hf;
wire signed [15:0] d[6] = (dout >> 24)  &'hf;
wire signed [15:0] d[7] = (dout >> 28)  &'hf;
*/
// I think I can extend it when it's ok_in to be used as a polynomial?


/*
[hash(random number)]->[cbd2_cal]->[ram]
*/

endmodule