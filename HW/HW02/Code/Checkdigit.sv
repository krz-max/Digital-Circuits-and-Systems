module Checkdigit(
    // Input signals
    in_num,
	in_valid,
	rst_n,
	clk,
    // Output signals
    out_valid,
    out
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input [3:0] in_num;
input in_valid, rst_n, clk;
output logic out_valid;
output logic [3:0] out;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [3:0] cnt, cnt_minus_one, Add, out_reg;
logic [3:0] Rem, Ans, Test, Greater_than_ten;
logic [4:0] Sum;
logic Check, Out;
//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------

// Combinational logic
assign cnt_minus_one = (!in_valid) ? 15 : cnt-1;
assign Out = ~|cnt;
assign out_valid = (Out) ? 1 : 0;

/*
// if(in_num*2 >= 10) t = 1;
// else t = 0; (9t = 9 or 0)
assign Greater_than_ten = (in_num <= 4) ? 0 : 9;


// if(cnt[0] == 0) out_reg = out + in_num
// else out_reg = (out + in_num*2/10 + in_num*2%10)%10 (= t + in_num*2 - 10 * t) 
assign Rem = (cnt[0] == 0) ? in_num : (in_num*2 - Greater_than_ten); 
*/

assign Test = (in_num <= 4) ? in_num : in_num-9;
assign Greater_than_ten = (cnt[0] == 1) ? Test : 0;
assign Rem = in_num + Greater_than_ten;
assign Sum = out+Rem;

assign Add = (Out) ? 0 : (Sum < 10) ? Sum : Sum-10;
assign Check = ~|Add;
assign Ans = (Check) ? 15 : 10-Add;
assign out_reg = (cnt == 1) ? Ans : Add;

// Sequential logic

always @(negedge rst_n or posedge clk) begin
    if(!rst_n) begin
        cnt <= 15;
    end
    else begin
        cnt <= cnt_minus_one;
    end
end

always @(negedge rst_n or posedge clk) begin
    if(!rst_n) begin
        out <= 0;
    end
    else begin
        out <= out_reg;
    end
end


endmodule
