//`timescale 1us/100ns
`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
	`include "Checkdigit.sv"
`elsif GATE
	`include "Checkdigit_SYN.v"
`endif

module TESTBENCH();

logic [3:0] in_num;
logic in_valid, rst_n, clk;

logic [3:0] out;
logic out_valid;

initial begin
	`ifdef RTL
		$fsdbDumpfile("Checkdigit.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("Checkdigit_SYN.fsdb");
		$sdf_annotate("Checkdigit_SYN.sdf", I_Checkdigit);
		$fsdbDumpvars(0,"+mda");
	`endif
end

Checkdigit I_Checkdigit
(
	.in_num(in_num),
	.in_valid(in_valid),
	.rst_n(rst_n),
	.clk(clk),
	.out_valid(out_valid),
	.out(out)
);

PATTERN I_PATTERN
(
	.in_num(in_num),
	.in_valid(in_valid),
	.rst_n(rst_n),
	.clk(clk),
	.out_valid(out_valid),
	.out(out)
);
endmodule
