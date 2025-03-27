module Output_handler_TB;
    logic           end_trans;
    logic   [7:0]   sum_money;
    logic   [7:0]   price;
    logic   [1:0]   item_select;
    wire            item_1;
    wire            item_2;
    wire            item_3;
    wire            item_4;
    wire   [7:0]   change;
    logic   [7:0]   result;

    output_handler output_handler_DUT(
        .end_trans(end_trans),
        .sum_money(sum_money),
        .price(price),
        .item_select(item_select),
        .item_1(item_1),
        .item_2(item_2),
        .item_3(item_3),
        .item_4(item_4),
        .change(change)
    );

    task Result_check;
        begin
            $display("\n[%0t] --- Result check ---", $time);
            if (end_trans) begin
                    $display("[%0t] --- Check the output value when end_trans = 1 ---", $time);
                    result = sum_money - price;
                    if (change == result) begin
                        $display("[%0t] PASSED - expect_result = %d, change = %d", $time, result, change);
                    end else begin
                        $display("[%0t] FAILED - expect_result = %d, change = %d", $time, result, change);
                    end
                    case (item_select)
                        2'b00: begin
                            if(item_1 && ~item_2 && ~item_3 && ~item_4) begin
                                $display("[%0t] PASSED - end_trans == %d, item_1 == %d", $time, end_trans, item_1);
                            end else begin
                                $display("[%0t] FAILED - end_trans == %d, item_1 == %d", $time, end_trans, item_1);
                            end
                        end
                        2'b01: begin
                            if(~item_1 && item_2 && ~item_3 && ~item_4) begin
                                $display("[%0t] PASSED - end_trans == %d, item_2 == %d", $time, end_trans, item_2);
                            end else begin
                                $display("[%0t] FAILED - end_trans == %d, item_2 == %d", $time, end_trans, item_2);
                            end
                        end
                        2'b10: begin
                            if(~item_1 && ~item_2 && item_3 && ~item_4) begin
                                $display("[%0t] PASSED - end_trans == %d, item_3 == %d", $time, end_trans, item_3);
                            end else begin
                                $display("[%0t] FAILED - end_trans == %d, item_3 == %d", $time, end_trans, item_3);
                            end
                        end
                        2'b11: begin
                            if(~item_1 && ~item_2 && ~item_3 && item_4) begin
                                $display("[%0t] PASSED - end_trans == %d, item_4 == %d", $time, end_trans, item_4);
                            end else begin
                                $display("[%0t] FAILED - end_trans == %d, item_4 == %d", $time, end_trans, item_4);
                            end
                        end
                    endcase
            end else begin
                $display("[%0t] --- Check the output when end_trans = 0 ---", $time);
                if(~item_1 && ~item_2 && ~item_3 && ~item_4 && ~change) begin
                    $display("[%0t] PASSED - item_1 = %d, item_2 = %d, item_3 = %d, item_4 = %d", $time, item_1, item_2, item_3, item_4); 
                end else begin
                    $display("[%0t] FAILED - item_1 = %d, item_2 = %d, item_3 = %d, item_4 = %d", $time, item_1, item_2, item_3, item_4); 
                end
            end
        end
    endtask

    task Random_value_equal_money;
        begin
            $display("\n[%0t] --- Random_value_equal_money ---", $time);
            item_select = $urandom_range(0, 3);
            price = $urandom_range(0, 255);
            sum_money = price;
            end_trans = 1;
            $display("[%0t] item_select = %h, price = %d, sum_money = %d", $time, item_select, price, sum_money);
            #5
            Result_check;
            #10
            end_trans = 0;
        end
    endtask

    task Random_value_greater_money;
        begin
            item_select = $urandom_range(0, 3);
            $display("\n[%0t] --- Random_value_greater_money ---", $time);
            price = $urandom_range(0, 255);
            sum_money = 8'h00;
            while(sum_money <= price) begin
                sum_money = $urandom_range(0, 255);
            end
            end_trans = 1;
            $display("[%0t] item_select = %d, price = %d, sum_money = %d", $time, item_select, price, sum_money);
            #5
            Result_check;
            #10
            end_trans = 0;
        end
    endtask

    task Continuos_transaction_with_random_value;
        input   [7:0]   i;
        begin
            repeat (i) begin
                Random_value_greater_money;
                Result_check;
            end
        end
    endtask

    initial begin
        Result_check;
        #10
        Random_value_equal_money;
        #10
        Random_value_greater_money;
        #10
        Continuos_transaction_with_random_value(8'hFF);
        $finish;
    end
endmodule
