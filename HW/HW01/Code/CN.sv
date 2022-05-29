module CN
(
    // Input signals
    opcode,
	in_n0,
	in_n1,
	in_n2,
	in_n3,
	in_n4,
	in_n5,
    // Output signals
    out_n
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input [3:0] in_n0, in_n1, in_n2, in_n3, in_n4, in_n5;
input [4:0] opcode;
output logic [8:0] out_n;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [4:0] ValArray [5:0];
logic [4:0] value0, value1, value2, value3, value4, value5;
//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------

register_file reg0(in_n0, value0);
register_file reg1(in_n1, value1);
register_file reg2(in_n2, value2);
register_file reg3(in_n3, value3);
register_file reg4(in_n4, value4);
register_file reg5(in_n5, value5);

sorting_block sort1(opcode, value0, value1, value2, value3, value4, value5, ValArray);

Calculator calc1(opcode, ValArray, out_n);

endmodule

module Calculator(
    opcode,
    ValArray,
    out_n
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input [4:0] opcode;
input [4:0] ValArray [5:0];
output logic [8:0] out_n;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------
always @(*) begin
    case(opcode[2:0])
        3'b000: out_n = ValArray[2] - ValArray[1];
        3'b001: out_n = ValArray[0] + ValArray[3];
        3'b010: out_n = (ValArray[3]*ValArray[4]) / 2;
        3'b011: out_n = ValArray[1] + (ValArray[5] << 1);
        3'b100: out_n = ValArray[1] & ValArray[2];
        3'b101: out_n = ~ValArray[0];
        3'b110: out_n = ValArray[3] ^ ValArray[4];
        3'b111: out_n = (ValArray[1] << 1);
    endcase
end
endmodule

module sorting_block(
    opcode,
    value0,
    value1,
    value2,
    value3,
    value4,
    value5,
    ValArray
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input [4:0] value0, value1, value2, value3, value4, value5;
input [4:0] opcode;
output logic [4:0] ValArray [5:0];

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [2:0] i,j;
//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------

always @(*) begin
    ValArray = {value5, value4, value3, value2, value1, value0};
    for(i=0; i<6; i=i+1) begin
        if(i % 2 == 1) begin
            for(j=1; j<5; j=j+2) begin
                if(ValArray[j] > ValArray[j+1]) begin
                    ValArray[j] ^= ValArray[j+1];
                    ValArray[j+1] ^= ValArray[j];
                    ValArray[j] ^= ValArray[j+1];
                end
            end
        end
        else begin
            for(j=0; j<5; j=j+2) begin
                if(ValArray[j] > ValArray[j+1]) begin
                    ValArray[j] ^= ValArray[j+1];
                    ValArray[j+1] ^= ValArray[j];
                    ValArray[j] ^= ValArray[j+1];
                end
            end
        end
    end
    case(opcode[4:3])
        2'b11: begin end
        2'b10: begin
            ValArray[0] ^= ValArray[5];
            ValArray[5] ^= ValArray[0];
            ValArray[0] ^= ValArray[5];
            ValArray[1] ^= ValArray[4];
            ValArray[4] ^= ValArray[1];
            ValArray[1] ^= ValArray[4];
            ValArray[2] ^= ValArray[3];
            ValArray[3] ^= ValArray[2];
            ValArray[2] ^= ValArray[3];
        end
        2'b01: ValArray = {value0, value1, value2, value3, value4, value5};
        2'b00: ValArray = {value5, value4, value3, value2, value1, value0};
    endcase
end

endmodule
//---------------------------------------------------------------------
//   Register design from TA (Do not modify, or demo fails)
//---------------------------------------------------------------------
module register_file(
    address,
    value
);
input [3:0] address;
output logic [4:0] value;

always_comb begin
    case(address)
    4'b0000:value = 5'd9;
    4'b0001:value = 5'd27;
    4'b0010:value = 5'd30;
    4'b0011:value = 5'd3;
    4'b0100:value = 5'd11;
    4'b0101:value = 5'd8;
    4'b0110:value = 5'd26;
    4'b0111:value = 5'd17;
    4'b1000:value = 5'd3;
    4'b1001:value = 5'd12;
    4'b1010:value = 5'd1;
    4'b1011:value = 5'd10;
    4'b1100:value = 5'd15;
    4'b1101:value = 5'd5;
    4'b1110:value = 5'd23;
    4'b1111:value = 5'd20;
    default: value = 0;
    endcase
end

endmodule
