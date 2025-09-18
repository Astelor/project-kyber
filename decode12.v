/*
This module works for 
technically you need to account for the sign extention
but the public key would be strictly positive integer, 
so it negates the need for one
*/

module decode12(
  input clk,
  input set,
  input reset,

  input readin,
  input [7:0]  din,
  input [15:0] in_index,

  output [15:0] dout_1,
  output [15:0] dout_2,
  output reg output_ok,
  output reg [15:0] out_index//,
  // output reg [3:0] ctrl_status
);

reg [2:0] counter;
reg [7:0] stage;
reg [15:0] temp_1;
reg [15:0] temp_2;

reg [1:0] t;

assign dout_1 = (output_ok) ? temp_1 : 0;
assign dout_2 = (output_ok) ? temp_2 : 0;

always @(posedge clk or posedge reset) begin
  if(reset) begin
    counter <= -1;
    out_index <= -1; // so the index acutally starts with 0
    output_ok <= 0;
    temp_1 <= 'dz;//0;
    temp_2 <= 'dz;//0;
    stage  <= 'dz;//0;
    t <= 0;
  end
  else if(set & readin) begin
    stage <= din;
    // t <= (in_index & 'b11) % 3; // surely this is fine :>
    t <= in_index % 3;
    // t <= (in_index & 'b11) + 1; // and change the case for t 
    case (t)
      0 : begin
        temp_1 <= stage;
      end
      1 : begin // only unsigned number
        temp_1 <= (temp_1 | stage << 8) & 12'hfff;
        temp_2 <= stage >> 4;
      end
      2 : begin
        temp_2 <= (temp_2 | stage << 4) & 12'hfff;
      end
    endcase
    if(counter == 2) begin
      counter <= 0;
      out_index <= out_index + 1;
      
      output_ok <= 1;
      // dout_1 <= temp_1;
      // dout_2 <= temp_2;
    end
    else begin
      counter <= counter + 1; // it should reset itself
      output_ok <= 0;
    end
  end
end

endmodule


/*

index & 1
    0          1          2          3
 01234567  89ab||cdef  01234567
[01234567][0123||4567][01234567]
[              ][              ]
              ↑ sign extend here 
1           2     3      4

1 2 3
      0 1 2 0 1 2
0 1 2 3 4 5 6 7 8
[][][][][][][][][]
[    ][    ][    ]

the encrytion key is compressed into byte array
and only every 12 bits has information

it is to conform with the specs 
do it every 2 byte input for the polyvec input? 


void poly_frombytes(poly *r, const uint8_t a[KYBER_POLYBYTES])
{
  unsigned int i;
  for(i=0;i<KYBER_N/2;i++) {
    r->coeffs[2*i]   = ((a[3*i+0] >> 0) | ((uint16_t)a[3*i+1] << 8)) & 0xFFF;
    r->coeffs[2*i+1] = ((a[3*i+1] >> 4) | ((uint16_t)a[3*i+2] << 4)) & 0xFFF;
  }
}
*/