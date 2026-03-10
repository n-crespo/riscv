# RISC-V 32I Pipelined Processor

A high-performance, 2-stage pipelined RISC-V processor core implemented in Verilog. This core is designed for FPGA deployment, featuring a modular architecture, synchronous memory integration, and a custom UART-based instruction "snooper" for dynamic code loading.

This project implements the RV32I Base Integer Instruction Set with a Fetch/Execute pipeline. Splitting the instruction cycle into two distinct stages achieves higher clock frequencies by shortening the critical path. It is specifically optimized for modern FPGA hardware (like the Xilinx Artix-7) by utilizing Synchronous Block RAM (BRAM) for instruction storage.

## Key Features

- Architecture: 2-Stage Pipeline (Fetch | Execute).
- ISA: RISC-V RV32I (Base Integer) compatible.
- Memory Model: Synchronous Instruction Memory (BRAM-ready) and Asynchronous Data Memory.
- Control Flow: Hardware-based Pipeline Flushing (1-cycle branch penalty) to handle control hazards.
- I/O & Debug: UART RX Snooper allows for uploading program hex files without re-synthesizing the bitstream.
- Optimizations: One-Hot encoded control unit and fast XOR-based zero detection for branches.

## Module Overview

### Instruction Fetch (IF)

- `pc.v`: The Program Counter. Holds the address of the next instruction to be fetched.
- `instr_mem.v`: Synchronous memory module. Latches the address on the rising edge and provides the instruction on the next cycle.

### Execute (EX)

- `control_unit.v`: Utilizes One-Hot Encoding to decode opcodes into control signals with minimal logic depth.
- `reg_file.v`: A 32-word general-purpose register file with asynchronous reads and synchronous writes.
- `alu.v`: Performs arithmetic (ADD, SUB), logical (AND, OR, XOR), and comparison (SLT) operations.
- `imm_gen.v`: Extracts and sign-extends immediates for I, S, B, U, and J-type instructions.

### Support & Peripherals

- `uart.v`: Handles serial-to-parallel conversion for the UART snooper.
- `pixel_processor.v`: Dedicated hardware accelerator mapped to a specific memory address for image processing tasks.
