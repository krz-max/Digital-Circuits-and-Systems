`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
	`include "Comb.sv"
`elsif GATE
	`include "Comb_SYN.v"
`endif


module TESTBED();

initial begin
	`ifdef RTL
		$fsdbDumpfile("Comb.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("Comb_SYN.fsdb");
		$sdf_annotate("Comb_SYN.sdf", I_Comb);
		$fsdbDumpvars(0,"+mda");
	`endif
end

logic [3:0] in_num0, in_num1, in_num2, in_num3;
logic [4:0] out_num0, out_num1;

Comb I_Comb
(
	.in_num0 (in_num0 ),
	.in_num1 (in_num1 ),
	.in_num2 (in_num2 ),
	.in_num3 (in_num3 ),
	.out_num0(out_num0),
	.out_num1(out_num1)
);

PATTERN I_PATTERN
(
	.in_num0 (in_num0 ),
	.in_num1 (in_num1 ),
	.in_num2 (in_num2 ),
	.in_num3 (in_num3 ),
	.out_num0(out_num0),
	.out_num1(out_num1)
);

endmodule