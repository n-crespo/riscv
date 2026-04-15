`timescale 1ns / 1ps

/**
 * Verification testbench for accumulator program
 */
module accumulator;

  reg clk;
  reg reset;
  reg RsRx;

  // include all shared counters, always blocks, and tasks
  `include "tb/utils.v"

  wire [15:0] led;

  top uut (
      .clk  (clk),
      .reset(reset),
      .RsRx (RsRx),
      .led  (led)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $readmemh(`SIM_HEX, uut.instruction_memory.ram);
    $dumpfile(`VCD_NAME);
    $dumpvars(0, accumulator);

    reset = 1;
    #25;
    reset = 0;

    // wait for ebreak (0x00100073)
    while (uut.instr_raw !== 32'h00100073 && cycles < 1000) begin
      @(posedge clk);
    end

    @(posedge clk);

    $display("\n--- LOGIC VERIFICATION ---");
    assert_eq(uut.registers.registers[12], 32'd150, "final accumulation sum");

    print_perf_report(cycles, instructions);

    $finish;
  end

endmodule
