`timescale 1ns / 1ps
// Represents the 32 general-purpose registers in a RISC-V CPU
module reg_file (
    input         clk,
    input         we,   // write enable
    input  [ 4:0] rs1,  // address of first source register
    input  [ 4:0] rs2,  // address of second source register
    input  [ 4:0] rd,   // address of destination register
    input  [31:0] wd,   // write data
    output [31:0] rd1,  // read data 1
    output [31:0] rd2   // read data 2
);

  // 32 registers, each 32 bits wide
  reg [31:0] registers[0:31];

  // read asynchronously. register 0 is hardwired to zero
  assign rd1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
  assign rd2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

  // write synchronously on the clock edge
  always @(posedge clk) begin
    // never overwrite register 0
    if (we && rd != 5'b0) begin
      registers[rd] <= wd;
    end
  end

endmodule
