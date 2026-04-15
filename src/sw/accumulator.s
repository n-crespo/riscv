# Performs a sequential vector sum and terminates with ebreak
# Registers: x10 (ptr), x11 (counter), x12 (sum), x5 (temp load)

# initialize pointers and constants
.org 0x00
addi x10, x0, 1024     # data pointer (base address 0x400)
addi x11, x0, 4        # loop counter (4 elements)
addi x12, x0, 0        # accumulator (sum = 0)

# manually prep memory with test data
addi x5, x0, 10
sw   x5, 0(x10)        # mem[1024] = 10
addi x5, x0, 20
sw   x5, 4(x10)        # mem[1028] = 20
addi x5, x0, 30
sw   x5, 8(x10)        # mem[1032] = 30
addi x5, x0, 40
sw   x5, 12(x10)       # mem[1036] = 40

# load value and add to accumulator
loop:
	lw  x5, 0(x10)        # fetch current pixel/value
	add x12, x12, x5      # sum = sum + pixel

	addi x10, x10, 4       # move to next word
	addi x11, x11, -1      # decrement counter
	bne  x11, x0, loop     # stay in loop if counter != 0

	sw x12, 16(x0)       # save result to address 16

	ebreak
