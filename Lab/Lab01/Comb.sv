module Comb(
  // Input signals
	in_num0,
	in_num1,
	in_num2,
	in_num3,
  // Output signals
	out_num0,
	out_num1
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input [3:0] in_num0, in_num1, in_num2, in_num3;
output logic [4:0] out_num0, out_num1;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [3:0] XNOR1_out, OR1_out, AND1_out, XOR1_out;
logic [4:0] Adder_out1, Adder_out2;

//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------
assign XNOR1_out = in_num0 ~^ in_num1;
assign OR1_out   = in_num1 |  in_num3;
assign AND1_out  = in_num0 &  in_num2;
assign XOR1_out  = in_num2 ^  in_num3;

assign Adder_out1 = XNOR1_out + OR1_out;
assign Adder_out2 = AND1_out  + XOR1_out;

assign out_num0 = (Adder_out1 <= Adder_out2) ? Adder_out1 : Adder_out2;
assign out_num1 = (Adder_out1 <= Adder_out2) ? Adder_out2 : Adder_out1;

endmodule
