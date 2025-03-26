`timescale 1ns/1ps
module testbench;	
	logic clk;
    logic rst;
    logic reset_n,
    logic start,
    logic done_money,
    logic cancel,
    logic continue_buy,
    logic [1:0] item_in;
    logic [2:0] money;
    logic done;
    logic [3:0] item_out;
    logic [7:0] change;

    parameter MAX_MONEY = 40;

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

    task1
        start = 'b1;
        item_in = 'b01;
        money = 'b001;
        @(assert done);
        if (change == 5 && !done && item_out == 'b0000) begin
            $display("TEST PASS");
        end else $display ("TEST FAIL: change: %d, done: %2b, item_out: %4b", change, done, item_out);
    endtask

    initial begin
        task1();
        //reset_value();
        //task2();
    end
endmodule
