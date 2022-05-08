//`timescale 1us/100ns
`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
	`include "Maxmin.sv"
`elsif GATE
	`include "Maxmin_SYN.v"
`endif

module TESTBENCH();

logic [7:0] in_num;
logic in_valid, rst_n, clk;

logic [7:0] out_max, out_min;
logic out_valid;

initial begin
	`ifdef RTL
		$fsdbDumpfile("Maxmin.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("Maxmin_SYN.fsdb");
		$sdf_annotate("Maxmin_SYN.sdf", I_Maxmin);
		$fsdbDumpvars(0,"+mda");
	`endif
end

Maxmin I_Maxmin
(
	.in_num(in_num),
	.in_valid(in_valid),
	.rst_n(rst_n),
	.clk(clk),
	.out_valid(out_valid),
	.out_max(out_max),
	.out_min(out_min)
);

PATTERN I_PATTERN
(
	.in_num(in_num),
	.in_valid(in_valid),
	.rst_n(rst_n),
	.clk(clk),
	.out_valid(out_valid),
	.out_max(out_max),
	.out_min(out_min)
);
endmodule
