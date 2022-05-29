`ifdef RTL
	`timescale 1ns/10ps
	`include "VM.sv"  
	`define CYCLE_TIME 5.0
`endif
`ifdef GATE
	`timescale 1ns/10ps
	`include "VM_SYN.v"
	`define CYCLE_TIME 5.0
`endif


module PATTERN(
    //OUTPUT 
    clk,
    rst_n,
    in_item_valid,
    in_coin_valid,
    in_coin,
    in_rtn_coin,
    in_buy_item,
    in_item_price,
    //inPUT
    out_monitor,
    out_valid,
    out_consumer,
	out_sell_num
);
//================================================================
// wire & registers 
//================================================================
output logic clk;
output logic rst_n;
output logic in_item_valid;
output logic in_coin_valid;
output logic [5:0] in_coin;
output logic in_rtn_coin;
output logic [2:0] in_buy_item;
output logic [4:0] in_item_price;
input [8:0] out_monitor;
input out_valid;
input [3:0] out_consumer;
input [5:0] out_sell_num;

// golden
logic [2:0] golden_coin_out_1;
logic golden_coin_out_5;   
logic golden_coin_out_10;   
logic [1:0] golden_coin_out_20;
logic [3:0] golden_coin_out_50;
logic [1:0] golden_item_0_led, golden_item_1_led, golden_item_2_led, golden_item_3_led, golden_item_4_led, golden_item_5_led, golden_item_6_led;
logic [2:0] golden_item_out;
int in_coinside,in_coinside_temp;
logic [4:0] items_price[5:0];
int golden_out_sell_num[5:0]; 

//================================================================
// parameters & integer
//================================================================
integer PATNUM=1000;
integer i;
integer patcount;
integer lat;
integer CYCLE = `CYCLE_TIME; 

always	#(CYCLE/2.0) clk = ~clk;

bit return_money;
int seed = 88;
int insert_num;
int i0_num,i1_num,i2_num,i3_num,i4_num,i5_num,i6_num;
int in_coin_choose;

logic golden;

logic [2:0] buy_item;

bit forbidden_buy;
int temp;
int y,total_latency; 
int mode;
int gap;
//integer input_file,output_file;
//integer count;
//integer check_count;
//================================================================
// initial
//================================================================
initial begin
    rst_n = 1'b1;
    in_coin_valid = 0;
    in_rtn_coin = 0;
    in_buy_item = 3'd0;
    in_item_price = 5'b0;
    in_item_valid = 0;
    in_coin = 6'b0;
    total_latency = 0;
    force clk = 0;
	reset_task;
    
	for(patcount = 0 ; patcount < PATNUM ; patcount = patcount + 1) begin
		golden_coin_out_1=0;
		golden_coin_out_5=0;
		golden_coin_out_10=0;
		golden_coin_out_20=0;
		golden_coin_out_50=0;
		mode=$random(seed)%'d30;
		if(patcount==0) begin
			task_in_item;
			gap=1+$random(seed)%'d4;
			repeat(gap)@(negedge clk);
			task_in_coin;
			task_choice_buy;
			wait_OUT_VALID;
			check_ans;
		end else if(patcount<62) begin
			repeat(4)@(negedge clk);
			task_in_coin;
			task_choice_buy;
			wait_OUT_VALID;	
			check_ans;		
		end else if(patcount==62) begin
			task_in_item;
			gap=1+$random(seed)%'d4;
			repeat(gap)@(negedge clk);
			task_in_coin;
			task_choice_buy;
			wait_OUT_VALID;
			check_ans;
		end	else begin
			if( (i3_num == 'd1) || (i4_num == 'd1) || (i5_num == 'd1) || (i6_num == 'd1)) begin
			task_in_item;
			gap=1+$random(seed)%'d4;
			repeat(gap)@(negedge clk);
			task_in_coin;
			task_choice_buy;
			wait_OUT_VALID;
			check_ans;			
			end else if(mode>28 || in_coinside>='d500) begin//replenish and price in
					task_in_item;
					gap=1+$random(seed)%'d4;
					repeat(gap)@(negedge clk);				  
					task_in_coin;
					task_choice_buy;
					wait_OUT_VALID;	
					check_ans;				   
			end else begin //in_coin
				repeat(4)@(negedge clk);
					task_in_coin;
					task_choice_buy;
					wait_OUT_VALID;	
					check_ans;						
			end
		end
		total_latency=total_latency+lat; 
	end
    YOU_PASS_task;
end
//================================================================
// task
//================================================================

task wait_OUT_VALID ; begin
	lat = 0;
	while(out_valid==0)begin
		lat = lat+1;
		if(lat == 100) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                        FAIL!                                                               ");
			$display ("                                                     The execution latency are over 100  cycles                                            ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
		end
	@(negedge clk);
	end
	
end endtask


task reset_task ; begin
  #( 0.5 ); rst_n = 0;

	#(20.0);

if( ( out_monitor !== 0 ) || (out_valid !==0) || ( out_consumer !== 0 )|| ( out_sell_num !== 0 ) )
      begin
       $display("----------------------------" );
       $display("            FAIL            " );
	   $display(" out_consumer should be 0 after rst  " );
       $display("----------------------------" );
	   $finish ;
	  end 
	
	#(10) rst_n = 1 ;
    #(3) release clk;
end endtask

task check_ans; begin
	y=0;
	while(out_valid)
	begin
	    //check_out_mointor;
		if(y>=6)
			begin
			    fail;
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display ("                                                                        FAIL!                                                               ");
				$display ("                                                           Outvalid is more than 7 cycles                                                   ");
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				repeat(6) @(negedge clk);
				$finish;
			end
        if(y == 0) begin
		if(out_consumer!==golden_item_out || out_sell_num !== golden_out_sell_num[0] )
				begin
					fail;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					$display ("                                                                        FAIL!                                                               ");
					$display ("                                                                   PATTERN NO.%4d                                                           ",patcount);
					$display ("                                                     Ans(item_out): %d,  Your output : %d  at %8t                                              ",golden_item_out,out_consumer,$time);
					$display ("                                                     Ans(out_sell_num[0]): %d,  Your output : %d  at %8t                                       ",golden_out_sell_num[0],out_sell_num,$time);
					//debug_display_task;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					repeat(6) @(negedge clk);
					$finish;
				end
        end
        if(y == 5) begin
		if(out_consumer!==golden_coin_out_1|| out_sell_num !== golden_out_sell_num[5])
				begin
					fail;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					$display ("                                                                        FAIL!                                                               ");
					$display ("                                                                   PATTERN NO.%4d                                                           ",patcount);
					$display ("                                                     Ans(coin_out_1): %d,  Your output : %d  at %8t                                              ",golden_coin_out_1,out_consumer,$time);					
					$display ("                                                     Ans(out_sell_num[5]): %d,  Your output : %d  at %8t                                       ",golden_out_sell_num[5],out_sell_num,$time);
					//debug_display_task;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					repeat(6) @(negedge clk);
					$finish;
				end
        end
        if(y== 4) begin
		if(out_consumer!==golden_coin_out_5|| out_sell_num !== golden_out_sell_num[4])
				begin
					fail;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					$display ("                                                                        FAIL!                                                               ");
					$display ("                                                                   PATTERN NO.%4d                                                           ",patcount);
					$display ("                                                     Ans(coin_out_5): %d,  Your output : %d  at %8t                                              ",golden_coin_out_5,out_consumer,$time);
					$display ("                                                     Ans(out_sell_num[4]): %d,  Your output : %d  at %8t                                       ",golden_out_sell_num[4],out_sell_num,$time);
					
					//debug_display_task;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					repeat(6) @(negedge clk);
					$finish;
				end
                end
                if(y == 3) begin              
		if(out_consumer!==golden_coin_out_10|| out_sell_num !== golden_out_sell_num[3])
				begin
					fail;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					$display ("                                                                        FAIL!                                                               ");
					$display ("                                                                   PATTERN NO.%4d                                                           ",patcount);
					$display ("                                                     Ans(coin_out_10): %d,  Your output : %d  at %8t                                              ",golden_coin_out_10,out_consumer,$time);
					$display ("                                                     Ans(out_sell_num[3]): %d,  Your output : %d  at %8t                                       ",golden_out_sell_num[3],out_sell_num,$time);
					
					//debug_display_task;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					repeat(6) @(negedge clk);
					$finish;
				end
                end
                if(y==2) begin
		if(out_consumer!==golden_coin_out_20|| out_sell_num !== golden_out_sell_num[2])
				begin
					fail;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					$display ("                                                                        FAIL!                                                               ");
					$display ("                                                                   PATTERN NO.%4d                                                           ",patcount);
					$display ("                                                     Ans(coin_out_20): %d,  Your output : %d  at %8t                                              ",golden_coin_out_20,out_consumer,$time);
					$display ("                                                     Ans(out_sell_num[2]): %d,  Your output : %d  at %8t                                       ",golden_out_sell_num[2],out_sell_num,$time);
					
					//debug_display_task;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					repeat(6) @(negedge clk);
					$finish;
				end
                end
                if(y==1) begin
		if(out_consumer!==golden_coin_out_50|| out_sell_num !== golden_out_sell_num[1])
				begin
					fail;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					$display ("                                                                        FAIL!                                                               ");
					$display ("                                                                   PATTERN NO.%4d                                                           ",patcount);
					$display ("                                                     Ans(coin_out_50): %d,  Your output : %d  at %8t                                              ",golden_coin_out_50,out_consumer,$time);
					$display ("                                                     Ans(out_sell_num[1]): %d,  Your output : %d  at %8t                                       ",golden_out_sell_num[1],out_sell_num,$time);
					
					//debug_display_task;
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					repeat(6) @(negedge clk);
					$finish;
				end				
                end
		repeat(1)@(negedge clk);	
		y=y+1;
        
	end		
	
	if(y < 5)
		begin
			fail;
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                                        FAIL!                                                               ");
			$display ("                                                         outvalid is less than 6 cycle                                                     ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(6) @(negedge clk);
			$finish;
		end		
end endtask

task task_in_item; begin
    @(negedge clk)
    in_item_valid = 1;


    for(i=0; i < 6; i=i+1) begin
		items_price[i] = 1+$random(seed)%32;
		golden_out_sell_num[i] = 0;
		in_item_price = items_price[i];
        @(negedge clk);
    end
    in_item_price = 0;
    in_item_valid = 0;
end endtask

task debug_display_task; begin
	// for (i=0;i<6;i=i+1)
	// 	$display ("                                                 Ans(golden_out_sell_num[%d]): %d                                                                   ",i,golden_out_sell_num[i]);
	$display ("                                                     Ans(golden_item_out): %d                                                                   ",golden_item_out);
	$display ("                                                     Ans(golden_coin_out_50): %d                                                                   ",golden_coin_out_50);
	$display ("                                                     Ans(golden_coin_out_20): %d                                                                   ",golden_coin_out_20);
	$display ("                                                     Ans(golden_coin_out_10): %d                                                                   ",golden_coin_out_10);
	$display ("                                                     Ans(golden_coin_out_5): %d                                                                   ",golden_coin_out_5);
	$display ("                                                     Ans(golden_coin_out_1): %d                                                                   ",golden_coin_out_1);
end endtask


task task_in_coin; begin 
    in_coin_valid = 1;
	if(patcount==0) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd1 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd2 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd3 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd4 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd5 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd6 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd7 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd8 : begin in_coin = 'd20; in_coinside=in_coinside+20; end // 1 6 16 36 86 87 92 102 122
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end
	
	else if(patcount==1) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd1 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd2 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd3 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd4 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd5 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd6 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd7 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd8 : begin in_coin = 'd10; in_coinside=in_coinside+10; end //50 51 56 66 86 136 137 142
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end
	
	else if(patcount==2) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd1 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd2 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd3 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd4 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd5 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd6 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd7 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd8 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end //20 70 71 76 86 106 126 176 177 182
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end
	
	else if(patcount==3) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd10; in_coinside=in_coinside+10; end 
			'd1 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd2 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd3 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd4 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd5 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd6 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd7 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd8 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end //10 30 80 81 86 96 116 166 167
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end 
	
	else if(patcount==4) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd1 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd2 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd3 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd4 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd5 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd6 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd7 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd8 : begin in_coin = 'd50; in_coinside=in_coinside+50; end //5 15 35 85 86 91 101 121 171 
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end
	
	else if(patcount==5) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd1 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd2 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd3 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd4 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd5 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd6 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd7 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd8 : begin in_coin = 'd20; in_coinside=in_coinside+20; end //1 6 16 36 86 87 92 102 132
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end else if(patcount==6) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd1 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd2 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd3 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd4 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd5 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd6 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd7 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd8 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end else if(patcount==7) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd1 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd2 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd3 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd4 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd5 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd6 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd7 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd8 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end
	
	else if(patcount==8) begin
		insert_num='d9;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd1 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd2 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd3 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			'd4 : begin in_coin = 'd5;  in_coinside=in_coinside+5; end
			'd5 : begin in_coin = 'd10; in_coinside=in_coinside+10; end
			'd6 : begin in_coin = 'd20; in_coinside=in_coinside+20; end
			'd7 : begin in_coin = 'd50; in_coinside=in_coinside+50; end
			'd8 : begin in_coin = 'd1;  in_coinside=in_coinside+1; end
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end	 else if(patcount >=40 && patcount <=44) begin
		in_coin = 'd50; 
		in_coinside=in_coinside+50;
		@(negedge clk);

		//check_out_mointor;
		in_coin=0;
	end else if(patcount==45 )
	begin
		insert_num='d3;
		for (i=0;i<insert_num;i=i+1)
		begin
			case(i)
			'd0 : begin in_coin = 'd1; in_coinside=in_coinside+1; end
			'd1 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd2 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end else if(patcount>=46 && patcount <=60 ) begin
		insert_num='d8;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd1; in_coinside=in_coinside+1; end
			'd1 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd2 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd3 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd4 : begin in_coin = 'd1; in_coinside=in_coinside+1; end
			'd5 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd6 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd7 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			endcase
			@(negedge clk);
		end
		in_coin=0;	
	end else if(patcount==61 ) begin
		insert_num='d5;
		for (i=0;i<insert_num;i=i+1) begin
			case(i)
			'd0 : begin in_coin = 'd1; in_coinside=in_coinside+1; end
			'd1 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd2 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd3 : begin in_coin = 'd5; in_coinside=in_coinside+5; end
			'd4 : begin in_coin = 'd1; in_coinside=in_coinside+1; end
			endcase
			@(negedge clk);

			//check_out_mointor;
		end
		in_coin=0;	
	end else begin
		insert_num=1+$random(seed)%'d9;	
		for(i=0;i<insert_num;i=i+1)	
		begin
			in_coin_choose = 1+$random(seed)%'d5;
            case(in_coin_choose)
				1:in_coin = 'd1;
				2:in_coin = 'd5;
				3:in_coin = 'd10;
				4:in_coin = 'd20;
				5:in_coin = 'd50;
            endcase
            
			case(in_coin_choose)
				1:in_coinside=in_coinside+1;
				2:in_coinside=in_coinside+5;
				3:in_coinside=in_coinside+10;	
				4:in_coinside=in_coinside+20;
				5:in_coinside=in_coinside+50;		   
            endcase
	
		@(negedge clk);	  
		end
		in_coin=0;	
	end
    in_coin_valid = 0;
	$write ( "PATTERN NO. = %4d ,in_coinside = %d ,",patcount,in_coinside );
end endtask  




task task_choice_buy; begin
    in_coinside_temp = in_coinside;
    in_coinside=0;
	if(patcount==0 || patcount==2 || patcount==4 || patcount==6 || patcount==8)
	return_money = 1;
	else if(patcount==1 || patcount==3 || patcount==5 || patcount==7 || patcount==9) begin
	in_buy_item = 'd1;
	return_money = 0;
	end
	else if(patcount==10 || patcount==12 || patcount==14 || patcount==16 || patcount==18) begin
	in_buy_item = 'd2;
	return_money = 0;
	end
	else if(patcount==11 || patcount==13 || patcount==15 || patcount==17 || patcount==19) begin
	in_buy_item = 'd3;
	return_money = 0;
	end	
	else if(patcount==20 || patcount==22 || patcount==24 || patcount==26 || patcount==28) begin
	in_buy_item = 'd4;
	return_money = 0;
	end		
	else if(patcount==21 || patcount==23 || patcount==25 || patcount==27 || patcount==29) begin
	in_buy_item = 'd5;
	return_money = 0;
	end	
	else if(patcount==30 || patcount==32 || patcount==34 || patcount==36 || patcount==38) begin
	in_buy_item = 'd6;
	return_money = 0;
	end	
	else if(patcount==31 || patcount==33 || patcount==35 || patcount==37 || patcount==39) begin
	in_buy_item = 'd6;
	return_money = 0;
	end	
	else if(patcount==40 || patcount==41 || patcount==42 || patcount==43 || patcount==44 ) begin
	in_buy_item = 'd1;
	return_money = 0;
	end
	else if(patcount >=45 && patcount <=61)
	begin
	in_buy_item ='d1;
	return_money = 0;
	end
	
	else return_money=$random(seed)%'d2;
	
	if(return_money==1) 
	begin 
		in_rtn_coin=1'b1;
        in_coinside=0; 
		@(negedge clk);
		in_rtn_coin=1'b0;
		golden_item_out = 0;
		task_money_out;	   
		$write ("\n");
	end
	
	else begin 
		if(patcount>61) in_buy_item = 1+$random(seed)%'d6;
		buy_item = in_buy_item;	   
		golden_item_out = in_buy_item;	
		forbidden_buy=0;
		if(in_coinside_temp < items_price[buy_item-1])   begin
			in_coinside = in_coinside_temp;
			forbidden_buy=1;
		end		   
	
		if(forbidden_buy==1) begin 
			golden_item_out=0;
		end	else begin	
			golden_out_sell_num[buy_item-1] = golden_out_sell_num[buy_item-1] +1 ;
			task_money_out;
		end		  
		$write ( "golden_out_sell_num = [%d,%d,%d,%d,%d,%d]\n",golden_out_sell_num[0],golden_out_sell_num[1],golden_out_sell_num[2],golden_out_sell_num[3],golden_out_sell_num[4],golden_out_sell_num[5] );
		@(negedge clk);
		in_buy_item=0;	 
	 end
end endtask


task task_money_out; begin
       if(return_money==1) 
	   begin 
		  golden_coin_out_50=in_coinside_temp/50;
		  temp=in_coinside_temp%50;
		  golden_coin_out_20=temp/20;
		  temp=temp%20;
		  golden_coin_out_10=temp/10;
		  temp=temp%10;
		  golden_coin_out_5=temp/5;
		  temp=temp%5;
		  golden_coin_out_1=temp;

	   end
	   else begin 
		  in_coinside_temp=in_coinside_temp-items_price[buy_item-1];
		  golden_coin_out_50=in_coinside_temp/50;
		  temp=in_coinside_temp%50;
		  golden_coin_out_20=temp/20;
		  temp=temp%20;
		  golden_coin_out_10=temp/10;
		  temp=temp%10;
		  golden_coin_out_5=temp/5;
		  temp=temp%5;
		  golden_coin_out_1=temp;
		   
	   end
end endtask
/*
task check_out_mointor; begin
   if(out_monitor!==in_coinside) begin
                     $display ("--------------------------------------------------------------------------------------------------------------------------------------------");                                                                      
                     $display ("                                                           out_monitor Fail!                                                                ");
                     $display ("                                                     Your : %9d, Correct : %9d                                                            ",out_monitor,in_coinside);
                     $display ("--------------------------------------------------------------------------------------------------------------------------------------------"); 
					repeat(6) @(negedge clk);
					$finish;    
   end
end endtask
*/

always @(negedge clk) begin
   if(out_monitor!==in_coinside) begin
                     $display ("--------------------------------------------------------------------------------------------------------------------------------------------");                                                                      
                     $display ("                                                           out_monitor Fail!                                                                ");
                     $display ("                                                     Your : %9d, Correct : %9d  at %8t  * 10ps                                                 ",out_monitor,in_coinside,$time);
                     $display ("--------------------------------------------------------------------------------------------------------------------------------------------"); 
					repeat(2) @(negedge clk);
					$finish;    
   end
end
 
task YOU_PASS_task;begin
$display("\033[37m                                                                                                                                          ");        
$display("\033[37m                                                                                \033[32m      :BBQvi.                                              ");        
$display("\033[37m                                                              .i7ssrvs7         \033[32m     BBBBBBBBQi                                           ");        
$display("\033[37m                        .:r7rrrr:::.        .::::::...   .i7vr:.      .B:       \033[32m    :BBBP :7BBBB.                                         ");        
$display("\033[37m                      .Kv.........:rrvYr7v7rr:.....:rrirJr.   .rgBBBBg  Bi      \033[32m    BBBB     BBBB                                         ");        
$display("\033[37m                     7Q  :rubEPUri:.       ..:irrii:..    :bBBBBBBBBBBB  B      \033[32m   iBBBv     BBBB       vBr                               ");        
$display("\033[37m                    7B  BBBBBBBBBBBBBBB::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB :R     \033[32m   BBBBBKrirBBBB.     :BBBBBB:                            ");        
$display("\033[37m                   Jd .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Bi    \033[32m  rBBBBBBBBBBBR.    .BBBM:BBB                             ");        
$display("\033[37m                  uZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B    \033[32m  BBBB   .::.      EBBBi :BBU                             ");        
$display("\033[37m                 7B .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B    \033[32m MBBBr           vBBBu   BBB.                             ");        
$display("\033[37m                .B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: JJ   \033[32m i7PB          iBBBBB.  iBBB                              ");        
$display("\033[37m                B. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  Lu             \033[32m  vBBBBPBBBBPBBB7       .7QBB5i                ");        
$display("\033[37m               Y1 KBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi XBBBBBBBi :B            \033[32m :RBBB.  .rBBBBB.      rBBBBBBBB7              ");        
$display("\033[37m              :B .BBBBBBBBBBBBBsRBBBBBBBBBBBrQBBBBB. UBBBRrBBBBBBr 1BBBBBBBBB  B.          \033[32m    .       BBBB       BBBB  :BBBB             ");        
$display("\033[37m              Bi BBBBBBBBBBBBBi :BBBBBBBBBBE .BBK.  .  .   QBBBBBBBBBBBBBBBBBB  Bi         \033[32m           rBBBr       BBBB    BBBU            ");        
$display("\033[37m             .B .BBBBBBBBBBBBBBQBBBBBBBBBBBB       \033[38;2;242;172;172mBBv \033[37m.LBBBBBBBBBBBBBBBBBBBBBB. B7.:ii:   \033[32m           vBBB        .BBBB   :7i.            ");        
$display("\033[37m            .B  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBbYQB. \033[38;2;242;172;172mBB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBB  Jr:::rK7 \033[32m             .7  BBB7   iBBBg                  ");        
$display("\033[37m           7M  PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBB..i   .   v1                  \033[32mdBBB.   5BBBr                 ");        
$display("\033[37m          sZ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBB iD2BBQL.                 \033[32m ZBBBr  EBBBv     YBBBBQi     ");        
$display("\033[37m  .7YYUSIX5 .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBB. \033[37mBBBBBBBBBBBBBBBBBBBBBBBBY.:.      :B                 \033[32m  iBBBBBBBBD     BBBBBBBBB.   ");        
$display("\033[37m LB.        ..BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. \033[38;2;242;172;172mBB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBMBBB. BP17si                 \033[32m    :LBBBr      vBBBi  5BBB   ");        
$display("\033[37m  KvJPBBB :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mZB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBsiJr .i7ssr:                \033[32m          ...   :BBB:   BBBu  ");        
$display("\033[37m i7ii:.   ::BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBj \033[38;2;242;172;172muBi \033[37mQBBBBBBBBBBBBBBBBBBBBBBBBi.ir      iB                \033[32m         .BBBi   BBBB   iMBu  ");        
$display("\033[37mDB    .  vBdBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBg \033[38;2;242;172;172m7Bi \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB rBrXPv.                \033[32m          BBBX   :BBBr        ");        
$display("\033[37m :vQBBB. BQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQ \033[38;2;242;172;172miB: \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .L:ii::irrrrrrrr7jIr   \033[32m          .BBBv  :BBBQ        ");        
$display("\033[37m :7:.   .. 5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mBr \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBB:            ..... ..YB. \033[32m           .BBBBBBBBB:        ");        
$display("\033[37mBU  .:. BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  \033[38;2;242;172;172mB7 \033[37mgBBBBBBBBBBBBBBBBBBBBBBBBBB. gBBBBBBBBBBBBBBBBBB. BL \033[32m             rBBBBB1.         ");        
$display("\033[37m rY7iB: BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: \033[38;2;242;172;172mB7 \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBB. QBBBBBBBBBBBBBBBBBi  v5                                ");        
$display("\033[37m     us EBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB \033[38;2;242;172;172mIr \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBgu7i.:BBBBBBBr Bu                                 ");        
$display("\033[37m      B  7BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.\033[38;2;242;172;172m:i \033[37mBBBBBBBBBBBBBBBBBBBBBBBBBBBv:.  .. :::  .rr    rB                                  ");        
$display("\033[37m      us  .BBBBBBBBBBBBBQLXBBBBBBBBBBBBBBBBBBBBBBBBq  .BBBBBBBBBBBBBBBBBBBBBBBBBv  :iJ7vri:::1Jr..isJYr                                   ");        
$display("\033[37m      B  BBBBBBB  MBBBM      qBBBBBBBBBBBBBBBBBBBBBB: BBBBBBBBBBBBBBBBBBBBBBBBBB  B:           iir:                                       ");        
$display("\033[37m     iB iBBBBBBBL       BBBP. :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  B.                                                       ");        
$display("\033[37m     P: BBBBBBBBBBB5v7gBBBBBB  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: Br                                                        ");        
$display("\033[37m     B  BBBs 7BBBBBBBBBBBBBB7 :BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                         ");        
$display("\033[37m    .B :BBBB.  EBBBBBQBBBBBJ .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB. B.                                                         ");        
$display("\033[37m    ij qBBBBBg          ..  .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB .B                                                          ");        
$display("\033[37m    UY QBBBBBBBBSUSPDQL...iBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBK EL                                                          ");        
$display("\033[37m    B7 BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB: B:                                                          ");        
$display("\033[37m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBYrBB vBBBBBBBBBBBBBBBBBBBBBBBB. Ls                                                          ");        
$display("\033[37m    B  BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBi_  /UBBBBBBBBBBBBBBBBBBBBBBBBB. :B:                                                        ");        
$display("\033[37m   rM .BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB  ..IBBBBBBBBBBBBBBBBQBBBBBBBBBB  B                                                        ");        
$display("\033[37m   B  BBBBBBBBBdZBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBPBBBBBBBBBBBBEji:..     sBBBBBBBr Br                                                       ");        
$display("\033[37m  7B 7BBBBBBBr     .:vXQBBBBBBBBBBBBBBBBBBBBBBBBBQqui::..  ...i:i7777vi  BBBBBBr Bi                                                       ");        
$display("\033[37m  Ki BBBBBBB  rY7vr:i....  .............:.....  ...:rii7vrr7r:..      7B  BBBBB  Bi                                                       ");        
$display("\033[37m  B. BBBBBB  B:    .::ir77rrYLvvriiiiiiirvvY7rr77ri:..                 bU  iQBB:..rI                                                      ");        
$display("\033[37m.S: 7BBBBP  B.                                                          vI7.  .:.  B.                                                     ");        
$display("\033[37mB: ir:.   :B.                                                             :rvsUjUgU.                                                      ");        
$display("\033[37mrMvrrirJKur                                                                                                                               \033[m");
$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                						             ");
$display ("                                           You have passed all patterns!          						             ");
$display ("                                                     Your total cycle:%d !                                                          ",total_latency);
$display ("                                                     Your total latency:%d NS!                                                          ",total_latency* CYCLE);
$display ("----------------------------------------------------------------------------------------------------------------------");

$finish;	
end endtask


task fail; begin
$display("\033[38;2;252;238;238m                                                                                                                                           ");      
$display("\033[38;2;252;238;238m                                                                                                :L777777v7.                                ");
$display("\033[31m  i:..::::::i.      :::::         ::::    .:::.       \033[38;2;252;238;238m                                       .vYr::::::::i7Lvi                             ");
$display("\033[31m  BBBBBBBBBBBi     iBBBBBL       .BBBB    7BBB7       \033[38;2;252;238;238m                                      JL..\033[38;2;252;172;172m:r777v777i::\033[38;2;252;238;238m.ijL                           ");
$display("\033[31m  BBBB.::::ir.     BBB:BBB.      .BBBv    iBBB:       \033[38;2;252;238;238m                                    :K: \033[38;2;252;172;172miv777rrrrr777v7:.\033[38;2;252;238;238m:J7                         ");
$display("\033[31m  BBBQ            :BBY iBB7       BBB7    :BBB:       \033[38;2;252;238;238m                                   :d \033[38;2;252;172;172m.L7rrrrrrrrrrrrr77v: \033[38;2;252;238;238miI.                       ");
$display("\033[31m  BBBB            BBB. .BBB.      BBB7    :BBB:       \033[38;2;252;238;238m                                  .B \033[38;2;252;172;172m.L7rrrrrrrrrrrrrrrrr7v..\033[38;2;252;238;238mBr                      ");
$display("\033[31m  BBBB:r7vvj:    :BBB   gBBs      BBB7    :BBB:       \033[38;2;252;238;238m                                  S:\033[38;2;252;172;172m v7rrrrrrrrrrrrrrrrrrr7v. \033[38;2;252;238;238mB:                     ");
$display("\033[31m  BBBBBBBBBB7    BBB:   .BBB.     BBB7    :BBB:       \033[38;2;252;238;238m                                 .D \033[38;2;252;172;172mi7rrrrrrr777rrrrrrrrrrr7v. \033[38;2;252;238;238mB.                    ");
$display("\033[31m  BBBB    ..    iBBBBBBBBBBBP     BBB7    :BBB:       \033[38;2;252;238;238m                                 rv\033[38;2;252;172;172m v7rrrrrr7rirv7rrrrrrrrrr7v \033[38;2;252;238;238m:I                    ");
$display("\033[31m  BBBB          BBBBi7vviQBBB.    BBB7    :BBB.       \033[38;2;252;238;238m                                 2i\033[38;2;252;172;172m.v7rrrrrr7i  :v7rrrrrrrrrrvi \033[38;2;252;238;238mB:                   ");
$display("\033[31m  BBBB         rBBB.      BBBQ   .BBBv    iBBB2ir777L7\033[38;2;252;238;238m                                 2i.\033[38;2;252;172;172mv7rrrrrr7v \033[38;2;252;238;238m:..\033[38;2;252;172;172mv7rrrrrrrrr77 \033[38;2;252;238;238mrX                   ");
$display("\033[31m .BBBB        :BBBB       BBBB7  .BBBB    7BBBBBBBBBBB\033[38;2;252;238;238m                                 Yv \033[38;2;252;172;172mv7rrrrrrrv.\033[38;2;252;238;238m.B \033[38;2;252;172;172m.vrrrrrrrrrrL.\033[38;2;252;238;238m:5                   ");
$display("\033[31m  . ..        ....         ...:   ....    ..   .......\033[38;2;252;238;238m                                 .q \033[38;2;252;172;172mr7rrrrrrr7i \033[38;2;252;238;238mPv \033[38;2;252;172;172mi7rrrrrrrrrv.\033[38;2;252;238;238m:S                   ");
$display("\033[38;2;252;238;238m                                                                                        Lr \033[38;2;252;172;172m77rrrrrr77 \033[38;2;252;238;238m:B. \033[38;2;252;172;172mv7rrrrrrrrv.\033[38;2;252;238;238m:S                   ");
$display("\033[38;2;252;238;238m                                                                                         B: \033[38;2;252;172;172m7v7rrrrrv. \033[38;2;252;238;238mBY \033[38;2;252;172;172mi7rrrrrrr7v \033[38;2;252;238;238miK                   ");
$display("\033[38;2;252;238;238m                                                                              .::rriii7rir7. \033[38;2;252;172;172m.r77777vi \033[38;2;252;238;238m7B  \033[38;2;252;172;172mvrrrrrrr7r \033[38;2;252;238;238m2r                   ");
$display("\033[38;2;252;238;238m                                                                       .:rr7rri::......    .     \033[38;2;252;172;172m.:i7s \033[38;2;252;238;238m.B. \033[38;2;252;172;172mv7rrrrr7L..\033[38;2;252;238;238mB                    ");
$display("\033[38;2;252;238;238m                                                        .::7L7rriiiirr77rrrrrrrr72BBBBBBBBBBBBvi:..  \033[38;2;252;172;172m.  \033[38;2;252;238;238mBr \033[38;2;252;172;172m77rrrrrvi \033[38;2;252;238;238mKi                    ");
$display("\033[38;2;252;238;238m                                                    :rv7i::...........    .:i7BBBBQbPPPqPPPdEZQBBBBBr:.\033[38;2;252;238;238m ii \033[38;2;252;172;172mvvrrrrvr \033[38;2;252;238;238mvs                     ");
$display("\033[38;2;252;238;238m                    .S77L.                      .rvi:. ..:r7QBBBBBBBBBBBgri.    .:BBBPqqKKqqqqPPPPPEQBBBZi  \033[38;2;252;172;172m:777vi \033[38;2;252;238;238mvI                      ");
$display("\033[38;2;252;238;238m                    B: ..Jv                   isi. .:rBBBBBQZPPPPqqqPPdERBBBBBi.    :BBRKqqqqqqqqqqqqPKDDBB:  \033[38;2;252;172;172m:7. \033[38;2;252;238;238mJr                       ");
$display("\033[38;2;252;238;238m                   vv SB: iu                rL: .iBBBQEPqqPPqqqqqqqqqqqqqPPPPbQBBB:   .EBQKqqqqqqPPPqqKqPPgBB:  .B:                        ");
$display("\033[38;2;252;238;238m                  :R  BgBL..s7            rU: .qBBEKPqqqqqqqqqqqqqqqqqqqqqqqqqPPPEBBB:   EBEPPPEgQBBQEPqqqqKEBB: .s                        ");
$display("\033[38;2;252;238;238m               .U7.  iBZBBBi :ji         5r .MBQqPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPKgBB:  .BBBBBdJrrSBBQKqqqqKZB7  I:                      ");
$display("\033[38;2;252;238;238m              v2. :rBBBB: .BB:.ru7:    :5. rBQqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPPBB:  :.        .5BKqqqqqqBB. Kr                     ");
$display("\033[38;2;252;238;238m             .B .BBQBB.   .RBBr  :L77ri2  BBqPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPbBB   \033[38;2;252;172;172m.irrrrri  \033[38;2;252;238;238mQQqqqqqqKRB. 2i                    ");
$display("\033[38;2;252;238;238m              27 :BBU  rBBBdB \033[38;2;252;172;172m iri::::: \033[38;2;252;238;238m.BQKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqKRBs\033[38;2;252;172;172mirrr7777L: \033[38;2;252;238;238m7BqqqqqqqXZB. BLv772i              ");
$display("\033[38;2;252;238;238m               rY  PK  .:dPMB \033[38;2;252;172;172m.Y77777r.\033[38;2;252;238;238m:BEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPPBqi\033[38;2;252;172;172mirrrrrv: \033[38;2;252;238;238muBqqqqqqqqqgB  :.:. B:             ");
$display("\033[38;2;252;238;238m                iu 7BBi  rMgB \033[38;2;252;172;172m.vrrrrri\033[38;2;252;238;238mrBEqKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQgi\033[38;2;252;172;172mirrrrv. \033[38;2;252;238;238mQQqqqqqqqqqXBb .BBB .s:.           ");
$display("\033[38;2;252;238;238m                i7 BBdBBBPqbB \033[38;2;252;172;172m.vrrrri\033[38;2;252;238;238miDgPPbPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQDi\033[38;2;252;172;172mirr77 \033[38;2;252;238;238m:BdqqqqqqqqqqPB. rBB. .:iu7         ");
$display("\033[38;2;252;238;238m                iX.:iBRKPqKXB.\033[38;2;252;172;172m 77rrr\033[38;2;252;238;238mi7QPBBBBPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPB7i\033[38;2;252;172;172mrr7r \033[38;2;252;238;238m.vBBPPqqqqqqKqBZ  BPBgri: 1B        ");
$display("\033[38;2;252;238;238m                 ivr .BBqqKXBi \033[38;2;252;172;172mr7rri\033[38;2;252;238;238miQgQi   QZKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPEQi\033[38;2;252;172;172mirr7r.  \033[38;2;252;238;238miBBqPqqqqqqPB:.QPPRBBB LK        ");
$display("\033[38;2;252;238;238m                   :I. iBgqgBZ \033[38;2;252;172;172m:7rr\033[38;2;252;238;238miJQPB.   gRqqqqqqqqPPPPPPPPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQ7\033[38;2;252;172;172mirrr7vr.  \033[38;2;252;238;238mUBqqPPgBBQPBBKqqqKB  B         ");
$display("\033[38;2;252;238;238m                     v7 .BBR: \033[38;2;252;172;172m.r7ri\033[38;2;252;238;238miggqPBrrBBBBBBBBBBBBBBBBBBQEPPqqPPPqqqqqqqqqqqqqqqqqqqqqqqqqPgPi\033[38;2;252;172;172mirrrr7v7  \033[38;2;252;238;238mrBPBBP:.LBbPqqqqqB. u.        ");
$display("\033[38;2;252;238;238m                      .j. . \033[38;2;252;172;172m :77rr\033[38;2;252;238;238miiBPqPbBB::::::.....:::iirrSBBBBBBBQZPPPPPqqqqqqqqqqqqqqqqqqqqEQi\033[38;2;252;172;172mirrrrrr7v \033[38;2;252;238;238m.BB:     :BPqqqqqDB .B        ");
$display("\033[38;2;252;238;238m                       YL \033[38;2;252;172;172m.i77rrrr\033[38;2;252;238;238miLQPqqKQJ. \033[38;2;252;172;172m ............       \033[38;2;252;238;238m..:irBBBBBBZPPPqqqqqqqPPBBEPqqqdRr\033[38;2;252;172;172mirrrrrr7v \033[38;2;252;238;238m.B  .iBB  dQPqqqqPBi Y:       ");
$display("\033[38;2;252;238;238m                     :U:.\033[38;2;252;172;172mrv7rrrrri\033[38;2;252;238;238miPgqqqqKZB.\033[38;2;252;172;172m.v77777777777777ri::..   \033[38;2;252;238;238m  ..:rBBBBQPPqqqqPBUvBEqqqPRr\033[38;2;252;172;172mirrrrrrvi\033[38;2;252;238;238m iB:RBBbB7 :BQqPqKqBR r7       ");
$display("\033[38;2;252;238;238m                    iI.\033[38;2;252;172;172m.v7rrrrrrri\033[38;2;252;238;238midgqqqqqKB:\033[38;2;252;172;172m 77rrrrrrrrrrrrr77777777ri:..   \033[38;2;252;238;238m .:1BBBEPPB:   BbqqPQr\033[38;2;252;172;172mirrrr7vr\033[38;2;252;238;238m .BBBZPqqDB  .JBbqKPBi vi       ");
$display("\033[38;2;252;238;238m                   :B \033[38;2;252;172;172miL7rrrrrrrri\033[38;2;252;238;238mibgqqqqqqBr\033[38;2;252;172;172m r7rrrrrrrrrrrrrrrrrrrrr777777ri:.  \033[38;2;252;238;238m .iBBBBi  .BbqqdRr\033[38;2;252;172;172mirr7v7: \033[38;2;252;238;238m.Bi.dBBPqqgB:  :BPqgB  B        ");
$display("\033[38;2;252;238;238m                   .K.i\033[38;2;252;172;172mv7rrrrrrrri\033[38;2;252;238;238miZgqqqqqqEB \033[38;2;252;172;172m.vrrrrrrrrrrrrrrrrrrrrrrrrrrr777vv7i.  \033[38;2;252;238;238m :PBBBBPqqqEQ\033[38;2;252;172;172miir77:  \033[38;2;252;238;238m:BB:  .rBPqqEBB. iBZB. Rr        ");
$display("\033[38;2;252;238;238m                    iM.:\033[38;2;252;172;172mv7rrrrrrrri\033[38;2;252;238;238mUQPqqqqqPBi\033[38;2;252;172;172m i7rrrrrrrrrrrrrrrrrrrrrrrrr77777i.   \033[38;2;252;238;238m.  :BddPqqqqEg\033[38;2;252;172;172miir7. \033[38;2;252;238;238mrBBPqBBP. :BXKqgB  BBB. 2r         ");
$display("\033[38;2;252;238;238m                     :U:.\033[38;2;252;172;172miv77rrrrri\033[38;2;252;238;238mrBPqqqqqqPB: \033[38;2;252;172;172m:7777rrrrrrrrrrrrrrr777777ri.   \033[38;2;252;238;238m.:uBBBBZPqqqqqqPQL\033[38;2;252;172;172mirr77 \033[38;2;252;238;238m.BZqqPB:  qMqqPB. Yv:  Ur          ");
$display("\033[38;2;252;238;238m                       1L:.\033[38;2;252;172;172m:77v77rii\033[38;2;252;238;238mqQPqqqqqPbBi \033[38;2;252;172;172m .ir777777777777777ri:..   \033[38;2;252;238;238m.:rBBBRPPPPPqqqqqqqgQ\033[38;2;252;172;172miirr7vr \033[38;2;252;238;238m:BqXQ: .BQPZBBq ...:vv.           ");
$display("\033[38;2;252;238;238m                         LJi..\033[38;2;252;172;172m::r7rii\033[38;2;252;238;238mRgKPPPPqPqBB:.  \033[38;2;252;172;172m ............     \033[38;2;252;238;238m..:rBBBBPPqqKKKKqqqPPqPbB1\033[38;2;252;172;172mrvvvvvr  \033[38;2;252;238;238mBEEDQBBBBBRri. 7JLi              ");
$display("\033[38;2;252;238;238m                           .jL\033[38;2;252;172;172m  777rrr\033[38;2;252;238;238mBBBBBBgEPPEBBBvri:::::::::irrrbBBBBBBDPPPPqqqqqqXPPZQBBBBr\033[38;2;252;172;172m.......\033[38;2;252;238;238m.:BBBBg1ri:....:rIr                 ");
$display("\033[38;2;252;238;238m                            vI \033[38;2;252;172;172m:irrr:....\033[38;2;252;238;238m:rrEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQQBBBBBBBBBBBBBQr\033[38;2;252;172;172mi:...:.   \033[38;2;252;238;238m.:ii:.. .:.:irri::                    ");
$display("\033[38;2;252;238;238m                             71vi\033[38;2;252;172;172m:::irrr::....\033[38;2;252;238;238m    ...:..::::irrr7777777777777rrii::....  ..::irvrr7sUJYv7777v7ii..                         ");
$display("\033[38;2;252;238;238m                               .i777i. ..:rrri77rriiiiiii:::::::...............:::iiirr7vrrr:.                                             ");
$display("\033[38;2;252;238;238m                                                      .::::::::::::::::::::::::::::::                                                      \033[m");

end endtask


endmodule


