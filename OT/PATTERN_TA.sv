`define CYCLE_TIME 5.0

module PATTERN(
  // Input signals
	clk,
	rst_n,
    in_valid,
    in_data,
  // Output signals
	out_valid,
    out_data
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output logic clk, rst_n, in_valid;
output logic [3:0] in_data;
input out_valid, out_data;

//================================================================
// parameters & integer
//================================================================
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;

//================================================================
// parameters & integer
//================================================================
integer PATNUM = 3060;
integer seed = 333;
integer i, j, k;
integer patcount;
integer gap;

integer delay;
integer total_delay;

logic [2:0] value;
logic sign, stop_flag;
logic [3:0] minimun, maximun;
integer in_cnt, sel, sel1, sel2, sel3;
logic [3:0] golden_in [0:3], temp;
logic [3:0] golden_sel [0:3], design_in [0:3];
logic [9:0] dividend, golden_out, design_out;
logic [3:0] divisor;
integer out_count;
//================================================================
// initial
//================================================================
initial begin
	rst_n = 1'b1;
    in_valid = 1'b0;
	in_data = 4'dx;
	total_delay = 0;
	minimun = 0;
	maximun = 9;
	stop_flag = 0;
	golden_in = {minimun, minimun, minimun, minimun};

	force clk = 0;
	reset_task;
	
	for(patcount=0; patcount<PATNUM; patcount=patcount+1)
	begin	
		delay_task;	
		$display("\033[33mPATTERN NO.%1d \033[m", patcount);
		input_task;
		ans_gen;
		wait_out_valid;
		check_ans;
		$display("\033[0;32mPASS PATTERN NO.%1d, Latency: %2d \033[m", patcount, delay);
		nxt_golden;
		if (stop_flag==1) break;
	end

	YOU_PASS_task;
	$finish;
end

//================================================================
// task
//================================================================

task delay_task; begin
	gap = $urandom_range(2,6);
	repeat(gap) @(negedge clk);
end endtask

task wait_out_valid ; begin
	delay = 0;
	while(out_valid !== 1) begin
		@(negedge clk);
		delay = delay + 1;
		
		if(delay==100)	begin
			// fail;
			$display ("----------------------------------------------------------------------");
			$display ("                             \033[0;31mSPEC3 FAIL!\033[m                              ");
			$display ("              out_valid should be high within 100 cycles              ");
			$display ("----------------------------------------------------------------------");
			#(100);
		    $finish ;
		end
	end
	total_delay = total_delay + delay;
end endtask


task reset_task ; begin
	#(2); rst_n = 0;

	#(10.0);
	if(out_valid !== 0 || out_data!==0) begin
		// fail;
		$display ("----------------------------------------------------------------------");
		$display ("                             \033[0;31mSPEC2 FAIL!\033[m                              ");
		$display ("        out_valid and out_data should be 0 after initial RESET        ");
		$display ("----------------------------------------------------------------------");
		#(100);
	    $finish ;
	end
	
	#(1.0); rst_n = 1 ;
	#(3.0); release clk;
end endtask

task nxt_golden; begin
	if ((golden_in[0]==maximun) && (golden_in[1]==maximun) && (golden_in[2]==maximun) && (golden_in[3]==maximun)) begin
		golden_in[0] = maximun;
		golden_in[1] = maximun;
		golden_in[2] = maximun;
		golden_in[3] = maximun;
		stop_flag = 1;
	end
	else if ((golden_in[0]==golden_in[1]) && (golden_in[1]==golden_in[2]) && (golden_in[2]==golden_in[3])) begin
		golden_in[0] = golden_in[0] + 1;
		golden_in[1] = minimun;
		golden_in[2] = minimun;
		golden_in[3] = minimun;
	end
	else if ((golden_in[1]==golden_in[2]) && (golden_in[2]==golden_in[3])) begin
		golden_in[1] = golden_in[1] + 1;
		golden_in[2] = minimun;
		golden_in[3] = minimun;
	end
	else if (golden_in[2]==golden_in[3]) begin
		golden_in[2] = golden_in[2] + 1;
		golden_in[3] = minimun;
	end
	else begin
		golden_in[3] = golden_in[3] + 1;
	end
end endtask

task input_task; begin
	golden_out = 0;
	in_valid = 1;
	golden_sel = golden_in;
	for(i=0; i<4; i=i+1)begin
		sel = $urandom_range(0,3-i);
		in_data = golden_sel[sel]+3;
		design_in[i] = in_data;
		for (j=sel; j<3; j=j+1) 
			golden_sel[j] = golden_sel[j+1];
		@(negedge clk);
		check_out_while_input;
	end
	in_valid = 0;
	in_data = 4'dx;
end endtask

task ans_gen; begin
	dividend = 100*golden_in[0] + 10*golden_in[2] + golden_in[3];
	divisor = golden_in[1];
	if (divisor == 0)
		golden_out = 1023;
	else
		golden_out = dividend/divisor;
	$display("\033[34m  in_date: %4b(%1d), %4b(%1d), %4b(%1d), %4b(%1d)\033[m", 
				design_in[0], design_in[0]-3, design_in[1], design_in[1]-3, design_in[2], design_in[2]-3, design_in[3], design_in[3]-3);
	$display("\033[34msort_date: %4b(%1d), %4b(%1d), %4b(%1d), %4b(%1d)\033[m", 
				golden_in[0], golden_in[0], golden_in[1], golden_in[1], golden_in[2], golden_in[2], golden_in[3], golden_in[3]);
	$display("\033[34mDividend: %2b_%4b_%4b(%3d), Divisor: %4b(%1d)\033[m", 
				dividend[9:8], dividend[7:4], dividend[3:0], dividend, divisor, divisor);
	$display("\033[34mQuotient: %2b_%4b_%4b(%3d)\033[m", 
				golden_out[9:8], golden_out[7:4], golden_out[3:0], golden_out);
end endtask

task check_out_while_input; begin

	if(in_valid===1&&out_valid!==0) begin
	// fail;
	$display ("----------------------------------------------------------------------");
	$display ("                             \033[0;31mSPEC3 FAIL!\033[m                              ");
	$display ("             out_valid should be 0 while in_valid is high             ");
	$display ("----------------------------------------------------------------------");
	#(100)
	$finish;
	end
	
end endtask

task check_ans; begin
	out_count = 0;
	design_out = 10'dx;
	while (out_valid===1) begin
		out_count = out_count + 1;
		if (out_count <= 10)
			design_out[10-out_count] = out_data;
		else if (out_count > 20)
			 break;
		@(negedge clk);
	end
	
	if(out_count!=10) begin
		// fail;
		$display ("----------------------------------------------------------------------");
		$display ("                             \033[0;31mSPEC5 FAIL!\033[m                              ");
		$display ("             out_valid should be high only for 10 cycles              ");
		if(out_count<20)
		$display ("                      Your out_valid : %2d cycles                     ", out_count);
		if(out_count>20)
		$display ("                    Your out_valid : exceed 20 cycles                   ");
		$display ("----------------------------------------------------------------------");
		#(100)
		$finish;
	end
	
	if(golden_out!==design_out) begin
		// fail;
		$display ("----------------------------------------------------------------------");
		$display ("                             \033[0;31mSPEC5 FAIL!\033[m                              ");
		$display ("                    Pattern No. %4d Wrong Answer                    ",patcount);
		$display ("                    Your answer: %3d (%2b_%4b_%4b)                    ", design_out, design_out[9:8], design_out[7:4], design_out[3:0]);
		$display ("                    Gold answer: %3d (%2b_%4b_%4b)                    ", golden_out, golden_out[9:8], golden_out[7:4], golden_out[3:0]);
		$display ("----------------------------------------------------------------------");
		#(100)
		$finish;
	end

	@(negedge clk);
	
end endtask

always@(negedge clk) begin
	if(out_valid===0 && out_data!==0) begin
		// fail;
		$display ("----------------------------------------------------------------------");
		$display ("                             \033[0;31mSPEC4 FAIL!\033[m                              ");
		$display ("               out_data should be 0 when out_valid is 0               ");
		$display ("----------------------------------------------------------------------");
		#(100)
		$finish;
	end
end

task YOU_PASS_task;begin
$display ("        __   _____  ___");
$display ("       r  `-\"     '\"   \"t     \033[0;32m ######    #####    ######   ###### \033[m");
$display ("      !                 |     \033[0;32m ##   ##  ##   ##  ##       ##      \033[m");
$display ("     /         ._;,  .  \\     \033[0;32m ######   #######   #####    #####  \033[m");
$display ("  \"\"/`    '    ⠀!|⠀     -\\\"\"  \033[0;32m ##       ##   ##       ##       ## \033[m");
$display (" --(-          ⠀|j⠀      -)-- \033[0;32m ##       ##   ##  ######   ######  \033[m");
$display (" /.-+-         ⠀        -+-.                                      ");
$display ("(                          \\ -------------------------------------");
$display ("|   ;                    : |           Congratulations!           ");
$display ("`=._)          X         l.;     You have passed all patterns!    ");
$display ("  (     ______________    )      Total latency : %5d cycles       ", total_delay);
$display ("  ;____/              \\___!  -------------------------------------");
$display ("\033[m");
$finish;	
end endtask

endmodule


