# The Simple Accumulator

Two programs were written.

1. `accumulator.s`, in bare assembly, and
2. `accumulator_c.c`, in C, which was compiled (with `just compile accumulator_c`) into `accumulator_c.s`

Running against the same test bench (below) reveals that they both are able to
achieve the same result, but the compiler's optimization (e.g. loop unrolling)
_drastically_ reduced the total clock cycles and instructions required.

Bare assembly:

```shell
~/dev/riscv/src main* ❯ just run accumulator accumulator
--- LOGIC VERIFICATION ---
PASS: emory address 16

================ PERFORMANCE REPORT ================
Total Cycles          :         45
Instructions Retired  :         43
Average CPI           :       1.05
====================================================
```

Compiled from C:

```
~/dev/riscv/src main* ❯ just run accumulator_c accumulator
--- LOGIC VERIFICATION ---
PASS: emory address 16

================ PERFORMANCE REPORT ================
Total Cycles          :         27
Instructions Retired  :         25
Average CPI           :       1.08
====================================================

tb/accumulator.v:50: $finish called at 295000 (1ps)
```
