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
    clk   = 0;
    reset = 1;
    RsRx  = 1;

    // --- Logic Paths (0-13) ---
    $readmemh("sim/tb.hex", uut.instruction_memory.ram);

    // adjust the run time to ensure PC reaches the final index
    #22 reset = 0;
    #590;

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
  task automatic check_test;
    input [31:0] actual;
    input [31:0] expected;
    input [127:0] test_name;
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
