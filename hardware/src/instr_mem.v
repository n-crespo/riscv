`timescale 1ns / 1ps
// dual port memory module optimized for BRAM
module instr_mem (
    input clk,

    // port a: for loading instructions via uart
    input        we,
    input [ 7:0] addr_a,
    input [31:0] din_a,

    // port b: for the cpu to read instructions
    input [31:0] addr_b,
    output reg [31:0] dout_b  // synchronous read
);

  reg [31:0] ram[0:255];

  // write logic (port a)
  always @(posedge clk) begin
    if (we) ram[addr_a] <= din_a;
  end

  // read logic (port b) - synchronous read (1-cycle delay)
  always @(posedge clk) begin
    dout_b <= ram[addr_b[9:2]];
  end

endmodule
