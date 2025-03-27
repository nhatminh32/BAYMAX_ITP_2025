module vending_machine_tb;
    // Inputs
    logic clk;
    logic reset_n;
    logic start;
    logic done_money;
    logic cancel;
    logic continue_buy;
    logic [2:0] money;      
    logic [1:0] item_in;

    // Outputs
    logic done;
    logic [3:0] item_out;
    logic [7:0] change;
    logic [3:0] state;
    logic end_trans;  
    logic out_stock;      

    logic [7:0] real_money;
    
    parameter MAX_MONEY = 40;
    integer n;
    logic out_constrain [5] = {3'b000, 3'b011, 3'b101, 3'b110, 3'b111};

    vending_machine dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .done_money(done_money),
        .cancel(cancel),
        .continue_buy(continue_buy),
        .money(money),
        .item_in(item_in),
        .done(done),
        .item_out(item_out),
        .change(change)
        // .end_trans(end_trans)
    );
assign end_trans = dut.end_trans;
assign state = dut.U1.state;
assign out_stock = dut.U1.U1.out_stock;
always #5 clk = ~clk;


task start_machine;
    begin
        start = 1'b1;
        #10;
        start = 1'b0;
    end
endtask


task select_item;
    input [1:0] item_code;
    begin
        item_in = item_code;
    end
endtask
    
task random_coin_denomination;
    output logic [2:0] coin;
    output integer coin_val;
    integer rand_type;
    begin
        rand_type = $urandom_range(0,2); 
        case(rand_type)
            0: begin coin = 3'b001; coin_val = 5;   end
            1: begin coin = 3'b010; coin_val = 10;  end
            2: begin coin = 3'b100; coin_val = 20;  end
            default: begin coin = 3'b001; coin_val = 5; end
        endcase
        $display("Random coin selected: type %0d, value %0d, coin bits: %b", rand_type, coin_val, coin);
    end
endtask

task simulate_money_insertion;
    input integer num_coins;
    input bit exceed_max; // 1: Ensure total_money > MAX_MONEY, 0: Ensure total_money <= MAX_MONEY
    output integer total_money;
    logic [2:0] coin;
    integer coin_val;
    
    begin
        total_money = 0;
        done_money = 0;
        
        repeat(num_coins) begin
            random_coin_denomination(coin, coin_val);
            money = coin;
            total_money = total_money + coin_val;
            $display("Inserted coin: %b, Value: %0d, Total so far: %0d", coin, coin_val, total_money);
            #10;  
            if ((exceed_max && total_money > MAX_MONEY) || (!exceed_max && total_money >= MAX_MONEY)) begin
                $display("Stopping early: total_money = %0d", total_money);
                break;
            end
        end
    if(exceed_max) done_money = 0;
    else done_money = 1;
    
    end
endtask

task task4;
    input integer num_coins;
    integer total;
    logic exceed_max;
    logic [1:0] random_item;
    integer wait_cycles;
    exceed_max = 0;
    begin
    start_machine;
    random_item = $urandom_range(0, 3);
    select_item(random_item);
    simulate_money_insertion(num_coins, exceed_max, total);
    @(posedge clk);
    done_money = 0;
    @(posedge clk);
    cancel = 1;
    wait_cycles = 0;

    while (end_trans !== 1'b1 && wait_cycles < 3) begin
        #10;
        wait_cycles++;
    end

    if (end_trans !== 1'b1) begin
        $display("Test Failed: end_trans did not assert within 3 cycles after cancellation.");
    end else if (change == total) begin
        $display("Test Passed: Insufficient money case correctly canceled and refunded. Total inserted: %0d, Change returned: %0d", total, change);
    end else begin
        $display("Test Failed: Incorrect refund after cancellation. Total inserted: %0d, Change returned: %0d", total, change);
    end
        cancel = 0;
    end
endtask

task task5;
    input integer num_coins;
    input logic exceed_max;
    input logic cancel_in;
    input logic test_continue;
    integer total;
    logic [1:0] random_item;
    integer wait_cycles;
    
    begin
        start_machine;
        random_item = $urandom_range(0, 3);
        select_item(random_item);

        simulate_money_insertion(num_coins, exceed_max, total);
    
        #10;
        done_money = 0;
        cancel = 0;
        @(posedge clk);
        
        if (cancel_in) begin
            cancel = 1;
            $display("Cancel signal raised.");
        end
        
        if (test_continue) begin
            continue_buy = 1;
            $display("Continue buy signal raised.");
        end

        wait_cycles = 0;

        // Wait for `end_trans` signal for up to 3 cycles
        while (end_trans !== 1'b1 && wait_cycles < 3) begin
            #10;
            wait_cycles++;
        end

        if (end_trans !== 1'b1) begin
            $display("Test Failed: end_trans did not assert within 3 cycles.");
        end else if (cancel_in && change == total) begin
            $display("Test Passed: Cancellation handled correctly. Total inserted: %0d, Change returned: %0d", total, change);
        end else if (!cancel_in) begin
            $display("Test Passed: No cancellation, continuing process.");
        end else begin
            $display("Test Failed: Incorrect refund after cancellation. Total inserted: %0d, Change returned: %0d", total, change);
        end

        cancel = 0;
        #20;

        if (test_continue) begin
            continue_buy = 0;
            // Check if the state transitions to SELECT_ITEM_STATE (assumed 3'b001)
            if (state == 3'b001) begin
                $display("Test Passed: State successfully transitioned to SELECT_ITEM_STATE.");
            end else begin
                $display("Test Failed: State did not transition to SELECT_ITEM_STATE. Current state: %0d", state);
            end
        end

        continue_buy = 0;
    end
endtask

///////////////////////////////////////Trung///////////////////////////////////////
task reset_value;
	begin
		reset_n = 0;
		start = 0;
		done_money = 0;
		cancel = 0;
		continue_buy = 0;
		item_in = 2'b00;
		money = 3'b000;

		#10 reset_n = 0;
		#5 reset_n = 1;
		$display("Reset complete");
	end
endtask

	task task6();
		start = 1'b1;
		#10;
		start = 1'b0;
		item_in = 'b01;
		money = (3'b001 << $urandom % 3);
		money = 'b100; 
		cancel = 'b1;
		#10;
		done_money = 'b1;
		#10;
		cancel = 'b0;
		@(posedge clk);
		@(posedge clk);
		case (money)
			'b001:
			begin
				real_money = 5;
			end
			'b010:
			begin
				real_money = 10;
			end
			'b100:
			begin
				real_money = 20;
			end
			default:
			begin
			end
		endcase
		if (change == real_money) begin
			$display($time);
			$display("Test Pass");
		end else begin
			$display($time);
			$display("Test Fail, change: %d, real_money: %d", change, real_money);
		end
	endtask
////////////////////////////////////////////////////////////// BDUC ///////////////////////////////////	
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
    $fsdbDumpvars;
    repeat(1000) begin
    	clk = 0;
    	reset_n = 0;
    	start = 0;
    	done_money = 0;
    	cancel = 0;
    	continue_buy = 0;
    	money = 3'b000;
    	item_in = 2'b00;
    	reset_value();
    	task4(4);
   	 
    	#10;
    	task5(2, 0, 1, 1);
    	reset_value();
    	task5(2, 1, 0, 0);
	reset_value();
	task6();
	reset_value();
	task2();
	reset_value();
	task3();
    	$finish;
    end
end
endmodule
