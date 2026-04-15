# Notes

## Architecture Improvements

- [ ] simpler ALU
- [ ] more space for RAM (16kb)

## Inline Assembly + C macros

```c
#define VMAC8(rd, rs1, rs2) \
  asm volatile(".word 0x00B50533" : [dst] "=r" (rd) : [s1] "r" (rs1), [s2] "r" (rs2))

```

Neural networks require "spatial stationary", rigid grids (image/video)

## Neural Network Inference

- will not implement floating point
  - instead, quantization (-1, 1) --> (-128, 128)
- will benchmark
  - baseline: (CNN code with only standard RISC-V instructions)
  - accelerated: swap inner MAC loop with custom VMAC MMIO calls
  - check cycle count with Verilator!

- [ ] train a CNN on `MNIST`
  - [x] designed for 28x28 MNIST
  - [x] Conv2D: 3x3 kernel, 4-8 filters (vmac)
  - [x] use ReLU as activation function for simplicity (division/exponentials are harder in RV32I)
  - [x] 2x2 maxpool (minimize BRAM)
  - [x] quantize weights with a power of 2 so i can bit shift
  - [ ] **channel count** as multiple of 4 or 8
  - **pruning!**: near zero weights --> 0
  - **flatten/dense** --> 10 outputs for 0-9 digits?

- benchmark
  - cycles per convoluiton
  - memory access count (stalls while waiting for BRAM)

- [ ] print one layer of weights to a text file
  - [ ] python script to grab weights, use include header
- [ ] write C to read weights/perform convolution
- [ ] compile to RISCV, check it output matches python

- MobileNet
  - (with width multiplier of 0.25)?
  - uses Depthwise Separable Convolutions instead of normal convolution
