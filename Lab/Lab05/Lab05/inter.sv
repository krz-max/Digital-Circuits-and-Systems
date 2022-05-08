module inter(
  // Input signals
  clk,
  rst_n,
  in_valid_1,
  in_valid_2,
  in_valid_3,
  data_in_1,
  data_in_2,
  data_in_3,
  ready_slave1,
  ready_slave2,
  // Output signals
  valid_slave1,
  valid_slave2,
  addr_out,
  value_out,
  handshake_slave1,
  handshake_slave2
);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
input clk, rst_n, in_valid_1, in_valid_2, in_valid_3;
input [6:0] data_in_1, data_in_2, data_in_3; 
input ready_slave1, ready_slave2;
output logic valid_slave1, valid_slave2;
output logic [2:0] addr_out, value_out;
output logic handshake_slave1, handshake_slave2;
//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
logic [3-1:0] state, next_state;
logic valid_slave1_reg, valid_slave2_reg;
logic [3-1:0] addr_out_reg, value_out_reg;
logic [3-1:0] Valid_Master_reg, Valid_Master;
logic handshake_slave1_reg, handshake_slave2_reg, handshake;
logic [7-1:0] data_in_1_reg, data_in_2_reg, data_in_3_reg, data1, data2, data3;
//---------------------------------------------------------------------
//   state parameter
//---------------------------------------------------------------------
parameter IDLE = 3'd0;
parameter MASTER1 = 3'd1;
parameter MASTER2 = 3'd2;
parameter MASTER3 = 3'd3;
parameter HANDSHAKE = 3'd4;

//---------------------------------------------------------------------
//   Your DESIGN                        
//---------------------------------------------------------------------
assign handshake_slave1_reg = (valid_slave1 && ready_slave1) ? 1'b1 : 1'b0;
assign handshake_slave2_reg = (valid_slave2 && ready_slave2) ? 1'b1 : 1'b0;
assign handshake = handshake_slave1_reg | handshake_slave2_reg;
assign data_in_1_reg = (state == IDLE) ? data_in_1 : data1;
assign data_in_2_reg = (state == IDLE) ? data_in_2 : data2;
assign data_in_3_reg = (state == IDLE) ? data_in_3 : data3;

always_comb begin
	if(state == IDLE) begin
		valid_slave1_reg = 0;
		valid_slave2_reg = 0;
		addr_out_reg = 0;
		value_out_reg = 0;
        Valid_Master_reg = {in_valid_1, in_valid_2, in_valid_3};
		case(Valid_Master_reg)
			3'b111: begin
				next_state = MASTER1;
			end
			3'b110: begin
				next_state = MASTER1;
			end
			3'b101: begin
				next_state = MASTER1;
			end
			3'b100: begin
				next_state = MASTER1;
			end
			3'b011: begin
				next_state = MASTER2;
			end
			3'b010: begin
				next_state = MASTER2;
			end
			3'b001: begin
				next_state = MASTER3;
			end
			default: begin
				next_state = IDLE;
			end
		endcase
	end
	else if (state == MASTER1) begin
		valid_slave1_reg = (handshake == 1) ? 0 : (data1[6] == 1'b0) ? 1'b1 : 1'b0;
		valid_slave2_reg = (handshake == 1) ? 0 : (data1[6] == 1'b1) ? 1'b1 : 1'b0;
		addr_out_reg = (handshake == 1) ? 0 : data1[5:3];
		value_out_reg = (handshake == 1) ? 0 : data1[2:0];
		next_state = (handshake == 1) ? HANDSHAKE : MASTER1;
        Valid_Master_reg = Valid_Master;
	end
	else if (state == MASTER2) begin
		valid_slave1_reg = (handshake == 1) ? 0 : (data2[6] == 1'b0) ? 1'b1 : 1'b0;
		valid_slave2_reg = (handshake == 1) ? 0 : (data2[6] == 1'b1) ? 1'b1 : 1'b0;
		addr_out_reg = (handshake == 1) ? 0 : data2[5:3];
		value_out_reg = (handshake == 1) ? 0 : data2[2:0];
		next_state = (handshake == 1) ? HANDSHAKE : MASTER2;
        Valid_Master_reg = Valid_Master;
	end
	else if (state == MASTER3) begin
		valid_slave1_reg = (handshake == 1) ? 0 : (data3[6] == 1'b0) ? 1'b1 : 1'b0;
        Valid_Master_reg = Valid_Master;
		valid_slave2_reg = (handshake == 1) ? 0 : (data3[6] == 1'b1) ? 1'b1 : 1'b0;
		addr_out_reg = (handshake == 1) ? 0 : data3[5:3];
		value_out_reg = (handshake == 1) ? 0 : data3[2:0];
		next_state = (handshake == 1) ? HANDSHAKE : MASTER3;
	end
	else begin
		valid_slave1_reg = 0;
		valid_slave2_reg = 0;
		addr_out_reg = 0;
		value_out_reg = 0;
        if(Valid_Master == 3'b111) begin
            next_state = MASTER2;
            Valid_Master_reg = 3'b011;
        end
        else if(Valid_Master == 3'b110) begin
            next_state = MASTER2;
            Valid_Master_reg = 3'b010;
        end
        else if(Valid_Master == 3'b101) begin
            next_state = MASTER3;
            Valid_Master_reg = 3'b001;
        end
        else if(Valid_Master == 3'b100) begin
            next_state = IDLE;
            Valid_Master_reg = 3'b000;
        end
        else if(Valid_Master == 3'b011) begin
            next_state = MASTER3;
            Valid_Master_reg = 3'b001;
        end
        else if(Valid_Master == 3'b010) begin
            next_state = IDLE;
            Valid_Master_reg = 3'b000;
        end
        else if(Valid_Master == 3'b001) begin
            next_state = IDLE;
            Valid_Master_reg = 3'b000;
        end
        else begin
        next_state = IDLE;
        Valid_Master_reg = 0;
        end
	end
end
//---------------------------------------------------------------------
//   Sequential Logic
//---------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		valid_slave1 <= 0;
        Valid_Master <= 0;
	end
	else begin
		valid_slave1 <= valid_slave1_reg;
        Valid_Master <= Valid_Master_reg;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		valid_slave2 <= 0;
	end
	else begin
		valid_slave2 <= valid_slave2_reg;
	end
end
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_out <= 0;
	end
	else begin
		addr_out <= addr_out_reg;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		value_out <= 0;
	end
	else begin
		value_out <= value_out_reg;
	end
end
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		handshake_slave1 <= 0;
	end
	else begin
		handshake_slave1 <= handshake_slave1_reg;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		handshake_slave2 <= 0;
	end
	else begin
		handshake_slave2 <= handshake_slave2_reg;
	end
end
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end

// data input
always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		data1 <= 0;
		data2 <= 0;
		data3 <= 0;
	end
	else begin
		data1 <= data_in_1_reg;
		data2 <= data_in_2_reg;
		data3 <= data_in_3_reg;
	end
end
endmodule




