`timescale 1ns / 1ps

/**
 * Arithmetic logic unit for standard RISC-V operations
 */
module alu (
    input      [31:0] a,         // first operand
    input      [31:0] b,         // second operand
    input      [ 3:0] alu_ctrl,  // operation selector
    output reg [31:0] out,       // calculation result
    output            zero,      // high if a == b
    output reg        lt         // high if a < b
);

  assign zero = (a == b);

  // detect if operation is subtraction for shared adder logic
  wire is_sub = (alu_ctrl == 4'b0001 || alu_ctrl == 4'b0011 || alu_ctrl == 4'b1001);

  // invert bits of b for two's complement subtraction
  wire [31:0] b_inv = is_sub ? ~b : b;

  // do the addition or subtraction with ONE 32-bit adder
  wire [31:0] sum = a + b_inv + is_sub;

  // get signed comparison result with sign bits and overflow logic
  wire slt_result = (a[31] != b[31]) ? a[31] : sum[31];

  always @(*) begin
    // default comparison output to zero
    lt = 1'b0;

    case (alu_ctrl)
      4'b0000: out = sum;  // add
      4'b0001: out = sum;  // subtract

      4'b0100: out = a ^ b;  // xor
      4'b0110: out = a | b;  // or
      4'b0111: out = a & b;  // and

      // use native verilog operations for simulation efficiency
      4'b0010: out = a << b[4:0];  // sll: shift left logical
      4'b0101: out = a >> b[4:0];  // srl: shift right logical
      4'b1000: out = $signed(a) >>> b[4:0];  // sra: shift right arithmetic (replicate sign bit)

      // signed comparison (slt/blt)
      4'b0011: begin
        out = {31'b0, slt_result};
        lt  = slt_result;
      end

      // unsigned comparison (sltu/bltu)
      4'b1001: begin
        out = (a < b) ? 32'd1 : 32'd0;
        lt  = (a < b);
      end

      default: out = 32'd0;
    endcase
  end

endmodule
