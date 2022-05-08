`timescale 1ns/10ps
module PATTERN(
//output
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
  //input
  valid_slave1,
  valid_slave2,
  addr_out,
  value_out,
  handshake_slave1,
  handshake_slave2
);

//================================================================
// wire & registers 
//================================================================

output logic clk,rst_n,in_valid_1,in_valid_2,in_valid_3,ready_slave1,ready_slave2;
output logic [6:0] data_in_1,data_in_2,data_in_3;
input [2:0] addr_out,value_out;
input valid_slave1,valid_slave2,handshake_slave1,handshake_slave2;

logic [2:0] mas_sel;
logic [2:0] golden1[0:7], golden2[0:7];
logic [6:0] data1, data2, data3;
//================================================================
// parameters & integer
//================================================================
integer PATNUM=1000;
integer input_file,output_file;
integer count;
integer check_count;
integer i,a,b;
integer patcount;
integer cycle_time;
integer lat,total_latency;
integer CYCLE = 5;

always	#(CYCLE/2.0) clk = ~clk;

mem_slave mem_slave1
(   
  .clk(clk),
  .rst_n(rst_n),
  .data_in_addr(addr_out),
  .data_in_value(value_out),
  .valid(valid_slave1),
  .ready(ready_slave1)
);

mem_slave mem_slave2
(
  .clk(clk),
  .rst_n(rst_n),
  .data_in_addr(addr_out),
  .data_in_value(value_out),
  .valid(valid_slave2),
  .ready(ready_slave2)
);

//================================================================
// initial
//================================================================
initial begin
	for(i=0;i<8;i=i+1) begin
        golden1[i] = 0;
        golden2[i] = 0;
    end
	rst_n = 1'b1;
	in_valid_1 = 0;
	in_valid_2 = 0;
	in_valid_3 = 0;
	data_in_1 = 'bx;
	data_in_2 = 'bx;
	data_in_3 = 'bx;

	force clk = 0;
	reset_task;
	total_latency = 0; 
	@(negedge clk);
	for(patcount = 0 ; patcount < PATNUM ; patcount = patcount + 1) begin
		input_task;
		check_ans;

	end
	YOU_PASS_task;
	$finish;
end 



//================================================================
// task
//================================================================
task reset_task ; begin
    #( 0.5 ); rst_n = 0;

	#(2.0);
	  if((valid_slave1 !== 0) || (valid_slave2 !== 0) || (addr_out !== 0) || (value_out !== 0) || (handshake_slave1 !== 0) || (handshake_slave2 !== 0))
	  begin
		fail;
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                              Fail!  Valid and output should be zero after rst                                              ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
	  $finish ;
	  end 
	
	#(1.0) rst_n = 1 ;
	#(3.0) release clk;
end endtask

task input_task ; begin
	mas_sel = $urandom_range(7,1);
	if(mas_sel[2]==1'b1)begin
		in_valid_1 = 1;
		data_in_1 = $urandom_range(127,0);
		end
	if(mas_sel[1]==1'b1)begin
		in_valid_2 = 1;
		data_in_2 = $urandom_range(127,0);
		end
	if(mas_sel[0]==1'b1)begin
		in_valid_3 = 1;
		data_in_3 = $urandom_range(127,0);
		end

    @(negedge clk);
    /* if(!data[6]) begin
        golden0[data[5:3]] = data[2:0];
    end
    else begin
        golden1[data[5:3]] = data[2:0];
    end */
	data1 = data_in_1;
	data2 = data_in_2;
	data3 = data_in_3;
	in_valid_1 = 0;
    in_valid_2 = 0;
    in_valid_3 = 0;
    data_in_1 = 'bx;
    data_in_2 = 'bx;
    data_in_3 = 'bx;
	@(negedge clk);
end endtask

task wait_handshake ; begin
	lat = 0;
	while(handshake_slave1 !== 1 && handshake_slave2 !== 1)begin
        $display("-----waiting for handshake-----");
		lat = lat + 1;
		if(lat == 30) begin
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			$display ("                                                    FAIL! The execution latency are over 30   cycles                                             ");
			$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
		end
	@(negedge clk);
	end
    if(handshake_slave1) $display("-----handshake success with slave1-----");
    if(handshake_slave2) $display("-----handshake success with slave2-----");
	total_latency = total_latency + lat;
end endtask



task check_ans ; begin
	//for master 1
	if(mas_sel[2]==1'b1)begin
		wait_handshake;
		if(!data1[6]) 
			golden1[data1[5:3]] = data1[2:0];
		else 
			golden2[data1[5:3]] = data1[2:0];
		if(
			mem_slave1.mem[0] !== golden1[0] ||
			mem_slave1.mem[1] !== golden1[1] ||
			mem_slave1.mem[2] !== golden1[2] ||
			mem_slave1.mem[3] !== golden1[3] ||
			mem_slave1.mem[4] !== golden1[4] ||
			mem_slave1.mem[5] !== golden1[5] ||
			mem_slave1.mem[6] !== golden1[6] ||
			mem_slave1.mem[7] !== golden1[7] ||
			mem_slave2.mem[0] !== golden2[0] ||
			mem_slave2.mem[1] !== golden2[1] ||
			mem_slave2.mem[2] !== golden2[2] ||
			mem_slave2.mem[3] !== golden2[3] ||
			mem_slave2.mem[4] !== golden2[4] ||
			mem_slave2.mem[5] !== golden2[5] ||
			mem_slave2.mem[6] !== golden2[6] ||
			mem_slave2.mem[7] !== golden2[7]) begin
				fail;
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display ("                                                     WRONG MEMORY ANSWER FAIL!                                                              ");
				$display ("                                                          Pattern No. %3d                                                          ",patcount);
				$display ("----------------------------memory slave1 and slave2, the form is: slave(number)_(address): (value)-----------------------------------------");
				$display ("                                          slave1_0:%3d       golden answer:%3d", mem_slave1.mem[0], golden1[0]);
				$display ("                                          slave1_1:%3d       golden answer:%3d", mem_slave1.mem[1], golden1[1]);
				$display ("                                          slave1_2:%3d       golden answer:%3d", mem_slave1.mem[2], golden1[2]);
				$display ("                                          slave1_3:%3d       golden answer:%3d", mem_slave1.mem[3], golden1[3]);
				$display ("                                          slave1_4:%3d       golden answer:%3d", mem_slave1.mem[4], golden1[4]);
				$display ("                                          slave1_5:%3d       golden answer:%3d", mem_slave1.mem[5], golden1[5]);
				$display ("                                          slave1_6:%3d       golden answer:%3d", mem_slave1.mem[6], golden1[6]);
				$display ("                                          slave1_7:%3d       golden answer:%3d", mem_slave1.mem[7], golden1[7]);
				$display ("                                          slave2_0:%3d       golden answer:%3d", mem_slave2.mem[0], golden2[0]);
				$display ("                                          slave2_1:%3d       golden answer:%3d", mem_slave2.mem[1], golden2[1]);
				$display ("                                          slave2_2:%3d       golden answer:%3d", mem_slave2.mem[2], golden2[2]);
				$display ("                                          slave2_3:%3d       golden answer:%3d", mem_slave2.mem[3], golden2[3]);
				$display ("                                          slave2_4:%3d       golden answer:%3d", mem_slave2.mem[4], golden2[4]);
				$display ("                                          slave2_5:%3d       golden answer:%3d", mem_slave2.mem[5], golden2[5]);
				$display ("                                          slave2_6:%3d       golden answer:%3d", mem_slave2.mem[6], golden2[6]);
				$display ("                                          slave2_7:%3d       golden answer:%3d", mem_slave2.mem[7], golden2[7]);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$finish ;
			end
		outvalid_rst;
	end
	//for master 2
	if(mas_sel[1]==1'b1)begin
		wait_handshake;
		if(!data2[6]) 
			golden1[data2[5:3]] = data2[2:0];
		else 
			golden2[data2[5:3]] = data2[2:0];
		if(
			mem_slave1.mem[0] !== golden1[0] ||
			mem_slave1.mem[1] !== golden1[1] ||
			mem_slave1.mem[2] !== golden1[2] ||
			mem_slave1.mem[3] !== golden1[3] ||
			mem_slave1.mem[4] !== golden1[4] ||
			mem_slave1.mem[5] !== golden1[5] ||
			mem_slave1.mem[6] !== golden1[6] ||
			mem_slave1.mem[7] !== golden1[7] ||
			mem_slave2.mem[0] !== golden2[0] ||
			mem_slave2.mem[1] !== golden2[1] ||
			mem_slave2.mem[2] !== golden2[2] ||
			mem_slave2.mem[3] !== golden2[3] ||
			mem_slave2.mem[4] !== golden2[4] ||
			mem_slave2.mem[5] !== golden2[5] ||
			mem_slave2.mem[6] !== golden2[6] ||
			mem_slave2.mem[7] !== golden2[7]) begin
				fail;
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display ("                                                     WRONG MEMORY ANSWER FAIL!                                                              ");
				$display ("                                                          Pattern No. %3d                                                          ",patcount);
				$display ("----------------------------memory slave1 and slave2, the form is: slave(number)_(address): (value)-----------------------------------------");
				$display ("                                          slave1_0:%3d       golden answer:%3d", mem_slave1.mem[0], golden1[0]);
				$display ("                                          slave1_1:%3d       golden answer:%3d", mem_slave1.mem[1], golden1[1]);
				$display ("                                          slave1_2:%3d       golden answer:%3d", mem_slave1.mem[2], golden1[2]);
				$display ("                                          slave1_3:%3d       golden answer:%3d", mem_slave1.mem[3], golden1[3]);
				$display ("                                          slave1_4:%3d       golden answer:%3d", mem_slave1.mem[4], golden1[4]);
				$display ("                                          slave1_5:%3d       golden answer:%3d", mem_slave1.mem[5], golden1[5]);
				$display ("                                          slave1_6:%3d       golden answer:%3d", mem_slave1.mem[6], golden1[6]);
				$display ("                                          slave1_7:%3d       golden answer:%3d", mem_slave1.mem[7], golden1[7]);
				$display ("                                          slave2_0:%3d       golden answer:%3d", mem_slave2.mem[0], golden2[0]);
				$display ("                                          slave2_1:%3d       golden answer:%3d", mem_slave2.mem[1], golden2[1]);
				$display ("                                          slave2_2:%3d       golden answer:%3d", mem_slave2.mem[2], golden2[2]);
				$display ("                                          slave2_3:%3d       golden answer:%3d", mem_slave2.mem[3], golden2[3]);
				$display ("                                          slave2_4:%3d       golden answer:%3d", mem_slave2.mem[4], golden2[4]);
				$display ("                                          slave2_5:%3d       golden answer:%3d", mem_slave2.mem[5], golden2[5]);
				$display ("                                          slave2_6:%3d       golden answer:%3d", mem_slave2.mem[6], golden2[6]);
				$display ("                                          slave2_7:%3d       golden answer:%3d", mem_slave2.mem[7], golden2[7]);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$finish ;
			end
		outvalid_rst;
	end
	//for master 3
	if(mas_sel[0]==1'b1)begin
		wait_handshake;
		if(!data3[6]) 
			golden1[data3[5:3]] = data3[2:0];
		else 
			golden2[data3[5:3]] = data3[2:0];
		if(
			mem_slave1.mem[0] !== golden1[0] ||
			mem_slave1.mem[1] !== golden1[1] ||
			mem_slave1.mem[2] !== golden1[2] ||
			mem_slave1.mem[3] !== golden1[3] ||
			mem_slave1.mem[4] !== golden1[4] ||
			mem_slave1.mem[5] !== golden1[5] ||
			mem_slave1.mem[6] !== golden1[6] ||
			mem_slave1.mem[7] !== golden1[7] ||
			mem_slave2.mem[0] !== golden2[0] ||
			mem_slave2.mem[1] !== golden2[1] ||
			mem_slave2.mem[2] !== golden2[2] ||
			mem_slave2.mem[3] !== golden2[3] ||
			mem_slave2.mem[4] !== golden2[4] ||
			mem_slave2.mem[5] !== golden2[5] ||
			mem_slave2.mem[6] !== golden2[6] ||
			mem_slave2.mem[7] !== golden2[7]) begin
				fail;
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$display ("                                                     WRONG MEMORY ANSWER FAIL!                                                              ");
				$display ("                                                          Pattern No. %3d                                                          ",patcount);
				$display ("----------------------------memory slave1 and slave2, the form is: slave(number)_(address): (value)-----------------------------------------");
				$display ("                                          slave1_0:%3d       golden answer:%3d", mem_slave1.mem[0], golden1[0]);
				$display ("                                          slave1_1:%3d       golden answer:%3d", mem_slave1.mem[1], golden1[1]);
				$display ("                                          slave1_2:%3d       golden answer:%3d", mem_slave1.mem[2], golden1[2]);
				$display ("                                          slave1_3:%3d       golden answer:%3d", mem_slave1.mem[3], golden1[3]);
				$display ("                                          slave1_4:%3d       golden answer:%3d", mem_slave1.mem[4], golden1[4]);
				$display ("                                          slave1_5:%3d       golden answer:%3d", mem_slave1.mem[5], golden1[5]);
				$display ("                                          slave1_6:%3d       golden answer:%3d", mem_slave1.mem[6], golden1[6]);
				$display ("                                          slave1_7:%3d       golden answer:%3d", mem_slave1.mem[7], golden1[7]);
				$display ("                                          slave2_0:%3d       golden answer:%3d", mem_slave2.mem[0], golden2[0]);
				$display ("                                          slave2_1:%3d       golden answer:%3d", mem_slave2.mem[1], golden2[1]);
				$display ("                                          slave2_2:%3d       golden answer:%3d", mem_slave2.mem[2], golden2[2]);
				$display ("                                          slave2_3:%3d       golden answer:%3d", mem_slave2.mem[3], golden2[3]);
				$display ("                                          slave2_4:%3d       golden answer:%3d", mem_slave2.mem[4], golden2[4]);
				$display ("                                          slave2_5:%3d       golden answer:%3d", mem_slave2.mem[5], golden2[5]);
				$display ("                                          slave2_6:%3d       golden answer:%3d", mem_slave2.mem[6], golden2[6]);
				$display ("                                          slave2_7:%3d       golden answer:%3d", mem_slave2.mem[7], golden2[7]);
				$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
				$finish ;
			end
		outvalid_rst;
	end   

end endtask

task outvalid_rst;begin
	@(negedge clk );
	if((handshake_slave1 !== 0) || (handshake_slave2 !== 0))begin
		fail;
	    $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                    Fail!   handshake should be high only one cycle                                         ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		#(100);
	    $finish ;
		end
end endtask






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


