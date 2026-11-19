`timescale 1ns / 1ps
// Simple testbench for vending_fsm.
// Each test inserts coins, then checks total / change / dispense / r20,r10,r5.

module vending_fsm_tb;

    reg clk = 0, reset_n = 0;
    reg c5 = 0, c10 = 0, c25 = 0, item_taken = 0;
    wire dispense, r5, r10, r20;
    wire [5:0] total, change;
    integer errors = 0;

    vending_fsm DUT (.clk(clk), .reset_n(reset_n),
                     .c5(c5), .c10(c10), .c25(c25), .item_taken(item_taken),
                     .dispense(dispense), .r5(r5), .r10(r10), .r20(r20),
                     .total(total), .change(change));

    always #5 clk = ~clk;   // 100 MHz

    // Insert one coin (1 clock pulse)
    task nickel;  begin c5  = 1; @(posedge clk); #1; c5  = 0; end endtask
    task dime;    begin c10 = 1; @(posedge clk); #1; c10 = 0; end endtask
    task quarter; begin c25 = 1; @(posedge clk); #1; c25 = 0; end endtask
    task take;    begin item_taken = 1; @(posedge clk); #1; item_taken = 0; end endtask

    // Check the outputs
    task check(input [5:0] exp_total, input [5:0] exp_change,
               input exp_dispense, input [2:0] exp_r20_r10_r5);
        begin
            if (total === exp_total && change === exp_change &&
                dispense === exp_dispense && {r20, r10, r5} === exp_r20_r10_r5)
                $display("PASS  total=%0d change=%0d dispense=%b r20/r10/r5=%b",
                         total, change, dispense, {r20, r10, r5});
            else begin
                $display("FAIL  total=%0d change=%0d dispense=%b r20/r10/r5=%b  (expected %0d %0d %b %b)",
                         total, change, dispense, {r20, r10, r5},
                         exp_total, exp_change, exp_dispense, exp_r20_r10_r5);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // Reset
        #22 reset_n = 1;
        @(posedge clk); #1;
        $display("--- After reset");
        check(0, 0, 0, 3'b000);

        $display("--- 5 + 5 + 5 + 5 + 5 = 25, no change");
        nickel; nickel; nickel; nickel; check(20, 0, 0, 3'b000);
        nickel; check(25, 0, 1, 3'b000);
        take;   check(0, 0, 0, 3'b000);

        $display("--- 10 + 10 + 5 = 25, no change");
        dime; dime; check(20, 0, 0, 3'b000);
        nickel; check(25, 0, 1, 3'b000);
        take;   check(0, 0, 0, 3'b000);

        $display("--- 25 = no change");
        quarter; check(25, 0, 1, 3'b000);
        take;    check(0, 0, 0, 3'b000);

        $display("--- 5 + 25 = 30, return a nickel (r5)");
        nickel; quarter; check(30, 5, 1, 3'b001);
        take;            check(0, 0, 0, 3'b000);

        $display("--- 10 + 25 = 35, return a dime (r10)");
        dime; quarter; check(35, 10, 1, 3'b010);
        take;          check(0, 0, 0, 3'b000);

        $display("--- 15 + 25 = 40, return a dime and a nickel (r10 + r5)");
        dime; nickel; quarter; check(40, 15, 1, 3'b011);
        take;                  check(0, 0, 0, 3'b000);

        $display("--- 20 + 25 = 45, return two dimes (r20)");
        dime; dime; quarter; check(45, 20, 1, 3'b100);
        take;                check(0, 0, 0, 3'b000);

        $display("--- 20 + 10 = 30, return a nickel (r5)");
        dime; dime; dime; check(30, 5, 1, 3'b001);
        take;             check(0, 0, 0, 3'b000);

        $display("--- Coins are ignored after dispensing, until the item is taken");
        quarter; check(25, 0, 1, 3'b000);
        quarter; dime; nickel; check(25, 0, 1, 3'b000);
        take;    check(0, 0, 0, 3'b000);

        $display("--- item_taken is ignored while still collecting coins");
        dime; take; check(10, 0, 0, 3'b000);

        $display("--- Reset in the middle of a sale");
        reset_n = 0; #1; reset_n = 1; @(posedge clk); #1;
        check(0, 0, 0, 3'b000);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TESTS FAILED", errors);
        $finish;
    end

endmodule
