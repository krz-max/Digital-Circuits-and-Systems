module Divider(
  // Input signals
	clk,
	rst_n,
    in_valid,
    in_data,
  // Output signals
    out_valid,
	out_data
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid;
input [3:0] in_data;
output logic out_valid, out_data;
 
//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
// output
logic out_data_nxt, out_valid_nxt;
// quotient
logic [10-1:0] quotient_reg, quotient_nxt;
// counter
logic [5-1:0] counter_reg, counter_nxt;
// INPUT
logic [4-1:0] in_data_reg;
// DECODE & SORT
logic [4-1:0] A_nxt, A_reg, B_nxt, B_reg, C_nxt, C_reg, D_nxt, D_reg;
// DIVISION
logic [20-1:0] dividend_reg, dividend_nxt;
logic [4-1:0] divisor_reg, divisor_nxt;
//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 0; // done
parameter INPUT = 1; // done
parameter OUTPUT = 2;

parameter DECODE = 3; // done
parameter SORT = 4; // done

parameter DIVISION_SETUP = 6; // done
parameter DIVISION = 5; // done

logic [3-1:0] state_reg, state_nxt;
//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out_data <= 0;
		state_reg <= IDLE;
		in_data_reg <= 0;
		counter_reg <= 0;
		A_reg <= 0;
		B_reg <= 0;
		C_reg <= 0;
		D_reg <= 0;
	end
	else begin
		out_valid <= out_valid_nxt;
		out_data <= out_data_nxt;
		state_reg <= state_nxt;
		in_data_reg <= in_data;
		counter_reg <= counter_nxt;
		A_reg <= A_nxt;
		B_reg <= B_nxt;
		C_reg <= C_nxt;
		D_reg <= D_nxt;
	end
end
assign quotient_reg = dividend_reg[9:0];
always_comb begin
	if(state_reg == OUTPUT) begin
		out_valid_nxt = 1;
		out_data_nxt = dividend_reg[counter_reg];
	end
	else begin
		out_valid_nxt = 0;
		out_data_nxt = 0;
	end
end
always_comb begin
	case(state_reg)
		IDLE: begin
			counter_nxt = (in_valid) ? 3 : 0;
			state_nxt = (in_valid) ? INPUT : IDLE;
		end
		INPUT: begin // 4 cycle
			counter_nxt = (counter_reg == 0) ? 0 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? DECODE : INPUT;
		end
		DECODE: begin // 1 cycle
			counter_nxt = 3;
			state_nxt = SORT;
		end
		SORT: begin // 4 cycle
			counter_nxt = (counter_reg == 0) ? 0 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? DIVISION_SETUP : SORT;
		end
		DIVISION_SETUP: begin // create dividend and divisor (ACD / B)
			counter_nxt = 9;
			state_nxt = (divisor_nxt == 0) ? OUTPUT : DIVISION;
		end
		DIVISION: begin
			counter_nxt = (divisor_reg == 0 || counter_reg == 0) ? 9 : counter_reg - 1;
			state_nxt = (divisor_reg == 0 || counter_reg == 0) ? OUTPUT : DIVISION;
		end
		OUTPUT: begin
			counter_nxt = (counter_reg == 0) ? 0 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? IDLE : OUTPUT;
		end
		default: begin
			counter_nxt = 0;
			state_nxt = IDLE;
		end
	endcase
end
always_comb begin
	if(state_reg == INPUT) begin
		case(counter_reg)
			3: begin
				A_nxt = in_data_reg;
				B_nxt = B_reg;
				C_nxt = C_reg;
				D_nxt = D_reg;
			end
			2: begin
				A_nxt = A_reg;
				B_nxt = in_data_reg;
				C_nxt = C_reg;
				D_nxt = D_reg;
			end
			1: begin
				A_nxt = A_reg;
				B_nxt = B_reg;
				C_nxt = in_data_reg;
				D_nxt = D_reg;
			end
			0: begin
				A_nxt = A_reg;
				B_nxt = B_reg;
				C_nxt = C_reg;
				D_nxt = in_data_reg;
			end
			default: begin
				A_nxt = A_reg;
				B_nxt = B_reg;
				C_nxt = C_reg;
				D_nxt = D_reg;
			end
		endcase
	end
	else if(state_reg == DECODE) begin
		A_nxt = A_reg - 3;
		B_nxt = B_reg - 3;
		C_nxt = C_reg - 3;
		D_nxt = D_reg - 3;
	end
	else if(state_reg == SORT) begin
		case(counter_reg)
			3, 1: begin
				A_nxt = (A_reg > B_reg) ? A_reg : B_reg;
				B_nxt = (A_reg > B_reg) ? B_reg : A_reg;
				C_nxt = (C_reg > D_reg) ? C_reg : D_reg;
				D_nxt = (C_reg > D_reg) ? D_reg : C_reg;
			end
			2, 0: begin
				A_nxt = A_reg;
				B_nxt = (B_reg > C_reg) ? B_reg : C_reg;
				C_nxt = (B_reg > C_reg) ? C_reg : B_reg;
				D_nxt = D_reg;
			end
			default: begin
				A_nxt = A_reg;
				B_nxt = B_reg;
				C_nxt = C_reg;
				D_nxt = D_reg;
			end
		endcase
	end
	else if(state_reg == IDLE) begin
		A_nxt = 0;
		B_nxt = 0;
		C_nxt = 0;
		D_nxt = 0;
	end
	else begin
		A_nxt = A_reg;
		B_nxt = B_reg;
		C_nxt = C_reg;
		D_nxt = D_reg;
	end
end
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		dividend_reg <= 0;
		divisor_reg <= 0;
	end
	else begin
		dividend_reg <= dividend_nxt;
		divisor_reg <= divisor_nxt;
	end
end
always_comb begin
	if(state_reg == DIVISION_SETUP) begin
		divisor_nxt = B_reg;
	end
	else if(state_reg == IDLE) begin
		divisor_nxt = 0;
	end
	else begin
		divisor_nxt = divisor_reg;
	end
end
always_comb begin
	if(state_reg == DIVISION_SETUP) begin
		dividend_nxt = (divisor_nxt == 0) ? 10'b11_1111_1111 : A_reg * 100 + C_reg * 10 + D_reg;
	end
	else if(state_reg == DIVISION) begin
		dividend_nxt = dividend_reg << 1;
		if(dividend_nxt[19:10] >= divisor_reg) begin
			dividend_nxt[19:10] = dividend_nxt[19:10] - divisor_reg;
			dividend_nxt[0] = 1'b1;
		end
	end
	else if(state_reg == IDLE) begin
		dividend_nxt = 0;
	end
	else begin
		dividend_nxt = dividend_reg;
	end
end
endmodule