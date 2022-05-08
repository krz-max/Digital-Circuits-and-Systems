module MIPS(
    //Input 
    clk,
    rst_n,
    in_valid,
    instruction,
	output_reg,
    //OUTPUT
    out_valid,
    out_1,
	out_2,
	out_3,
	out_4,
	instruction_fail
);

    //Input 
input clk;
input rst_n;
input in_valid;
input [31:0] instruction;
input [19:0] output_reg;
    //OUTPUT
output logic out_valid, instruction_fail;
output logic [31:0] out_1, out_2, out_3, out_4;
//---------------------------------------------------------------------
//  Logic Declaration
//---------------------------------------------------------------------
logic [32-1:0] register_file [6-1:0], register_file_nxt [6-1:0];
logic [32-1:0] instrn_reg, x_rs, x_rs_nxt, x_rt, x_rt_nxt, alu_result, instruction_nxt;
logic [20-1:0] output_reg$1, output_reg$2, output_reg$3, output_reg$1_nxt;
logic [6-1:0] Opcode;
logic [5-1:0] rs, rt, rd_nxt, rd;
logic [16-1:0] immd_nxt, immd;
logic out_valid$1, out_valid$2, out_valid$3, instruction_fail_nxt, instruction_fail$1, instruction_fail$2;
logic rs_legal, rt_legal, rd_legal, legalAddress, Format, Format_nxt, legal;
//---------------------------------------------------------------------
//  Your design 
//---------------------------------------------------------------------

assign instruction_nxt = (in_valid == 1) ? instruction : 0;
assign output_reg$1_nxt = (in_valid == 1) ? output_reg : 0;
// level 1 : INPUT
// stage 1 : FF1
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        instrn_reg <= 0;
        output_reg$1 <= 0;
        out_valid$1 <= 0;
    end
    else begin
        instrn_reg <= instruction_nxt;
        output_reg$1 <= output_reg$1_nxt;
        out_valid$1 <= in_valid;
    end
end


// level 2 : Decode & Read register
// {Opcode, rs, rt, rd_nxt, Shamt_nxt, funct6_nxt} = instrn_reg
// {Opcode, rs, rt, immd_nxt} = instrn_reg
assign Opcode = instrn_reg[31:26];
assign rs = instrn_reg[25:21];
assign rt = instrn_reg[20:16];
assign rd_nxt = (Format_nxt == 0) ? rt : instrn_reg[15:11];
assign immd_nxt = instrn_reg[15:0];
// Format :
// 0 : illegal
// 1 : R format
// 2 : I format
assign Format_nxt = ~Opcode[3];
always_comb begin
    if(Opcode == 6'b000000) begin
        case(instrn_reg[5:0])
            6'b100000, 6'b100100, 6'b100101, 6'b100111, 6'b000000, 6'b000010: legal = 1;
            default: legal = 0;
        endcase
    end
    else if (Opcode == 6'b001000) begin
        legal = 1;
    end
    else begin
        legal = 0;
    end
end
// decode register_file
always_comb begin
    case(rs) // x_rs
        5'b10001: x_rs_nxt = register_file[5];
        5'b10010: x_rs_nxt = register_file[4];
        5'b01000: x_rs_nxt = register_file[3];
        5'b10111: x_rs_nxt = register_file[2];
        5'b11111: x_rs_nxt = register_file[1];
        5'b10000: x_rs_nxt = register_file[0];
        default: x_rs_nxt = 0;
    endcase
    case(rt) // x_rt
        5'b10001: x_rt_nxt = register_file[5];
        5'b10010: x_rt_nxt = register_file[4];
        5'b01000: x_rt_nxt = register_file[3];
        5'b10111: x_rt_nxt = register_file[2];
        5'b11111: x_rt_nxt = register_file[1];
        5'b10000: x_rt_nxt = register_file[0];
        default: x_rt_nxt = 0;
    endcase
end
always_comb begin
    case(rs) // rs_legal
        5'b10001, 5'b10010, 5'b01000, 5'b10111, 5'b11111, 5'b10000: rs_legal = 1;
        default: rs_legal = 0;
    endcase
    case(rt) // rt_legal
        5'b10001, 5'b10010, 5'b01000, 5'b10111, 5'b11111, 5'b10000: rt_legal = 1;
        default: rt_legal = 0;
    endcase
    case(rd_nxt) // rd_legal
        5'b10001, 5'b10010, 5'b01000, 5'b10111, 5'b11111, 5'b10000: rd_legal = 1;
        default: rd_legal = 0;
    endcase
end
assign legalAddress = rs_legal && rt_legal && rd_legal;
assign instruction_fail_nxt = (out_valid$1 == 0) ? 0 : (legal == 0 || legalAddress == 0) ? 1 : 0;

// stage 2 : FF2
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        output_reg$2 <= 0;
        out_valid$2 <= 0;
        instruction_fail$1 <= 0;
        x_rs <= 0;
        x_rt <= 0;
        rd <= 0;
        immd <= 0;
        Format <= 0;
    end
    else begin
        output_reg$2 <= output_reg$1;
        out_valid$2 <= out_valid$1;
        instruction_fail$1 <= instruction_fail_nxt;
        x_rs <= x_rs_nxt;
        x_rt <= x_rt_nxt;
        rd <= rd_nxt;
        immd <= immd_nxt;
        Format <= Format_nxt;
    end
end

// level 3 : ALU Calculate
always_comb begin
    if(Format == 0) begin
        alu_result = x_rs + immd;
    end
    else begin
        case(immd[5:0])
            6'b100000: alu_result = x_rs + x_rt;
            6'b100100: alu_result = x_rs & x_rt;
            6'b100101: alu_result = x_rs | x_rt;
            6'b100111: alu_result = ~(x_rs | x_rt);
            6'b000000: alu_result = x_rt << immd[10:6];
            6'b000010: alu_result = x_rt >> immd[10:6];
            default: alu_result = 0;
        endcase
    end
end
// if illegal, register is not changed.
// rd = rt if is I type
// rd = rd if is R type(is determined in previous stage)
always_comb begin
    if(instruction_fail$1 == 1) begin
        register_file_nxt = register_file;
    end
    else begin
        case(rd)
            5'b10001: register_file_nxt = {alu_result, register_file[4], register_file[3], register_file[2], register_file[1], register_file[0]};
            5'b10010: register_file_nxt = {register_file[5], alu_result, register_file[3], register_file[2], register_file[1], register_file[0]};
            5'b01000: register_file_nxt = {register_file[5], register_file[4], alu_result, register_file[2], register_file[1], register_file[0]};
            5'b10111: register_file_nxt = {register_file[5], register_file[4], register_file[3], alu_result, register_file[1], register_file[0]};
            5'b11111: register_file_nxt = {register_file[5], register_file[4], register_file[3], register_file[2], alu_result, register_file[0]};
            5'b10000: register_file_nxt = {register_file[5], register_file[4], register_file[3], register_file[2], register_file[1], alu_result};
            default: register_file_nxt = register_file;
        endcase
    end
end
// stage 3 : FF and write back
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        output_reg$3 <= 0;
        register_file <= {0, 0, 0, 0, 0, 0};
        out_valid$3 <= 0;
        instruction_fail$2 <= 0;
    end
    else begin
        output_reg$3 <= output_reg$2;
        register_file <= register_file_nxt;
        out_valid$3 <= out_valid$2;
        instruction_fail$2 <= instruction_fail$1;
    end
end

// level 4 : OUTPUT select
assign instruction_fail = instruction_fail$2;
assign out_valid = out_valid$3;
always_comb begin
    if(instruction_fail$2 == 1) begin
        out_1 = 0;
        out_2 = 0;
        out_3 = 0;
        out_4 = 0;
    end
    else begin
    case(output_reg$3[19:15]) // out1
        5'b10001: out_4 = register_file[5];
        5'b10010: out_4 = register_file[4];
        5'b01000: out_4 = register_file[3];
        5'b10111: out_4 = register_file[2];
        5'b11111: out_4 = register_file[1];
        5'b10000: out_4 = register_file[0];
        default:  out_4 = 0;
    endcase
    case(output_reg$3[14:10]) // out2
        5'b10001: out_3 = register_file[5];
        5'b10010: out_3 = register_file[4];
        5'b01000: out_3 = register_file[3];
        5'b10111: out_3 = register_file[2];
        5'b11111: out_3 = register_file[1];
        5'b10000: out_3 = register_file[0];
        default:  out_3 = 0;
    endcase
    case(output_reg$3[9:5]) // out3
        5'b10001: out_2 = register_file[5];
        5'b10010: out_2 = register_file[4];
        5'b01000: out_2 = register_file[3];
        5'b10111: out_2 = register_file[2];
        5'b11111: out_2 = register_file[1];
        5'b10000: out_2 = register_file[0];
        default:  out_2 = 0;
    endcase
    case(output_reg$3[4:0]) // out4
        5'b10001: out_1 = register_file[5];
        5'b10010: out_1 = register_file[4];
        5'b01000: out_1 = register_file[3];
        5'b10111: out_1 = register_file[2];
        5'b11111: out_1 = register_file[1];
        5'b10000: out_1 = register_file[0];
        default:  out_1 = 0;
    endcase
    end
end

endmodule

