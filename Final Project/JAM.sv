module JAM(
  // Input signals
	clk,
	rst_n,
    in_valid,
    in_cost,
  // Output signals
	out_valid,
    out_job,
	out_cost
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid;
input [6:0] in_cost;
output logic out_valid;
output logic [3:0] out_job;
output logic [9:0] out_cost;

//---------------------------------------------------------------------
//   state
//---------------------------------------------------------------------
parameter IDLE = 0; // done
parameter INPUT = 1; // done
parameter MAKE_ZERO_COL = 2; // done
parameter COVER_ZERO_ONE = 3; // first attempt done, need to do SUBTRACT_ADD_MIN
parameter COVER_ZERO_TWO = 4;
parameter COVER_ZERO_THREE = 5;
parameter COVER_ZERO_FOUR = 6;
parameter COVER_ZERO_FIVE = 7;
parameter COVER_ZERO_SIX = 8;
parameter COVER_ZERO_SEVEN = 9;
parameter FIND_OPT_JOB = 10;
parameter OUTPUT_STAGE = 11;
parameter COUNT_ZERO = 12; // done
parameter SUBTRACT_ADD_MIN = 13;
logic [4-1:0] state_reg, state_nxt;
//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [7-1:0] job_cost_reg [8-1:0][8-1:0];
logic [7-1:0] job_cost_nxt [8-1:0][8-1:0];
logic [7-1:0] in_cost_reg;
logic [8-1:0] counter_reg, counter_nxt; 
logic [3-1:0] counter_col, counter_row;
logic [3-1:0] row_min_idx_nxt, row_min_idx_reg;
logic [7-1:0] row_min_val;
logic success;
// MAKE_ZERO_COL
logic [3-1:0] col_min_idx0, col_min_idx1, col_min_idx2, col_min_idx3, col_min_idx4, col_min_idx5, col_min_idx6;
logic [7-1:0] col_min_val;
// COUNT ZERO
logic is_zero0_c, is_zero1_c, is_zero2_c, is_zero3_c, is_zero4_c, is_zero5_c, is_zero6_c, is_zero7_c;
logic is_zero0_r, is_zero1_r, is_zero2_r, is_zero3_r, is_zero4_r, is_zero5_r, is_zero6_r, is_zero7_r;
logic [3-1:0] total_zero_c, total_zero_r;
logic [3-1:0] num_of_zero_col_nxt [8-1:0], num_of_zero_col_reg [8-1:0], num_of_zero_row_nxt [8-1:0], num_of_zero_row_reg [8-1:0];
// COVER ZERO
logic [3-1:0] max_idx_of_zero0_c, max_idx_of_zero1_c, max_idx_of_zero2_c, max_idx_of_zero3_c, max_idx_of_zero4_c, max_idx_of_zero5_c, max_idx_of_zero6_c;
logic [3-1:0] max_idx_of_zero0_r, max_idx_of_zero1_r, max_idx_of_zero2_r, max_idx_of_zero3_r, max_idx_of_zero4_r, max_idx_of_zero5_r, max_idx_of_zero6_r;
logic [4-1:0] draw, draw_line_reg [7-1:0], draw_line_nxt [7-1:0]; // reg stores the position of used line, 7 lines at most(8 lines -> FIND_OPT_JOB)
logic [3-1:0] zero_number_reg_c [8-1:0], zero_number_nxt_c [8-1:0], zero_number_reg_r [8-1:0], zero_number_nxt_r [8-1:0];
logic all_zero_covered_c, all_zero_covered_r;
//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------
// input register
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_cost_reg <= 0;
		state_reg <= IDLE;
		counter_reg <= 0;
		row_min_idx_reg <= 0;
	end
	else begin
		in_cost_reg <= in_cost;
		state_reg <= state_nxt;
		counter_reg <= counter_nxt;
		row_min_idx_reg <= row_min_idx_nxt;
	end
end
// output register
assign out_cost = 0;
assign out_valid = 0;
assign out_job = 0;
/*
assign out_cost_nxt = (state_reg == OUTPUT_STAGE) ? opt_cost_reg : 0;
assign out_job_nxt = (state_reg == OUTPUT_STAGE) ? 8 - opt_job_reg[counter_reg] : 0;
assign out_valid_nxt = (state_reg == OUTPUT_STAGE) ? 1 : 0;
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		out_job <= 0;
		out_cost <= 0;
	end
	else begin
		out_valid <= out_valid_nxt;
		out_job <= out_job_nxt;
		out_cost <= out_cost_nxt;
	end
end
*/
// STATE MACHINE
always_comb begin
	case(state_reg)
		IDLE: begin
			counter_nxt = 0;
			state_nxt = (in_valid) ? INPUT : IDLE;
		end
		INPUT: begin // with MAKE_ZERO_ROW
			counter_nxt = (counter_reg == 63) ? 7 : counter_reg + 1;
			state_nxt = (counter_reg == 63) ? MAKE_ZERO_COL : INPUT;
		end
		MAKE_ZERO_COL: begin
			counter_nxt = (counter_reg == 0) ? 7 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? COUNT_ZERO : MAKE_ZERO_COL;
		end
		COUNT_ZERO: begin
			counter_nxt = (counter_reg == 0) ? 1 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? COVER_ZERO_ONE : COUNT_ZERO;
		end
		COVER_ZERO_ONE: begin // cover all zero with only one line
			counter_nxt = (counter_reg == 0) ? 2 : counter_reg - 1;
			state_nxt = (success) ? SUBTRACT_ADD_MIN : (counter_reg == 0) ? COVER_ZERO_TWO : COVER_ZERO_ONE;
		end
		COVER_ZERO_TWO: begin // cover all zero with two lines
			counter_nxt = (counter_reg == 0) ? 3 : counter_reg - 1;
			state_nxt = (success) ? SUBTRACT_ADD_MIN : (counter_reg == 0) ? COVER_ZERO_THREE : COVER_ZERO_TWO;
		end
		COVER_ZERO_THREE: begin // cover all zero with three lines
			counter_nxt = (counter_reg == 0) ? 4 : counter_reg - 1;
			state_nxt = (success) ? SUBTRACT_ADD_MIN : (counter_reg == 0) ? COVER_ZERO_FOUR : COVER_ZERO_THREE;
		end
		COVER_ZERO_FOUR: begin // cover all zero with four lines
			counter_nxt = (counter_reg == 0) ? 5 : counter_reg - 1;
			state_nxt = (success) ? SUBTRACT_ADD_MIN : (counter_reg == 0) ? COVER_ZERO_FIVE : COVER_ZERO_FOUR;
		end
		COVER_ZERO_FIVE: begin // cover all zero with five lines
			counter_nxt = (counter_reg == 0) ? 6 : counter_reg - 1;
			state_nxt = (success) ? SUBTRACT_ADD_MIN : (counter_reg == 0) ? COVER_ZERO_SIX : COVER_ZERO_FIVE;
		end
		COVER_ZERO_SIX: begin // cover all zero with six lines
			counter_nxt = (counter_reg == 0) ? 7 : counter_reg - 1;
			state_nxt = (success) ? SUBTRACT_ADD_MIN : (counter_reg == 0) ? COVER_ZERO_SEVEN : COVER_ZERO_SIX;
		end
		COVER_ZERO_SEVEN: begin // cover all zero with seven lines
			counter_nxt = (counter_reg == 0) ? 7 : counter_reg - 1; // find opt job in 8 cycles, not sure
			state_nxt = (success) ? SUBTRACT_ADD_MIN : (counter_reg == 0) ? FIND_OPT_JOB : COVER_ZERO_SEVEN;
		end
		// since there is at least one zero in any row or column, when zero_number_reg_c(_r)[idx] == 0, we know that the column(row) is covered
		// when both zero_number != 0 at (i, j), job_cost_reg[i][j] is not covered by lines so that we could find minimal uncovered element.
		SUBTRACT_ADD_MIN: begin // find minimal uncovered element and do addition and subtraction
			// need some inspiration QAQ
			// draw_line_reg stores the line number that we drew, use draw[3] to know the line is vertical(1) or horizontal(0)
			// use draw[2:0] to know the index of the line
		end
		FIND_OPT_JOB: begin // find optimal job(since you can cover all zero with at least 8 lines)
			// not done yet, but I think is not that hard as COVER_LINE is
			counter_nxt = (counter_reg == 0) ? 7 : counter_reg - 1;
			state_nxt = (success) ? OUTPUT_STAGE : FIND_OPT_JOB;
		end
		OUTPUT_STAGE: begin
			counter_nxt = (counter_reg == 0) ? 0 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? IDLE : OUTPUT_STAGE;
		end
		default: begin
			counter_nxt = 0;
			state_nxt = IDLE;
		end
	endcase
end
assign counter_col = counter_reg[2:0];
assign counter_row = counter_reg[5:3];
always_comb begin
	if(state_reg == INPUT) begin
		if(counter_col == 0 || in_cost_reg < job_cost_reg[0][row_min_idx_reg]) begin
			row_min_idx_nxt = 0;
		end
		else begin
			row_min_idx_nxt = row_min_idx_reg + 1;
		end
	end
	else begin
		row_min_idx_nxt = row_min_idx_reg;
	end
end

// INPUT
assign row_min_val = (counter_col == 7) ? (in_cost_reg < job_cost_reg[0][row_min_idx_reg]) ? in_cost_reg : job_cost_reg[0][row_min_idx_reg] : 0;
// MAKE_ZERO_COL
assign col_min_idx0 = (job_cost_reg[7][counter_col] < job_cost_reg[6][counter_col]) ? 7 : 6;
assign col_min_idx1 = (job_cost_reg[col_min_idx0][counter_col] < job_cost_reg[5][counter_col]) ? col_min_idx0 : 5;
assign col_min_idx2 = (job_cost_reg[col_min_idx1][counter_col] < job_cost_reg[4][counter_col]) ? col_min_idx1 : 4;
assign col_min_idx3 = (job_cost_reg[col_min_idx2][counter_col] < job_cost_reg[3][counter_col]) ? col_min_idx2 : 3;
assign col_min_idx4 = (job_cost_reg[col_min_idx3][counter_col] < job_cost_reg[2][counter_col]) ? col_min_idx3 : 2;
assign col_min_idx5 = (job_cost_reg[col_min_idx4][counter_col] < job_cost_reg[1][counter_col]) ? col_min_idx4 : 1;
assign col_min_idx6 = (job_cost_reg[col_min_idx5][counter_col] < job_cost_reg[0][counter_col]) ? col_min_idx5 : 0;
assign col_min_val = job_cost_reg[col_min_idx6][counter_col];
// count zero
// row
assign is_zero7_r = (job_cost_reg[counter_col][7] == 0);
assign is_zero6_r = (job_cost_reg[counter_col][6] == 0);
assign is_zero5_r = (job_cost_reg[counter_col][5] == 0);
assign is_zero4_r = (job_cost_reg[counter_col][4] == 0);
assign is_zero3_r = (job_cost_reg[counter_col][3] == 0);
assign is_zero2_r = (job_cost_reg[counter_col][2] == 0);
assign is_zero1_r = (job_cost_reg[counter_col][1] == 0);
assign is_zero0_r = (job_cost_reg[counter_col][0] == 0);
assign total_zero_r = is_zero7_r + is_zero6_r + is_zero5_r + is_zero4_r + is_zero3_r + is_zero2_r + is_zero1_r + is_zero0_r;
// col
assign is_zero7_c = (job_cost_reg[7][counter_col] == 0);
assign is_zero6_c = (job_cost_reg[6][counter_col] == 0);
assign is_zero5_c = (job_cost_reg[5][counter_col] == 0);
assign is_zero4_c = (job_cost_reg[4][counter_col] == 0);
assign is_zero3_c = (job_cost_reg[3][counter_col] == 0);
assign is_zero2_c = (job_cost_reg[2][counter_col] == 0);
assign is_zero1_c = (job_cost_reg[1][counter_col] == 0);
assign is_zero0_c = (job_cost_reg[0][counter_col] == 0);
assign total_zero_c = is_zero7_c + is_zero6_c + is_zero5_c + is_zero4_c + is_zero3_c + is_zero2_c + is_zero1_c + is_zero0_c;
always_comb begin
	if(state_reg == COUNT_ZERO) begin
		num_of_zero_row_nxt = {num_of_zero_row_reg[6:0], total_zero_r};
		num_of_zero_col_nxt = {num_of_zero_col_reg[6:0], total_zero_c};
	end
	else begin
		num_of_zero_row_nxt = num_of_zero_row_reg;
		num_of_zero_col_nxt = num_of_zero_col_reg;
	end
end
always_comb begin
	if(success) begin
		zero_number_nxt_c = zero_number_reg_c;
		zero_number_nxt_r = zero_number_reg_r;
	end
	else if(counter_reg == 0 && !success) begin // reset to initial
		zero_number_nxt_c = num_of_zero_col_nxt;
		zero_number_nxt_r = num_of_zero_row_nxt;
	end
	else begin
		if(draw[3] == 1) begin
			for(integer i = 7; i >= 0; i = i - 1) begin
				zero_number_nxt_c[i] = (i == draw[2:0]) ? 0 : zero_number_reg_c[i];
				zero_number_nxt_r[i] = (job_cost_reg[i][draw[2:0]] == 0) ? zero_number_reg_r[i] - 1 : zero_number_reg_r[i];
			end
		end
		else begin
			for(integer i = 7; i >= 0; i = i - 1) begin
				zero_number_nxt_c[i] = (job_cost_reg[draw[2:0]][i] == 0) ? zero_number_reg_c[i] - 1 : zero_number_reg_c[i];
				zero_number_nxt_r[i] = (i == draw[2:0]) ? 0 : zero_number_reg_r[i];
			end
		end
	end
end
assign all_zero_covered_r = zero_number_reg_r[7] == 0 && zero_number_reg_r[6] == 0 && zero_number_reg_r[5] == 0 && zero_number_reg_r[4] == 0 && zero_number_reg_r[3] == 0 && zero_number_reg_r[2] == 0 && zero_number_reg_r[1] == 0 && zero_number_reg_r[0] == 0;
assign all_zero_covered_c = zero_number_reg_c[7] == 0 && zero_number_reg_c[6] == 0 && zero_number_reg_c[5] == 0 && zero_number_reg_c[4] == 0 && zero_number_reg_c[3] == 0 && zero_number_reg_c[2] == 0 && zero_number_reg_c[1] == 0 && zero_number_reg_c[0] == 0;
always_comb begin
	case(state_reg)
		COVER_ZERO_ONE, COVER_ZERO_TWO, COVER_ZERO_THREE, COVER_ZERO_FOUR, COVER_ZERO_FIVE, COVER_ZERO_SIX, COVER_ZERO_SEVEN : begin
			success = ( (counter_reg == 0) && (all_zero_covered_c) && (all_zero_covered_r) ) ? 1 : 0; 
		end
		default: begin
			success = 1'b0;
		end
	endcase
end
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		num_of_zero_row_reg <= {8{0}};
		num_of_zero_col_reg <= {8{0}};
		zero_number_reg_c <= {8{0}};
		zero_number_reg_r <= {8{0}};
		draw_line_reg <= {7{0}};
	end
	else begin
		num_of_zero_row_reg <= num_of_zero_row_nxt;
		num_of_zero_col_reg <= num_of_zero_col_nxt;
		zero_number_reg_c <= zero_number_nxt_c;
		zero_number_reg_r <= zero_number_nxt_r;
		draw_line_reg <= draw_line_nxt;
	end
end
// COVER_ZERO_ONE
// 3 bits
assign max_idx_of_zero0_r = (zero_number_reg_r[7] > zero_number_reg_r[6]) ? 7 : 6;
assign max_idx_of_zero1_r = (zero_number_reg_r[max_idx_of_zero0_r] > zero_number_reg_r[5]) ? max_idx_of_zero0_r : 5;
assign max_idx_of_zero2_r = (zero_number_reg_r[max_idx_of_zero1_r] > zero_number_reg_r[4]) ? max_idx_of_zero1_r : 4;
assign max_idx_of_zero3_r = (zero_number_reg_r[max_idx_of_zero2_r] > zero_number_reg_r[3]) ? max_idx_of_zero2_r : 3;
assign max_idx_of_zero4_r = (zero_number_reg_r[max_idx_of_zero3_r] > zero_number_reg_r[2]) ? max_idx_of_zero3_r : 2;
assign max_idx_of_zero5_r = (zero_number_reg_r[max_idx_of_zero4_r] > zero_number_reg_r[1]) ? max_idx_of_zero4_r : 1;
assign max_idx_of_zero6_r = (zero_number_reg_r[max_idx_of_zero5_r] > zero_number_reg_r[0]) ? max_idx_of_zero5_r : 0;
assign max_idx_of_zero0_c = (zero_number_reg_c[7] > zero_number_reg_c[6]) ? 7 : 6;
assign max_idx_of_zero1_c = (zero_number_reg_c[max_idx_of_zero0_c] > zero_number_reg_c[5]) ? max_idx_of_zero0_c : 5;
assign max_idx_of_zero2_c = (zero_number_reg_c[max_idx_of_zero1_c] > zero_number_reg_c[4]) ? max_idx_of_zero1_c : 4;
assign max_idx_of_zero3_c = (zero_number_reg_c[max_idx_of_zero2_c] > zero_number_reg_c[3]) ? max_idx_of_zero2_c : 3;
assign max_idx_of_zero4_c = (zero_number_reg_c[max_idx_of_zero3_c] > zero_number_reg_c[2]) ? max_idx_of_zero3_c : 2;
assign max_idx_of_zero5_c = (zero_number_reg_c[max_idx_of_zero4_c] > zero_number_reg_c[1]) ? max_idx_of_zero4_c : 1;
assign max_idx_of_zero6_c = (zero_number_reg_c[max_idx_of_zero5_c] > zero_number_reg_c[0]) ? max_idx_of_zero5_c : 0;

//{1/0, 3'didx} (1 for col, 0 for row)
assign draw[3] = (zero_number_reg_c[max_idx_of_zero6_c] > zero_number_reg_r[max_idx_of_zero6_r]) ? 1'b1 : 1'b0;
assign draw[2:0] = (zero_number_reg_c[max_idx_of_zero6_c] > zero_number_reg_r[max_idx_of_zero6_r]) ? max_idx_of_zero6_c : max_idx_of_zero6_r;
always_comb begin
	case(state_reg)
		COVER_ZERO_ONE, COVER_ZERO_TWO, COVER_ZERO_THREE, COVER_ZERO_FOUR, COVER_ZERO_FIVE, COVER_ZERO_SIX, COVER_ZERO_SEVEN: begin
			draw_line_nxt = (counter_reg == 0) ? (success == 1) ? draw_line_reg : {7{0}} : {draw_line_reg[5:0], draw};
		end
		default: begin
			draw_line_nxt = draw_line_reg;
		end
	endcase
end


// INPUT STATE
always_comb begin
	if(state_reg == INPUT) begin //shift register for 2d array
		for(integer i = 7; i > 0; i = i - 1) job_cost_nxt[7][i] = job_cost_reg[7][i-1];
		job_cost_nxt[7][0] = job_cost_reg[6][7];
		for(integer i = 7; i > 0; i = i - 1) job_cost_nxt[6][i] = job_cost_reg[6][i-1];
		job_cost_nxt[6][0] = job_cost_reg[5][7];
		for(integer i = 7; i > 0; i = i - 1) job_cost_nxt[5][i] = job_cost_reg[5][i-1];
		job_cost_nxt[5][0] = job_cost_reg[4][7];
		for(integer i = 7; i > 0; i = i - 1) job_cost_nxt[4][i] = job_cost_reg[4][i-1];
		job_cost_nxt[4][0] = job_cost_reg[3][7];
		for(integer i = 7; i > 0; i = i - 1) job_cost_nxt[3][i] = job_cost_reg[3][i-1];
		job_cost_nxt[3][0] = job_cost_reg[2][7];
		for(integer i = 7; i > 0; i = i - 1) job_cost_nxt[2][i] = job_cost_reg[2][i-1];
		job_cost_nxt[2][0] = job_cost_reg[1][7];
		for(integer i = 7; i > 0; i = i - 1) job_cost_nxt[1][i] = job_cost_reg[1][i-1];
		job_cost_nxt[1][0] = job_cost_reg[0][7];
		for(integer i = 7; i > 0; i = i - 1) job_cost_nxt[0][i] = job_cost_reg[0][i-1] - row_min_val;
		job_cost_nxt[0][0] = in_cost_reg - row_min_val;
	end
	else if(state_reg == MAKE_ZERO_COL) begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			for(integer j = 7; j >= 0; j = j - 1) begin
				job_cost_nxt[i][j] = (j == counter_col) ? job_cost_reg[i][j] - col_min_val : job_cost_reg[i][j];
			end
		end
	end
	else begin
		job_cost_nxt = job_cost_reg;
	end
end
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(integer i = 0; i < 8; i = i + 1) begin
			for(integer j = 0; j < 8; j = j + 1) begin
				job_cost_reg[i][j] <= 0;
			end
		end
	end
	else begin
		job_cost_reg <= job_cost_nxt;
	end
end


endmodule