`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/10/2024 08:13:11 PM
// Design Name: 
// Module Name: txuart
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

/* 
    data_in: data inputs
    wr_in: write enable
    tx_out: data outputs
    busy_out: writing in progress
*/

module txuart(clk, wr_in, data_in, tx_out, busy_out);

    input wire clk;
    input wire wr_in;
    input wire [7:0] data_in;
    output reg tx_out;
    output reg busy_out;

/* frequency divider and baud */
    // reg [2:0] count;
    // reg new_clk;

    reg [6:0] baud_count;
    reg baud_stb;

    reg [3:0] state;

    /* parameter baud_rate = 'd115200;
    baud_count = 12Mhz / baud_rate */

    initial tx_out = 'b1;
    initial busy_out = 'b0;

    // initial count = 'b111;
    // initial new_clk = 'b0;
    parameter [6:0] bauds = 'b1101001;
    initial baud_count = bauds;
    initial baud_stb = 'b0;

    initial state = 'b0000;

    always @(posedge clk)
    begin
        // if (wr_in && !busy_out)
        //     count <= 'b111;
        // else
        //     count <= (count == 0) ? 'b111 : count - 'b1;
        // new_clk <= (count == 0) ? 'b1 : 'b0;

        if (wr_in && !busy_out)
            baud_count <= bauds;
        else
            baud_count <= (baud_count == 0) ? bauds : baud_count - 'b1;
        baud_stb <= (baud_count == 0) ? 'b1 : 'b0;
    end

/* update current state */
    always @(posedge clk)
    if (wr_in && !busy_out)
        state <= 'b0001;
    else if ((state == 'b1010) && baud_stb)
        state <= 'b0000;
    else if ((state != 'b0000) && baud_stb)
        state <= state + 'b1;
    else
        state <= state;

/* state actions */
    always @(posedge clk)
    case (state)
    'b0001: tx_out <= 'b0;
    'b0010: tx_out <= data_in[0];
    'b0011: tx_out <= data_in[1];
    'b0100: tx_out <= data_in[2];
    'b0101: tx_out <= data_in[3];
    'b0110: tx_out <= data_in[4];
    'b0111: tx_out <= data_in[5];
    'b1000: tx_out <= data_in[6];
    'b1001: tx_out <= data_in[7];
    'b1010: tx_out <= 'b1;
    default: tx_out <= tx_out;
    endcase

/* outputs wiring */
    always @(posedge clk)
        busy_out <= !(state == 'b0000);

/* formal verification */
`ifdef FORMAL
    reg past_valid;
    initial past_valid = 'b0;
    always @(posedge clk)
    past_valid <= 'b1;

/* check inputs */
    always @(posedge clk)
    if (past_valid && $past(busy_out))
        assert(data_in == $past(data_in));

/* check states */
    always @(posedge clk)
    if (past_valid && $past(wr_in) && !$past(busy_out))
            assert(state <= 'b0001);

    always @(posedge clk)
    if (past_valid && $past(state) == 'b1010 && $past(baud_stb))
            assert(state == 'b0000);

    always @(posedge clk)
    if (past_valid && $past(state) != 'b0000 && $past(state) != 'b1010 && $past(baud_stb) && (!$past(wr_in) || $past(busy_out)))
        assert(state == ($past(state) + 'b1));

    always @(*)
    begin
        case (state)
        'b0000: assert(1);
        'b0001: assert(1);
        'b0010: assert(1);
        'b0011: assert(1);
        'b0100: assert(1);
        'b0101: assert(1);
        'b0110: assert(1);
        'b0111: assert(1);
        'b1000: assert(1);
        'b1001: assert(1);
        'b1010: assert(1);
        default: assert(0);
        endcase
    end

/* check baud */
    always @(posedge clk)
    if (past_valid && $past(wr_in) && !$past(busy_out))
        assert(baud_count == bauds);

    always @(posedge clk)
    if (past_valid && $past(baud_count) == 0)
        assert(baud_count == bauds);

    always @(posedge clk)
    if (past_valid && $past(baud_count) != 0 && (!$past(wr_in) || $past(busy_out)))
        assert(baud_count == ($past(baud_count) - 'b1));

    always @(posedge clk)
    if (past_valid && $past(baud_count == 0))
        assert(baud_stb == 'b1);

/* check outputs */
    always @(posedge clk)
    if (past_valid && $past(baud_stb))
    begin
        case ($past(state))
        'b0000: assert(1);
        'b0001: assert(tx_out == 'b0);
        'b0010: assert(tx_out == data_in[0]);
        'b0011: assert(tx_out == data_in[1]);
        'b0100: assert(tx_out == data_in[2]);
        'b0101: assert(tx_out == data_in[3]);
        'b0110: assert(tx_out == data_in[4]);
        'b0111: assert(tx_out == data_in[5]);
        'b1000: assert(tx_out == data_in[6]);
        'b1001: assert(tx_out == data_in[7]);
        'b1010: assert(tx_out == 'b1);
        default: assert(0);
        endcase
    end

    always @(posedge clk)
    if (past_valid)
        assert(busy_out == !($past(state) == 'b0000));

/* check frequency divider */
    // always @(*)
    // cover(count == 0);
    // cover(new_clk == 1);
`endif
    
endmodule
