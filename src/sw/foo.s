# foo.s - minimal alu and register file test
.section .text
.globl   _start

_start:
# test addi: x1 = 0 + 10
addi x1, x0, 10

# test addi: x2 = 0 + 5
addi x2, x0, 5

# test add: x3 = x1 + x2 (should be 15)
add x3, x1, x2

# test x0 hardwiring: x4 = x3 + x0 (should still be 15)
add x4, x3, x0

loop:
# infinite loop to stop pc from running into empty memory
j loop
