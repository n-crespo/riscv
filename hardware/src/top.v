module top (
    input clk,  // clock
    input reset,  // system reset
    input RsRx,  // the serial data
    output [15:0] led  // displaying 16 bits of the 32-bit instruction
);

  wire        rx_dv;  // data valid?
  wire [ 7:0] rx_byte;  // will carry bytes of the serial data

  // a register holding the 32 instruction bits, currently set to all zeros in hex
  reg  [31:0] instruction_reg = 32'h0;
  // a register containing 2 bits, initialized to 00 in binary
  reg  [ 1:0] byte_count = 2'b00;
  // a register containing 8 bits to track memory location
  reg  [ 7:0] write_addr = 8'h0;

  // wire to trigger the instruction memory save
  wire        mem_we;

  // wires for the program counter and fetched instruction
  wire [31:0] pc_wire;
  wire [31:0] fetched_instruction;

  // branching and jump logic
  wire        branch;
  wire        jump;
  wire        take_jump;  // 1 when we need to jump to target_pc
  wire [31:0] target_pc;  // the address of the instruction we need to jump to

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
      .clk      (clk),
      .reset    (reset),
      .take_jump(take_jump),
      .target_pc(target_pc),
      .pc_out   (pc_wire)
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
  wire [31:0] alu_a_in;  // wire for ALU's first input MUX
  wire        data_mem_we;  // wire for data memory write enable
  wire [ 1:0] result_src;  // wire for writeback selection
  wire        jalr_flag;  // wire for jalr signal

  control_unit ctrl (
      .opcode    (opcode),
      .funct3    (funct3),
      .funct7    (funct7),
      .reg_we    (reg_we),
      .alu_ctrl  (alu_ctrl),
      .alu_src   (alu_src),      // control whether we give the alu register or imm
      .mem_we    (data_mem_we),
      .result_src(result_src),
      .branch    (branch),
      .jump      (jump),
      .jalr_flag (jalr_flag)
  );

  // alu, mux, and data memory wires
  wire [31:0] alu_result;
  wire        alu_zero;
  wire [31:0] alu_b_in;
  wire [31:0] data_rd;
  wire [31:0] reg_wd;

  wire        branch_condition_met;

  // jump target calculation
  // jal/branch: pc + (immediate / 4)
  // jalr: use the exact word-index stored in the register (alu_result)
  assign target_pc = jalr_flag ? alu_result : (pc_wire + imm_val);

  // logic gate determining if the pc should actually jump
  // we jump if it's a jal, a jalr, or a successful branch
  assign take_jump = jump | jalr_flag | branch_condition_met;

  // wire to calculate the return address
  wire [31:0] pc_plus_4 = pc_wire + 32'd4;

  // logic to determine if we are accessing the accelerator
  // if address >= 128 (8'h80), it's the pixel processor
  wire        is_accel_addr = alu_result[7];

  // split the write enable signal
  wire        ram_we_wire = data_mem_we & !is_accel_addr;
  wire        accel_we_wire = data_mem_we & is_accel_addr;

  // wire for data coming back from the hardware
  wire [31:0] accel_dout;

  // choose between ram and accelerator data
  wire [31:0] final_data_rd = is_accel_addr ? accel_dout : data_rd;

  assign reg_wd = (result_src == 2'b11) ? alu_result :
                  (result_src == 2'b10) ? pc_plus_4 :
                  (result_src == 2'b01) ? final_data_rd :
                                          alu_result;

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

  // r-type/i-type (reg_rd1), auipc (pc), and lui (zero)
  assign alu_a_in = (opcode == 7'b0010111) ? {24'b0, pc_wire} :  // AUIPC: use PC
      (opcode == 7'b0110111) ? 32'b0 :  // LUI:   use 0
      reg_rd1;  // Default: use rs1

  // alu instance
  alu main_alu (
      .a       (alu_a_in),
      .b       (alu_b_in),
      .alu_ctrl(alu_ctrl),
      .out     (alu_result),
      .zero    (alu_zero)
  );

  // determine what kind of branching we're doing
  branch_comparator branch_comp (
      .branch  (branch),
      .funct3  (funct3),
      .rs1_data(reg_rd1),
      .rs2_data(reg_rd2),
      .take    (branch_condition_met)
  );

  // data memory instance
  data_mem ram_blocks (
      .clk        (clk),
      .we         (ram_we_wire),      // controlled by snooper signal
      .funct3     (funct3),           // pass the instruction type
      .word_addr  (alu_result[9:2]),  // the row in ram
      .byte_offset(alu_result[1:0]),  // the column in row in ram
      .wd         (reg_rd2),          // data to save comes from register 2
      .rd         (data_rd)           // read data output
  );

  // pixel processor instance
  pixel_processor img_engine (
      .clk  (clk),
      .reset(reset),
      .we   (accel_we_wire),
      .addr (alu_result[3:2]),  // changed from [1:0] to [3:2] for word alignment
      .din  (reg_rd2),          // same data source as RAM
      .dout (accel_dout)        // result sent back to CPU
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
