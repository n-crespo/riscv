`timescale 1ns / 1ps
// Arithmetic logic unit for standard RISC-V operations
module alu (
    input      [31:0] a,         // first operand
    input      [31:0] b,         // second operand
    input      [ 3:0] alu_ctrl,  // operation selector
    output reg [31:0] out,       // calculation result
    output            zero,      // high if a == b (when subtracting)
    output reg        lt         // high if a < b
);

  assign zero = (a == b);  // compare inputs directly for speed

  always @(*) begin
    case (alu_ctrl)
      4'b0000: out = a + b;  // add
      4'b0001: out = a - b;  // subtract
      4'b0010: out = a << b[4:0];  // shift left logical
      4'b0011: begin  // slt / blt logic
        out = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        lt  = ($signed(a) < $signed(b));
      end
      4'b0100: out = a ^ b;  // xor
      4'b0101: out = a >> b[4:0];  // shift right logical
      4'b0110: out = a | b;  // or
      4'b0111: out = a & b;  // and
      4'b1000: out = $signed(a) >>> b[4:0];  // shift right arithmetic
      4'b1001: begin  // sltu / bltu logic
        out = (a < b) ? 32'd1 : 32'd0;
        lt  = (a < b);
      end
      default: begin
        out = 32'd0;
        lt  = 1'b0;
      end
    endcase
  end

endmodule
