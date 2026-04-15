`timescale 1ns / 1ps

/**
 * Data memory module with asynchronous read for a 2-stage pipeline
 */
module data_mem (
    input clk,
    input  [ 3:0] be,    // byte enable mask (one bit per byte)
    input  [11:0] addr,  // expanded to 12 bits for 4096 words (16 kb)
    input  [31:0] wd,    // data to write (pre-steered in top.v)
    output [31:0] rd     // raw 32-bit data out
);

  // internal storage for 4096 32-bit words
  reg [31:0] ram[0:4095];

  // synchronous write logic with byte-level granularity
  always @(posedge clk) begin
    // only write to specific bytes if their enable bit is high
    if (be[0]) ram[addr][7:0] <= wd[7:0];
    if (be[1]) ram[addr][15:8] <= wd[15:8];
    if (be[2]) ram[addr][23:16] <= wd[23:16];
    if (be[3]) ram[addr][31:24] <= wd[31:24];
  end

  // asynchronous read used for immediate feedback in the execute stage
  assign rd = ram[addr];

endmodule
