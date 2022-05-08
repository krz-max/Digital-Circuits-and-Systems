//`timescale 1us/100ns
`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
	`include "Timer.sv"
`elsif GATE
	`include "Timer_SYN.v"
`endif

module TESTBENCH();

logic [4:0] in;
logic out_valid, in_valid, rst_n, clk;

initial begin
	`ifdef RTL
		$fsdbDumpfile("Timer.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("Timer_SYN.fsdb");
		$sdf_annotate("Timer_SYN.sdf", I_Timer);
		$fsdbDumpvars(0,"+mda");
	`endif
end

Timer I_Timer
(
	.in(in),
	.out_valid(out_valid),
	.in_valid(in_valid),
	.rst_n(rst_n),
	.clk(clk)
);

PATTERN I_PATTERN
(
	.in(in),
	.out_valid(out_valid),
	.in_valid(in_valid),
	.rst_n(rst_n),
	.clk(clk)
);
endmodule

