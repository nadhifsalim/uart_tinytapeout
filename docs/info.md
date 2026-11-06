<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a UART transceiver buffered by an 8-byte synchronous FIFO (`tt_um_uart_fifo`), configured for a 50 MHz system clock (`CLOCK_PERIOD = 20` ns) and 9600 baud (8N1):

- **UART Receiver (`receiver.v`)**: Oversamples the incoming `uart_rx` (`ui_in[0]`) serial line at 16x the baud rate (`counter` with `M = 326`) to detect the start bit, sample 8 data bits (LSB first), and validate the stop bit.
- **Synchronous FIFO (`fifo.v`)**: Buffers up to 8 received bytes (`WIDTH = 8, DEPTH = 8`) between the receiver and transmitter and exposes `fifo_empty` (`uo_out[2]`) and `fifo_full` (`uo_out[3]`) flags.
- **UART Transmitter (`transmitter.v`)**: Automatically reads buffered bytes from the FIFO when non-empty and shifts them out serially on `uart_tx` (`uo_out[0]`) at 9600 baud (`counter` with `M = 5208`), asserting `tx_busy` (`uo_out[1]`) while a frame is in flight.

## How to test

1. Drive `clk` at 50 MHz and hold `ui_in[0]` (`uart_rx`) high (idle) while pulsing `rst_n` low to reset the design.
2. Send 8N1 UART frames at 9600 baud into `ui_in[0]` (`uart_rx`).
3. Observe the buffered frames transmitted back out on `uo_out[0]` (`uart_tx`) along with status flags on `uo_out[3:1]`.

## External hardware

USB-to-UART adapter (3.3V logic level) connected to `ui_in[0]` (RX) and `uo_out[0]` (TX).

