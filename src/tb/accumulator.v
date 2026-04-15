`timescale 1ns / 1ps

/**
 * Verification testbench for accumulator program
 */
module accumulator;

  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

  // performance counters
  integer cycles = 0;
  integer instructions = 0;
  real cpi;

  always @(posedge clk) begin
    if (!reset) cycles <= cycles + 1;
  end

  // count retired instructions
  always @(posedge clk) begin
    if (!reset && cycles > 0 && uut.instr_raw !== 32'h00100073) begin
      instructions <= instructions + 1;
    end
  end

  // uut instantiation
  top uut (
      .clk  (clk),
      .reset(reset),
      .RsRx (RsRx),
      .led  (led)
  );

  // clock generation: 100mhz
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // simulation logic
  initial begin
    $readmemh(`SIM_HEX, uut.instruction_memory.ram);
    $dumpfile(`VCD_NAME);
    $dumpvars(0, accumulator);

    // system reset
    reset = 1;
    RsRx  = 1;
    #25;
    reset = 0;

    // wait for ebreak (0x00100073) or timeout
    while (uut.instr_raw !== 32'h00100073 && cycles < 1000) begin
      @(posedge clk);
    end

    // allow pipeline to settle
    @(posedge clk);

    $display("\n================ PERFORMANCE REPORT ================");
    $display("%-22s: %10d", "Final Result (x12)", $signed(uut.registers.registers[12]));
    $display("----------------------------------------------------");
    $display("%-22s: %10d", "Total Cycles", cycles);
    $display("%-22s: %10d", "Instructions Retired", instructions);

    if (instructions > 0) begin
      cpi = (cycles * 1.0) / instructions;
      $display("%-22s: %10.2f", "Average CPI", cpi);
    end
    $display("====================================================\n");

    $finish;
  end

endmodule
