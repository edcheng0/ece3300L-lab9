`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: vending_fsm
// Description: Moore FSM for a vending machine. One item costs 25 cents.
//              Accepts nickels (c5), dimes (c10) and quarters (c25).
//              c5, c10, c25 and item_taken must be 1-clock-cycle pulses.
//
//   States S0..S20  : waiting for coins (amount inserted so far is the number)
//   States D0..D20  : item dispensed (number = change due), wait for item_taken
//
//   Largest possible amount = 20 + 25 = 45 cents -> largest change = 20 cents
//////////////////////////////////////////////////////////////////////////////////

module vending_fsm(
    input clk, reset_n,
    input c5, c10, c25, item_taken,
    output dispense,
    output r5, r10, r20,
    output reg [5:0] total,    // cents inserted (for the display)
    output reg [5:0] change    // cents of change due (for the display)
    );

    reg [3:0] state_reg, state_next;
    parameter S0  = 0, S5  = 1, S10 = 2, S15 = 3, S20 = 4,
              D0  = 5, D5  = 6, D10 = 7, D15 = 8, D20 = 9;

    // Sequential state register
    always @(posedge clk, negedge reset_n)
    begin
        if (~reset_n)
            state_reg <= S0;
        else
            state_reg <= state_next;
    end

    // Next state logic (if two coins arrive at once, the bigger coin wins)
    always @(*)
    begin
        state_next = state_reg;
        case (state_reg)
            S0:  if      (c25) state_next = D0;
                 else if (c10) state_next = S10;
                 else if (c5)  state_next = S5;
            S5:  if      (c25) state_next = D5;
                 else if (c10) state_next = S15;
                 else if (c5)  state_next = S10;
            S10: if      (c25) state_next = D10;
                 else if (c10) state_next = S20;
                 else if (c5)  state_next = S15;
            S15: if      (c25) state_next = D15;
                 else if (c10) state_next = D0;    // 15 + 10 = 25
                 else if (c5)  state_next = S20;
            S20: if      (c25) state_next = D20;
                 else if (c10) state_next = D5;    // 20 + 10 = 30
                 else if (c5)  state_next = D0;    // 20 + 5  = 25
            // Item was dispensed: ignore coins until the item is taken
            D0, D5, D10, D15, D20:
                 if (item_taken) state_next = S0;
            default: state_next = S0;
        endcase
    end

    // Output logic (Moore): amount inserted and change due for each state
    always @(*)
    begin
        case (state_reg)
            S0:      begin total = 0;  change = 0;  end
            S5:      begin total = 5;  change = 0;  end
            S10:     begin total = 10; change = 0;  end
            S15:     begin total = 15; change = 0;  end
            S20:     begin total = 20; change = 0;  end
            D0:      begin total = 25; change = 0;  end
            D5:      begin total = 30; change = 5;  end
            D10:     begin total = 35; change = 10; end
            D15:     begin total = 40; change = 15; end
            D20:     begin total = 45; change = 20; end
            default: begin total = 0;  change = 0;  end
        endcase
    end

    assign dispense = (state_reg >= D0);
    assign r5  = (change == 5)  | (change == 15);   // 15 = dime + nickel
    assign r10 = (change == 10) | (change == 15);
    assign r20 = (change == 20);                    // two dimes

endmodule
