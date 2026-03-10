`timescale 1ns / 1ps
// Represents the 32 general-purpose registers in a RISC-V CPU
module reg_file (
    input         clk,
    input         we,   // WRITE: switch that enables write
    input  [ 4:0] rs1,  // READ input: address of first source register
    input  [ 4:0] rs2,  // READ input: address of second source register
    input  [ 4:0] rd,   // WRITE: address of destination register
    input  [31:0] wd,   // WRITE: the data to write
    output [31:0] rd1,  // READ output: read data 1
    output [31:0] rd2   // READ output:read data 2
);

  // 32 registers, each 32 bits wide
  reg [31:0] registers[0:31];

  // if we are writing to the same register we are reading from, pass the 'wd'
  // directly to the output. prevents a 1-cycle delay.
  assign rd1 = (rs1 == 5'b0) ? 32'b0 : ((we && (rs1 == rd)) ? wd : registers[rs1]);

  assign rd2 = (rs2 == 5'b0) ? 32'b0 : ((we && (rs2 == rd)) ? wd : registers[rs2]);

  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1) begin
      registers[i] = 32'b0;
    end
  end

  // write synchronously on the clock edge
  always @(posedge clk) begin
    // never overwrite register 0
    if (we && rd != 5'b0) begin
      registers[rd] <= wd;
    end
  end

  // note: this always outputs the values of 2 registers, even if we only
  // requested on (ex. addi). we can discard the second, unused, potentially
  // garbage data with a mux that knows that the second argument to the ALU
  // should be an immediate, not a register value.
  //
  // we only feed rd1 into the ALU directly. rd2 goes to the  mux first so that
  // we can discard it if we don't need it.

endmodule
