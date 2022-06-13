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
// 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 8 (used_line == 8) ? 9 : (covered) ? 
parameter IDLE = 0; // done
parameter INPUT = 1; // done
parameter OUTPUT = 2;

parameter MAKE_ZERO_COL = 3; // done
parameter MAKE_ZERO_ROW = 4; // done
parameter COUNT_ZERO = 5; // done

parameter ASSIGN_ROW_TASK = 6; // done
parameter ASSIGN_COL_TASK = 7; // done
parameter MAKE_HOR_CHECK = 8;
parameter MAKE_VER_CHECK = 9;
parameter REPEAT_CHECK_RESET = 10;

parameter FIND_UNCOVERED_MIN = 11;
parameter SUBTRACT_ADD_MIN = 12;

parameter ASSIGN_JOB_AND_CALC_COST = 13;
parameter ARB_ASSIGN = 14;
parameter DFS = 15;
logic [4-1:0] state_reg, state_nxt;
//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
// INPUT
logic hit;
logic [8-1:0] row_stat_nxt[8-1:0], row_stat_reg[8-1:0];
logic [3-1:0] counter_col, counter_row;
logic [8-1:0] job_cost_reg [8-1:0][8-1:0];
logic [8-1:0] job_cost_nxt [8-1:0][8-1:0];
logic [7-1:0] input_nxt[8-1:0][8-1:0], input_reg[8-1:0][8-1:0];
logic is_zero_ij [8-1:0][8-1:0]; // check if job_cost_reg[i][j] is zero
logic [7-1:0] in_cost_reg;
logic [6-1:0] counter_reg, counter_nxt; 
// MAKE_ZERO_ROW, MAKE_ZERO_COL
logic [7-1:0] MIN_VAL_nxt [8-1:0], MIN_VAL_reg [8-1:0];
// COUNT ZERO
logic [4-1:0] total_zero_c [8-1:0], total_zero_r [8-1:0];
logic [4-1:0] col_zero_count_nxt [8-1:0], col_zero_count_reg [8-1:0], row_zero_count_nxt [8-1:0], row_zero_count_reg [8-1:0];
// ASSIGN_ROW_TASK
// ASSIGN_COL_TASK
logic arbitrary_assign;
logic [8-1:0] marked_zero_nxt[8-1:0], marked_zero_reg[8-1:0];
// MAKE_CHECK
logic [8-1:0] vertical_check_nxt, horizontal_check_nxt, vertical_check_reg, horizontal_check_reg;
logic repeat_check_nxt, repeat_check_reg;
// FIND_UNCOVERED_MIN
logic [7-1:0] UNCOVERED_MIN_VAL_nxt, UNCOVERED_MIN_VAL_reg;
// SUBTRACT_ADD_MIN
// ASSIGN_JOB_AND_CALC_COST
logic [3-1:0] opt_job_reg [8-1:0], opt_job_nxt [8-1:0];
logic uncovered;
logic check_srcA[8-1:0], check_srcB[8-1:0];
logic one_zero_row_found;
// store ANS for output
// FOJ
// OUTPUT
logic [10-1:0] cost_nxt, cost_reg;
logic out_valid_nxt;
logic [4-1:0] out_job_nxt;
logic [10-1:0] out_cost_nxt;
// test
logic can_assign;
logic [5-1:0] total_line;
logic [4-1:0] vertical_line, horizontal_line;
//---------------------------------------------------------------------
//   Your design                        
//---------------------------------------------------------------------
assign one_zero_row_found = marked_zero_nxt != marked_zero_reg;
assign arbitrary_assign = row_zero_count_nxt[7] != 0
					   || row_zero_count_nxt[6] != 0
					   || row_zero_count_nxt[5] != 0
					   || row_zero_count_nxt[4] != 0
					   || row_zero_count_nxt[3] != 0
					   || row_zero_count_nxt[2] != 0
					   || row_zero_count_nxt[1] != 0
					   || row_zero_count_nxt[0] != 0;
always_comb begin
	for(integer i = 7; i >= 0; i = i - 1) begin
		for(integer j = 7; j >= 0; j = j - 1) begin
			is_zero_ij[i][j] = job_cost_reg[i][j] == 0;
		end
	end
end
// input register
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_cost_reg <= 0;
		state_reg <= IDLE;
		counter_reg <= 0;
	end
	else begin
		in_cost_reg <= in_cost;
		state_reg <= state_nxt;
		counter_reg <= counter_nxt;
	end
end
// output register
assign out_valid_nxt = (state_reg == OUTPUT) ? 1 : 0;
assign out_job_nxt = (state_reg == OUTPUT) ? 8 - opt_job_reg[counter_reg[2:0]] : 0;
assign out_cost_nxt = (state_reg == OUTPUT) ? cost_reg : 0;
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
        cost_reg <= cost_nxt;
	end
end
assign total_line = (state_reg == FIND_UNCOVERED_MIN) ? horizontal_line + vertical_line : 0;
assign vertical_line = vertical_check_reg[7] + vertical_check_reg[6] + vertical_check_reg[5] + vertical_check_reg[4] 
				  + vertical_check_reg[3] + vertical_check_reg[2] + vertical_check_reg[1] + vertical_check_reg[0];
assign horizontal_line = !horizontal_check_reg[7] + !horizontal_check_reg[6] + !horizontal_check_reg[5] + !horizontal_check_reg[4] 
				  + !horizontal_check_reg[3] + !horizontal_check_reg[2] + !horizontal_check_reg[1] + !horizontal_check_reg[0];
always_comb begin
	can_assign =( (marked_zero_reg[7] != 0 
				&& marked_zero_reg[6] != 0 
				&& marked_zero_reg[5] != 0 
				&& marked_zero_reg[4] != 0 
				&& marked_zero_reg[3] != 0 
				&& marked_zero_reg[2] != 0 
				&& marked_zero_reg[1] != 0 
				&& marked_zero_reg[0] != 0) 
				|| total_line == 8 );
end
// STATE MACHINE
always_comb begin
	case(state_reg)
		IDLE: begin
			counter_nxt = 63;
			state_nxt = (in_valid) ? INPUT : IDLE;
		end
		INPUT: begin // with MAKE_ZERO_ROW
			counter_nxt = (counter_reg == 0) ? 15 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? MAKE_ZERO_ROW : INPUT;
		end
		MAKE_ZERO_COL: begin
			counter_nxt = (counter_reg == 0) ? 0 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? COUNT_ZERO : MAKE_ZERO_COL;
		end
		MAKE_ZERO_ROW: begin
			counter_nxt = (counter_reg == 0) ? 15 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? MAKE_ZERO_COL : MAKE_ZERO_ROW;
		end
		COUNT_ZERO: begin
			counter_nxt = (counter_reg == 0) ? 7 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? ASSIGN_ROW_TASK : COUNT_ZERO;
		end
		ASSIGN_ROW_TASK: begin
			counter_nxt = (counter_reg == 0) ? 7 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? ASSIGN_COL_TASK : ASSIGN_ROW_TASK;
		end
		ASSIGN_COL_TASK: begin
			counter_nxt = (counter_reg == 0) ? (arbitrary_assign) ? 7 : 0 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? (arbitrary_assign) ? ARB_ASSIGN : MAKE_VER_CHECK : ASSIGN_COL_TASK;
		end
		MAKE_HOR_CHECK: begin
			counter_nxt = 0;
			state_nxt = MAKE_VER_CHECK;
		end
		MAKE_VER_CHECK: begin
			counter_nxt = (repeat_check_nxt) ? 6'bx : 15;
			state_nxt = (repeat_check_nxt) ? REPEAT_CHECK_RESET : FIND_UNCOVERED_MIN;
		end
		REPEAT_CHECK_RESET: begin
			counter_nxt = 0;
			state_nxt = MAKE_HOR_CHECK;
		end
		FIND_UNCOVERED_MIN: begin
			counter_nxt = (can_assign) ? 7 : (counter_reg == 0) ? 6'bx : counter_reg - 1;
			state_nxt = (can_assign) ? DFS : (counter_reg == 0) ? SUBTRACT_ADD_MIN : FIND_UNCOVERED_MIN;
		end
		SUBTRACT_ADD_MIN: begin
			counter_nxt = 0;
			state_nxt = COUNT_ZERO;
		end
		ARB_ASSIGN: begin
			counter_nxt = (one_zero_row_found || counter_reg == 0) ? 7 : counter_reg - 1;
			state_nxt = (one_zero_row_found || counter_reg == 0) ? ASSIGN_ROW_TASK : ARB_ASSIGN;
		end
		DFS: begin
			counter_nxt = (hit) ? (counter_reg == 0) ? 7 : counter_reg - 1 : counter_reg + 1;
			state_nxt = (counter_reg == 0 && hit) ? ASSIGN_JOB_AND_CALC_COST : DFS;
		end
		ASSIGN_JOB_AND_CALC_COST: begin
			counter_nxt = (counter_reg == 0) ? 7 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? OUTPUT : ASSIGN_JOB_AND_CALC_COST;
		end
		OUTPUT: begin
			counter_nxt = (counter_reg == 0) ? 63 : counter_reg - 1;
			state_nxt = (counter_reg == 0) ? IDLE : OUTPUT;
		end
		default: begin
			counter_nxt = 6'bx;
			state_nxt = 4'bx;
		end
	endcase
end
// ASSIGN_JOB_AND_CALC_COST
// logic [3-1:0] opt_job_reg [8-1:0], opt_job_nxt [8-1:0];
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
	end
	else begin
		opt_job_reg <= opt_job_nxt;
	end
end
always_comb begin
	if(state_reg == ASSIGN_JOB_AND_CALC_COST) begin
		case(1'b1)
			marked_zero_reg[counter_reg[2:0]][7]: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = (i == counter_reg[2:0]) ? 7 : opt_job_reg[i];
				end
				cost_nxt = cost_reg + input_reg[counter_reg[2:0]][7];
			end
			marked_zero_reg[counter_reg[2:0]][6]: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = (i == counter_reg[2:0]) ? 6 : opt_job_reg[i];
				end
				cost_nxt = cost_reg + input_reg[counter_reg[2:0]][6];
			end
			marked_zero_reg[counter_reg[2:0]][5]: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = (i == counter_reg[2:0]) ? 5 : opt_job_reg[i];
				end
				cost_nxt = cost_reg + input_reg[counter_reg[2:0]][5];
			end
			marked_zero_reg[counter_reg[2:0]][4]: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = (i == counter_reg[2:0]) ? 4 : opt_job_reg[i];
				end
				cost_nxt = cost_reg + input_reg[counter_reg[2:0]][4];
			end
			marked_zero_reg[counter_reg[2:0]][3]: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = (i == counter_reg[2:0]) ? 3 : opt_job_reg[i];
				end
				cost_nxt = cost_reg + input_reg[counter_reg[2:0]][3];
			end
			marked_zero_reg[counter_reg[2:0]][2]: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = (i == counter_reg[2:0]) ? 2 : opt_job_reg[i];
				end
				cost_nxt = cost_reg + input_reg[counter_reg[2:0]][2];
			end
            marked_zero_reg[counter_reg[2:0]][1]: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = (i == counter_reg[2:0]) ? 1 : opt_job_reg[i];
				end
				cost_nxt = cost_reg + input_reg[counter_reg[2:0]][1];
			end
			marked_zero_reg[counter_reg[2:0]][0]: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = (i == counter_reg[2:0]) ? 0 : opt_job_reg[i];
				end
				cost_nxt = cost_reg + input_reg[counter_reg[2:0]][0];
			end
			default: begin
				for(integer i=7; i>=0; i=i-1) begin
					opt_job_nxt[i] = opt_job_reg[i];
				end
				cost_nxt = cost_reg;
			end
		endcase
	end
	else if(state_reg == OUTPUT) begin
		for(integer i=7; i>=0; i=i-1) begin
			opt_job_nxt[i] = opt_job_reg[i];
		end
		cost_nxt = cost_reg;
	end
	else begin
		for(integer i=7; i>=0; i=i-1) begin
			opt_job_nxt[i] = 0;
		end
		cost_nxt = 0;
	end
end
// SUBTRACT_ADD_MIN
// FIND_UNCOVERED_MIN
// logic [9-1:0] UNCOVERED_MIN_VAL_nxt, UNCOVERED_MIN_VAL_reg;
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
	end
	else begin
		UNCOVERED_MIN_VAL_reg <= UNCOVERED_MIN_VAL_nxt;
	end
end
assign uncovered = (vertical_check_reg[counter_reg[2:0]] == 0) && (horizontal_check_reg[counter_reg[5:3]] == 1);
assign counter_col = counter_reg[2:0];
assign counter_row = counter_reg[5:3];
always_comb begin
	if(state_reg == IDLE || state_reg == SUBTRACT_ADD_MIN) begin
		UNCOVERED_MIN_VAL_nxt = 7'b1111_111;
	end
	else if(state_reg == FIND_UNCOVERED_MIN) begin
		if(horizontal_check_reg[counter_reg[2:0]] == 1 && MIN_VAL_reg[counter_reg[2:0]] < UNCOVERED_MIN_VAL_reg) begin
			UNCOVERED_MIN_VAL_nxt = MIN_VAL_reg[counter_reg[2:0]];
		end
		else begin
			UNCOVERED_MIN_VAL_nxt = UNCOVERED_MIN_VAL_reg;
		end
	end
	else begin
		UNCOVERED_MIN_VAL_nxt = UNCOVERED_MIN_VAL_reg;
	end
end
// MAKE_CHECK
// logic [8-1:0] vertical_check_nxt, horizontal_check_nxt, vertical_check_reg, horizontal_check_reg;
// logic repeat_check_nxt, repeat_check_reg;
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        repeat_check_reg <= 0;
	end
	else begin
		vertical_check_reg <= vertical_check_nxt;
		horizontal_check_reg <= horizontal_check_nxt;
		repeat_check_reg <= repeat_check_nxt;
	end
end
always_comb begin
	if(state_reg == MAKE_VER_CHECK) begin
		for(integer i=7; i>=0; i=i-1) begin
			check_srcA[i] = vertical_check_nxt[i];
			check_srcB[i] = vertical_check_reg[i];
		end
	end
	else if(state_reg == MAKE_HOR_CHECK) begin
		for(integer i=7; i>=0; i=i-1) begin
			check_srcA[i] = horizontal_check_nxt[i];
			check_srcB[i] = horizontal_check_reg[i];
		end
	end
	else begin
		for(integer i=7; i>=0; i=i-1) begin
			check_srcA[i] = 3'bx;
			check_srcB[i] = 3'bx;
		end
	end
end
always_comb begin
	if(state_reg == MAKE_VER_CHECK || state_reg == MAKE_HOR_CHECK) begin
		repeat_check_nxt = check_srcA[7] != check_srcB[7]
						|| check_srcA[6] != check_srcB[6]
						|| check_srcA[5] != check_srcB[5]
						|| check_srcA[4] != check_srcB[4]
						|| check_srcA[3] != check_srcB[3]
						|| check_srcA[2] != check_srcB[2]
						|| check_srcA[1] != check_srcB[1]
						|| check_srcA[0] != check_srcB[0]
						|| repeat_check_reg;
	end
	else if(state_reg == ASSIGN_COL_TASK || state_reg == REPEAT_CHECK_RESET) begin
		repeat_check_nxt = 0;
	end
	else begin
		repeat_check_nxt = 1'bx;
	end
end

// ASSIGN_ROW_TASK
// ASSIGN_COL_TASK
// logic assign_task_done;
// FROM COUNT ZERO
// logic [3-1:0] total_zero_c, total_zero_r;
// logic [3-1:0] col_zero_count_nxt [8-1:0], col_zero_count_reg [8-1:0], row_zero_count_nxt [8-1:0], row_zero_count_reg [8-1:0];
// logic marked_zero_nxt [8-1:0][8-1:0], marked_zero_reg [8-1:0][8-1:0];

always_comb begin
	if(state_reg == COUNT_ZERO) begin
		row_zero_count_nxt = {total_zero_r[7], total_zero_r[6], total_zero_r[5], total_zero_r[4], total_zero_r[3], total_zero_r[2], total_zero_r[1], total_zero_r[0]};
		col_zero_count_nxt = {total_zero_c[7], total_zero_c[6], total_zero_c[5], total_zero_c[4], total_zero_c[3], total_zero_c[2], total_zero_c[1], total_zero_c[0]};
	end
	else if(state_reg == ASSIGN_ROW_TASK) begin
		if(row_zero_count_reg[counter_reg[2:0]] == 1) begin // the row has only one zero and can be assigned
			if(col_zero_count_reg[7] != 0 && is_zero_ij[counter_reg[2:0]][7]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][7] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 7) ? 0 : col_zero_count_reg[i];
				end
			end
			else if(col_zero_count_reg[6] != 0 && is_zero_ij[counter_reg[2:0]][6]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][6] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 6) ? 0 : col_zero_count_reg[i];
				end
			end
			else if(col_zero_count_reg[5] != 0 && is_zero_ij[counter_reg[2:0]][5]) begin	
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][5] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 5) ? 0 : col_zero_count_reg[i];
				end
			end
			else if(col_zero_count_reg[4] != 0 && is_zero_ij[counter_reg[2:0]][4]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][4] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 4) ? 0 : col_zero_count_reg[i];
				end
			end
			else if(col_zero_count_reg[3] != 0 && is_zero_ij[counter_reg[2:0]][3]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][3] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 3) ? 0 : col_zero_count_reg[i];
				end
			end
			else if(col_zero_count_reg[2] != 0 && is_zero_ij[counter_reg[2:0]][2]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][2] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 2) ? 0 : col_zero_count_reg[i];
				end
			end
			else if(col_zero_count_reg[1] != 0 && is_zero_ij[counter_reg[2:0]][1]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][1] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 1) ? 0 : col_zero_count_reg[i];
				end
			end
			else if(col_zero_count_reg[0] != 0 && is_zero_ij[counter_reg[2:0]][0]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][0] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 0) ? 0 : col_zero_count_reg[i];
				end
			end
			else begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = row_zero_count_reg[i];
					col_zero_count_nxt[i] = col_zero_count_reg[i];
				end
			end
		end
		else begin
			for(integer i=7; i>=0; i=i-1) begin
				row_zero_count_nxt[i] = row_zero_count_reg[i];
				col_zero_count_nxt[i] = col_zero_count_reg[i];
			end
		end
	end
	else if(state_reg == ASSIGN_COL_TASK) begin
		if(col_zero_count_reg[counter_reg[2:0]] == 1) begin // the col has only one zero
			if(row_zero_count_reg[7] != 0 && is_zero_ij[7][counter_reg[2:0]]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == 7) ? 0 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[7][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(row_zero_count_reg[6] != 0 && is_zero_ij[6][counter_reg[2:0]]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == 6) ? 0 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[6][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(row_zero_count_reg[5] != 0 && is_zero_ij[5][counter_reg[2:0]]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == 5) ? 0 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[5][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(row_zero_count_reg[4] != 0 && is_zero_ij[4][counter_reg[2:0]]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == 4) ? 0 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[4][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(row_zero_count_reg[3] != 0 && is_zero_ij[3][counter_reg[2:0]]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == 3) ? 0 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[3][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(row_zero_count_reg[2] != 0 && is_zero_ij[2][counter_reg[2:0]]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == 2) ? 0 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[2][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(row_zero_count_reg[1] != 0 && is_zero_ij[1][counter_reg[2:0]]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == 1) ? 0 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[1][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(row_zero_count_reg[0] != 0 && is_zero_ij[0][counter_reg[2:0]]) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == 0) ? 0 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[0][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = row_zero_count_reg[i];
					col_zero_count_nxt[i] = col_zero_count_reg[i];
				end
			end
		end
		else begin
			for(integer i=7; i>=0; i=i-1) begin
				row_zero_count_nxt[i] = row_zero_count_reg[i];
				col_zero_count_nxt[i] = col_zero_count_reg[i];
			end
		end
	end
	else if(state_reg == ARB_ASSIGN) begin
   		if(row_zero_count_reg[counter_reg[2:0]] != 0) begin
			if(marked_zero_nxt[counter_reg[2:0]][7] == 1) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][7] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 7) ? 0 : (is_zero_ij[counter_reg[2:0]][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(marked_zero_nxt[counter_reg[2:0]][6] == 1) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][6] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 6) ? 0 : (is_zero_ij[counter_reg[2:0]][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(marked_zero_nxt[counter_reg[2:0]][5] == 1) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][5] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 5) ? 0 : (is_zero_ij[counter_reg[2:0]][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(marked_zero_nxt[counter_reg[2:0]][4] == 1) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][4] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 4) ? 0 : (is_zero_ij[counter_reg[2:0]][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(marked_zero_nxt[counter_reg[2:0]][3] == 1) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][3] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 3) ? 0 : (is_zero_ij[counter_reg[2:0]][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(marked_zero_nxt[counter_reg[2:0]][2] == 1) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][2] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 2) ? 0 : (is_zero_ij[counter_reg[2:0]][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(marked_zero_nxt[counter_reg[2:0]][1] == 1) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][1] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 1) ? 0 : (is_zero_ij[counter_reg[2:0]][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else if(marked_zero_nxt[counter_reg[2:0]][0] == 1) begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = (i == counter_reg[2:0]) ? 0 : (is_zero_ij[i][0] && row_zero_count_reg[i] != 0) ? row_zero_count_reg[i] - 1 : row_zero_count_reg[i];
					col_zero_count_nxt[i] = (i == 0) ? 0 : (is_zero_ij[counter_reg[2:0]][i] && col_zero_count_reg[i] != 0) ? col_zero_count_reg[i] - 1 : col_zero_count_reg[i];
				end
			end
			else begin
				for(integer i=7; i>=0; i=i-1) begin
					row_zero_count_nxt[i] = row_zero_count_reg[i];
					col_zero_count_nxt[i] = col_zero_count_reg[i];
				end
			end
		end
		else begin
			for(integer i=7; i>=0; i=i-1) begin
				row_zero_count_nxt[i] = row_zero_count_reg[i];
				col_zero_count_nxt[i] = col_zero_count_reg[i];
			end
		end
	end
	else begin
		row_zero_count_nxt = row_zero_count_reg;
		col_zero_count_nxt = col_zero_count_reg;
	end
end
// ARB_ASSIGN
always_comb begin
	if(state_reg == MAKE_VER_CHECK) begin
		for(integer i=7; i>=0; i=i-1) begin
			vertical_check_nxt[i] = (horizontal_check_reg[7] && is_zero_ij[7][i])
								 || (horizontal_check_reg[6] && is_zero_ij[6][i])
								 || (horizontal_check_reg[5] && is_zero_ij[5][i])
								 || (horizontal_check_reg[4] && is_zero_ij[4][i])
								 || (horizontal_check_reg[3] && is_zero_ij[3][i])
								 || (horizontal_check_reg[2] && is_zero_ij[2][i])
								 || (horizontal_check_reg[1] && is_zero_ij[1][i])
								 || (horizontal_check_reg[0] && is_zero_ij[0][i]);
		end
	end
    else if(state_reg == REPEAT_CHECK_RESET) begin
        vertical_check_nxt = (can_assign) ? 0 : vertical_check_reg;
    end
	else if(state_reg == DFS) begin
		if(hit) begin
			vertical_check_nxt = vertical_check_reg - marked_zero_reg[counter_col];
			if(marked_zero_nxt[counter_col][7]) begin
				vertical_check_nxt[7] = 1;
			end
			else if(marked_zero_nxt[counter_col][6]) begin
				vertical_check_nxt[6] = 1;
			end
			else if(marked_zero_nxt[counter_col][5]) begin
				vertical_check_nxt[5] = 1;
			end
			else if(marked_zero_nxt[counter_col][4]) begin
				vertical_check_nxt[4] = 1;
			end
			else if(marked_zero_nxt[counter_col][3]) begin
				vertical_check_nxt[3] = 1;
			end
			else if(marked_zero_nxt[counter_col][2]) begin
				vertical_check_nxt[2] = 1;
			end
			else if(marked_zero_nxt[counter_col][1]) begin
				vertical_check_nxt[1] = 1;
			end
			else if(marked_zero_nxt[counter_col][0]) begin
				vertical_check_nxt[0] = 1;
			end
		end
		else begin
			for(integer i = 7; i >= 0; i = i - 1) begin
				vertical_check_nxt[i] = (marked_zero_reg[counter_col][i]) ? 0 : vertical_check_reg[i];
			end
		end
	end
	else if(state_reg == FIND_UNCOVERED_MIN) begin
		vertical_check_nxt = (can_assign) ? 0 : vertical_check_reg;
	end
	else if(state_reg == IDLE || state_reg == SUBTRACT_ADD_MIN) begin
		vertical_check_nxt = 0;
	end
	else begin
		vertical_check_nxt = vertical_check_reg;
	end
end
always_comb begin
	if(state_reg == ASSIGN_COL_TASK || state_reg == ASSIGN_ROW_TASK || state_reg == ARB_ASSIGN) begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			horizontal_check_nxt[i] = (marked_zero_nxt[i] == 0) ? 1 : 0;
		end
	end
	else if(state_reg == MAKE_HOR_CHECK) begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			horizontal_check_nxt[i] =   (vertical_check_reg[7] && marked_zero_reg[i][7])
									 || (vertical_check_reg[6] && marked_zero_reg[i][6])
									 || (vertical_check_reg[5] && marked_zero_reg[i][5])
									 || (vertical_check_reg[4] && marked_zero_reg[i][4])
									 || (vertical_check_reg[3] && marked_zero_reg[i][3])
									 || (vertical_check_reg[2] && marked_zero_reg[i][2])
									 || (vertical_check_reg[1] && marked_zero_reg[i][1])
									 || (vertical_check_reg[0] && marked_zero_reg[i][0])
									 || horizontal_check_reg[i];
		end
	end
    else if(state_reg == REPEAT_CHECK_RESET) begin
        horizontal_check_nxt = horizontal_check_reg;
    end
	else if(state_reg == DFS) begin
		if(hit) begin
			for(integer i = 7; i >= 0; i = i - 1) begin
				horizontal_check_nxt[i] = (i == counter_reg[2:0]) ? 1 : horizontal_check_reg[i];
			end
		end
		else begin
			for(integer i=7; i>= 0; i=i-1) begin
				horizontal_check_nxt[i] = (i == counter_reg[2:0]) ? 0 : horizontal_check_reg[i];
			end
		end
	end
	else if(state_reg == FIND_UNCOVERED_MIN) begin
		horizontal_check_nxt = (can_assign) ? 0 : horizontal_check_reg;
	end
	else if(state_reg == IDLE || state_reg == SUBTRACT_ADD_MIN) begin
		horizontal_check_nxt = 0;
	end
	else begin
		horizontal_check_nxt = horizontal_check_reg;
	end
end
always_comb begin
	if(state_reg == DFS) begin
		for(integer i=7; i>=0; i=i-1) begin
			if(horizontal_check_reg[i]) begin
				if(marked_zero_nxt[i][7]) begin
					row_stat_nxt[i] = 8'b1000_0000;
				end
				else if(marked_zero_nxt[i][6]) begin
					row_stat_nxt[i] = 8'b1100_0000;
				end
				else if(marked_zero_nxt[i][5]) begin
					row_stat_nxt[i] = 8'b1110_0000;
				end
				else if(marked_zero_nxt[i][4]) begin
					row_stat_nxt[i] = 8'b1111_0000;
				end
				else if(marked_zero_nxt[i][3]) begin
					row_stat_nxt[i] = 8'b1111_1000;
				end
				else if(marked_zero_nxt[i][2]) begin
					row_stat_nxt[i] = 8'b1111_1100;
				end
				else if(marked_zero_nxt[i][1]) begin
					row_stat_nxt[i] = 8'b1111_1110;
				end
				else if(marked_zero_nxt[i][0]) begin
					row_stat_nxt[i] = 8'b1111_1111;
				end
				else begin
					row_stat_nxt[i] = row_stat_reg[i];
				end
			end
			else begin
				row_stat_nxt[i] = 0;
			end
		end
	end
	else begin
		row_stat_nxt = {0, 0, 0, 0, 0, 0, 0, 0};
	end
end
always_comb begin
	if(state_reg == DFS) begin	
		if( (is_zero_ij[counter_col][7] && !row_stat_reg[counter_col][7] && !vertical_check_reg[7])
		||  (is_zero_ij[counter_col][6] && !row_stat_reg[counter_col][6] && !vertical_check_reg[6]) 
		||  (is_zero_ij[counter_col][5] && !row_stat_reg[counter_col][5] && !vertical_check_reg[5])
		||  (is_zero_ij[counter_col][4] && !row_stat_reg[counter_col][4] && !vertical_check_reg[4])
		||  (is_zero_ij[counter_col][3] && !row_stat_reg[counter_col][3] && !vertical_check_reg[3])
		||  (is_zero_ij[counter_col][2] && !row_stat_reg[counter_col][2] && !vertical_check_reg[2])
		||  (is_zero_ij[counter_col][1] && !row_stat_reg[counter_col][1] && !vertical_check_reg[1])
		||  (is_zero_ij[counter_col][0] && !row_stat_reg[counter_col][0] && !vertical_check_reg[0]) ) begin
			hit = 1;
		end
		else begin
			hit = 0;
		end
	end
	else begin
		hit = 1'bx;
	end
end
always_comb begin
	if(state_reg == ASSIGN_ROW_TASK) begin
		for(integer i=7; i>=0; i=i-1) begin
			for(integer j=7; j>=0; j=j-1) begin
				if(row_zero_count_reg[counter_reg[2:0]] == 1) begin
					marked_zero_nxt[i][j] = (i == counter_reg[2:0]) ? (is_zero_ij[i][j] && col_zero_count_reg[j] != 0) : marked_zero_reg[i][j];
				end
				else begin
					marked_zero_nxt[i][j] = marked_zero_reg[i][j];
				end
			end
		end
	end
	else if(state_reg == ASSIGN_COL_TASK) begin
		for(integer i=7; i>=0; i=i-1) begin
			for(integer j=7; j>=0; j=j-1) begin
				if(col_zero_count_reg[counter_reg[2:0]] == 1) begin
					marked_zero_nxt[i][j] = (j == counter_reg[2:0]) ? (is_zero_ij[i][j] && row_zero_count_reg[i] != 0) : marked_zero_reg[i][j];
				end
				else begin
					marked_zero_nxt[i][j] = marked_zero_reg[i][j];
				end
			end
		end
	end
	else if(state_reg == ARB_ASSIGN) begin
		if(row_zero_count_reg[counter_reg[2:0]] != 0) begin
			for(integer i=7; i>=0; i=i-1) begin
				if(i == counter_reg[2:0]) begin
					if(is_zero_ij[i][7] && col_zero_count_reg[7] != 0) begin
						marked_zero_nxt[i] = 8'b1000_0000;
					end
					else if(is_zero_ij[i][6] && col_zero_count_reg[6] != 0) begin
						marked_zero_nxt[i] = 8'b0100_0000;
					end
					else if(is_zero_ij[i][5] && col_zero_count_reg[5] != 0) begin
						marked_zero_nxt[i] = 8'b0010_0000;
					end
					else if(is_zero_ij[i][4] && col_zero_count_reg[4] != 0) begin
						marked_zero_nxt[i] = 8'b0001_0000;
					end
					else if(is_zero_ij[i][3] && col_zero_count_reg[3] != 0) begin
						marked_zero_nxt[i] = 8'b0000_1000;
					end
					else if(is_zero_ij[i][2] && col_zero_count_reg[2] != 0) begin
						marked_zero_nxt[i] = 8'b0000_0100;
					end
					else if(is_zero_ij[i][1] && col_zero_count_reg[1] != 0) begin
						marked_zero_nxt[i] = 8'b0000_0010;
					end
					else if(is_zero_ij[i][0] && col_zero_count_reg[0] != 0) begin
						marked_zero_nxt[i] = 8'b0000_0001;
					end
					else begin
						marked_zero_nxt[i] = marked_zero_reg[i];
					end
				end
				else begin
					marked_zero_nxt[i][7] = marked_zero_reg[i][7];
					marked_zero_nxt[i][6] = marked_zero_reg[i][6];
					marked_zero_nxt[i][5] = marked_zero_reg[i][5];
					marked_zero_nxt[i][4] = marked_zero_reg[i][4];
					marked_zero_nxt[i][3] = marked_zero_reg[i][3];
					marked_zero_nxt[i][2] = marked_zero_reg[i][2];
					marked_zero_nxt[i][1] = marked_zero_reg[i][1];
					marked_zero_nxt[i][0] = marked_zero_reg[i][0];
				end
			end
		end
		else begin
			marked_zero_nxt = marked_zero_reg;
		end
	end
    else if(state_reg == REPEAT_CHECK_RESET) begin
		for(integer i=7; i>=0; i=i-1) begin
            marked_zero_nxt[i] = (can_assign) ? 0 : marked_zero_reg[i];
		end
    end
	else if(state_reg == DFS) begin
		if(is_zero_ij[counter_col][7] && !row_stat_reg[counter_col][7] && !vertical_check_reg[7]) begin
			for(integer i=7; i>=0; i=i-1) begin
				marked_zero_nxt[i] = (i == counter_col) ? 8'b1000_0000 : marked_zero_reg[i];
			end
		end
		else if(is_zero_ij[counter_col][6] && !row_stat_reg[counter_col][6] && !vertical_check_reg[6]) begin
			for(integer i=7; i>=0; i=i-1) begin
				marked_zero_nxt[i] = (i == counter_col) ? 8'b0100_0000 : marked_zero_reg[i];
			end
		end
		else if(is_zero_ij[counter_col][5] && !row_stat_reg[counter_col][5] && !vertical_check_reg[5]) begin
			for(integer i=7; i>=0; i=i-1) begin
				marked_zero_nxt[i] = (i == counter_col) ? 8'b0010_0000 : marked_zero_reg[i];
			end
		end
		else if(is_zero_ij[counter_col][4] && !row_stat_reg[counter_col][4] && !vertical_check_reg[4]) begin
			for(integer i=7; i>=0; i=i-1) begin
				marked_zero_nxt[i] = (i == counter_col) ? 8'b0001_0000 : marked_zero_reg[i];
			end
		end
		else if(is_zero_ij[counter_col][3] && !row_stat_reg[counter_col][3] && !vertical_check_reg[3]) begin
			for(integer i=7; i>=0; i=i-1) begin
				marked_zero_nxt[i] = (i == counter_col) ? 8'b0000_1000 : marked_zero_reg[i];
			end
		end
		else if(is_zero_ij[counter_col][2] && !row_stat_reg[counter_col][2] && !vertical_check_reg[2]) begin
			for(integer i=7; i>=0; i=i-1) begin
				marked_zero_nxt[i] = (i == counter_col) ? 8'b0000_0100 : marked_zero_reg[i];
			end
		end
		else if(is_zero_ij[counter_col][1] && !row_stat_reg[counter_col][1] && !vertical_check_reg[1]) begin
			for(integer i=7; i>=0; i=i-1) begin
				marked_zero_nxt[i] = (i == counter_col) ? 8'b0000_0010 : marked_zero_reg[i];
			end
		end
		else if(is_zero_ij[counter_col][0] && !row_stat_reg[counter_col][0] && !vertical_check_reg[0]) begin
			for(integer i=7; i>=0; i=i-1) begin
				marked_zero_nxt[i] = (i == counter_col) ? 8'b0000_0001 : marked_zero_reg[i];
			end
		end
		else begin
			for(integer i=7; i>=0; i=i-1) begin //this row cannot be assigned
				marked_zero_nxt[i] = (i == counter_col) ? 0 : marked_zero_reg[i];
			end
		end
	end
	else if(state_reg == IDLE || state_reg == FIND_UNCOVERED_MIN) begin
		for(integer i=7; i>=0; i=i-1) begin
			marked_zero_nxt[i] = 0;
		end
	end
	else begin
		marked_zero_nxt = marked_zero_reg;
	end
end
// COUNT ZERO
// logic [3-1:0] total_zero_c, total_zero_r;
// logic [3-1:0] col_zero_count_nxt [8-1:0], col_zero_count_reg [8-1:0], row_zero_count_nxt [8-1:0], row_zero_count_reg [8-1:0];
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		marked_zero_reg <= {0, 0, 0, 0, 0, 0, 0, 0};
		row_zero_count_reg <= {0, 0, 0, 0, 0, 0, 0, 0};
		col_zero_count_reg <= {0, 0, 0, 0, 0, 0, 0, 0};
	end
	else begin
	 	row_zero_count_reg <= row_zero_count_nxt;
		col_zero_count_reg <= col_zero_count_nxt;
		marked_zero_reg <= marked_zero_nxt;
	end
end
always_comb begin
	for(integer i=7; i>=0; i=i-1) begin
		total_zero_r[i] = is_zero_ij[i][7] + is_zero_ij[i][6] + is_zero_ij[i][5] + is_zero_ij[i][4] + is_zero_ij[i][3] + is_zero_ij[i][2] + is_zero_ij[i][1] + is_zero_ij[i][0];
		total_zero_c[i] = is_zero_ij[7][i] + is_zero_ij[6][i] + is_zero_ij[5][i] + is_zero_ij[4][i] + is_zero_ij[3][i] + is_zero_ij[2][i] + is_zero_ij[1][i] + is_zero_ij[0][i];
	end
end

// MAKE_ZERO_ROW, MAKE_ZERO_COL
// logic [3-1:0] min_idx_nxt [8-1:0], min_idx_reg[8-1:0];
// logic [7-1:0] MIN_VAL_nxt [8-1:0], MIN_VAL_reg [8-1:0];
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
	end
	else begin
		MIN_VAL_reg <= MIN_VAL_nxt;
		row_stat_reg <= row_stat_nxt;
	end
end
always_comb begin
	if(state_reg == MAKE_ZERO_COL) begin
		if(counter_reg == 0) begin
			for(integer i = 7; i >= 0; i=i-1) begin
				MIN_VAL_nxt[i] = 127;
			end
		end
		else begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			MIN_VAL_nxt[i] = (counter_reg[3] == 1 && job_cost_reg[counter_reg[2:0]][i] < MIN_VAL_reg[i]) ? job_cost_reg[counter_reg[2:0]][i] : MIN_VAL_reg[i];
		end
		end
	end
	else if(state_reg == MAKE_ZERO_ROW) begin
		if(counter_reg == 0) begin
			for(integer i = 7; i >= 0; i=i-1) begin
				MIN_VAL_nxt[i] = 127;
			end
		end
		else begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			MIN_VAL_nxt[i] = (counter_reg[3] == 1 && job_cost_reg[i][counter_reg[2:0]] < MIN_VAL_reg[i]) ? job_cost_reg[i][counter_reg[2:0]] : MIN_VAL_reg[i];
		end
		end
	end
	else if(state_reg == FIND_UNCOVERED_MIN) begin
		if(counter_reg[3] == 1) begin
			if(vertical_check_reg[counter_reg[2:0]] == 0) begin
				for(integer i = 7; i >= 0; i=i-1) begin
					MIN_VAL_nxt[i] = (job_cost_reg[i][counter_reg[2:0]] < MIN_VAL_reg[i]) ? job_cost_reg[i][counter_reg[2:0]] : MIN_VAL_reg[i];
				end
			end
			else begin
				MIN_VAL_nxt = MIN_VAL_reg;
			end
		end
		else begin
			MIN_VAL_nxt = MIN_VAL_reg;
		end
	end
	else begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			MIN_VAL_nxt[i] = 127;
		end
	end
end


// INPUT STATE
always_comb begin
	if(state_reg == INPUT) begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			for(integer j = 7; j >= 0; j = j - 1) begin
				input_nxt[i][j] = job_cost_nxt[i][j];
			end
		end
	end
	else begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			for(integer j = 7; j >= 0; j = j - 1) begin
				input_nxt[i][j] = input_reg[i][j];
			end
		end
	end
end

always_comb begin
	if(state_reg == INPUT) begin //shift register for 2d array
		for(integer i = 7; i > 0; i = i - 1) begin
			job_cost_nxt[7][i] = job_cost_reg[7][i-1];
			job_cost_nxt[6][i] = job_cost_reg[6][i-1];
			job_cost_nxt[5][i] = job_cost_reg[5][i-1];
			job_cost_nxt[4][i] = job_cost_reg[4][i-1];
			job_cost_nxt[3][i] = job_cost_reg[3][i-1];
			job_cost_nxt[2][i] = job_cost_reg[2][i-1];
			job_cost_nxt[1][i] = job_cost_reg[1][i-1];
			job_cost_nxt[0][i] = job_cost_reg[0][i-1];
		end
		for(integer i = 7; i > 0; i = i - 1) begin
			job_cost_nxt[i][0] = job_cost_reg[i-1][7];
		end
		job_cost_nxt[0][0] = in_cost_reg;
	end
	else if(state_reg == MAKE_ZERO_COL) begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			for(integer j = 7; j >= 0; j = j - 1) begin
				job_cost_nxt[i][j] = (counter_reg[3] == 0 && i == counter_reg[2:0]) ? job_cost_reg[i][j] - MIN_VAL_reg[j] : job_cost_reg[i][j];
			end
		end
	end
	else if(state_reg == MAKE_ZERO_ROW) begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			for(integer j = 7; j >= 0; j = j - 1) begin
				job_cost_nxt[i][j] = (counter_reg[3] == 0 && j == counter_reg[2:0]) ? job_cost_reg[i][j] - MIN_VAL_reg[i] : job_cost_reg[i][j];
			end
		end
	end
	else if(state_reg == SUBTRACT_ADD_MIN) begin
		for(integer i = 7; i >= 0; i = i - 1) begin
			for(integer j = 7; j >= 0; j = j - 1) begin
				job_cost_nxt[i][j] = (vertical_check_reg[j] == 0 && horizontal_check_reg[i] == 1) ? job_cost_reg[i][j] - UNCOVERED_MIN_VAL_reg 
								   : (vertical_check_reg[j] == 1 && horizontal_check_reg[i] == 0) ? job_cost_reg[i][j] + UNCOVERED_MIN_VAL_reg 
								   : job_cost_reg[i][j];
			end
		end
	end
	else begin
		job_cost_nxt = job_cost_reg;
	end
end
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
	end
	else begin
		job_cost_reg <= job_cost_nxt;
		input_reg <= input_nxt;
	end
end


endmodule
