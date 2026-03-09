`timescale 1ns / 1ps
// Evaluates branch conditions based on register data and funct3
module branch_comparator (
    input             branch,   // control signal indicating a branch instruction
    input      [ 2:0] funct3,   // specifies the type of comparison
    input      [31:0] rs1_data, // data from register 1
    input      [31:0] rs2_data, // data from register 2
    output reg        take      // 1 if the branch condition is met
);

  // evaluate conditions
  always @(*) begin
    // default to false
    take = 1'b0;

    if (branch) begin
      case (funct3)
        3'b000: take = (rs1_data == rs2_data);                   // beq
        3'b001: take = (rs1_data != rs2_data);                   // bne
        3'b100: take = ($signed(rs1_data) < $signed(rs2_data));  // blt
        3'b101: take = ($signed(rs1_data) >= $signed(rs2_data)); // bge
        3'b110: take = (rs1_data < rs2_data);                    // bltu
        3'b111: take = (rs1_data >= rs2_data);                   // bgeu
        default: take = 1'b0;
      endcase
    end
  end

endmodule
