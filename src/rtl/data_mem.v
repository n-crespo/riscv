`timescale 1ns / 1ps
// TODO: migrate to synchronous BRAM. will require adding 3rd pipeline stage so
// that CPU stalls and waits for data to arrive in the next cycle

module data_mem (
    input clk,
    input  [ 3:0] be,    // byte enable mask (one bit per byte)
    input  [ 7:0] addr,  // 256 words
    input  [31:0] wd,    // data to write (pre-steered in top.v)
    output [31:0] rd     // raw 32-bit data out
);
  reg [31:0] ram[0:255];

  always @(posedge clk) begin
    // only write to specific bytes if their enable bit is high
    if (be[0]) ram[addr][7:0] <= wd[7:0];
    if (be[1]) ram[addr][15:8] <= wd[15:8];
    if (be[2]) ram[addr][23:16] <= wd[23:16];
    if (be[3]) ram[addr][31:24] <= wd[31:24];
  end

  assign rd = ram[addr];

endmodule
