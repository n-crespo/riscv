// Random access memory for storing variables and state during execution
module data_mem (
    input             clk,
    input             we,           // write enable from CU
    input      [ 2:0] funct3,       // instruction type
    input      [ 7:0] word_addr,    // the word-aligned memory address
    input      [ 1:0] byte_offset,  // the exact byte location within the word
    input      [31:0] wd,           // the data to write
    output reg [31:0] rd            // read data output
);

  // 256 slots, each 32 bits wide
  reg [31:0] ram[0:255];

  // holds the full 32-bit row before we slice it up
  reg [31:0] raw_word;

  // surgical writes (stores)
  always @(posedge clk) begin
    if (we) begin
      case (funct3)
        3'b000: begin  // sb (store byte)
          // store just the lowest 8 bits of wd (rs2) into whatever byte is specified
          case (byte_offset)
            2'b00: ram[word_addr][7:0] <= wd[7:0];
            2'b01: ram[word_addr][15:8] <= wd[7:0];
            2'b10: ram[word_addr][23:16] <= wd[7:0];
            2'b11: ram[word_addr][31:24] <= wd[7:0];
          endcase
        end
        3'b001: begin  // sh (store halfword)
          // store lowest 16 bits of wd (rs2) into proper halfword in ram
          if (byte_offset[1] == 1'b0) begin
            ram[word_addr][15:0] <= wd[15:0];
          end else begin
            ram[word_addr][31:16] <= wd[15:0];
          end
        end
        3'b010: begin  // sw (store word)
          // just take all of the data and overwrite the entire row
          ram[word_addr] <= wd;
        end
      endcase
    end
  end

  // surgical reads (loads)
  always @(*) begin
    // grab the full word first
    raw_word = ram[word_addr];

    case (funct3)
      // lb (load byte, sign-extended)
      3'b000: begin
        case (byte_offset)
          2'b00: rd = {{24{raw_word[7]}}, raw_word[7:0]};
          2'b01: rd = {{24{raw_word[15]}}, raw_word[15:8]};
          2'b10: rd = {{24{raw_word[23]}}, raw_word[23:16]};
          2'b11: rd = {{24{raw_word[31]}}, raw_word[31:24]};
        endcase
      end

      // lh (load halfword, sign-extended)
      3'b001: begin
        if (byte_offset[1] == 1'b0) begin
          rd = {{16{raw_word[15]}}, raw_word[15:0]};
        end else begin
          rd = {{16{raw_word[31]}}, raw_word[31:16]};
        end
      end

      // lw (load word)
      3'b010: rd = raw_word;

      // lbu (load byte, unsigned)
      3'b100: begin
        case (byte_offset)
          2'b00: rd = {24'd0, raw_word[7:0]};
          2'b01: rd = {24'd0, raw_word[15:8]};
          2'b10: rd = {24'd0, raw_word[23:16]};
          2'b11: rd = {24'd0, raw_word[31:24]};
        endcase
      end

      // lhu (load halfword, unsigned)
      3'b101: begin
        if (byte_offset[1] == 1'b0) begin
          rd = {16'd0, raw_word[15:0]};
        end else begin
          rd = {16'd0, raw_word[31:16]};
        end
      end

      // default to full word
      default: rd = raw_word;
    endcase
  end

endmodule
