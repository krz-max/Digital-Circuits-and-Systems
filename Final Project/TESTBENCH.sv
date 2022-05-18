`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
	`include "JAM.sv"
`elsif GATE
	`include "JAM_SYN.v"
`endif

module TESTBED();

logic clk, rst_n, in_valid;
logic [6:0] in_cost;
logic out_valid;
logic [3:0] out_job;
logic [9:0] out_cost;

initial begin
	`ifdef RTL
		$fsdbDumpfile("JAM.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("JAM_SYN.fsdb");
		$sdf_annotate("JAM_SYN.sdf", I_DESIGN);
		$fsdbDumpvars(0);
	`endif
end

JAM I_DESIGN
(
	.clk		(clk),
	.rst_n		(rst_n),
	.in_valid	(in_valid),
	.in_cost	(in_cost),
	.out_valid	(out_valid),
	.out_job	(out_job),
	.out_cost	(out_cost)
);

PATTERN I_PATTERN
(
	.clk		(clk),
	.rst_n		(rst_n),
	.in_valid	(in_valid),
	.in_cost	(in_cost),
	.out_valid	(out_valid),
	.out_job	(out_job),
	.out_cost	(out_cost)
);

endmodule