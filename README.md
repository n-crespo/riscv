<div align="center">

# 32-bit RISC-V Microprocessor

A RISC-V processor core with dynamic instruction loading and a memory-mapped pixel processor.

</div>

## Project Overview

This project implements a custom 32-bit RISC-V microprocessor based on the RV32I ISA. It has been deployed onto the Basys3 FPGA and features a UART Snooper for live code deployment.

## Architecture Diagram

The processor is divided into two concurrent stages. The pipeline bridge handles control hazards through hardware flushing and ensures data synchronization between the fetch cycle and the ALU.

![Architecture Diagram](./docs/lab4.png)

## Getting Started

### 1. Requirements

- RISC-V Toolchain: `riscv64-unknown-elf-` for assembling `.s` files.
- Simulator: `iverilog` (recommended) or Xilinx Vivado 2025.2+.
- `just`: for building and running

### 2. Running Simulations

The project includes a robust automated testing suite managed via `Makefile`:

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
