`include "synchronizer.v"
module CDC(// Input signals
			clk_1,
			clk_2,
			in_valid,
			rst_n,
			in_a,
			mode,
			in_b,
		  //  Output signals
			out_valid,
			out
			);		
input clk_1; 
input clk_2;			
input rst_n;
input in_valid;
input[3:0]in_a,in_b;
input mode;
output logic out_valid;
output logic [7:0]out; 			

parameter IDLE = 2'b00;
parameter COMPUTE = 2'b01;
parameter OUT = 2'b10;
logic in_valid_xor, P_reg, Q_nxt, Q_reg, CDC_res_xor;
logic [2-1:0] state_reg, state_nxt;
logic [4-1:0] A_reg, B_reg;
logic Mode_reg, out_valid_nxt;
logic [8-1:0] out_nxt, result;



//---------------------------------------------------------------------
//   your design  (Using synchronizer)       
// Example :
//logic P,Q,Y;
//synchronizer x5(.D(P),.Q(Y),.clk(clk_2),.rst_n(rst_n));           
//---------------------------------------------------------------------		
synchronizer x5(.D(P_reg), .Q(Q_nxt), .clk(clk_2), .rst_n(rst_n));

assign in_valid_xor = in_valid ^ P_reg;
always_ff @(posedge clk_1 or negedge rst_n) begin
    if(!rst_n) begin
        P_reg <= 0;
    end
    else begin
        P_reg <= in_valid_xor;
    end
end
assign CDC_res_xor = Q_nxt ^ Q_reg;
always_ff @(posedge clk_2 or negedge rst_n) begin
    if(!rst_n) begin
        Q_reg <= 0;
    end
    else begin
        Q_reg <= Q_nxt;
    end
end


// FSM
always_comb begin
    case(state_reg)
        IDLE: begin
            state_nxt = (CDC_res_xor == 1) ? COMPUTE : IDLE;
        end
        COMPUTE: begin
            state_nxt = OUT;
        end
        default: begin
            state_nxt = IDLE;
        end
    endcase
end
always_ff @(posedge clk_2 or negedge rst_n) begin
    if(!rst_n) begin
        state_reg <= IDLE;
    end
    else begin
        state_reg <= state_nxt;
    end
end
always_comb begin
    out_valid_nxt = (state_reg == OUT) ? 1 : 0;
    out_nxt = (state_reg == OUT) ? result : 0;
end
assign result = (Mode_reg == 0) ? A_reg + B_reg : A_reg * B_reg;

always_ff @(posedge clk_2 or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out <= 0;
    end
    else begin
        out_valid <= out_valid_nxt;
        out <= out_nxt;
    end
end
always_ff @(posedge clk_1 or negedge rst_n) begin
    if(!rst_n) begin
        A_reg <= 0;
        B_reg <= 0;
        Mode_reg <= 0;
    end
    else begin
        A_reg <= in_a;
        B_reg <= in_b;
        Mode_reg <= mode;
    end
end

		
endmodule
