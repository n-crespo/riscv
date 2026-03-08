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
    output reg [1:0] result_src,  // 0 for alu result, 1 for mem read, 10 for pc+1

    // conditionals/loops
    output reg branch,  // 1 when branch instruction received
    output reg jump,  // 1 when jal instruction received
    output reg jalr_flag  // 1 when jalr instruction received
);

  // determine control signals based on opcode
  always @(*) begin
    // default values to prevent latches
    reg_we     = 1'b0;
    alu_ctrl   = 4'b0000;
    alu_src    = 1'b0;
    mem_we     = 1'b0;
    result_src = 2'b00;
    branch     = 1'b0;
    jump       = 1'b0;
    jalr_flag  = 1'b0;

    case (opcode)
      // r-type instructions (add, sub, and, or, etc)
      7'b0110011: begin
        reg_we  = 1'b1;  // we want to save the math result
        alu_src = 1'b0;  // route rs2 into the alu's second input

        case (funct3)
          3'b000: begin
            if (funct7 == 7'b0100000) begin
              alu_ctrl = 4'b0001;  // sub
            end else begin
              alu_ctrl = 4'b0000;  // add
            end
          end
          3'b001:  alu_ctrl = 4'b0010;  // sll
          3'b010:  alu_ctrl = 4'b0011;  // slt
          3'b011:  alu_ctrl = 4'b1001;  // sltu
          3'b100:  alu_ctrl = 4'b0100;  // xor
          3'b101: begin
            if (funct7 == 7'b0100000) begin
              alu_ctrl = 4'b1000;  // sra
            end else begin
              alu_ctrl = 4'b0101;  // srl
            end
          end
          3'b110:  alu_ctrl = 4'b0110;  // or
          3'b111:  alu_ctrl = 4'b0111;  // and
          default: alu_ctrl = 4'b0000;
        endcase
      end

      // i-type instructions (addi, slli, ori, etc)
      7'b0010011: begin
        reg_we  = 1'b1;  // we want to save the math result
        alu_src = 1'b1;  // route imm_val into the alu's second input

        case (funct3)
          3'b000:  alu_ctrl = 4'b0000;  // addi
          3'b001:  alu_ctrl = 4'b0010;  // slli
          3'b010:  alu_ctrl = 4'b0011;  // slti
          3'b011:  alu_ctrl = 4'b1001;  // sltiu
          3'b100:  alu_ctrl = 4'b0100;  // xori
          3'b101: begin
            if (funct7 == 7'b0100000) begin
              alu_ctrl = 4'b1000;  // srai
            end else begin
              alu_ctrl = 4'b0101;  // srli
            end
          end
          3'b110:  alu_ctrl = 4'b0110;  // ori
          3'b111:  alu_ctrl = 4'b0111;  // andi
          default: alu_ctrl = 4'b0000;
        endcase
      end

      // load instructions (lw)
      7'b0000011: begin
        reg_we     = 1'b1;  // saving data from memory into a register
        alu_src    = 1'b1;  // add the immediate offset to the base address
        alu_ctrl   = 4'b0000;  // standard addition
        mem_we     = 1'b0;  // reading from memory, not writing
        result_src = 2'b01;  // route memory data to register file instead of alu result
      end

      // store instructions (sw)
      7'b0100011: begin
        reg_we     = 1'b0;  // not saving to a register
        alu_src    = 1'b1;  // add the immediate offset to the base address
        alu_ctrl   = 4'b0000;  // standard addition
        mem_we     = 1'b1;  // write to memory!
        result_src = 1'b0;  // doesn't matter, reg_we is 0
      end

      // branch instructions
      7'b1100011: begin
        reg_we     = 1'b0;
        alu_src    = 1'b0;  // compare two registers
        alu_ctrl   = 4'b0001;  // subtract
        mem_we     = 1'b0;
        result_src = 1'b0;
        branch     = 1'b1;  // flag as a branch
        jump       = 1'b0;
      end

      // jump instruction (jal)
      7'b1101111: begin
        reg_we     = 1'b1;  // save return address
        alu_src    = 1'b0;
        alu_ctrl   = 4'b0000;
        mem_we     = 1'b0;
        result_src = 2'b10;  // flag to select PC + 1
        branch     = 1'b0;
        jump       = 1'b1;  // flag as a jal
      end

      // jump and link register (jalr)
      7'b1100111: begin
        reg_we     = 1'b1;  // save return address (PC + 1)
        alu_src    = 1'b1;  // route immediate into ALU
        alu_ctrl   = 4'b0000;  // ALU does addition (rs1 + imm)
        mem_we     = 1'b0;
        result_src = 2'b10;  // flag to select PC + 1 for the register file
        branch     = 1'b0;
        jump       = 1'b0;  // handled by jalr_flag instead
        jalr_flag  = 1'b1;  // flag as a jalr
      end

      default: begin
        reg_we     = 1'b0;
        alu_ctrl   = 4'b0000;
        alu_src    = 1'b0;
        mem_we     = 1'b0;
        result_src = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr_flag  = 1'b0;
      end
    endcase
  end

endmodule
