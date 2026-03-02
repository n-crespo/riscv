module top (
    input clk,  // clock
    input reset,  // system reset
    input RsRx,  // the serial data
    output [15:0] led  // displaying 16 bits of the 32-bit instruction
);

  wire rx_dv;  // data valid?
  wire [7:0] rx_byte;  // will carry bytes of the serial data

  // a register holding the 32 instruction bits, currently set to all zeros in hex
  reg [31:0] instruction_reg = 32'h0;
  // a register containing 2 bits, initialized to 00 in binary
  reg [1:0] byte_count = 2'b00;
  // a register containing 8 bits to track memory location
  reg [7:0] write_addr = 8'h0;

  // wire to trigger the instruction memory save
  wire mem_we;

  // wires for the program counter and fetched instruction
  wire [7:0] pc_wire;
  wire [31:0] fetched_instruction;

  uart_rx #(
      .CLKS_PER_BIT(10416)
  ) uart_receiver (
      .clk(clk),
      .rx_serial(RsRx),
      .rx_dv(rx_dv),
      .rx_byte(rx_byte)
  );

  // program counter instance
  pc program_counter (
      .clk(clk),
      .reset(reset),
      .pc_out(pc_wire)
  );

  // filing cabinet to store instructions
  instr_mem instruction_memory (
      .clk   (clk),
      .we    (mem_we),
      .addr_a(write_addr),
      .din_a (instruction_reg),
      .addr_b(pc_wire),             // driven by the program counter
      .dout_b(fetched_instruction)  // outputs the current instruction
  );

  // decoded instruction fields
  wire [6:0] opcode;
  wire [4:0] rd;
  wire [2:0] funct3;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [6:0] funct7;

  // instruction decoder instance
  decoder instr_decoder (
      .instr(fetched_instruction),
      .opcode(opcode),
      .rd(rd),
      .funct3(funct3),
      .rs1(rs1),
      .rs2(rs2),
      .funct7(funct7)
  );

  wire [31:0] imm_val;

  // immediate generator instance
  imm_gen immediate_generator (
      .instr  (fetched_instruction),
      .imm_out(imm_val)
  );

  // register file wires
  wire [31:0] reg_rd1;
  wire [31:0] reg_rd2;

  // control unit wires
  wire        reg_we;
  wire [ 3:0] alu_ctrl;
  wire        alu_src;  // when 0, use source register, when 1 use immediate value
  wire        data_mem_we;  // new wire for data memory write enable
  wire        result_src;  // new wire for writeback selection

  control_unit ctrl (
      .opcode    (opcode),
      .funct3    (funct3),
      .funct7    (funct7),
      .reg_we    (reg_we),
      .alu_ctrl  (alu_ctrl),
      .alu_src   (alu_src),      // control whether we give the alu register or imm
      .mem_we    (data_mem_we),
      .result_src(result_src)
  );

  // alu, mux, and data memory wires
  wire [31:0] alu_result;
  wire        alu_zero;
  wire [31:0] alu_b_in;
  wire [31:0] data_rd;
  wire [31:0] reg_wd;

  // register file instance
  reg_file registers (
      .clk(clk),
      .we (reg_we),   // write enable?
      .rs1(rs1),      // the address of a register we want to read from
      .rs2(rs2),      // the address of a register we want to read from
      .rd (rd),       // the address of the destination register
      .wd (reg_wd),   // the actual data to write
      .rd1(reg_rd1),  // read output 1
      .rd2(reg_rd2)   // read output 2
  );

  // selects between register and immediate value for the alu
  mux2 alu_mux (
      .d0 (reg_rd2),
      .d1 (imm_val),
      .sel(alu_src),  // 0: add 2 registers, 1: immediate value
      .out(alu_b_in)
  );

  // alu instance
  alu main_alu (
      .a       (reg_rd1),
      .b       (alu_b_in),
      .alu_ctrl(alu_ctrl),
      .out     (alu_result),
      .zero    (alu_zero)
  );

  // data memory instance
  data_mem ram_blocks (
      .clk (clk),
      .we  (data_mem_we),
      .addr(alu_result[7:0]),  // address is calculated by the alu
      .wd  (reg_rd2),          // data to save comes from register 2
      .rd  (data_rd)           // read data output
  );

  // mux to select between alu result and memory read data for the register file
  mux2 writeback_mux (
      .d0 (alu_result),
      .d1 (data_rd),
      .sel(result_src),
      .out(reg_wd)
  );

  always @(posedge clk) begin
    if (rx_dv) begin
      // shift in bytes: standard RISC-V is little-endian
      // byte 0 goes to [7:0], byte 1 to [15:8], etc.
      case (byte_count)
        2'b00:   instruction_reg[7:0] <= rx_byte;
        2'b01:   instruction_reg[15:8] <= rx_byte;
        2'b10:   instruction_reg[23:16] <= rx_byte;
        2'b11:   instruction_reg[31:24] <= rx_byte;
        default: instruction_reg <= instruction_reg;  // do nothing
      endcase

      // increment counter; it will wrap around back to 00 after 4 bytes
      byte_count <= byte_count + 1'b1;

      // move to next address only after the 4th byte is processed
      if (byte_count == 2'b11) begin
        write_addr <= write_addr + 1'b1;
      end
    end
  end

  // only trigger memory save when the 4th byte is valid
  assign mem_we = (rx_dv && byte_count == 2'b11);

  // display lower bits of instruction on right LEDs and address on left LEDs
  assign led[7:0] = instruction_reg[7:0];
  assign led[15:8] = write_addr;

endmodule
