`timescale 1ns / 1ps
// Simple testbench for seg7_driver.
// Displays "25" on the two rightmost digits and checks the segments and anodes.

module seg7_driver_tb;

    reg clk = 0, reset_n = 0;
    reg [31:0] digits;
    wire [7:0] an;
    wire [6:0] seg;
    wire dp;
    integer errors = 0;

    seg7_driver DUT (.clk(clk), .reset_n(reset_n), .digits(digits),
                     .an(an), .seg(seg), .dp(dp));

    always #5 clk = ~clk;   // 100 MHz

    // Wait until the given anode is the one that is on, then check the segments
    task check_digit(input [7:0] exp_an, input [6:0] exp_seg);
        begin
            wait (an == exp_an);
            #100;
            if (seg === exp_seg) $display("PASS  an=%b seg=%b", an, seg);
            else begin
                $display("FAIL  an=%b seg=%b (expected %b)", an, seg, exp_seg);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // digit7..digit0 = blank blank blank blank blank blank 2 5
        digits = 32'hFFFFFF25;
        #22 reset_n = 1;

        check_digit(8'b11111110, 7'b0010010);   // digit 0 shows 5
        check_digit(8'b11111101, 7'b0100100);   // digit 1 shows 2
        check_digit(8'b11111011, 7'b1111111);   // digit 2 is blank
        check_digit(8'b01111111, 7'b1111111);   // digit 7 is blank

        // Change the digits: "40" and "15"
        digits = 32'hFF40FF15;
        check_digit(8'b11111110, 7'b0010010);   // digit 0 shows 5
        check_digit(8'b11111101, 7'b1111001);   // digit 1 shows 1
        check_digit(8'b11101111, 7'b1000000);   // digit 4 shows 0
        check_digit(8'b11011111, 7'b0011001);   // digit 5 shows 4

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TESTS FAILED", errors);
        $finish;
    end

endmodule
