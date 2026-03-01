// initialization
ADDI x2, x0, 10
ADDI x3, x0, 5

// pass 1 records the memory address of this label
LOOP:
    LW x1, 0(x2)
    ADDI x1, x1, 1
    SW x1, 0(x2)

    // branch requires knowing the target address
    BEQ x1, x3, END_LOOP

    // jump back to start
    JAL x0, LOOP

END_LOOP:
    WAIT
    END
