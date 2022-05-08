//`timescale 1us/100ns
`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
	`include "CN.sv"
`elsif GATE
	`include "CN_SYN.v"
`endif

module TESTBENCH();

logic [3:0] in_n0, in_n1, in_n2, in_n3, in_n4, in_n5;
logic [4:0] opcode;
logic [8:0] out_n;

initial begin
	`ifdef RTL
		$fsdbDumpfile("CN.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("CN_SYN.fsdb");
		$sdf_annotate("CN_SYN.sdf", I_CN);
		$fsdbDumpvars(0,"+mda");
	`endif
end

CN I_CN
(
	.opcode(opcode),
	.in_n0(in_n0),
	.in_n1(in_n1),
	.in_n2(in_n2),
	.in_n3(in_n3),
	.in_n4(in_n4),
	.in_n5(in_n5),
	.out_n(out_n)
);

PATTERN I_PATTERN
(
	.opcode(opcode),
	.in_n0(in_n0),
	.in_n1(in_n1),
	.in_n2(in_n2),
	.in_n3(in_n3),
	.in_n4(in_n4),
	.in_n5(in_n5),
	.out_n(out_n)
);
endmodule

