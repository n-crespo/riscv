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

  // single 32-bit adder/subtractor logic
  // handle subtraction by inverting B and adding 1 (via carry-in)
  wire        is_sub = (alu_ctrl == 4'b0001 || alu_ctrl == 4'b0011 || alu_ctrl == 4'b1001);
  wire [31:0] b_inv = is_sub ? ~b : b;
  wire [31:0] sum = a + b_inv + is_sub;

  // sign-bit logic for comparisons
  wire        slt_result = (a[31] != b[31]) ? a[31] : sum[31];

  always @(*) begin
    // default lt to zero unless in comparison mode
    lt = 1'b0;

    case (alu_ctrl)
      4'b0000: out = sum;  // add
      4'b0001: out = sum;  // subtract
      4'b0010: out = a << b[4:0];  // shift left logical
      4'b0011: begin  // slt / blt logic
        out = {31'b0, slt_result};
        lt  = slt_result;
      end
      4'b0100: out = a ^ b;  // xor
      4'b0101: out = a >> b[4:0];  // shift right logical
      4'b0110: out = a | b;  // or
      4'b0111: out = a & b;  // and
      4'b1000: out = $signed(a) >>> b[4:0];  // shift right arithmetic
      4'b1001: begin  // sltu / bltu logic
        // for unsigned, we can use the carry out of the adder
        // if a < b, then a - b will require a borrow (sum[31] in this context)
        // a simpler way is to check the literal comparison
        out = (a < b) ? 32'd1 : 32'd0;
        lt  = (a < b);
      end
      default: out = 32'd0;
    endcase
  end

endmodule
