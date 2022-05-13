# DCS
## Lab01: Basic combinational
1. Lab Description
   - There will be 4 numbers, take `A = num0 XNOR num1, B = num1 OR num3, C = num0 & num2, D = num2 XOR num3`
   - After that, calculate `A+B` and `C+D`, and output in ascending order.
2. Port declaration
   - Input
     - [4-1:0] in_num0, in_num1, in_num3, in_num4
   - Output
     - [5-1:0] out_num0, out_num1
## Lab02: Timer
1. Lab Description
   - When `in_valid` is given, set `out_valid` to 1 after `in` cycles.
2. Port declaration
   - Input
     - clk, rst_n, in_valid
     - [5-1:0] in
   - Output
     - out_valid
## Lab03: MaxMin
1. Lab Description
   - Find Maximum and Minimum value in a given sequence.
   - Input will be given at each negedge of `clk`
2. Port declaration
   - Input
     - clk, rst_n, in_valid
     - [8-1:0] in_num
   - Output
     - [8-1:0] out_max, out_min
     - out_valid
## Lab04: Sequence(FSM)
1. Lab Description
   - Design a FSM to detect any 3 continuous bit(0 or 1) in the given sequence.
2. Port declaration
   - Input
     - clk, rst_n, in_data, in_state_reset
   - Output
     - out
     - [3-1:0] out_cur_state
## Lab05: AHB interconnect
1. Lab Description
   - Masters will send input data to interconnect
   - Decode input data for `valid`, `address` and `value`
   - Based on master priority(1->2->3), send data to slave memory
   - Output handshake signal
2. Port declaration
   - Input
     - clk, rst_n, in_valid_1, in_valid_2, in_valid_3, ready_slave1, ready_slave2
     - [7-1:0] data_in_1, data_in_2, data_in_3
   - Output
     - valid_slave1, valid_slave2, handshake_slave1, handshake_slave2
     - [3-1:0] addr_out, value_out
## Lab06: Floating Point Computation(bfloat16)
1. Lab Description
   - Design a module to compute addition and multiplication of float number in `bfloat16` format
2. Port declaration
   - Input
     - clk, rst_n, in_valid, mode
     - [16-1:0] in_a, in_b
   - Output
     - out_valid
     - [16-1:0] out
---
/**************************** Template ******************************/
## Labxx: 
1. Lab Description
   - 
2. Port declaration
   - Input
   - Output
   - 
/**************************** Template ******************************/
