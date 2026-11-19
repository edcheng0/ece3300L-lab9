`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: vending_top
// Target Board: Nexys A7-100T
// Description: Vending machine on the FPGA.
//   BTNL = nickel (c5)   BTNU = dime (c10)   BTNR = quarter (c25)
//   BTND = item_taken    CPU RESET = reset
//   LD0 = r5   LD1 = r10   LD2 = r20   LD3 = dispense
//   RGB LEDs (LD16 and LD17): red = not enough money yet, green = item dispensed
//   7-seg: digits 5-4 = total inserted, digits 1-0 = change due
//////////////////////////////////////////////////////////////////////////////////

module vending_top(
    input clk, reset_n,
    input btnl, btnu, btnr, btnd,
    output [3:0] led,
    output [1:0] rgb_r, rgb_g,          // [0] = LD16, [1] = LD17
    output [7:0] an,
    output [6:0] seg,
    output dp
    );

    // Debounce each button and make a 1-clock pulse on the press
    wire c5, c10, c25, item_taken;
    wire unused_d0, unused_d1, unused_d2, unused_d3;
    wire unused_n0, unused_n1, unused_n2, unused_n3;
    wire unused_e0, unused_e1, unused_e2, unused_e3;

    button B_C5   (.clk(clk), .reset_n(reset_n), .noisy(btnl),
                   .debounced(unused_d0), .p_edge(c5),
                   .n_edge(unused_n0), ._edge(unused_e0));
    button B_C10  (.clk(clk), .reset_n(reset_n), .noisy(btnu),
                   .debounced(unused_d1), .p_edge(c10),
                   .n_edge(unused_n1), ._edge(unused_e1));
    button B_C25  (.clk(clk), .reset_n(reset_n), .noisy(btnr),
                   .debounced(unused_d2), .p_edge(c25),
                   .n_edge(unused_n2), ._edge(unused_e2));
    button B_TAKE (.clk(clk), .reset_n(reset_n), .noisy(btnd),
                   .debounced(unused_d3), .p_edge(item_taken),
                   .n_edge(unused_n3), ._edge(unused_e3));

    // Vending machine FSM
    wire dispense, r5, r10, r20;
    wire [5:0] total, change;

    vending_fsm FSM0 (
        .clk(clk), .reset_n(reset_n),
        .c5(c5), .c10(c10), .c25(c25), .item_taken(item_taken),
        .dispense(dispense), .r5(r5), .r10(r10), .r20(r20),
        .total(total), .change(change)
    );

    assign led = {dispense, r20, r10, r5};

    // RGB LED shows the machine state (duty 0-256, 64 = dim so it is not too bright)
    wire [8:0] red_duty   = dispense ? 9'd0  : 9'd64;   // red   = not enough money yet
    wire [8:0] green_duty = dispense ? 9'd64 : 9'd0;    // green = enough money, item dispensed
    wire red_pwm, green_pwm, unused_blue_pwm;

    rgb_driver #(.R(8)) RGB0 (
        .clk(clk), .reset_n(reset_n),
        .red_duty(red_duty), .green_duty(green_duty), .blue_duty(9'd0),
        .red_LED(red_pwm), .green_LED(green_pwm), .blue_LED(unused_blue_pwm)
    );

    // Same color on both RGB LEDs
    assign rgb_r = {red_pwm, red_pwm};
    assign rgb_g = {green_pwm, green_pwm};

    // Split the amounts into tens and ones (blank the tens digit when it is 0)
    wire [3:0] total_tens  = total / 10;
    wire [3:0] total_ones  = total % 10;
    wire [3:0] change_tens = change / 10;
    wire [3:0] change_ones = change % 10;

    wire [3:0] total_tens_shown  = (total_tens  == 0) ? 4'hF : total_tens;
    wire [3:0] change_tens_shown = (change_tens == 0) ? 4'hF : change_tens;

    //                       d7    d6    d5                 d4          d3    d2    d1                  d0
    wire [31:0] digits = {4'hF, 4'hF, total_tens_shown, total_ones, 4'hF, 4'hF, change_tens_shown, change_ones};

    seg7_driver SEG0 (
        .clk(clk), .reset_n(reset_n), .digits(digits),
        .an(an), .seg(seg), .dp(dp)
    );

endmodule
