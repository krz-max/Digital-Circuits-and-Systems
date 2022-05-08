
`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
`include "Fpc.sv"
`elsif GATE
`include "Fpc_SYN.v"
`endif

module TESTBED();


logic clk, rst_n, in_valid, mode;
logic [15:0] in_a, in_b;
logic out_valid;
logic [15:0] out;


initial begin
  `ifdef RTL
    $fsdbDumpfile("Fpc.fsdb");
	  $fsdbDumpvars();
	  $fsdbDumpvars("+mda");
  `elsif GATE
    $fsdbDumpfile("Fpc_SYN.fsdb");
	  $sdf_annotate("Fpc_SYN.sdf",I_design);
	  $fsdbDumpvars();
  `endif 
end

	


Fpc I_design
(
  .clk(clk),
	.rst_n(rst_n),
  .in_valid(in_valid),
  .in_a(in_a),
  .in_b(in_b),
  .mode(mode),
  .out_valid(out_valid),
  .out(out)
);


PATTERN I_PATTERN
(
  .clk(clk),
	.rst_n(rst_n),
  .in_valid(in_valid),
  .in_a(in_a),
  .in_b(in_b),
  .mode(mode),
  .out_valid(out_valid),
  .out(out)
);
endmodule

