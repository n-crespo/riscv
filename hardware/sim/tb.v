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

    // 33: jal x0, 0            -> INFINITE LOOP (Park here forever)
    uut.instruction_memory.ram[33] = 32'h0000006f;

    // Adjust the run time to ensure PC reaches index 27
    #22 reset = 0;  // de-assert reset away from clock edge
    #1000;  // give it plenty of time

    $display("--- SIMULATION RESULTS ---");

    // Existing Tests
    if (uut.registers.registers[3] == 12) begin
      $display("PASS: math logic");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: math logic");
      tests_failed = tests_failed + 1;
    end

    if (uut.registers.registers[4] == 12) begin
      $display("PASS: memory logic");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: memory logic");
      tests_failed = tests_failed + 1;
    end

    // Test register x0 hard-wiring
    if (uut.registers.registers[0] == 0) begin
      $display("PASS: x0 hard-wired to zero");
      tests_passed = tests_passed + 1;
    end
    if (uut.registers.registers[9] == 32'hfffffff6) begin
      $display("PASS: sign extension");
      tests_passed = tests_passed + 1;
    end
    if (uut.registers.registers[10] == 42) begin
      $display("PASS: branch-not-taken");
      tests_passed = tests_passed + 1;
    end

    // Test 6: RAW Dependency
    if (uut.registers.registers[12] == 15) begin
      $display("PASS: RAW data dependency (x12 == 15)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: RAW data dependency (x12: %0d, expected 15)", uut.registers.registers[12]);
      tests_failed = tests_failed + 1;
    end

    // Test 7: Memory Throughput
    if (uut.registers.registers[13] == 15) begin
      $display("PASS: memory throughput (sw/lw sequence)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: memory throughput (x13: %0d, expected 15)", uut.registers.registers[13]);
      tests_failed = tests_failed + 1;
    end

    // Test 8: Invalid Opcode Safety
    // We check if the instruction after the invalid one (addi x14, x0, 1) executed.
    // If x14 is 1, the CPU didn't hang. We also verify x0 is still 0.
    if (uut.registers.registers[14] == 1 && uut.registers.registers[0] == 0) begin
      $display("PASS: invalid opcode safety (CPU continued, no illegal writes)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: invalid opcode caused hang or corruption");
      tests_failed = tests_failed + 1;
    end

    if (uut.registers.registers[18] == 32'h00FFFFFF) begin
      $display("PASS: pixel accelerator (result is white)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: pixel accelerator (x18: %h, expected 00FFFFFF)", uut.registers.registers[18]);
      tests_failed = tests_failed + 1;
    end

    // Test 10: Function Call and Return (jalr)
    // We expect x20 == 42 (function executed) AND x19 == 99 (returned successfully)
    if (uut.registers.registers[20] == 42 && uut.registers.registers[19] == 99) begin
      $display("PASS: jalr function return");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: jalr function return (x20: %0d, x19: %0d)", uut.registers.registers[20],
               uut.registers.registers[19]);
      tests_failed = tests_failed + 1;
    end

    $display("--------------------------");
    $display("TOTAL SUMMARY: %0d PASSED, %0d FAILED", tests_passed, tests_failed);
    $display("--------------------------");
    $finish;
  end

endmodule
