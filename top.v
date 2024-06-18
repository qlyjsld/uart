`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/10/2024 08:13:11 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top(clk, uart_rxd_out);

    input wire clk;
    output reg uart_rxd_out;

    reg tx_wr;
    reg [7:0] tx_data;
    wire tx_out;
    wire busy;

    reg [2:0] state;
    reg [7:0] count;

    initial tx_wr = 'b0;
    initial tx_data = 'h0;

    initial state = 'b000;
    initial count = 'b11111111;

/* count for write enable */
    always @(posedge clk)
    begin
        count <= (count == 0) ? 'b11111111 : count - 'b1;
        tx_wr <= (count == 0 && !busy && state < 'b110) ? 'b1 : 'b0;
    end

/* update current state */
    always @(posedge clk)
    if (tx_wr && !busy)
        state <= state + 'b1;
    else
        state <= (count == 0 && !busy && !(state < 'b110)) ? 'b000 : state;

/* state actions */
    always @(posedge clk)
    case(state)
    'b001: tx_data <= "h";
    'b010: tx_data <= "e";
    'b011: tx_data <= "l";
    'b100: tx_data <= "l";
    'b101: tx_data <= "o";
    'b110: tx_data <= " ";
    default: tx_data <= "";
    endcase

/* outputs */
    always @(posedge clk)
        uart_rxd_out <= tx_out;

    txuart txuart(clk, tx_wr, tx_data, tx_out, busy);

/* formal verification */
`ifdef FORMAL
    reg past_valid;
    initial past_valid = 'b0;
    always @(posedge clk)
    past_valid <= 'b1;

/* check inputs */
    always @(posedge clk)
    if (past_valid && $past(count) != 0)
        assert(count == $past(count) - 1);

    always @(posedge clk)
    if (past_valid && $past(count) == 0)
        assert(count == 'b11111111);

    always @(posedge clk)
    if (past_valid && $past(count) == 0 && !$past(busy) && $past(state) < 'b110)
        assert(tx_wr == 'b1);

    always @(posedge clk)
    if (past_valid && $past(tx_wr))
        assert(!tx_wr);

/* check states */
    always @(posedge clk)
    if (past_valid && $past(tx_wr) && !$past(busy) && $past(state) != 'b111)
        assert(state == $past(state) + 'b1);

/* check outputs */
    always @(posedge clk)
    if (past_valid)
        case($past(state))
        'b001: assert(tx_data == "h");
        'b010: assert(tx_data == "e");
        'b011: assert(tx_data == "l");
        'b100: assert(tx_data == "l");
        'b101: assert(tx_data == "o");
        'b110: assert(tx_data == " ");
        default: assert(tx_data == "");
        endcase

    always @(posedge clk)
    if (past_valid)
        assert(uart_rxd_out == $past(tx_out)) ;

/* check frequency divider */
    // always @(*)
    // cover(count == 0);
    // cover(new_clk == 1);
`endif
    
endmodule
