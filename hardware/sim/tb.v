`timescale 1ns / 1ps

// Testbench for the RISC-V top module
module tb;

  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

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

    // forcefully inject the machine code into the instruction memory array
    uut.instruction_memory.ram[0] = 32'h00500093;  // addi x1, x0, 5
    uut.instruction_memory.ram[1] = 32'h00700113;  // addi x2, x0, 7
    uut.instruction_memory.ram[2] = 32'h002081b3;  // add x3, x1, x2
    uut.instruction_memory.ram[3] = 32'h00000000;  // empty padding

    // hold reset for a few cycles, then release to start the program counter
    #20 reset = 0;

    // let the cpu run for enough clock cycles to execute the instructions
    #100;

    // print the results to the vivado tcl console
    $display("Register x1: %0d", uut.registers.registers[1]);
    $display("Register x2: %0d", uut.registers.registers[2]);
    $display("Register x3: %0d", uut.registers.registers[3]);
    // expected:
    // Register x1: 5
    // Register x2: 7
    // Register x3: 12

    $finish;
  end

endmodule
