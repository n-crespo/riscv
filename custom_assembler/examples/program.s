# program.s
.section .text
.globl _start

_start:
    # initialization
    addi x2, x0, 10
    addi x3, x0, 5

loop:
    lw   x1, 0(x2)
    addi x1, x1, 1
    sw   x1, 0(x2)

    # branch requires knowing the target address
    # the assembler calculates the offset for you
    beq  x1, x3, end_loop

    # jump back to start
    jal  x0, loop

end_loop:
    # 'wait' and 'end' aren't standard RV32I.
    # We'll use a custom nop or an infinite loop for now.
    ebreak             # common way to signal 'stop' to a debugger/sim
    unimp              # illegal instruction often used to signal end
