// Generates control signals for the datapath based on the instruction opcode
module control_unit (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg reg_we,
    output reg [3:0] alu_ctrl
);

  // determine control signals based on opcode
  always @(*) begin
    // default values to prevent latches
    reg_we   = 1'b0;
    alu_ctrl = 4'b0000;

    case (opcode)
      // r-type instructions (add, sub, and, or, etc)
      7'b0110011: begin
        reg_we = 1'b1;  // we want to save the math result

        case (funct3)
          3'b000: begin
            if (funct7 == 7'b0100000) begin
              alu_ctrl = 4'b0001;  // sub
            end else begin
              alu_ctrl = 4'b0000;  // add
            end
          end
          3'b111:  alu_ctrl = 4'b0111;  // and
          3'b110:  alu_ctrl = 4'b0110;  // or
          3'b100:  alu_ctrl = 4'b0100;  // xor
          3'b001:  alu_ctrl = 4'b0010;  // sll
          3'b101:  alu_ctrl = 4'b0101;  // srl
          3'b010:  alu_ctrl = 4'b0011;  // slt
          default: alu_ctrl = 4'b0000;
        endcase
      end

      // you will add more opcodes here later (i-type, loads, branches)
      default: begin
        reg_we   = 1'b0;
        alu_ctrl = 4'b0000;
      end
    endcase
  end

endmodule
