`timescale 1ns / 1ps

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

    // --- Original Logic Paths ---
    uut.instruction_memory.ram[0] = 32'h00500093;  // 0: addi x1, x0, 5
    uut.instruction_memory.ram[1] = 32'h00700113;  // 1: addi x2, x0, 7
    uut.instruction_memory.ram[2] = 32'h002081b3;  // 2: add x3, x1, x2
    uut.instruction_memory.ram[3] = 32'h00302223;  // 3: sw x3, 4(x0)
    uut.instruction_memory.ram[4] = 32'h00402203;  // 4: lw x4, 4(x0)
    uut.instruction_memory.ram[5] = 32'h00418463;  // 5: beq x3, x4, 8 (jump to 7)
    uut.instruction_memory.ram[6] = 32'h06300293;  // 6: addi x5, x0, 99 (skipped)
    uut.instruction_memory.ram[7] = 32'h0080036f;  // 7: jal x6, 8 (jump to 9)
    uut.instruction_memory.ram[8] = 32'h06300393;  // 8: addi x7, x0, 99 (skipped)
    uut.instruction_memory.ram[9] = 32'h00100413;  // 9: addi x8, x0, 1

    // --- New Test Paths ---
    // 10: addi x0, x0, 50     -> Attempt to write to x0 (should remain 0)
    uut.instruction_memory.ram[10] = 32'h03200013;
    // 11: addi x9, x0, -10    -> Test sign extension (should be 0xFFFFFFF6)
    uut.instruction_memory.ram[11] = 32'hff600493;
    // 12: bne x1, x2, 8       -> Branch NOT taken (beq x1, x2)
    // using beq x1, x2 with offset that would skip x10 if it failed
    uut.instruction_memory.ram[12] = 32'h00208463;
    // 13: addi x10, x0, 42    -> Should execute because x1 (5) != x2 (7)
    uut.instruction_memory.ram[13] = 32'h02a00513;

    #20 reset = 0;
    #250;  // increased time to cover new instructions

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

    // Test 1: Register x0 Hard-wiring
    if (uut.registers.registers[0] == 0) begin
      $display("PASS: x0 is hard-wired to zero");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: x0 was overwritten! Value: %0d", uut.registers.registers[0]);
      tests_failed = tests_failed + 1;
    end

    // Test 2: Sign Extension
    if (uut.registers.registers[9] == 32'hfffffff6) begin
      $display("PASS: sign extension (negative immediates)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: sign extension (x9: %h, expected fffffff6)", uut.registers.registers[9]);
      tests_failed = tests_failed + 1;
    end

    // Test 3: Branch NOT Taken
    if (uut.registers.registers[10] == 42) begin
      $display("PASS: branch-not-taken logic");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: branch-not-taken (x10 should be 42)");
      tests_failed = tests_failed + 1;
    end

    $display("--------------------------");
    $display("TOTAL SUMMARY: %0d PASSED, %0d FAILED", tests_passed, tests_failed);
    $display("--------------------------");
    $finish;
  end

endmodule
