# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start UART FIFO loopback test")

    # 50 MHz clock (20 ns period, matching CLOCK_PERIOD in src/config.json)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset with UART RX line idle high (ui_in[0] = 1)
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0x01
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # Check initial idle state: TX=1 (bit 0), tx_busy=0 (bit 1), fifo_empty=1 (bit 2), fifo_full=0 (bit 3)
    assert (int(dut.uo_out.value) & 0x0F) == 0b0101

    # Transmit a byte (0xA5) over UART RX at 9600 baud (5208 clocks per bit)
    tx_byte = 0xA5
    bit_clocks = 5208

    # Start bit (0)
    dut.ui_in.value = 0x00
    await ClockCycles(dut.clk, bit_clocks)

    # 8 data bits (LSB first)
    for i in range(8):
        bit_val = (tx_byte >> i) & 1
        dut.ui_in.value = bit_val
        await ClockCycles(dut.clk, bit_clocks)

    # Stop bit (1)
    dut.ui_in.value = 0x01

    # Wait until transmitter starts sending the start bit (uo_out[0] goes low)
    for _ in range(bit_clocks * 2):
        await ClockCycles(dut.clk, 1)
        if (int(dut.uo_out.value) & 1) == 0:
            break
    assert (int(dut.uo_out.value) & 1) == 0, "Expected UART TX start bit (0)"

    # Advance to middle of start bit, then sample 8 data bits
    await ClockCycles(dut.clk, bit_clocks // 2)
    rx_byte = 0
    for i in range(8):
        await ClockCycles(dut.clk, bit_clocks)
        rx_bit = int(dut.uo_out.value) & 1
        rx_byte |= (rx_bit << i)

    # Check stop bit
    await ClockCycles(dut.clk, bit_clocks)
    assert (int(dut.uo_out.value) & 1) == 1, "Expected UART TX stop bit (1)"
    assert rx_byte == tx_byte, f"Expected 0x{tx_byte:02X}, got 0x{rx_byte:02X}"

