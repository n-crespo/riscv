`timescale 1ns / 1ps

// this tests:
// - arithmetic operations (r_type and i_type)
// - loading and storing data to RAM (lw and sw)
// - sign extension of negative constants by immediate generator
//
// - jumping and branching causes nonsequential program counter (beq, jal)
// - jal saves correct return address into destination register
// - jumps are ignored when branch condition is false
//
// - register x0 cannot be written to and is always zero
// - Read-after-write (using a result calculated in previous instruction)
// - memory throughput (consecutive mempory store/load without corruption)
// - control unit disables all write-enables on invalid opcode

module tb;

  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

  integer tests_passed = 0;
  integer tests_failed = 0;

  // instantiate the top module
  top uut (
      .clk  (clk),
      .reset(reset),
      .RsRx (RsRx),
      .led  (led)
  );

  // generate a 100MHz clock (10ns period)
  always #5 clk = ~clk;

  initial begin
    clk = 0;
    reset = 1;
    RsRx = 1;

    // --- Logic Paths (0-13) ---
    uut.instruction_memory.ram[0] = 32'h00500093;  // addi x1, x0, 5
    uut.instruction_memory.ram[1] = 32'h00700113;  // addi x2, x0, 7
    uut.instruction_memory.ram[2] = 32'h002081b3;  // add x3, x1, x2
    uut.instruction_memory.ram[3] = 32'h00302223;  // sw x3, 4(x0)
    uut.instruction_memory.ram[4] = 32'h00402203;  // lw x4, 4(x0)
    uut.instruction_memory.ram[5] = 32'h00418463;  // beq x3, x4, 8
    uut.instruction_memory.ram[6] = 32'h06300293;  // addi x5, x0, 99 (skip)
    uut.instruction_memory.ram[7] = 32'h0080036f;  // jal x6, 8
    uut.instruction_memory.ram[8] = 32'h06300393;  // addi x7, x0, 99 (skip)
    uut.instruction_memory.ram[9] = 32'h00100413;  // addi x8, x0, 1
    uut.instruction_memory.ram[10] = 32'h03200013;  // addi x0, x0, 50
    uut.instruction_memory.ram[11] = 32'hff600493;  // addi x9, x0, -10
    uut.instruction_memory.ram[12] = 32'h00208463;  // beq x1, x2, 8 (not taken)
    uut.instruction_memory.ram[13] = 32'h02a00513;  // addi x10, x0, 42

    // --- Throughput & Dependency Paths ---
    // 14: addi x11, x0, 10   -> Setup for dependency
    uut.instruction_memory.ram[14] = 32'h00a00593;
    // 15: addi x12, x11, 5   -> RAW Dependency: x11 is used immediately
    uut.instruction_memory.ram[15] = 32'h00558613;
    // 16: sw x12, 8(x0)      -> Memory throughput: back-to-back store
    uut.instruction_memory.ram[16] = 32'h00c02423;
    // 17: lw x13, 8(x0)      -> Memory throughput: back-to-back load
    uut.instruction_memory.ram[17] = 32'h00802683;
    // 18: 32'h0000000b       -> Invalid Opcode (Custom-0 space)
    // This should do nothing (no reg write, no mem write)
    uut.instruction_memory.ram[18] = 32'h0000000b;
    // 19: addi x14, x0, 1    -> Flag to show we finished
    uut.instruction_memory.ram[19] = 32'h00100713;

    // 20: addi x15, x0, 128    -> Base address 0x80
    uut.instruction_memory.ram[20] = 32'h08000793;

    // 21: addi x16, x0, 0      -> Set Threshold = 0 (ANY color becomes white)
    uut.instruction_memory.ram[21] = 32'h00000813;

    // 22: sw x16, 4(x15)       -> Store 0 to 0x84
    uut.instruction_memory.ram[22] = 32'h0107a223;

    // 23: addi x17, x0, 255    -> Load 255 (Bright Blue) using standard ADDI
    uut.instruction_memory.ram[23] = 32'h0ff00893;

    // 24: sw x17, 0(x15)       -> Send pixel to 0x80
    uut.instruction_memory.ram[24] = 32'h0117a023;

    // --- NOPs for Pipeline Latency ---
    uut.instruction_memory.ram[25] = 32'h00000013;  // nop
    uut.instruction_memory.ram[26] = 32'h00000013;  // nop

    // 27: lw x18, 0(x15)       -> Read result back
    uut.instruction_memory.ram[27] = 32'h0007a903;

    // --- JALR Function Call Test ---
    // 28: jal x1, 12           -> Jump forward 3 words (to index 31). Save '29' in x1.
    uut.instruction_memory.ram[28] = 32'h00c000ef;

    // 29: addi x19, x0, 99     -> RETURN POINT. Set x19 = 99 to prove we came back.
    uut.instruction_memory.ram[29] = 32'h06300993;

    // 30: jal x0, 12           -> ESCAPE. Jump forward 3 words to index 33 (Infinite Loop).
    uut.instruction_memory.ram[30] = 32'h00c0006f;

    // 31: addi x20, x0, 42     -> FUNCTION BODY. Set x20 = 42 to prove we jumped here.
    uut.instruction_memory.ram[31] = 32'h02a00a13;

    // 32: jalr x0, 0(x1)       -> RETURN. Jump to address in x1 (which is 29).
    uut.instruction_memory.ram[32] = 32'h00008067;

    // --- Sub-Word Memory Access Tests ---
    // 33: addi x25, x0, 64     -> Set base address to 64
    uut.instruction_memory.ram[33] = 32'h04000c93;

    // Store 4 individual bytes sequentially to build the word 0xDDCCBBAA
    // 34: addi x26, x0, 0xAA   -> Load 0xAA into x26
    uut.instruction_memory.ram[34] = 32'h0aa00d13;
    // 35: sb x26, 0(x25)       -> Store 0xAA at address 64 (Byte 0)
    uut.instruction_memory.ram[35] = 32'h01ac8023;

    // 36: addi x26, x0, 0xBB   -> Load 0xBB into x26
    uut.instruction_memory.ram[36] = 32'h0bb00d13;
    // 37: sb x26, 1(x25)       -> Store 0xBB at address 65 (Byte 1)
    uut.instruction_memory.ram[37] = 32'h01ac80a3;

    // 38: addi x26, x0, 0xCC   -> Load 0xCC into x26
    uut.instruction_memory.ram[38] = 32'h0cc00d13;
    // 39: sb x26, 2(x25)       -> Store 0xCC at address 66 (Byte 2)
    uut.instruction_memory.ram[39] = 32'h01ac8123;

    // 40: addi x26, x0, 0xDD   -> Load 0xDD into x26
    uut.instruction_memory.ram[40] = 32'h0dd00d13;
    // 41: sb x26, 3(x25)       -> Store 0xDD at address 67 (Byte 3)
    uut.instruction_memory.ram[41] = 32'h01ac81a3;

    // Now test the loads!
    // 42: lw x27, 0(x25)       -> Load Word. Expect x27 = 0xDDCCBBAA
    uut.instruction_memory.ram[42] = 32'h000cad83;

    // 43: lhu x28, 0(x25)      -> Load Half Unsigned (Bytes 1-0). Expect x28 = 0x0000BBAA
    uut.instruction_memory.ram[43] = 32'h000cde03;

    // 44: lh x29, 2(x25)       -> Load Half Signed (Bytes 3-2). 0xDDCC is negative! Expect x29 = 0xFFFFDDCC
    uut.instruction_memory.ram[44] = 32'h002c9e83;

    // 45: lbu x30, 1(x25)      -> Load Byte Unsigned (Byte 1). Expect x30 = 0x000000BB
    uut.instruction_memory.ram[45] = 32'h001ccf03;

    // 46: lb x31, 3(x25)       -> Load Byte Signed (Byte 3). 0xDD is negative! Expect x31 = 0xFFFFFFDD
    uut.instruction_memory.ram[46] = 32'h003c8f83;

    // 47: addi x23, x0, 0x5A5  // load 0x05A5 into x23
    uut.instruction_memory.ram[47] = 32'h5a500b93;

    // 48: sh x23, 2(x25)       // store halfword 0x05A5 at address 66
    uut.instruction_memory.ram[48] = 32'h017c9123;

    // 49: lw x24, 0(x25)       // load the full word back into x24 to check the damage
    uut.instruction_memory.ram[49] = 32'h000cac03;

    // --- branch comparator tests ---
    // set up test values
    // 50: addi x21, x0, 10
    uut.instruction_memory.ram[50] = 32'h00a00a93;
    // 51: addi x22, x0, -5
    uut.instruction_memory.ram[51] = 32'hffb00b13;

    // test bne: 10 != -5
    // 52: addi x28, x0, 0       // initialize flag to 0
    // test bne (10 != -5)
    // initialize flag to 0
    uut.instruction_memory.ram[52] = 32'h00000293;
    uut.instruction_memory.ram[53] = 32'h016a9463;
    uut.instruction_memory.ram[54] = 32'h0080006f;
    // success, set x5 to 1
    uut.instruction_memory.ram[55] = 32'h00100293;

    // test blt (-5 < 10)
    // initialize flag to 0
    uut.instruction_memory.ram[56] = 32'h00000313;
    uut.instruction_memory.ram[57] = 32'h015b4463;
    uut.instruction_memory.ram[58] = 32'h0080006f;
    // success, set x6 to 1
    uut.instruction_memory.ram[59] = 32'h00100313;

    // test bge (10 >= -5)
    // initialize flag to 0
    uut.instruction_memory.ram[60] = 32'h00000393;
    uut.instruction_memory.ram[61] = 32'h016ad463;
    uut.instruction_memory.ram[62] = 32'h0080006f;

    // success, set x7 to 1
    uut.instruction_memory.ram[63] = 32'h00100393;
    // --- clean, consolidated time delay ---
    // adjust the run time to ensure PC reaches the final index
    #22 reset = 0;
    #2000;

    $display("--- SIMULATION RESULTS ---");

    // basic logic & memory
    check_test(uut.registers.registers[3], 12, "math logic");
    check_test(uut.registers.registers[4], 12, "memory logic");
    check_test(uut.registers.registers[0], 0, "x0 hard-wired to zero");
    check_test(uut.registers.registers[9], 32'hfffffff6, "sign extension");
    check_test(uut.registers.registers[10], 42, "branch-not-taken");

    // dependencies & safety
    check_test(uut.registers.registers[12], 15, "RAW data dependency");
    check_test(uut.registers.registers[13], 15, "memory throughput");
    check_test({uut.registers.registers[14], uut.registers.registers[0]}, {32'd1, 32'd0},
               "invalid opcode safety");

    // accelerator & function calls
    check_test(uut.registers.registers[18], 32'h00FFFFFF, "pixel accelerator");
    check_test({uut.registers.registers[20], uut.registers.registers[19]}, {32'd42, 32'd99},
               "jalr function return");

    // sub-word memory access
    check_test(uut.registers.registers[27], 32'hDDCCBBAA, "sb and lw logic");
    check_test({uut.registers.registers[28], uut.registers.registers[29]}, {
               32'h0000BBAA, 32'hFFFFDDCC}, "lh/lhu logic");
    check_test({uut.registers.registers[30], uut.registers.registers[31]}, {
               32'h000000BB, 32'hFFFFFFDD}, "lb/lbu logic");
    check_test(uut.registers.registers[24], 32'h05A5BBAA, "sh logic");

    // branch comparator
    check_test(uut.registers.registers[5], 1, "bne logic");
    check_test(uut.registers.registers[6], 1, "blt logic");
    check_test(uut.registers.registers[7], 1, "bge logic");

    $display("--------------------------");
    $display("SUMMARY: %0d PASSED, %0d FAILED", tests_passed, tests_failed);
    $display("--------------------------");
    $finish;
  end

  // task to automate the pass/fail boilerplate
  task check_test(input [31:0] actual, input [31:0] expected, input [127:0] test_name);
    begin
      if (actual === expected) begin
        $display("PASS: %s", test_name);
        tests_passed = tests_passed + 1;
      end else begin
        $display("FAIL: %s (Actual: %h, Expected: %h)", test_name, actual, expected);
        tests_failed = tests_failed + 1;
      end
    end
  endtask

endmodule
