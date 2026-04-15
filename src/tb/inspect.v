`timescale 1ns / 1ps

// Module documentation for inspect: provides a generic simulation wrapper with signed decimal register reporting
module inspect;

  reg clk;
  reg reset;
  reg RsRx;
  wire [15:0] led;

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

    // run for a set number of cycles
    repeat (1000) @(posedge clk);

    // print final report
    $display("\n================ SIMULATION END STATE ================");
    $display("Final PC_IF: %h", uut.pc_if);
    $display("Final PC_EX: %h", uut.pc_ex);
    $display("Final LED:   %b", led);
    $display("------------------------------------------------------");

    print_registers();

    $display("======================================================\n");
    $finish;
  end

  // format register output in decimal
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
