module Seq(
    // Input signals
    clk,
    rst_n,
    in_data,
    in_state_reset,
    // Output signals
    out_cur_state,
    out
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_data, in_state_reset;
output logic [2:0] out_cur_state;
output logic out;

//---------------------------------------------------------------------
//   FSM state
//---------------------------------------------------------------------
parameter S_0 = 3'd0;
parameter S_1 = 3'd1;
parameter S_2 = 3'd2;
parameter S_3 = 3'd3;
parameter S_4 = 3'd4;
parameter S_5 = 3'd5;
parameter S_6 = 3'd6;
parameter S_7 = 3'd7;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [2:0] next_state;
logic out_reg;

//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------

assign out = (out_cur_state == S_7) ? 1 : 0;

always_comb begin
	if(in_state_reset == 1) begin
		next_state = S_0;
	end
	else begin
		case (out_cur_state)
			S_0: next_state = (in_data == 0) ? S_2 : S_1;
			S_1: next_state = (in_data == 0) ? S_4 : S_1;
			S_2: next_state = (in_data == 0) ? S_3 : S_4;
			S_3: next_state = (in_data == 0) ? S_6 : S_5;
			S_4: next_state = (in_data == 0) ? S_5 : S_4;
			S_5: next_state = (in_data == 0) ? S_7 : S_5;
			S_6: next_state = (in_data == 0) ? S_6 : S_7;
			S_7: next_state = S_7;
		endcase
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_cur_state <= S_0;
	end
	else begin
		out_cur_state <= next_state;
	end
end

endmodule

