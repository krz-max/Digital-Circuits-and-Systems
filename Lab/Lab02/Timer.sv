module Timer(
    // Input signals
  in,
	in_valid,
	rst_n,
	clk,
  // Output signals
  out_valid
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid;
input [4:0] in;
output logic out_valid;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [4:0] cnt_reg;
logic [4:0] out_valid_comb, cnt_minus_one, cnt_comb

//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------

always @(negedge rst_n or posedge clk) begin
  if(!rst_n) begin
    cnt_reg <= 0;
  end
  else begin
    cnt_reg <= cnt_comb;
  end
end

assign cnt_minus_one = cnt_reg - 1;
assign cnt_comb = (in_valid) ? in : cnt_minus_one;
assign out_valid_comb = (cnt_minus_one == 0) ? 1 : 0;

always @(negedge rst_n, posedge clk) begin
  if(!rst_n) begin
    out_valid <= 0;
  end
  else begin
    out_valid <= out_valid_comb;
  end
end

endmodule

