
`timescale 1ns/1ps
`include "PATTERN.sv"
`ifdef RTL
`include "VM.sv"
`elsif GATE
`include "VM_SYN.v"
`endif

module TESTBED();


logic clk;
logic rst_n;
logic in_item_valid;
logic in_coin_valid;
logic [5:0] in_coin;
logic in_rtn_coin;
logic [2:0] in_buy_item;
logic [4:0] in_item_price;
logic [1:0] in_item_num;
logic [8:0] out_monitor;
logic out_valid;
logic [3:0] out_consumer;
logic [5:0] out_sell_num;

initial begin
  `ifdef RTL
    $fsdbDumpfile("VM.fsdb");
	  $fsdbDumpvars(0,"+mda");
  `elsif GATE
    $fsdbDumpfile("VM_SYN.fsdb");
	  $sdf_annotate("VM_SYN.sdf",I_design);
	  $fsdbDumpvars(0,"+mda");
  `endif
end

	


VM I_design
(
.clk(clk),
.rst_n(rst_n),
.in_coin_valid(in_coin_valid),
.in_coin(in_coin),
.in_item_valid(in_item_valid),
.in_item_price(in_item_price),
.in_rtn_coin(in_rtn_coin),
.in_buy_item(in_buy_item),
.out_monitor(out_monitor), 
.out_valid(out_valid),
.out_consumer(out_consumer),
.out_sell_num(out_sell_num)
);


PATTERN I_PATTERN
(
.clk(clk),
.rst_n(rst_n),
.in_coin_valid(in_coin_valid),
.in_coin(in_coin),
.in_item_valid(in_item_valid),
.in_item_price(in_item_price),
.in_rtn_coin(in_rtn_coin),
.in_buy_item(in_buy_item),
.out_monitor(out_monitor),
.out_valid(out_valid),
.out_consumer(out_consumer),
.out_sell_num(out_sell_num)
);
endmodule

