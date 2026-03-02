`timescale 1ns / 1ps

// Testbench for the RISC-V top module
module tb;

  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

  // test tracking variables
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
    // initialize inputs
    clk = 0;
    reset = 1;
    RsRx = 1;  // an idle uart line sits high

    // inject machine code to test all datapath flows
    // 0: addi x1, x0, 5      -> r-type/i-type math
    uut.instruction_memory.ram[0] = 32'h00500093;
    // 1: addi x2, x0, 7
    uut.instruction_memory.ram[1] = 32'h00700113;
    // 2: add x3, x1, x2      -> x3 should equal 12
    uut.instruction_memory.ram[2] = 32'h002081b3;
    // 3: sw x3, 4(x0)        -> store 12 into ram address 4
    uut.instruction_memory.ram[3] = 32'h00302223;
    // 4: lw x4, 4(x0)        -> load from ram address 4, x4 should equal 12
    uut.instruction_memory.ram[4] = 32'h00402203;
    // 5: beq x3, x4, 8       -> jump forward 8 bytes (2 words) if equal
    uut.instruction_memory.ram[5] = 32'h00418463;
    // 6: addi x5, x0, 99     -> should be skipped by branch
    uut.instruction_memory.ram[6] = 32'h06300293;
    // 7: jal x6, 8           -> unconditionally jump 8 bytes (2 words), save return address (8) to x6
    uut.instruction_memory.ram[7] = 32'h0080036f;
    // 8: addi x7, x0, 99     -> should be skipped by jump
    uut.instruction_memory.ram[8] = 32'h06300393;
    // 9: addi x8, x0, 1      -> final instruction executed
    uut.instruction_memory.ram[9] = 32'h00100413;

    // hold reset for a few cycles, then release to start the program counter
    #20 reset = 0;

    // let the cpu run for enough clock cycles to execute all instructions
    #150;

    // check results
    $display("--- SIMULATION RESULTS ---");

    // test 1: r-type and i-type math
    if (uut.registers.registers[3] == 12) begin
      $display("PASS: math logic (x3 == 12)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: math logic (x3 == %0d, expected 12)", uut.registers.registers[3]);
      tests_failed = tests_failed + 1;
    end

    // test 2: memory store and load
    if (uut.registers.registers[4] == 12) begin
      $display("PASS: memory logic (x4 == 12)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: memory logic (x4 == %0d, expected 12)", uut.registers.registers[4]);
      tests_failed = tests_failed + 1;
    end

    // test 3: branch logic
    if (uut.registers.registers[5] == 0) begin
      $display("PASS: branch logic (x5 == 0, instruction successfully skipped)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: branch logic (x5 == %0d, expected 0)", uut.registers.registers[5]);
      tests_failed = tests_failed + 1;
    end

    // test 4: jump logic and link
    if (uut.registers.registers[7] == 0 && uut.registers.registers[6] == 8) begin
      $display("PASS: jump logic (x7 == 0 skipped, x6 == 8 return address saved)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: jump logic (x7 == %0d expected 0, x6 == %0d expected 8)",
               uut.registers.registers[7], uut.registers.registers[6]);
      tests_failed = tests_failed + 1;
    end

    // test 5: execution continued after jump
    if (uut.registers.registers[8] == 1) begin
      $display("PASS: execution continuation (x8 == 1)");
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: execution continuation (x8 == %0d, expected 1)", uut.registers.registers[8]);
      tests_failed = tests_failed + 1;
    end

    // print final summary
    $display("--------------------------");
    $display("TEST SUMMARY: %0d PASSED, %0d FAILED", tests_passed, tests_failed);
    $display("--------------------------");

    $finish;
  end

endmodule
