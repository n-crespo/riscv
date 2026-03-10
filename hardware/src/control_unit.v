`timescale 1ns / 1ps
// Generates control signals for the datapath based on the instruction opcode
module control_unit (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg reg_we,
    output reg [3:0] alu_ctrl,
    output reg alu_src,
    output reg mem_we,     // data memory write enable
    output reg [1:0] result_src,  // 0: alu result, 1: mem read, 10: pc+1, 11: upper_imm result
    output reg [2:0] imm_src,     // 0:I, 1:S, 2:B, 3:J, 4:U

    // conditionals/loops
    output reg branch,  // 1 when branch instruction received
    output reg jump,  // 1 when jal instruction received
    output reg jalr_flag  // 1 when jalr instruction received
);

  // -------------------------------------------------------------------------
  // One-Hot Opcode Decoding
  // -------------------------------------------------------------------------
  // we pre-decode opcodes into individual wires to speed up signal generation
  wire is_r_type = (opcode == 7'b0110011);
  wire is_i_type = (opcode == 7'b0010011);
  wire is_load   = (opcode == 7'b0000011);
  wire is_store  = (opcode == 7'b0100011);
  wire is_branch = (opcode == 7'b1100011);
  wire is_jal    = (opcode == 7'b1101111);
  wire is_jalr   = (opcode == 7'b1100111);
  wire is_lui    = (opcode == 7'b0110111);
  wire is_auipc  = (opcode == 7'b0010111);

  // determine control signals based on opcode
  always @(*) begin
    // default values to prevent latches
    reg_we     = is_r_type | is_i_type | is_load | is_jal | is_jalr | is_lui | is_auipc;
    alu_src    = is_i_type | is_load | is_store | is_jalr | is_lui | is_auipc;
    mem_we     = is_store;
    result_src = (is_load)           ? 2'b01 : 
                 (is_jal | is_jalr)  ? 2'b10 : 
                 (is_lui | is_auipc) ? 2'b11 : 
                                       2'b00;
    
    // imm_src logic
    imm_src    = (is_store)          ? 3'b001 : // s-type
                 (is_branch)         ? 3'b010 : // b-type
                 (is_jal)            ? 3'b011 : // j-type
                 (is_lui | is_auipc) ? 3'b100 : // u-type
                                       3'b000;  // i-type (default)

    branch     = is_branch;
    jump       = is_jal;
    jalr_flag  = is_jalr;

    // ALU Control logic
    if (is_r_type) begin
      case (funct3)
        3'b000:  alu_ctrl = (funct7 == 7'b0100000) ? 4'b0001 : 4'b0000; // sub : add
        3'b001:  alu_ctrl = 4'b0010; // sll
        3'b010:  alu_ctrl = 4'b0011; // slt
        3'b011:  alu_ctrl = 4'b1001; // sltu
        3'b100:  alu_ctrl = 4'b0100; // xor
        3'b101:  alu_ctrl = (funct7 == 7'b0100000) ? 4'b1000 : 4'b0101; // sra : srl
        3'b110:  alu_ctrl = 4'b0110; // or
        3'b111:  alu_ctrl = 4'b0111; // and
        default: alu_ctrl = 4'b0000;
      endcase
    end else if (is_i_type) begin
      case (funct3)
        3'b000:  alu_ctrl = 4'b0000; // addi
        3'b001:  alu_ctrl = 4'b0010; // slli
        3'b010:  alu_ctrl = 4'b0011; // slti
        3'b011:  alu_ctrl = 4'b1001; // sltiu
        3'b100:  alu_ctrl = 4'b0100; // xori
        3'b101:  alu_ctrl = (funct7 == 7'b0100000) ? 4'b1000 : 4'b0101; // srai : srli
        3'b110:  alu_ctrl = 4'b0110; // ori
        3'b111:  alu_ctrl = 4'b0111; // andi
        default: alu_ctrl = 4'b0000;
      endcase
    end else if (is_branch) begin
        case (funct3)
          3'b000, 3'b001: alu_ctrl = 4'b0001; // beq, bne -> subtract to get zero flag
          3'b100, 3'b101: alu_ctrl = 4'b0011; // blt, bge -> signed comparison for lt flag
          3'b110, 3'b111: alu_ctrl = 4'b1001; // bltu, bgeu -> unsigned comparison for lt flag
          default:        alu_ctrl = 4'b0001;
        endcase
    end else begin
      alu_ctrl = 4'b0000; // default to add for loads, stores, jumps, and auipc/lui
    end
  end

endmodule
