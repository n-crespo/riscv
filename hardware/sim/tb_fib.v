`timescale 1ns / 1ps

module tb_fib;
  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

  top uut (
      .clk  (clk),
      .reset(reset),
      .RsRx (RsRx),
      .led  (led)
  );

  always #5 clk = ~clk;

  // --- Timeout Watchdog ---
  initial begin
    #1000000;  // Give it 1ms total
    $display("\n[TIMEOUT] Simulation ran too long!");
    $finish;
  end

  // --- Main Test Logic ---
  initial begin
    clk   = 0;
    RsRx  = 1;
    reset = 1;
    $readmemh("sim/fib.hex", uut.instruction_memory.ram);

    #22 reset = 0;
    $display("--- RUNNING FIBONACCI ---");

    // monitor starts immediately after reset
    $monitor("Time: %0t | PC_EX: %h | INSTR: %h | x3: %d | x4: %d | JMP: %b", $time, uut.pc_ex,
             uut.instr_ex, uut.registers.registers[3], uut.registers.registers[4], uut.take_jump);

    // wait for result (use 3 if you kept the small test, 34 if you went back to 10)
    wait (uut.registers.registers[3] == 32'd3);

    #50;  // extra padding to see the final state
    $display("\nSUCCESS: Fibonacci result reached!");
    $display("Final x3 value: %d", uut.registers.registers[3]);
    $finish;
  end
endmodule
