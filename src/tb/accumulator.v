`timescale 1ns / 1ps

/**
 * Verification testbench for accumulator program
 */
module accumulator;

  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

  // clock cycle counter
  integer cycles = 0;
  always @(posedge clk) begin
    if (!reset) cycles <= cycles + 1;
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

    $display("\n================ ACCUMULATOR REPORT ================");
    // check if sum matches 10+20+30+40+50
    if (uut.registers.registers[12] == 32'd150) begin
      $display("SUCCESS: final sum in x12 is 150");
    end else begin
      $display("FAILURE: expected 150, got %d", $signed(uut.registers.registers[12]));
    end

    $display("Final Pointer (x10): %d", uut.registers.registers[10]);
    $display("Total Cycles:       %d", cycles);
    $display("====================================================\n");

    $finish;
  end

endmodule
