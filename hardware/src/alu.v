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
  wire           is_sub = (alu_ctrl == 4'b0001 || alu_ctrl == 4'b0011 || alu_ctrl == 4'b1001);
  wire    [31:0] b_inv = is_sub ? ~b : b;
  wire    [31:0] sum = a + b_inv + is_sub;

  // sign-bit logic for comparisons
  wire           slt_result = (a[31] != b[31]) ? a[31] : sum[31];

  // Unified Shifter
  // flip the bits for left shift support
  integer        j;
  reg     [31:0] a_flipped;
  always @(*) begin
    for (j = 0; j < 32; j = j + 1) a_flipped[j] = a[31-j];
  end

  // pick the right operand for the shifter
  wire [31:0] shifter_in = (alu_ctrl == 4'b0010) ? a_flipped : a;

  // the unified shifter unit
  // $signed() + >>> allows us to support both SRL and SRA in one line
  wire [31:0] shifter_raw = (alu_ctrl == 4'b1000) ? ($signed(
      shifter_in
  ) >>> b[4:0]) : (shifter_in >> b[4:0]);

  // flip it back if we were doing a left shift
  reg [31:0] shifter_out;
  always @(*) begin
    for (j = 0; j < 32; j = j + 1) shifter_out[j] = shifter_raw[31-j];
  end

  // final choice for shift result
  wire [31:0] final_shift = (alu_ctrl == 4'b0010) ? shifter_out : shifter_raw;

  always @(*) begin
    // default lt to zero unless in comparison mode
    lt = 1'b0;

    case (alu_ctrl)
      4'b0000: out = sum;  // add
      4'b0001: out = sum;  // subtract
      4'b0010: out = final_shift;  // shift left logical (using unified shifter)
      4'b0011: begin  // slt / blt logic
        out = {31'b0, slt_result};
        lt  = slt_result;
      end
      4'b0100: out = a ^ b;  // xor
      4'b0101: out = final_shift;  // shift right logical (using unified shifter)
      4'b0110: out = a | b;  // or
      4'b0111: out = a & b;  // and
      4'b1000: out = final_shift;  // shift right arithmetic (using unified shifter)
      4'b1001: begin  // sltu / bltu logic
        // if a < b, then a - b will require a borrow (sum[31] in this context)
        out = (a < b) ? 32'd1 : 32'd0;
        lt  = (a < b);
      end
      default: out = 32'd0;
    endcase
  end

endmodule
