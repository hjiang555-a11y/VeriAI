# I2C Master Controller

A gold-standard, parameterized I2C master controller designed for FPGA implementation.

## Overview
This module implements a complete I2C master state machine, supporting both Standard Mode (100kHz) and Fast Mode (400kHz). It handles 7-bit addressing, bidirectional data flow, and clock stretching.

## Features
- **Parameterized Frequency**: Supports 100kHz or 400kHz via `I2C_FREQ` parameter.
- **Full Protocol Support**: START, STOP, Repeated START, and 7-bit addressing.
- **Clock Stretching**: Automatically detects and waits for slave clock stretching.
- **Robust Error Handling**: Reports NACK errors via `ack_err` signal.
- **Synthesizable**: Written in Verilog-2001, optimized for Xilinx 7-series FPGAs.

## Interface Specification

| Signal | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | In | 1 | System Clock |
| `rst_n` | In | 1 | Synchronous active-low reset |
| `cmd` | In | 3 | Command: 0=START, 1=STOP, 2=WRITE, 3=READ_ACK, 4=READ_NACK |
| `cmd_start` | In | 1 | Command trigger pulse |
| `dev_addr` | In | 7 | Target slave device address |
| `tx_data` | In | 8 | Data byte to transmit |
| `rx_data` | Out | 8 | Received data byte |
| `rx_valid` | Out | 1 | Pulse indicating transfer completion |
| `ack_err` | Out | 1 | High if NACK was received |
| `busy` | Out | 1 | High during active transaction |
| `bus_busy` | Out | 1 | High when I2C bus is occupied |
| `scl_o` | Out | 1 | SCL open-drain output |
| `scl_i` | In | 1 | SCL input (sampling for stretching) |
| `sda_o` | Out | 1 | SDA open-drain output |
| `sda_i` | In | 1 | SDA input (sampling for data/ACK) |

## Verification Summary
- **Static Analysis**: RTL verified against I2C specification v6.0.
- **Testbench**: `tb_i2c_master.v` covers basic write/read, NACK detection, and clock stretching.
- **Verification Status**: $\checkmark$ RTL Logic Validated.

## Acceptance Checklist
- [x] 7-bit Address Phase correctly implemented
- [x] Start/Stop conditions generated accurately
- [x] ACK/NACK detection functional
- [x] Clock stretching handled via `scl_i` sensing
- [x] Parameterized clock division operational
