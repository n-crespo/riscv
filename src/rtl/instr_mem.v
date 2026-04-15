`timescale 1ns / 1ps

/**
 * Dual-port memory module optimized for bram-like behavior
 */
module instr_mem (
    input clk,

    // used by UART snooper to live-program FPGA
    input        we,      // write enable
    input [11:0] addr_a,  // index where instruction is to be saved
    input [31:0] din_a,   // the actual instruction to be loaded

    // used by CPU to read instructions
    input [31:0] addr_b,  // address that the PC wants to read from
    output reg [31:0] dout_b  // the instruction we are going to return
);

  // 16 kb of instruction space (4096 32-bit words)
  reg [31:0] ram[0:4095];

  // synchronous write logic for loading program data via uart
  always @(posedge clk) begin
    if (we) ram[addr_a] <= din_a;
  end

  // bits [13:2] divides requested address by 4 to get proper RAM address
  always @(posedge clk) begin
    dout_b <= ram[addr_b[13:2]];
  end

endmodule
