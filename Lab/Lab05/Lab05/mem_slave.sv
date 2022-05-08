module mem_slave(
  // Input signals
  clk,
  rst_n,
  data_in_addr,
  data_in_value,
  valid,
  // Output signals
  ready
);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
input clk, rst_n, valid;
input [2:0] data_in_addr, data_in_value;
output logic ready;
logic [2:0] mem [0:7]; 
logic [23:0] count;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ready <= 0;
        mem[0] <= 0;
        mem[1] <= 0;
        mem[2] <= 0;
        mem[3] <= 0;
        mem[4] <= 0;
        mem[5] <= 0;
        mem[6] <= 0;
        mem[7] <= 0;
        count <= 0;
    end
    else begin
        if(valid && ready) begin
            mem[data_in_addr] <= data_in_value;
            ready <= 0;
        end
        else begin
            count <= count + 1;
            if(count == 10) begin
                ready <= 1;
                count <= $urandom_range(5, 0);
            end
        end
    end
end
endmodule
