// Generates sign-extended immediate values from a 32-bit instruction
module imm_gen (
    input  [31:0] instr,
    output [31:0] imm_out
);

  // right now we only support I-type instructions (like addi)
  // this takes bits 31:20 and copies the sign bit (bit 31) 20 times to fill the 32-bit width
  assign imm_out = {{20{instr[31]}}, instr[31:20]};

endmodule
