/*
 * Copyright (c) 2024 nadhifsalim
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/* verilator lint_off DECLFILENAME */
module tt_um_nadhifsalim_uart_fifo (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire rst = !rst_n;

    wire line_out;
    wire tx_busy;
    wire fifo_empty;
    wire fifo_full;

    uart_fifo u_uart_fifo (
        .clk     (clk),
        .rst     (rst),
        .line_in (ui_in[0]),
        .line_out(line_out),
        .tx_busy (tx_busy),
        .empty   (fifo_empty),
        .full    (fifo_full)
    );

    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out  = {4'b0000, fifo_full, fifo_empty, tx_busy, line_out};
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
/* verilator lint_on DECLFILENAME */
