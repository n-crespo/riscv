# Fibonacci Sequence: 0, 1, 1, 2, 3...
# Result should be 3 in x3

addi x1, x0, 0      # f0 = 0
addi x2, x0, 1      # f1 = 1
addi x4, x0, 3      # counter = 3 (Reduced for faster simulation)

loop:
	add  x3, x1, x2  # next = f0 + f1
	addi x1, x2, 0   # f0 = f1
	addi x2, x3, 0   # f1 = next
	addi x4, x4, -1  # counter--
	bne  x4, x0, loop # repeat until x4 is 0

# Final result is in x3
addi x0, x0, 0      # NOP for pipeline safety
