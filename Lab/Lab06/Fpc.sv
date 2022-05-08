module Fpc(
    clk,
    rst_n,
    in_valid,
    mode,
    in_a,
    in_b,
    out_valid,
    out
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid, mode;
input [16-1:0] in_a, in_b;
output logic out_valid;
output logic [16-1:0] out;

//---------------------------------------------------------------------
//   FSM state
//---------------------------------------------------------------------
parameter CALC = 0;
parameter OUTPUT = 1;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [1:0] state, state_nxt;
logic [16-1:0] out_nxt; 
logic signed [16-1:0] mul_reg;
logic [7-1:0] Frac_result, Frac_result_m;
logic move, Sign;
logic [8-1:0] shift, sum_exp, mul_exp, a_ext, b_ext;
logic signed [9-1:0] a_reg, b_reg, a_Frac, b_Frac, a_shift, b_shift;
logic signed [10-1:0] sum_reg, sum_sign;
logic [4-1:0] point_shift;
logic [5-1:0] point_shift_m;
//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------
assign state_nxt = (in_valid == 0) ? CALC : OUTPUT;
assign out_valid = (state == OUTPUT) ? 1'b1 : 1'b0;

assign a_ext = {1'b1, in_a[6:0]};
assign b_ext = {1'b1, in_b[6:0]};
assign move = (in_a[14:7] >= in_b[14:7]) ? 1 : 0;
assign shift = (move == 1) ? in_a[14:7] - in_b[14:7] : in_b[14:7] - in_a[14:7];
assign a_shift = (move == 0) ? a_ext >> shift : a_ext;
assign b_shift = (move == 1) ? b_ext >> shift : b_ext;
assign a_reg = (in_a[15] == 1) ? ~a_shift+1 : a_shift;
assign b_reg = (in_b[15] == 1) ? ~b_shift+1 : b_shift;

assign sum_reg = a_reg + b_reg;
assign mul_reg = a_ext * b_ext;
assign Sign = (mode == 0) ? (sum_reg[9] == 1) ? 1 : 0 : (in_a[15] ^ in_b[15]) ? 1 : 0;
assign sum_sign = (Sign) ? ~sum_reg+1 : sum_reg;
always_comb begin
    if(sum_sign[8] == 1) begin
        point_shift = 9;
    end
    else if(sum_sign[7] == 1) begin
        point_shift = 8;
    end
    else if(sum_sign[6] == 1) begin
        point_shift = 7;
    end
    else if(sum_sign[5] == 1) begin
        point_shift = 6;
    end
    else if(sum_sign[4] == 1) begin
        point_shift = 5;
    end
    else if(sum_sign[3] == 1) begin
        point_shift = 4;
    end
    else if(sum_sign[2] == 1) begin
        point_shift = 3;
    end
    else if(sum_sign[1] == 1) begin
        point_shift = 2;
    end
    else if(sum_sign[0] == 1) begin
        point_shift = 1;
    end
    else begin
        point_shift = 0;
    end
end
always_comb begin
    if(mul_reg[15] == 1) begin
        point_shift_m = 16;
    end
    else if(mul_reg[14] == 1) begin
        point_shift_m = 15;
    end
    else if(mul_reg[13] == 1) begin
        point_shift_m = 14;
    end
    else if(mul_reg[12] == 1) begin
        point_shift_m = 13;
    end
    else if(mul_reg[11] == 1) begin
        point_shift_m = 12;
    end
    else if(mul_reg[10] == 1) begin
        point_shift_m = 11;
    end
    else if(mul_reg[9] == 1) begin
        point_shift_m = 10;
    end
    else if(mul_reg[8] == 1) begin
        point_shift_m = 9;
    end
    else if(mul_reg[7] == 1) begin
        point_shift_m = 8;
    end
    else if(mul_reg[6] == 1) begin
        point_shift_m = 7;
    end
    else if(mul_reg[5] == 1) begin
        point_shift_m = 6;
    end
    else if(mul_reg[4] == 1) begin
        point_shift_m = 5;
    end
    else if(mul_reg[3] == 1) begin
        point_shift_m = 4;
    end
    else if(mul_reg[2] == 1) begin
        point_shift_m = 3;
    end
    else if(mul_reg[1] == 1) begin
        point_shift_m = 2;
    end
    else if(mul_reg[0] == 1) begin
        point_shift_m = 1;
    end
    else begin
        point_shift_m = 0;
    end
end
always_comb begin
    case (point_shift)
        9: Frac_result = sum_sign[7:1];
        8: Frac_result = sum_sign[6:0];
        7: Frac_result = {sum_sign[5:0], 1'b0};
        6: Frac_result = {sum_sign[4:0], 2'b0};
        5: Frac_result = {sum_sign[3:0], 3'b0};
        4: Frac_result = {sum_sign[2:0], 4'b0};
        3: Frac_result = {sum_sign[1:0], 5'b0};
        2: Frac_result = {sum_sign[0], 6'b0};
        default: Frac_result = 0;
    endcase
end

always_comb begin
    case (point_shift)
        9: sum_exp = (move == 1) ? in_a[14:7] + 1 : in_b[14:7] + 1;
        8: sum_exp = (move == 1) ? in_a[14:7] : in_b[14:7];
        7: sum_exp = (move == 1) ? in_a[14:7] - 1 : in_b[14:7] - 1;
        6: sum_exp = (move == 1) ? in_a[14:7] - 2 : in_b[14:7] - 2;
        5: sum_exp = (move == 1) ? in_a[14:7] - 3 : in_b[14:7] - 3;
        4: sum_exp = (move == 1) ? in_a[14:7] - 4 : in_b[14:7] - 4;
        3: sum_exp = (move == 1) ? in_a[14:7] - 5 : in_b[14:7] - 5;
        2: sum_exp = (move == 1) ? in_a[14:7] - 6 : in_b[14:7] - 6;
        1: sum_exp = (move == 1) ? in_a[14:7] - 7 : in_b[14:7] - 7;
        default: sum_exp = (move == 1) ? in_a[14:7] : in_b[14:7];
    endcase
end

always_comb begin
    case (point_shift_m)
        16: Frac_result_m = mul_reg[14:8];
        15: Frac_result_m = mul_reg[13:7];
        14: Frac_result_m = mul_reg[12:6];
        13: Frac_result_m = mul_reg[11:5];
        12: Frac_result_m = mul_reg[10:4];
        11: Frac_result_m = mul_reg[9:3];
        10: Frac_result_m = mul_reg[8:2];
        9: Frac_result_m = mul_reg[7:1];
        8: Frac_result_m = mul_reg[6:0];
        7: Frac_result_m = {mul_reg[5:0], 1'b0};
        6: Frac_result_m = {mul_reg[4:0], 2'b0};
        5: Frac_result_m = {mul_reg[3:0], 3'b0};
        4: Frac_result_m = {mul_reg[2:0], 4'b0};
        3: Frac_result_m = {mul_reg[1:0], 5'b0};
        2: Frac_result_m = {mul_reg[0], 6'b0};
        default: Frac_result_m = 0;
    endcase
end

always_comb begin
    case (point_shift_m)
        16: mul_exp = in_a[14:7] + in_b[14:7] + 1 - 127;
        15: mul_exp = in_a[14:7] + in_b[14:7] - 127;
        14: mul_exp = in_a[14:7] + in_b[14:7] - 1 - 127;
        13: mul_exp = in_a[14:7] + in_b[14:7] - 2 - 127;
        12: mul_exp = in_a[14:7] + in_b[14:7] - 3 - 127;
        11: mul_exp = in_a[14:7] + in_b[14:7] - 4 - 127;
        10: mul_exp = in_a[14:7] + in_b[14:7] - 5 - 127;
        9: mul_exp = in_a[14:7] + in_b[14:7] - 6 - 127;
        8: mul_exp = in_a[14:7] + in_b[14:7] - 7 - 127;
        7: mul_exp = in_a[14:7] + in_b[14:7] - 8 - 127;
        6: mul_exp = in_a[14:7] + in_b[14:7] - 9 - 127;
        5: mul_exp = in_a[14:7] + in_b[14:7] - 10 - 127;
        4: mul_exp = in_a[14:7] + in_b[14:7] - 11 - 127;
        3: mul_exp = in_a[14:7] + in_b[14:7] - 12 - 127;
        2: mul_exp = in_a[14:7] + in_b[14:7] - 13 - 127;
        1: mul_exp = in_a[14:7] + in_b[14:7] - 14 - 127;
        default: mul_exp = in_a[14:7] + in_b[14:7] - 127;
    endcase
end

always_comb begin
    if(in_valid) begin
        if(mode == 0) begin
            out_nxt = {Sign, sum_exp, Frac_result};
        end
        else begin
            out_nxt = {Sign, mul_exp, Frac_result_m};
        end
    end
    else out_nxt = 0;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
        state <= CALC;
    end
    else begin
        out <= out_nxt;
        state <= state_nxt;
    end
end

endmodule
