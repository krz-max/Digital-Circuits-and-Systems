`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
`include "inter.sv"
`include "mem_slave.sv"
`elsif GATE
`include "inter_SYN.v"
`include "mem_slave.sv"
`endif



module TESTBENCH();



logic clk,rst_n,in_valid_1,in_valid_2,in_valid_3;
logic [6:0] data_1, data_2, data_3;
logic valid_master2slave1, valid_master2slave2, ready_slave1, ready_slave2;
logic [2:0] addr_master2slave, value_master2slave;
logic [2:0] golden0[7:0], golden1[7:0];
logic interconnect2master_ready1, interconnect2master_ready2;


initial begin 
  `ifdef RTL
      $fsdbDumpfile("inter.fsdb");
	  $fsdbDumpvars;
  `elsif GATE
      $fsdbDumpfile("inter_SYN.fsdb");
	  $sdf_annotate("inter_SYN.sdf",I_interconnect);
	  $fsdbDumpvars();
  `endif 
end
//================================================================
// parameters & integer
//================================================================



inter I_interconnect
(
  .clk(clk),
  .rst_n(rst_n),
  .in_valid_1(in_valid_1),
  .in_valid_2(in_valid_2),
  .in_valid_3(in_valid_3),
  .data_in_1(data_1),
  .data_in_2(data_2),
  .data_in_3(data_3),
  .valid_slave1(valid_master2slave1),
  .valid_slave2(valid_master2slave2),
  .ready_slave1(ready_slave1),
  .ready_slave2(ready_slave2),
  .addr_out(addr_master2slave),
  .value_out(value_master2slave),
  .handshake_slave1(interconnect2master_ready1),
  .handshake_slave2(interconnect2master_ready2)
);



PATTERN I_PATTERN
(
  .clk(clk),
  .rst_n(rst_n),
  .in_valid_1(in_valid_1),
  .in_valid_2(in_valid_2),
  .in_valid_3(in_valid_3),
  .data_in_1(data_1),
  .data_in_2(data_2),
  .data_in_3(data_3),
  .valid_slave1(valid_master2slave1),
  .valid_slave2(valid_master2slave2),
  .ready_slave1(ready_slave1),
  .ready_slave2(ready_slave2),
  .addr_out(addr_master2slave),
  .value_out(value_master2slave),
  .handshake_slave1(interconnect2master_ready1),
  .handshake_slave2(interconnect2master_ready2)
);
endmodule
