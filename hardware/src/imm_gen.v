// Generates sign-extended immediate values from a 32-bit instruction
module imm_gen (
    input      [31:0] instr,
    output reg [31:0] imm_out
);

  wire [6:0] opcode = instr[6:0];

  always @(*) begin
    case (opcode)
      // i-type instructions (addi, lw, etc)
      7'b0010011, 7'b0000011: begin
        imm_out = {{20{instr[31]}}, instr[31:20]};
      end

      // s-type instructions (sw, etc)
      7'b0100011: begin
        imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      end

      default: imm_out = 32'd0;
    endcase
  end

endmodule
