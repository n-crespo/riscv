# ----------------------------------
# --- Logic Paths and Basic Math ---
# ----------------------------------
.org 0x00               # starts at uut.instruction_memory.ram[0]

addi x1, x0, 5 # x1 = x0+5 = 5
addi x2, x0, 7 # x2 = x0+7 = 7
add  x3, x1, x2 # x3 = x1 + x2 = 12
sw   x3, 4(x0) # store value in x3 (12) in memory at address 4
lw   x4, 4(x0) # x4 <- value at memory address 4 (12)
beq  x3, x4, L1 # jump to L1 if x3 == x4 (12 == 12)
addi x5, x0, 99 # SKIPPED (x5 = 99)

L1:
	jal  x6, L2 # jump to L2 (+8 bytes, 4 bytes per instruction)
	addi x7, x0, 99 # SKIPPED (x7 = 00)

L2:
	addi x8, x0, 1 # x8 = 1
	addi x0, x0, 50 # test x0 hard-wiring (x0 = 50 shouldn't change x0)
	addi x9, x0, -10 # x9 = -10 (test sign extension)
	beq  x1, x2, L3 # NOT TAKEN jump to L3 if x1 == x2 (5 == 7)
	addi x10, x0, 42 # x10 = 42

L3:

# -------------------------------------------------------
# --- RAM Module Throughput and Invalid Opcode Safety ---
# -------------------------------------------------------
.org 0x38               # 14 * 4 = 0x38 (starts at uut.instruction_memory.ram[14])

addi  x11, x0, 10 # x11 = 10 (setup for dependency)
addi  x12, x11, 5 # x12 = 10+5 = 15 (raw dependency)
sw    x12, 8(x0) # mem[8] <- 15 (memory throughput store)
lw    x13, 8(x0) # x13 <- mem[8] (should be 15) (memory throughput load)
.word 0x0000000B # send invalid opcode
addi  x14, x0, 1 # x14 = 1 (this should execute despite invalid opcode above)

# ---------------------------------------------------------
# --- Pixel Accelerator (uses Memory Mapped I/O (MIMO)) ---
# ---------------------------------------------------------
.org 0x50               # 20 * 4 = 0x50 (starts at uut.instruction_memory.ram[20])

addi x15, x0, 128 # x15 = 128 = 0x80 (base address 0x80)

# set the threshold
addi x16, x0, 0 # x16 = 0 (set threshold to 0)

# ADDRESS 132 (holds the threshold)
# Bits:  [31:24]    [23:16]    [15:8]     [7:0]
# Field:  (unused)   (unused)   (unused)   Threshold
# Value:  (00)       (00)       (00)       (0)    <-- Just set to zero

sw x16, 4(x15) # mem[132] = 0 (store threshold)

# send the pixel
addi x17, x0, 255 # x17 = 255 (load color blue)
sw   x17, 0(x15) # mem[128] = 255 (send pixel)

# ADDRESS 128 (holds the pixel)
# Bits:  [31:24]    [23:16]    [15:8]     [7:0]
# Field:  Alpha      Red        Green      Blue
# Value:  (00)       (00)       (00)       (255)  <-- Pure Blue

# save the result
addi x0, x0, 0 # wait a few cycles to ensure the processor is finished
addi x0, x0, 0 # nop
lw   x18, 0(x15) # read pixel processor result back into reg 18 (for testing)

# ------------
# --- jalr ---
# ------------
.org 0x70               # 28 * 4 = 0x70 (starts at uut.instruction_memory.ram[28])

jal  x1, J1 # jump to J1, save return address in x1
addi x19, x0, 99 # return point: x19 = 99
jal  x0, J2 # escape: jump to J2

J1:
	addi x20, x0, 42 # jump lands here: (function body) x20 = 42
	jalr x0, 0(x1) # return!

J2:

# ------------------------------
# --- Sub Word Memory Access ---
# ------------------------------
.org 0x84               # 33 * 4 = 0x84 (starts at uut.instruction_memory.ram[33])

# store tests (source, destination)
addi x25, x0, 64 # x25 = 64 (Base Address)
addi x26, x0, 0xAA # x26 = 170
sb   x26, 0(x25) # first byte of x26 -> byte 0 of mem[x25]
addi x26, x0, 0xBB # x26 = 187
sb   x26, 1(x25) # first byte of x26 -> byte 1 of mem[x25]
addi x26, x0, 0xCC # x26 = 204
sb   x26, 2(x25) # first byte of x26 -> byte 2 of mem[x25]
addi x26, x0, 0xDD # x26 = 221
sb   x26, 3(x25) # first byte of x26 -> byte 3 of mem[x25]

# load tests
lw  x27, 0(x25) # x27 <- bytes 0, 1, 2, 3 of mem[x25] (full word)
lhu x28, 0(x25) # x28 <- bytes 0, 1 of mem[x25] (unsigned half)
lh  x29, 2(x25) # x29 <- bytes 2, 3 of mem[x25] (signed half)
lbu x30, 1(x25) # x30 <- byte 1 of mem[x25] (unsigned byte)
lb  x31, 3(x25) # x31 <- byte 3 of mem[x25] (signed byte)

# store halfword test
addi x23, x0, 0x5A5 # x23 = 1, 445
sh   x23, 2(x25) # first 2 bytes of x23 -> bytes 2 & 3 of mem[x25]
lw   x24, 0(x25) # x24 <- bytes 0, 1, 2, 3 of mem[x25]

# -------------------------
# --- Branch Comparator ---
# -------------------------
.org 0xC8               # 50 * 4 = 0xC8 (starts at uut.instruction_memory.ram[50])

# branch comparator setup
addi x21, x0, 10 # x21 <- 10
addi x22, x0, -5 # x22 <- -5

# test bne (10 != -5)
addi x5, x0, 0 # x5 = 0 (initialize flag)
bne  x21, x22, B1 # jump to B1 if (10 != -5)
jal  x0, B2 # skip success

B1:
	addi x5, x0, 1 # x5 = 1 (success)

B2:

# test blt (-5 < 10)
addi x6, x0, 0 # x6 = 0 (initialize flag)
blt  x22, x21, B3 # jump to B3 if (-5 < 10)
jal  x0, B4 # skip success

B3:
	addi x6, x0, 1 # x6 = 1 (success)

B4:

# test bge (10 >= -5)
addi x7, x0, 0 # x7 = 0 (initialize flag)
bge  x21, x22, B5 # jump to B5 if (-10 > -5)
jal  x0, B6 # jump to B6, don't set success flag (THIS SHOULD BE SKIPPED)

B5:
	addi x7, x0, 1 # x7 = 1 (success)

B6:

# -------------------------
# --- U-Type Instructions ---
# -------------------------
.org 0x100               # 64 * 4 = 0x100 (starts at ram[64])

# Load 0x12345 into the upper 20 bits of x22
lui x22, 0x12345 # Result should be 0x12345000

# Add 0x00001 to the current PC and store in x23
# The PC at this instruction is 0x104 (byte address).
# PC (0x104) + 0x00001000 = 0x00001104
auipc x23, 0x1

end_sim:
	addi x2, x0, 1 # set finished flag
	jal  x0, end_sim # infinite loop so flag is always set
