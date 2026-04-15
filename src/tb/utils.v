/**
 * Shared monitoring and testing utilities
 */

// performance and test counters
integer cycles = 0;
integer instructions = 0;
integer tests_passed = 0;
integer tests_failed = 0;

// count raw clock cycles
always @(posedge clk) begin
  if (!reset) cycles <= cycles + 1;
end

// count retired instructions (ignores reset and the ebreak sentinel)
always @(posedge clk) begin
  if (!reset && cycles > 0 && uut.instr_raw !== 32'h00100073) begin
    instructions <= instructions + 1;
  end
end

// task to automate the pass/fail boilerplate
task automatic assert_eq;
  input [63:0] actual;
  input [63:0] expected;
  input [127:0] test_name;
  begin
    if (actual === expected) begin
      $display("PASS: %s", test_name);
      tests_passed = tests_passed + 1;
    end else begin
      $display("FAIL: %s (actual: %h, expected: %h)", test_name, actual, expected);
      tests_failed = tests_failed + 1;
    end
  end
endtask

// task to format register output in signed decimal
task print_registers;
  integer i;
  begin
    for (i = 0; i < 32; i = i + 4) begin
      $display("x%02d: %11d | x%02d: %11d | x%02d: %11d | x%02d: %11d", i,
               $signed(uut.registers.registers[i]), i + 1, $signed(uut.registers.registers[i+1]),
               i + 2, $signed(uut.registers.registers[i+2]), i + 3,
               $signed(uut.registers.registers[i+3]));
    end
  end
endtask

// task to print pure performance metrics
task print_perf_report(input integer cycles, input integer instructions);
  real cpi;
  begin
    $display("\n================ PERFORMANCE REPORT ================");
    $display("%-22s: %10d", "Total Cycles", cycles);
    $display("%-22s: %10d", "Instructions Retired", instructions);

    if (instructions > 0) begin
      cpi = (cycles * 1.0) / instructions;
      $display("%-22s: %10.2f", "Average CPI", cpi);
    end
    $display("====================================================\n");
  end
endtask
