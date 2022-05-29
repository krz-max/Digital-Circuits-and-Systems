module Conv(
  // Input signals
  clk,
  rst_n,
  image_valid,
  filter_valid,
  in_data,
  // Output signals
  out_valid,
  out_data
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, image_valid, filter_valid;
input [3:0] in_data;
output logic signed [15:0] out_data;
output logic out_valid;
//---------------------------------------------------------------------
//   parameter 
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   logic                       
//---------------------------------------------------------------------
logic signed [4-1:0] row_filter_nxt [5-1:0];
logic signed [4-1:0] col_filter_nxt [5-1:0];
logic signed [4-1:0] row_weight_nxt [5-1:0];
logic signed [16-1:0] col1_weight_nxt [5-1:0];
logic signed [16-1:0] col2_weight_nxt [5-1:0];
logic signed [16-1:0] col3_weight_nxt [5-1:0];
logic signed [16-1:0] col4_weight_nxt [5-1:0];
logic signed [10-1:0] row_filter_sum, col_weight_reg;
logic [7-1:0] valid_count_nxt;
logic [3-1:0] input_col_nxt;
logic signed [8-1:0] row_mul1, row_mul2, row_mul3, row_mul4, row_mul5;
logic signed [8-1:0] row_mul1_reg, row_mul2_reg, row_mul3_reg, row_mul4_reg, row_mul5_reg;

logic signed [4-1:0] row_filter_reg [5-1:0];
logic signed [4-1:0] col_filter_reg [5-1:0];
logic signed [4-1:0] row_weight_reg [5-1:0];
logic signed [16-1:0] col1_weight_reg [5-1:0];
logic signed [16-1:0] col2_weight_reg [5-1:0];
logic signed [16-1:0] col3_weight_reg [5-1:0];
logic signed [16-1:0] col4_weight_reg [5-1:0];
logic [3-1:0] input_col_reg;
logic [4-1:0] in_data_reg;
logic filter_valid_reg, image_valid_reg;
logic [7-1:0] cnt_nxt, cnt_reg;
logic signed [16-1:0] col_mul_src1, col_mul_src2, col_mul_src3, col_mul_src4, col_mul_src5;
logic signed [16-1:0] col_mul1, col_mul2, col_mul3, col_mul4, col_mul5;
logic signed [16-1:0] col_mul1_reg, col_mul2_reg, col_mul3_reg, col_mul4_reg, col_mul5_reg;
logic signed [16-1:0] col_filter_sum;
logic [16-1:0] image_nxt [12-1:0];
logic [16-1:0] image_reg [12-1:0];
logic out_valid_nxt;
logic [16-1:0] out_data_nxt;
//---------------------------------------------------------------------
//   Your design                       
//---------------------------------------------------------------------
assign cnt_nxt = (image_valid || filter_valid || (74 <= cnt_reg && cnt_reg <= 79)) ? cnt_reg + 1 : 0;
assign input_col_nxt = (14 <= cnt_nxt) ? input_col_reg + 1 : 0;
assign row_filter_nxt = (cnt_reg < 6) ? {row_filter_reg[3], row_filter_reg[2], row_filter_reg[1], row_filter_reg[0], in_data_reg} : row_filter_reg;
assign col_filter_nxt = (6 <= cnt_reg && cnt_reg < 11) ? {col_filter_reg[3], col_filter_reg[2], col_filter_reg[1], col_filter_reg[0], in_data_reg} : col_filter_reg;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_reg <= 0;
        input_col_reg <= 0;
    end
    else begin
        cnt_reg <= cnt_nxt;
        input_col_reg <= input_col_nxt;
    end
end
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        in_data_reg <= 0;
	end
	else begin
		in_data_reg <= in_data;
        row_filter_reg <= row_filter_nxt;
        col_filter_reg <= col_filter_nxt;
	end
end
assign row_mul1 = row_filter_reg[4] * row_weight_reg[4];
assign row_mul2 = row_filter_reg[3] * row_weight_reg[3];
assign row_mul3 = row_filter_reg[2] * row_weight_reg[2];
assign row_mul4 = row_filter_reg[1] * row_weight_reg[1];
assign row_mul5 = row_filter_reg[0] * row_weight_reg[0];
assign row_weight_nxt = {row_weight_reg[3], row_weight_reg[2], row_weight_reg[1], row_weight_reg[0], in_data_reg};
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
    end
    else begin
        row_weight_reg <= row_weight_nxt;
        row_mul1_reg <= row_mul1;
        row_mul2_reg <= row_mul2;
        row_mul3_reg <= row_mul3;
        row_mul4_reg <= row_mul4;
        row_mul5_reg <= row_mul5;
    end
end
assign row_filter_sum = row_mul1_reg + row_mul2_reg + row_mul3_reg + row_mul4_reg + row_mul5_reg;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
    end
    else begin
        col_weight_reg <= row_filter_sum;
    end
end
always_comb begin
    if(18 <= cnt_reg) begin
	    case (input_col_reg)
		    5: begin
	    		col1_weight_nxt = {col1_weight_reg[3], col1_weight_reg[2], col1_weight_reg[1], col1_weight_reg[0], col_weight_reg};
	    		col2_weight_nxt = col2_weight_reg;
	    		col3_weight_nxt = col3_weight_reg;
	    		col4_weight_nxt = col4_weight_reg;
	    	end
	    	6: begin
	    		col1_weight_nxt = col1_weight_reg;
	    		col2_weight_nxt = {col2_weight_reg[3], col2_weight_reg[2], col2_weight_reg[1], col2_weight_reg[0], col_weight_reg};
	    		col3_weight_nxt = col3_weight_reg;
	    		col4_weight_nxt = col4_weight_reg;
	    	end
	    	7: begin
	    		col1_weight_nxt = col1_weight_reg;
	    		col2_weight_nxt = col2_weight_reg;
	    		col3_weight_nxt = {col3_weight_reg[3], col3_weight_reg[2], col3_weight_reg[1], col3_weight_reg[0], col_weight_reg};
	    		col4_weight_nxt = col4_weight_reg;
	    	end
	    	0: begin
	    		col1_weight_nxt = col1_weight_reg;
	    		col2_weight_nxt = col2_weight_reg;
	    		col3_weight_nxt = col3_weight_reg;
	    		col4_weight_nxt = {col4_weight_reg[3], col4_weight_reg[2], col4_weight_reg[1], col4_weight_reg[0], col_weight_reg};
	    	end
	    	default: begin
	    		col1_weight_nxt = col1_weight_reg;
	    		col2_weight_nxt = col2_weight_reg;
	    		col3_weight_nxt = col3_weight_reg;
	    		col4_weight_nxt = col4_weight_reg;
	    	end
	    endcase
    end
    else begin
	    	col1_weight_nxt = col1_weight_reg;
	    	col2_weight_nxt = col2_weight_reg;
			col3_weight_nxt = col3_weight_reg;
    		col4_weight_nxt = col4_weight_reg;
    end
end
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        col1_weight_reg <= {0, 0, 0, 0, 0};
        col2_weight_reg <= {0, 0, 0, 0, 0};
        col3_weight_reg <= {0, 0, 0, 0, 0};
        col4_weight_reg <= {0, 0, 0, 0, 0};
        col_mul1_reg <= 0;
        col_mul2_reg <= 0;
        col_mul3_reg <= 0;
        col_mul4_reg <= 0;
        col_mul5_reg <= 0;
    end
    else begin
        col1_weight_reg <= col1_weight_nxt;
        col2_weight_reg <= col2_weight_nxt;
        col3_weight_reg <= col3_weight_nxt;
        col4_weight_reg <= col4_weight_nxt;
        col_mul1_reg <= col_mul1;
        col_mul2_reg <= col_mul2;
        col_mul3_reg <= col_mul3;
        col_mul4_reg <= col_mul4;
        col_mul5_reg <= col_mul5;
    end
end
always_comb begin
    case(input_col_reg)
        6: begin
            col_mul_src1 = col1_weight_reg[4];
            col_mul_src2 = col1_weight_reg[3];
            col_mul_src3 = col1_weight_reg[2];
            col_mul_src4 = col1_weight_reg[1];
            col_mul_src5 = col1_weight_reg[0];
        end
        7: begin
            col_mul_src1 = col2_weight_reg[4];
            col_mul_src2 = col2_weight_reg[3];
            col_mul_src3 = col2_weight_reg[2];
            col_mul_src4 = col2_weight_reg[1];
            col_mul_src5 = col2_weight_reg[0];
        end
        0: begin
            col_mul_src1 = col3_weight_reg[4];
            col_mul_src2 = col3_weight_reg[3];
            col_mul_src3 = col3_weight_reg[2];
            col_mul_src4 = col3_weight_reg[1];
            col_mul_src5 = col3_weight_reg[0];
        end
        1: begin
            col_mul_src1 = col4_weight_reg[4];
            col_mul_src2 = col4_weight_reg[3];
            col_mul_src3 = col4_weight_reg[2];
            col_mul_src4 = col4_weight_reg[1];
            col_mul_src5 = col4_weight_reg[0];
        end
        default: begin
            col_mul_src1 = 9'bx;
            col_mul_src2 = 9'bx;
            col_mul_src3 = 9'bx;
            col_mul_src4 = 9'bx;
            col_mul_src5 = 9'bx;
        end
    endcase
end
assign col_mul1 = col_filter_reg[4] * col_mul_src1;
assign col_mul2 = col_filter_reg[3] * col_mul_src2;
assign col_mul3 = col_filter_reg[2] * col_mul_src3;
assign col_mul4 = col_filter_reg[1] * col_mul_src4;
assign col_mul5 = col_filter_reg[0] * col_mul_src5;
assign col_filter_sum = col_mul1_reg + col_mul2_reg + col_mul3_reg + col_mul4_reg + col_mul5_reg;
assign image_nxt = ((out_valid) || (52 <= cnt_reg && (input_col_reg == 7 || input_col_reg == 0 || input_col_reg == 1 || input_col_reg == 2))) ? 
    {image_reg[10], image_reg[9], image_reg[8], image_reg[7], 
    image_reg[6], image_reg[5], image_reg[4], image_reg[3], 
    image_reg[2], image_reg[1], image_reg[0], col_filter_sum} : image_reg;
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
    end
    else begin
        image_reg <= image_nxt;
    end
end
assign out_valid = (65 <= cnt_reg) ? 1 : 0;
always_comb begin
    case(cnt_reg)
        65, 66, 67, 68, 69, 70, 71, 72: begin
            out_data = image_reg[7];
        end
        73, 74, 75, 76: begin
            out_data = image_reg[4];
        end
        77, 78, 79, 80: begin
            out_data = image_reg[0];
        end
        default: begin
            out_data = 0;
        end
    endcase
end
endmodule
