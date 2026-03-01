# Plan (nicolas)

- control unit
  - branching should work

- LATER: debug environment
  - map program counter to LEDs
  - switch/button debouncing
  - debug mode when END signal is received

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
