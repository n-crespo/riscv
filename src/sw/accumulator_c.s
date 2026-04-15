	.file	"accumulator_c.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	li	a5,1024
	li	a4,10
	sw	a4,0(a5)
	li	a1,1028
	li	a4,20
	sw	a4,0(a1)
	li	a2,1032
	li	a4,30
	sw	a4,0(a2)
	li	a3,1036
	li	a4,40
	sw	a4,0(a3)
	li	a0,50
	li	a4,1040
	sw	a0,0(a4)
	lw	a5,0(a5)
	lw	a1,0(a1)
	lw	a2,0(a2)
	lw	a3,0(a3)
	add	a5,a5,a1
	lw	a4,0(a4)
	add	a5,a5,a2
	add	a5,a5,a3
	add	a5,a5,a4
	sw	a5,16(zero)
 #APP
# 28 "sw/accumulator_c.c" 1
	ebreak
# 0 "" 2
 #NO_APP
	ret
	.size	main, .-main
	.ident	"GCC: (13.2.0-11ubuntu1+12) 13.2.0"
