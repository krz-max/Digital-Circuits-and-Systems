module P_MUL(
    clk,
    rst_n,
    in_1,
    in_2,
    in_3,
    in_valid,
    out_valid,
    out
);
//port
input clk, rst_n, in_valid;
input [47-1:0] in_1, in_2;
input [48-1:0] in_3;
output logic out_valid;
output logic [96-1:0] out;

//reg
logic [47-1:0] in1_reg, in2_reg;
logic [48-1:0] in3_reg, sumA, sumB;
logic [24-1:0] MUL16 [16-1:0];
logic [12-1:0] Pa [4-1:0];
logic [12-1:0] Pb [4-1:0];
logic [7-1:0] shift;
logic [96-1:0] ADD8 [8-1:0];
logic [96-1:0] ADD4 [4-1:0];
logic [96-1:0] ADD;

logic [48-1:0] A_reg, B_reg;
logic inValid_reg1, inValid_reg2, inValid_reg3, valid;
logic [24-1:0] MUL16_reg [16-1:0];

//design
//stage 1
assign valid = (in_valid == 1) ? 1 : 0;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in1_reg <= 0;
        in2_reg <= 0;
        in3_reg <= 0;
        inValid_reg1 <= 0;
    end
    else begin
        in1_reg <= in_1;
        in2_reg <= in_2;
        in3_reg <= in_3;
        inValid_reg1 <= valid;
    end
end

//stage 2
assign sumA = in1_reg + in2_reg;
assign sumB = in3_reg;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        A_reg <= 0;
        B_reg <= 0;
        inValid_reg2 <= 0;
    end
    else begin
        A_reg <= sumA;
        B_reg <= sumB;
        inValid_reg2 <= inValid_reg1;
    end
end

//stage 3
always_comb begin
    Pa[0] = A_reg[11:0];
    Pa[1] = A_reg[23:12];
    Pa[2] = A_reg[35:24];
    Pa[3] = A_reg[47:36];
    Pb[0] = B_reg[11:0];
    Pb[1] = B_reg[23:12];
    Pb[2] = B_reg[35:24];
    Pb[3] = B_reg[47:36];
    MUL16[0] = Pa[0] * Pb[0];
    MUL16[1] = Pa[0] * Pb[1];
    MUL16[2] = Pa[0] * Pb[2];
    MUL16[3] = Pa[0] * Pb[3];
    MUL16[4] = Pa[1] * Pb[0];
    MUL16[5] = Pa[1] * Pb[1];
    MUL16[6] = Pa[1] * Pb[2];
    MUL16[7] = Pa[1] * Pb[3];
    MUL16[8] = Pa[2] * Pb[0];
    MUL16[9] = Pa[2] * Pb[1];
    MUL16[10] = Pa[2] * Pb[2];
    MUL16[11] = Pa[2] * Pb[3];
    MUL16[12] = Pa[3] * Pb[0];
    MUL16[13] = Pa[3] * Pb[1];
    MUL16[14] = Pa[3] * Pb[2];
    MUL16[15] = Pa[3] * Pb[3];
end
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        MUL16_reg <= {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        inValid_reg3 <= 0;
    end
    else begin
        MUL16_reg <= MUL16;
        inValid_reg3 <= inValid_reg2;
    end
end

//stage 4
always_comb begin
    ADD = (MUL16_reg[0] + (MUL16_reg[1]<<12)) + ((MUL16_reg[2]<<24) + (MUL16_reg[3]<<36)) + 
        ((MUL16_reg[4]<<12 )+ (MUL16_reg[5]<<24)) + ((MUL16_reg[6]<<36) + (MUL16_reg[7]<<48)) +
        ((MUL16_reg[8]<<24 )+ (MUL16_reg[9]<<36)) + ((MUL16_reg[10]<<48) + (MUL16_reg[11]<<60)) +
        ((MUL16_reg[12]<<36) + (MUL16_reg[13]<<48)) + ((MUL16_reg[14]<<60) + (MUL16_reg[15]<<72));
end
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
        out_valid <= 0;
    end
    else begin
        out <= ADD;
        out_valid <= inValid_reg3;
    end
end


endmodule