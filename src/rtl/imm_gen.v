// extracts sign-extended immediate values from a 32-bit instruction
module imm_gen (
    input      [31:0] instr,
    input      [ 2:0] imm_src,  // 0:I, 1:S, 2:B, 3:J, 4:U
    output reg [31:0] imm_out
);

  // Pre-calculated immediate types using direct wiring (zero logic cost)
  // I-type: sign extension, extract constant from instruction
  wire [31:0] i_imm = {{20{instr[31]}}, instr[31:20]};

  // S-type: sign extension, combined from two separate fields (sw, etc)
  wire [31:0] s_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

  // B-type: sign extension with shifted bits for branches (beq, bne, etc)
  wire [31:0] b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

  // J-type: sign extension for long jumps (jal)
  wire [31:0] j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

  // U-type: take top 20 bits and pad bottom with 12 zeros (lui, auipc)
  wire [31:0] u_imm = {instr[31:12], 12'b0};

  always @(*) begin
    case (imm_src)
      3'b000:  imm_out = i_imm;  // i-type
      3'b001:  imm_out = s_imm;  // s-type
      3'b010:  imm_out = b_imm;  // b-type
      3'b011:  imm_out = j_imm;  // j-type
      3'b100:  imm_out = u_imm;  // u-type
      default: imm_out = 32'd0;
    endcase
  end

endmodule
