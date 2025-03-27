`timescale 1ns / 1ps

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
    
    localparam int MAX_MONEY = 40;

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
            
            done_money = 1;
        end
    endtask


task check_insufficient_money;
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



    task check_cancel_during_insertion_with_refund;
        input integer num_coins;
        integer total;
        integer wait_cycles;
        logic [1:0] random_item;
        begin
            random_item = $urandom_range(0, 3);
            start_machine;
            select_item(random_item);
            simulate_money_insertion(num_coins, total);
            cancel = 1;
            
            wait_cycles = 0;
            while (dut.end_trans !== 1'b1 && wait_cycles < 3) begin
                #10; // Wait one cycle
                wait_cycles++;
            end

            if (dut.end_trans === 1'b1) begin
                if (change == total) begin
                    $display("Test Passed: Cancellation refunded the correct amount. Total inserted: %0d, Change returned: %0d, Random Item: %b", total, change, random_item);
                end else begin
                    $display("Test Failed: Cancellation did not return the correct amount. Total inserted: %0d, Change returned: %0d, Random Item: %b", total, change, random_item);
                end
            end else begin
                $display("Test Failed: end_trans did not assert within 3 cycles after cancellation. Random Item: %b", random_item);
            end

            cancel = 0;
        end
    endtask

    initial begin
        clk = 0;
        reset_n = 0;
        start = 0;
        done_money = 0;
        cancel = 0;
        continue_buy = 0;
        money = 3'b000;
        item_in = 2'b00;
        #10;
        reset_n = 1;
        #10;
        check_insufficient_money(2);
        
        #50;
        check_cancel_during_insertion_with_refund(2);
        
        #50;
        $finish;
    end
endmodule
