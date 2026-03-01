# Plan (nicolas)

- [ ] **Custom Assembler (Python)**: Write a script that reads a text file
      containing custom RISC-V assembly, translates each line into a 32-bit binary
      instruction, and saves it as a binary or hex file.

- [ ] **UART Receiver (Verilog)**: Implement a serial receiver to capture 8-bit packets
      sent from your computer over the USB-serial connection.

- [ ] **Byte Stitcher & Memory Interface (Verilog)**: Build a state machine that collects
      four consecutive 8-bit UART packets, concatenates them into a 32-bit word, and
      writes that word into the FPGA's block RAM.

- [ ] **Peripheral Controllers (Verilog)**: Write the hardware drivers for the user
      interface. This includes a debouncer for the physical buttons (to step the clock
      or pause execution) and a multiplexer to drive the 4-digit 7-segment display.

- [ ] **Top-Level Module (Verilog)**: Create the master file that connects RAM,
      UART, and I/O controllers to Frank's simulated CPU core.

## Fused-MAC Extension

Standard RISC-V requires multiple instructions to perform a single neural
network operation ($Load \rightarrow \ Multiply \rightarrow \ Add$).
This creates a bottleneck at the register file.

- **The Extension:** `vmac.8` (Vector Multiply-Accumulate 8-bit).
- **What it does:** It treats two 32-bit registers as vectors of four 8-bit
  integers (INT8). In a single cycle, it multiplies all four pairs and adds the
  sum to a 32-bit accumulator.
- **Benefit over CPU/GPU:**
  - **vs. CPU:** A CPU would take ~12 instructions to do what this does in 1. This
    reduces power consumption by 50–80% for the same task.
  - **vs. GPU:** GPUs are fast but "jittery." They have variable latency due to
    driver overhead. This extension provides **deterministic latency**—you know
    exactly which clock cycle the result will be ready, which is critical for
    safety-critical robotics.

---

Inline Assembly + C macros

```c
#define VMAC8(rd, rs1, rs2) \
  asm volatile(".word 0x00B50533" : [dst] "=r" (rd) : [s1] "r" (rs1), [s2] "r" (rs2))

```
