# Notes

Inline Assembly + C macros

```c
#define VMAC8(rd, rs1, rs2) \
  asm volatile(".word 0x00B50533" : [dst] "=r" (rd) : [s1] "r" (rs1), [s2] "r" (rs2))

```

neural networks require "spatial stationary", rigid grids (image/video)

## Neural Network Inference

- will not implement floating point
  - instead, quantization (-1, 1) --> (-128, 128)
- will benchmark
  - baseline: (CNN code with only standard RISC-V instructions)
  - accelerated: swap inner MAC loop with custom VMAC MMIO calls
  - check cycle count with Verilator!

- [ ] train a model on `MNIST`
- [ ] print one layer of weights to a text file
- [ ] write C to read weights/perform convolution
- [ ] compile to RISCV, check it output matches python

- MobileNet
  - (with width multiplier of 0.25)?
  - uses Depthwise Separable Convolutions instead of normal convolution
