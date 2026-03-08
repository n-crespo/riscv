// extracts sign-extended immediate values from a 32-bit instruction
module imm_gen (
    input      [31:0] instr,
    output reg [31:0] imm_out
);

  wire [6:0] opcode = instr[6:0];

  always @(*) begin
    case (opcode)
      // i-type instructions (addi, lw, etc)
      7'b0010011, 7'b0000011, 7'b1100111: begin
        // sign extension, extract constant from instruction
        imm_out = {{20{instr[31]}}, instr[31:20]};
      end

      // s-type instructions (sw, etc)
      7'b0100011: begin
        imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      end

      // b-type instructions (beq, bne, etc)
      7'b1100011: begin
        imm_out = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      end

      // j-type instructions (jal)
      7'b1101111: begin
        imm_out = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      end

      default: imm_out = 32'd0;
    endcase
  end

endmodule
