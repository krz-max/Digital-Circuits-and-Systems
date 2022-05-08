
`timescale 1ns/1ps
`include "pattern.sv"
`ifdef RTL
`include "lab07_3.sv"
`elsif GATE
`include "lab07_3_SYN.v"
`endif
module testbench();

logic clk,rst_n;
logic in_valid;
logic [3:0] in_number;
logic [1:0] mode;

logic out_valid;
logic signed [6:0] out_result;



initial begin
  `ifdef RTL
    $fsdbDumpfile("lab07_3.fsdb");
	  $fsdbDumpvars;
  `elsif GATE
    $fsdbDumpfile("lab07_3_SYN.fsdb");
	  $sdf_annotate("lab07_3_SYN.sdf",I_Counter);
	  $fsdbDumpvars();
  `endif
end

	


lab07_3 I_lab07_3
(
  .clk(clk),
  .rst_n(rst_n),
  .in_valid(in_valid),
  .out_valid(out_valid),
  .in_number(in_number),
  .mode(mode),
  .out_result(out_result)
);


pattern I_pattern
(
  .clk(clk),
  .rst_n(rst_n),
  .in_valid(in_valid),
  .out_valid(out_valid),
  .in_number(in_number),
  .mode(mode),
  .out_result(out_result)
);
endmodule

