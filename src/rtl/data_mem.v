`timescale 1ns / 1ps

/**
 * Data memory module with zero-initialization for simulation
 */
module data_mem (
    input clk,
    input  [ 3:0] be,    // byte enable mask
    input  [11:0] addr,  // 12-bit index for 4096 words (16 kb)
    input  [31:0] wd,    // data to write (pre-steered in top.v)
    output [31:0] rd     // raw 32-bit data out
);

  // internal storage for 4096 32-bit words
  reg [31:0] ram[0:4095];

  // loop through all memory addresses to clear them at t=0 (only in simulation)
  integer i;
  initial begin
    for (i = 0; i < 4096; i = i + 1) begin
      ram[i] = 32'h0;
    end
  end

  // synchronous write logic with byte-level granularity
  always @(posedge clk) begin
    // only write to specific bytes if their enable bit is high
    if (be[0]) ram[addr][7:0] <= wd[7:0];
    if (be[1]) ram[addr][15:8] <= wd[15:8];
    if (be[2]) ram[addr][23:16] <= wd[23:16];
    if (be[3]) ram[addr][31:24] <= wd[31:24];
  end

  // asynchronous read for immediate feedback in the execute stage
  assign rd = ram[addr];

endmodule
