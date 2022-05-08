module Maxmin(
    // Input signals
    clk,
    rst_n,
    in_valid,
    in_num,
    // Output signals
    out_max,
    out_min,
    out_valid
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid;
input [7:0] in_num;
output logic out_valid;
output logic [7:0] out_max, out_min;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [7:0] max_reg, min_reg;
logic [3:0] cnt, cnt_reg;

//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------
assign max_reg = (!in_valid) ? 0 : (in_num > out_max) ? in_num : out_max;
assign min_reg = (!in_valid) ? 255 : (in_num < out_min) ? in_num : out_min;
assign cnt = (cnt_reg == 15) ? 1 : cnt_reg + 1;

always @(negedge rst_n or posedge clk) begin
  if(!rst_n) begin
    cnt_reg <= 0;
  end
  else begin
    cnt_reg <= (in_valid) ? cnt : 1;
  end
end

always @(negedge rst_n or posedge clk) begin
  if(!rst_n) begin
    out_max <= 0;
  end
  else begin
    out_max <= max_reg;
  end
end

always @(negedge rst_n or posedge clk) begin
  if(!rst_n) begin
    out_min <= 255;
  end
  else begin
    out_min <= min_reg;
  end
end

always @(negedge rst_n or posedge clk) begin
  if(!rst_n) begin
    out_valid <= 0;
  end
  else begin
    out_valid <= (cnt_reg == 15) ? 1 : 0;
  end
end

endmodule
