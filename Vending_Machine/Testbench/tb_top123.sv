`timescale 1ns/1ps
`include "vending_machine.v"
module tb;	
	logic clk;
    logic reset_n;
    logic start;
    logic done_money;
    logic cancel;
    logic continue_buy;
    logic [1:0] item_in;
    logic [2:0] money;
    logic done;
    logic [3:0] item_out;
    logic [7:0] change;

    parameter MAX_MONEY = 40;
    integer n;
    logic out_constrain [5] = {3'b000, 3'b011, 3'b101, 3'b110, 3'b111};
    //rand bit [1:0] index; 
    vending_machine dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .done_money(done_money),
        .cancel(cancel),
        .continue_buy(continue_buy),
        .item_in(item_in),
        .money(money),
        .done(done),
        .item_out(item_out),
        .change(change)
    );
		initial begin 
				clk = 1'b0;
				forever #5 clk = ~clk;
			end

	task reset_value;
		 begin
			  // Reset all inputs
			  reset_n = 0;
			  start         = 0;
			  done_money    = 0;
			  cancel        = 0;
			  continue_buy  = 0;
			  item_in       = 2'b00;
			  money         = 3'b000;

			  // Reset all outputs
			//  done          = 0;
			//  item_out      = 4'b0000;
			//  change        = 8'b00000000;

			  // Hold reset for some cycles
			  #10 reset_n = 0;   // Deassert reset
			  #5  reset_n = 1; 
			  
			  $display("RESET COMPLETE: Ready for new test case");
		 end
	endtask
	task task2;
			  #10 reset_n = 0;   // Deassert reset
			      start = 1;
			  #5  reset_n = 1;
				start = 0; 
				if (change == 0 && !done && item_out == 4'b0000) begin
					$display("TEST PASS RESET CASE");
				end else begin
					$display ("TEST FAIL: change: %d, done: %2b, item_out: %4b, time: %d", change, done, item_out, $time);	
				end 	
		  endtask
		  
    task task3;
		  integer i; 
		  integer numchanges;
		  integer sum_money_r;
		  integer sum_money;
		  integer j;
		  integer a;
		  integer rand_type;
		  const int item_price[4] = '{3, 12, 20, 45};
		  sum_money_r = 0;
		  sum_money = 0;
        	  start = 'b1;
		  reset_n = 'b1;
		  cancel = 0;
		  continue_buy = $urandom_range(0,1);
		  j = 0;
		  a = 0;
       		  item_in = $urandom_range(0,3);
		  // item_in = 2'b01;
		  // numchanges = ($urandom%5) + 	1;
        	  numchanges = 1;
		  
		  for (i = 0; i < 1; i = i + 1) begin
			//index = $urandom_range(0,3);
				rand_type = $urandom_range(0,3); 
				case(rand_type)
				    0: begin money = 3'b001;    end
				    1: begin money = 3'b010;   end
				    2: begin money = 3'b100;  end
				    3: begin money = out_constrain[$urandom_range(0,5)];  end
				    default: begin money = out_constrain[$urandom_range(0,5)]; end
				endcase
			   //money = constrain[index]; 
				//money = 'b100;
				//done_money = $urandom;
				done_money = 1;
				case(money) 
					3'b001:	begin
						sum_money_r = 5;
						end
					3'b010:	begin
						sum_money_r = 10;
						end
					3'b100:	begin
						sum_money_r = 20;
						end
					default: begin
						sum_money_r = 0;
						end
					endcase
				
				sum_money = sum_money + sum_money_r;
		  end
		  
		  i = 0;
		  while (!dut.U1.end_trans) begin
		  		if (dut.U1.U1.state == 3'b010) begin
						j = j+1;
						if ((j == 3) & (change == 0 && !done  && item_out == 4'b0000)) begin
							$display("TEST PASS: HOLD IN RECEIVE MONEY");
							a = 1;
							break;
							
						end
				 end 
				#10;
				i = i+1;
				if (i == 10) begin
					$display("TEST FAIL: HOLD IN RECEIVE MONEY");
					break;
				end
				
		  end
		  if (a==0) begin
			  if ((dut.U1.end_trans) && (continue_buy) && (dut.U1.U1.next_state = 3'b001)) begin
					$display("TEST PASS: CONTINUE = 1");
					if (change == sum_money - item_price[item_in] && done && item_out == (4'b0001 << item_in)) begin
						$display("TEST PASS: FUNCTION");
					end else begin
						$display("TEST FAIL: FUNCTION, change: %d, done: %2b, item_out: %4b, time: %d", change, done, item_out, $time);
					end 
				
				end else begin
					if (change == sum_money - item_price[item_in] && done && item_out == (4'b0001 << item_in)) begin
						$display("TEST PASS: FUNCTION");
					end else begin
						$display("TEST FAIL: FUNCTION, change: %d, done: %2b, item_out: %4b, time: %d", change, done, item_out, $time);
					end
				end
			end else begin
				a = 0;
			end
	 endtask
	 
	 
    initial begin
		
		  repeat (10000) begin
        	  reset_value();
        	  task3();
		  end
		  repeat (50) begin
        	  reset_value();
        	  task2();
		  end
	

			
	
		  #200	$finish;
    end
endmodule
