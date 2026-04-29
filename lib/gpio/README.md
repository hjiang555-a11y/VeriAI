# General Purpose I/O (GPIO)

A gold-standard, parameterized GPIO module for FPGA.

## Overview
This module provides a simple and efficient interface for controlling general-purpose input/output pins. Each pin can be independently configured as an input or output.

## Features
- **Fully Parameterized**: Pin width configurable via `WIDTH` parameter (default 32).
- **Independent Control**: Each pin's direction (input/output) is controlled individually.
- **Single-Cycle Access**: Low-latency read/write access.
- **Safe Reset State**: All pins default to input mode on reset to prevent bus contention.
- **High Fidelity**: Implements true bidirectional pin control for FPGA IOBUFs.

## Interface Specification

| Signal | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | In | 1 | System Clock |
| `rst_n` | In | 1 | Synchronous active-low reset |
| `dir` | In | WIDTH | Direction control: 1=Output, 0=Input |
| `out_data` | In | WIDTH | Data to output (when `dir=1`) |
| `in_data` | Out | WIDTH | Current level of the physical pins |
| `gpio_pins` | InOut | WIDTH | Physical FPGA pins |

## Verification Summary
- **Static Analysis**: Verified against standard IOBUF behavior.
- **Testbench**: `tb_gpio.v` verifies direction switching and data transparency.
- **Verification Status**: $\checkmark$ RTL Logic Validated.

## Acceptance Checklist
- [x] Per-pin direction control functional
- [x] Input read is combinational and transparent
- [x] Output drive is gated by direction register
- [x] Reset state is high-impedance (Input)
- [x] Parameterized width scaling verified
