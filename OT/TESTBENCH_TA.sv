`timescale 1ns/1ps
`include "PATTERN_TA.sv"
`ifdef RTL
	`include "Divider.sv"
`elsif GATE
	`include "Divider_SYN.v"
`endif

module TESTBED();

logic clk, rst_n, in_valid;
logic [3:0] in_data;
logic out_valid, out_data;

initial begin
	`ifdef RTL
		$fsdbDumpfile("Divider.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("Divider_SYN.fsdb");
		$sdf_annotate("Divider_SYN.sdf", I_Divider);
		$fsdbDumpvars(0);
	`endif
end

Divider I_Divider
(
	.clk		(clk),
	.rst_n		(rst_n),
    .in_valid	(in_valid),
    .in_data	(in_data),
	.out_valid	(out_valid),
    .out_data	(out_data)
);

PATTERN I_PATTERN
(
	.clk		(clk),
	.rst_n		(rst_n),
    .in_valid	(in_valid),
    .in_data	(in_data),
	.out_valid	(out_valid),
    .out_data	(out_data)
);

endmodule
