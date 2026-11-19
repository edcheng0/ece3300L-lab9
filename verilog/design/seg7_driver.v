`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: seg7_driver
// Description: Multiplexes the 8 seven-segment digits of the Nexys A7 (100 MHz).
//              Each 4-bit group of "digits" is one digit (digits[3:0] = rightmost).
//              Values 0-9 show that number, anything else (use 4'hF) is blank.
//              Segments and anodes are active low on the Nexys A7.
//////////////////////////////////////////////////////////////////////////////////

module seg7_driver(
    input clk, reset_n,
    input [31:0] digits,
    output reg [7:0] an,
    output reg [6:0] seg,     // seg[0] = CA ... seg[6] = CG
    output dp
    );

    // Refresh counter: top 3 bits pick the digit (about 190 Hz for the whole display)
    reg [18:0] refresh_reg;
    always @(posedge clk, negedge reset_n)
    begin
        if (~reset_n)
            refresh_reg <= 0;
        else
            refresh_reg <= refresh_reg + 1;
    end

    wire [2:0] sel = refresh_reg[18:16];
    wire [3:0] nibble = digits[4*sel +: 4];

    always @(*)
    begin
        an = ~(8'b00000001 << sel);   // turn on only the selected digit
        case (nibble)                 //     gfedcba
            4'd0:    seg = 7'b1000000;
            4'd1:    seg = 7'b1111001;
            4'd2:    seg = 7'b0100100;
            4'd3:    seg = 7'b0110000;
            4'd4:    seg = 7'b0011001;
            4'd5:    seg = 7'b0010010;
            4'd6:    seg = 7'b0000010;
            4'd7:    seg = 7'b1111000;
            4'd8:    seg = 7'b0000000;
            4'd9:    seg = 7'b0010000;
            default: seg = 7'b1111111;   // blank
        endcase
    end

    assign dp = 1'b1;   // decimal point off

endmodule
