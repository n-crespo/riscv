`timescale 1ns / 1ps

/**
 * Dynamic simulation wrapper that terminates on EBREAK or a timeout
 */
module inspect;

  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

  // count cycles
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

  // simulation control
  initial begin
    // initialize instruction memory via macro
    $readmemh(`SIM_HEX, uut.instruction_memory.ram);

    // setup waveform dumping
    $dumpfile(`VCD_NAME);
    $dumpvars(0, inspect);

    // system reset sequence
    reset = 1;
    RsRx  = 1;
    #25;
    reset = 0;

    // wait for either the ebreak instruction or a timeout
    // ebreak opcode is 32'h00100073
    while (uut.instr_raw !== 32'h00100073 && cycles < 50000) begin
      @(posedge clk);
    end

    // check why we exited the loop
    if (cycles >= 50000) begin
      $display("\n[TIMEOUT] reached 50,000 cycles without hitting ebreak.");
    end else begin
      // give the pipeline one extra cycle to settle after ebreak
      @(posedge clk);
    end

    // print final report
    $display("\n================ SIMULATION END STATE ================");
    $display("Final PC_IF: %h", uut.pc_if);
    $display("Final PC_EX: %h", uut.pc_ex);
    $display("Total Cycles: %d", cycles);
    $display("------------------------------------------------------");

    print_registers();

    $display("======================================================\n");
    $finish;
  end

  // format register output in signed decimal
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

endmodule
