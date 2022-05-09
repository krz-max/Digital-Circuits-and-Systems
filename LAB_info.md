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
