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

  // include shared counters, always blocks, and tasks (includes utils.v)
  `include "tb/utils.v"

  // instantiate the top module
  top uut (
      .clk  (clk),
      .reset(reset),
      .RsRx (RsRx),
      .led  (led)
  );

  // generate a 100MHz clock (10ns period)
  always #5 clk = ~clk;

  // generate waveform! (open with `gtkwave tb_waveform.vcd`)
  initial begin
    $dumpfile("sw/.build/tb_waveform.vcd");
    $dumpvars(0, tb);
  end

  initial begin
    clk   = 0;
    RsRx  = 1;
    reset = 1;

    $readmemh("sw/.build/tb.hex", uut.instruction_memory.ram);  // load assembly
    #22 reset = 0;  // release reset and start CPU

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

    // wait one final clock cycle for last write to settle
    $display("--- SIMULATION RESULTS ---");

    // basic logic & memory
    assert_eq(uut.registers.registers[3], 12, "math logic");
    assert_eq(uut.registers.registers[4], 12, "memory logic");
    assert_eq(uut.registers.registers[0], 0, "x0 hard-wired to zero");
    assert_eq(uut.registers.registers[9], 32'hfffffff6, "sign extension");
    assert_eq(uut.registers.registers[10], 42, "branch-not-taken");

    // dependencies & safety
    assert_eq(uut.registers.registers[12], 15, "raw data dependency");
    assert_eq(uut.registers.registers[13], 15, "memory throughput");
    assert_eq({uut.registers.registers[14], uut.registers.registers[0]}, {32'd1, 32'd0},
              "invalid opcode safety");

    // accelerator & function calls
    assert_eq(uut.registers.registers[18], 32'h00FFFFFF, "pixel accelerator");
    assert_eq({uut.registers.registers[20], uut.registers.registers[19]}, {32'd42, 32'd99},
              "jalr function return");

    // sub-word memory access
    assert_eq(uut.registers.registers[27], 32'hDDCCBBAA, "sb and lw logic");
    assert_eq({uut.registers.registers[28], uut.registers.registers[29]}, {
              32'h0000BBAA, 32'hFFFFDDCC}, "lh/lhu logic");
    assert_eq({uut.registers.registers[30], uut.registers.registers[31]}, {
              32'h000000BB, 32'hFFFFFFDD}, "lb/lbu logic");
    assert_eq(uut.registers.registers[24], 32'h05A5BBAA, "sh logic");

    // branch comparator
    assert_eq(uut.registers.registers[5], 1, "bne logic");
    assert_eq(uut.registers.registers[6], 1, "blt logic");
    assert_eq(uut.registers.registers[7], 1, "bge logic");

    // u-type instructions
    assert_eq(uut.registers.registers[22], 32'h12345000, "lui logic");
    // pc was 0x104 when this ran. 0x104 + 0x1000 = 0x1104
    assert_eq(uut.registers.registers[23], 32'h00001104, "auipc logic");

    $display("--------------------------");
    $display("SUMMARY: %0d PASSED, %0d FAILED", tests_passed, tests_failed);
    $display("--------------------------");

    print_perf_report(cycles, instructions);

    $finish;
  end

endmodule
