`timescale 1ns / 1ps

/**
 * Verification testbench for the mini_inference assembly program
 */
module accumulator;

  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

  // unit under test
  top uut (
      .clk  (clk),
      .reset(reset),
      .RsRx (RsRx),
      .led  (led)
  );


  integer cycles = 0;
  always @(posedge clk) cycles <= cycles + 1;

  // generate 100mhz clock
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

    // allow enough time for the loop to finish (4 iterations)
    repeat (200) @(posedge clk);

    $display("\n================ MINI INFERENCE REPORT ================");
    // verify result: 10 + 20 + 30 + 40 = 100
    if (uut.registers.registers[12] == 32'd100) begin
      $display("SUCCESS: final sum in x12 is 100");
    end else begin
      $display("FAILURE: expected 100, got %d", $signed(uut.registers.registers[12]));
    end
    $display("Final Pointer (x10): %d (Expected 1040)", uut.registers.registers[10]);
    $display("======================================================\n");
    $display("Total Cycles: %d", cycles);
    $finish;
  end

endmodule
