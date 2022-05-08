//`timescale 1us/100ns
`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
	`include "P_MUL.sv"
`elsif GATE
	`include "P_MUL_SYN.v"
`endif

module TESTBENCH();

logic [46:0] in_1, in_2;
logic [47:0] in_3;
logic in_valid, rst_n, clk;

logic [95:0] out;
logic out_valid;

initial begin
	`ifdef RTL
		$fsdbDumpfile("P_MUL.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("P_MUL_SYN.fsdb");
		$sdf_annotate("P_MUL_SYN.sdf", I_P_MUL);
		$fsdbDumpvars(0,"+mda");
	`endif
end

P_MUL I_P_MUL
(
	.in_1(in_1),
	.in_2(in_2),
	.in_3(in_3),
	.in_valid(in_valid),
	.rst_n(rst_n),
	.clk(clk),
	.out_valid(out_valid),
	.out(out)
);

PATTERN I_PATTERN
(
	.in_1(in_1),
	.in_2(in_2),
	.in_3(in_3),
	.in_valid(in_valid),
	.rst_n(rst_n),
	.clk(clk),
	.out_valid(out_valid),
	.out(out)
);
endmodule
