
`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
`include "Seq.sv"
`elsif GATE
`include "Seq_SYN.v"
`endif

module TESTBED();


logic clk,rst_n;
logic in_valid,in_data,in_state_reset;
logic out_valid,out;
logic [2:0]out_cur_state;


initial begin
  `ifdef RTL
    $fsdbDumpfile("Seq.fsdb");
	  $fsdbDumpvars;
  `elsif GATE
    $fsdbDumpfile("Seq_SYN.fsdb");
	  $sdf_annotate("Seq_SYN.sdf",I_design);
	  $fsdbDumpvars();
  `endif 
end

	


Seq I_design
(
	.clk(clk),
	.rst_n(rst_n),
  .in_data(in_data),
  .in_state_reset(in_state_reset),
	.out_cur_state(out_cur_state),
  .out(out)
);


PATTERN I_PATTERN
(
	.clk(clk),
	.rst_n(rst_n),
  .in_data(in_data),
  .in_state_reset(in_state_reset),
	.out_cur_state(out_cur_state),
  .out(out)
);
endmodule

