`timescale 1ns / 1ps
// dual port memory module
module instr_mem (
    input        clk,
    // port a: for loading instructions via uart
    input        we,      // write enable. only save data if is high
    input [ 7:0] addr_a,  // (memory address) where to save (0 to 255)
    input [31:0] din_a,   // (data in) the 32-bit instruction to save

    // port b: for the cpu to read instructions
    input [7:0] addr_b,     // which address the cpu wants the instruction of
    output reg [31:0] dout_b // data out (32 bit instruction)
);

  // 256 slots, each 32 bits wide
  reg [31:0] ram[0:255];

  // Write Logic (Port A)
  always @(posedge clk) begin
    if (we) begin
      ram[addr_a] <= din_a;
    end
  end

  // Read Logic (Port B)
  always @(posedge clk) begin
    dout_b <= ram[addr_b];
  end

endmodule
