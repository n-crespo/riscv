# program.s
.section .text
.globl   _start

_start:
# initialization
addi x2, x0, 10
addi x3, x0, 5

loop:
	lw   x1, 0(x2)
	addi x1, x1, 1
	sw   x1, 0(x2)

	beq x1, x3, end_loop

	jal x0, loop

end_loop:
	ebreak
