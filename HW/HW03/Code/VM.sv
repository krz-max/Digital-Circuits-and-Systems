module VM(
    //Input 
    clk,
    rst_n,
    in_item_valid,
    in_coin_valid,
    in_coin,
    in_rtn_coin,
    in_buy_item,
    in_item_price,
    //OUTPUT
    out_monitor,
    out_valid,
    out_consumer,
    out_sell_num
);

//Input 
input clk, rst_n, in_item_valid, in_coin_valid;
input [5:0] in_coin;
input in_rtn_coin;
input [2:0] in_buy_item;
input [4:0] in_item_price;
//OUTPUT
output logic [8:0] out_monitor;
output logic out_valid;
output logic [3:0] out_consumer;
output logic [5:0] out_sell_num;

//---------------------------------------------------------------------
//  State Parameter
//---------------------------------------------------------------------
parameter SETUP = 2'b00;
parameter IN_COIN = 2'b01;
parameter RTN_COIN_OR_BUY_ITEM = 2'b10;
parameter OUTPUT = 2'b11;

//---------------------------------------------------------------------
//  Logic Declaration
//---------------------------------------------------------------------
logic [3-1:0] cnt, cnt_nxt;
logic [5-1:0] Price [6-1:0], Item;
logic [5-1:0] Price_nxt [6-1:0];
logic [6-1:0] Sold [6-1:0];
logic [6-1:0] Sold_nxt [6-1:0], Sold_Now;
logic [9-1:0] out_monitor_nxt, Remainder, Remainder_reg, Subtract;
logic [4-1:0] Coin50, Coin50_reg;
logic [3-1:0] Sold_Item, Coin1, Coin1_reg;
logic [2-1:0] Coin20, Coin20_reg, next, state, state_nxt;
logic Coin5, Coin5_reg, Coin10, Coin10_reg, Success, Success_reg;
//---------------------------------------------------------------------
//  Your design(Using FSM)                            
//---------------------------------------------------------------------

// State
always_comb begin
    if(in_rtn_coin == 1 || !(in_buy_item == 0)) next = 0;
    else if(in_item_valid == 1) next = 1;
    else next = 2;
end
always_comb begin
    case(state)
        SETUP: state_nxt = (cnt == 0) ? IN_COIN : SETUP;
        IN_COIN: state_nxt = (next == 0) ? RTN_COIN_OR_BUY_ITEM : (next == 1) ? SETUP : IN_COIN;
        default: state_nxt = (cnt == 0) ? IN_COIN : OUTPUT;
    endcase
end

// SETUP
assign cnt_nxt = (state == SETUP || state == OUTPUT) ? cnt - 1 : 5;
always_comb begin
    if(state_nxt == SETUP) begin
        case(cnt_nxt)
            5: Price_nxt = {in_item_price, 0, 0, 0, 0, 0};
            4: Price_nxt = {Price[5], in_item_price, 0, 0, 0, 0};
            3: Price_nxt = {Price[5], Price[4], in_item_price, 0, 0, 0};
            2: Price_nxt = {Price[5], Price[4], Price[3], in_item_price, 0, 0};
            1: Price_nxt = {Price[5], Price[4], Price[3], Price[2], in_item_price, 0};
            0: Price_nxt = {Price[5], Price[4], Price[3], Price[2], Price[1], in_item_price};
            default: Price_nxt = Price;
        endcase
    end
    else begin
        Price_nxt = Price;
    end
end

// IN_COIN

always_comb begin
    case(state_nxt)
        RTN_COIN_OR_BUY_ITEM: Success_reg = (out_monitor >= Item) ? 1 : 0;
        OUTPUT: Success_reg = Success;
        default: Success_reg = 0;
    endcase
end

assign out_monitor_nxt = (Success_reg == 1) ? 0 : out_monitor + in_coin;
// OUTPUT
// RTN_COIN 2^9 = 512

// Calculate Remainding Money
// And update Remaindersell
assign Remainder_reg = (state_nxt == RTN_COIN_OR_BUY_ITEM) ? out_monitor - Item : Remainder - Subtract;

always_comb begin
    case(in_buy_item)
        1: Item = Price[5];
        2: Item = Price[4];
        3: Item = Price[3];
        4: Item = Price[2];
        5: Item = Price[1];
        6: Item = Price[0];
        default: Item = 0;
    endcase
end
always_comb begin
    case(cnt_nxt)
        5: Subtract = 50 * Coin50_reg;
        4: Subtract = (Coin20_reg == 2) ? 40 : (Coin20_reg == 1) ? 20 : 0;
        3: Subtract = (Coin10_reg) ? 10 : 0;
        2: Subtract = (Coin5_reg) ? 5 : 0;
        1: Subtract = Coin1_reg;
        default: Subtract = 0;
    endcase
end
always_comb begin
    if(Remainder >= 500) begin
        Coin50_reg = 10;
    end
    else if(Remainder >= 450) begin
        Coin50_reg = 9;
    end
    else if(Remainder >= 400) begin
        Coin50_reg = 8;
    end
    else if(Remainder >= 350) begin
        Coin50_reg = 7;
    end
    else if(Remainder >= 300) begin
        Coin50_reg = 6;
    end
    else if(Remainder >= 250) begin
        Coin50_reg = 5;
    end
    else if(Remainder >= 200) begin
        Coin50_reg = 4;
    end
    else if(Remainder >= 150) begin
        Coin50_reg = 3;
    end
    else if(Remainder >= 100) begin
        Coin50_reg = 2;
    end
    else if(Remainder >= 50) begin
        Coin50_reg = 1;
    end
    else begin
        Coin50_reg = 0;
    end
end
assign Coin20_reg = (Remainder >= 40) ? 2 : (Remainder >= 20) ? 1 : 0;
assign Coin10_reg = (Remainder >= 10) ? 1 : 0;
assign Coin5_reg = (Remainder >= 5) ? 1 : 0;
assign Coin1_reg = Remainder;
// BUY_ITEM
always_comb begin
    if(Success) begin
        case (cnt_nxt)
            5: out_consumer = Sold_Item;
            4: out_consumer = Coin50;
            3: out_consumer = Coin20;
            2: out_consumer = Coin10;
            1: out_consumer = Coin5;
            0: out_consumer = Coin1;
            default: out_consumer = 0;
        endcase
    end
    else begin
        out_consumer = 0;
    end
end
assign out_sell_num = Sold[cnt_nxt];
assign out_valid = (state_nxt == OUTPUT) ? 1 : 0;

always_comb begin
    case(in_buy_item)
        1: Sold_Now = Sold[5] + 1;
        2: Sold_Now = Sold[4] + 1;
        3: Sold_Now = Sold[3] + 1;
        4: Sold_Now = Sold[2] + 1; 
        5: Sold_Now = Sold[1] + 1;
        6: Sold_Now = Sold[0] + 1;
        default: Sold_Now = 0;
    endcase
end
always_comb begin
    if(state_nxt == SETUP) begin
        Sold_nxt = {0, 0, 0, 0, 0, 0};
    end
    else if(state_nxt == RTN_COIN_OR_BUY_ITEM && Success_reg) begin
        case(in_buy_item)
            1: Sold_nxt = {Sold_Now, Sold[4], Sold[3], Sold[2], Sold[1], Sold[0]};
            2: Sold_nxt = {Sold[5], Sold_Now, Sold[3], Sold[2], Sold[1], Sold[0]};
            3: Sold_nxt = {Sold[5], Sold[4], Sold_Now, Sold[2], Sold[1], Sold[0]};
            4: Sold_nxt = {Sold[5], Sold[4], Sold[3], Sold_Now, Sold[1], Sold[0]};
            5: Sold_nxt = {Sold[5], Sold[4], Sold[3], Sold[2], Sold_Now, Sold[0]};
            6: Sold_nxt = {Sold[5], Sold[4], Sold[3], Sold[2], Sold[1], Sold_Now};
            default: Sold_nxt = Sold;
        endcase
    end
    else begin
        Sold_nxt = Sold;
    end
end

// Sequential Logic
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 6;
        state <= IN_COIN;
        out_monitor <= 0;
        Price <= {0, 0, 0, 0, 0, 0};
        Sold <= {0, 0, 0, 0, 0, 0};
        Coin50 <= 0;
        Coin20 <= 0;
        Coin10 <= 0;
        Coin5 <= 0;
        Coin1 <= 0;
        Sold_Item <= 0;
        Success <= 0;
        Remainder <= 0;
    end
    else begin
        cnt <= cnt_nxt;
        state <= state_nxt;
        out_monitor <= out_monitor_nxt;
        Price <= Price_nxt;
        Sold <= Sold_nxt;
        Coin50 <= Coin50_reg;
        Coin20 <= Coin20_reg;
        Coin10 <= Coin10_reg;
        Coin5 <= Coin5_reg;
        Coin1 <= Coin1_reg;
        Sold_Item <= in_buy_item;
        Success <= Success_reg;
        Remainder <= Remainder_reg;
    end
end

endmodule

