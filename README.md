<div align="center">

# 32-bit RISC-V Microprocessor

A RISC-V processor core with dynamic instruction loading and a memory-mapped pixel processor.

</div>

## Project Overview

This project implements a custom 32-bit RISC-V microprocessor based on the RV32I ISA. It has been deployed onto a Xilinx Artix-7 Basys 3 FPGA and features a UART Snooper for live code deployment.

## Architecture Diagram

![Architecture Diagram](./docs/lab4.png)

## Getting Started

### 1. Requirements

- RISC-V Toolchain: `riscv64-unknown-elf-` for assembling `.s` files
- Simulator: `iverilog` (recommended) or Xilinx Vivado 2025.2+.
- `just`: a fancy Makefile

### 2. Running Simulations

The testing suite can be run with `just`:

```bash
# Run the full RV32I regression test suite
just test
```

### 3. FPGA Deployment

To generate the bitstream and program the Basys3 board:

```bash
just bitstream
just program
```
