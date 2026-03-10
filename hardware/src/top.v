module top (
    input clk,  // clock
    input reset,  // system reset
    input RsRx,  // the serial data
    output [15:0] led  // displaying 16 bits of the 32-bit instruction
);

  // -------------------------------------------------------------------------
  // Internal Nets & Declarations
  // -------------------------------------------------------------------------

  // uart & snooper signals
  wire        rx_dv;
  wire [ 7:0] rx_byte;
  reg  [31:0] instruction_reg = 32'h0;
  reg  [ 1:0] byte_count = 2'b00;
  reg  [ 7:0] write_addr = 8'h0;
  wire        mem_we;

  // instruction fetch signals
  wire [31:0] pc_wire;
  wire [31:0] fetched_instruction;
  wire [31:0] target_pc;
  wire [31:0] next_pc;
  wire [31:0] pc_plus_4;
  wire        take_jump;

  // decoder & immediate signals
  wire [ 6:0] opcode;
  wire [4:0] rd, rs1, rs2;
  wire [ 2:0] funct3;
  wire [ 6:0] funct7;
  wire [31:0] imm_val;

  // control unit signals
  wire        reg_we;
  wire [ 3:0] alu_ctrl;
  wire        alu_src;
  wire        data_mem_we;
  wire [ 1:0] result_src;
  wire branch, jump, jalr_flag;

  // execution & data path signals
  wire [31:0] reg_rd1, reg_rd2, reg_wd;
  wire [31:0] alu_a_in, alu_b_in, alu_result;
  wire alu_zero;
  wire branch_condition_met;

  // memory & accelerator signals
  wire [31:0] data_rd, final_data_rd, accel_dout;
  wire is_accel_addr, ram_we_wire, accel_we_wire;

  // -------------------------------------------------------------------------
  // UART, Fetch & Decode
  // -------------------------------------------------------------------------

  uart_rx #(
      .CLKS_PER_BIT(10416)
  ) uart_receiver (
      .clk(clk),
      .rx_serial(RsRx),
      .rx_dv(rx_dv),
      .rx_byte(rx_byte)
  );

  pc program_counter (
      .clk  (clk),
      .reset(reset),
      .d    (next_pc),  // feed the winner of the MUX
      .q    (pc_wire)
  );

  instr_mem instruction_memory (
      .clk(clk),
      .we(mem_we),
      .addr_a(write_addr),
      .din_a(instruction_reg),
      .addr_b(pc_wire),
      .dout_b(fetched_instruction)
  );

  decoder instr_decoder (
      .instr(fetched_instruction),
      .opcode(opcode),
      .rd(rd),
      .funct3(funct3),
      .rs1(rs1),
      .rs2(rs2),
      .funct7(funct7)
  );

  imm_gen immediate_generator (
      .instr  (fetched_instruction),
      .imm_out(imm_val)
  );

  control_unit ctrl (
      .opcode(opcode),
      .funct3(funct3),
      .funct7(funct7),
      .reg_we(reg_we),
      .alu_ctrl(alu_ctrl),
      .alu_src(alu_src),
      .mem_we(data_mem_we),
      .result_src(result_src),
      .branch(branch),
      .jump(jump),
      .jalr_flag(jalr_flag)
  );
  // -------------------------------------------------------------------------
  // Register File & Execution (ALU)
  // -------------------------------------------------------------------------

  reg_file registers (
      .clk(clk),
      .we (reg_we),
      .rs1(rs1),
      .rs2(rs2),
      .rd (rd),
      .wd (reg_wd),
      .rd1(reg_rd1),
      .rd2(reg_rd2)
  );

  // ALU Mux A: selects between rs1, PC (AUIPC), or 0 (LUI)
  assign alu_a_in = (opcode == 7'b0010111) ? pc_wire : (opcode == 7'b0110111) ? 32'b0 : reg_rd1;

  // ALU Mux B: selects between rs2 and immediate
  mux2 alu_mux (
      .d0 (reg_rd2),
      .d1 (imm_val),
      .sel(alu_src),
      .out(alu_b_in)
  );

  alu main_alu (
      .a(alu_a_in),
      .b(alu_b_in),
      .alu_ctrl(alu_ctrl),
      .out(alu_result),
      .zero(alu_zero)
  );

  branch_comparator branch_comp (
      .branch(branch),
      .funct3(funct3),
      .rs1_data(reg_rd1),
      .rs2_data(reg_rd2),
      .take(branch_condition_met)
  );

  // -------------------------------------------------------------------------
  // Memory, Writeback & Control Flow
  // -------------------------------------------------------------------------


  // pc logic
  assign target_pc     = jalr_flag ? alu_result : (pc_wire + imm_val);
  assign next_pc       = take_jump ? target_pc : pc_plus_4;

  // jump calculation
  assign take_jump     = jump | jalr_flag | branch_condition_met;
  assign pc_plus_4     = pc_wire + 32'd4;

  // memory & MIMO logic
  assign is_accel_addr = alu_result[7];
  assign ram_we_wire   = data_mem_we & !is_accel_addr;
  assign accel_we_wire = data_mem_we & is_accel_addr;
  assign final_data_rd = is_accel_addr ? accel_dout : data_rd;

  data_mem ram_blocks (
      .clk(clk),
      .we(ram_we_wire),
      .funct3(funct3),
      .word_addr(alu_result[9:2]),
      .byte_offset(alu_result[1:0]),
      .wd(reg_rd2),
      .rd(data_rd)
  );

  pixel_processor img_engine (
      .clk(clk),
      .reset(reset),
      .we(accel_we_wire),
      .addr(alu_result[3:2]),
      .din(reg_rd2),
      .dout(accel_dout)
  );

  // final writeback mux
  assign reg_wd = (result_src == 2'b11) ? alu_result    :
                    (result_src == 2'b10) ? pc_plus_4     :
                    (result_src == 2'b01) ? final_data_rd :
                                            alu_result;

  // -------------------------------------------------------------------------
  // UART Snooper Logic & Debug
  // -------------------------------------------------------------------------

  // allow FPGA to receive instructions via UART
  always @(posedge clk) begin
    if (reset) begin  // reset instructions on reset signal
      byte_count <= 2'b00;
      write_addr <= 8'h0;
    end else if (rx_dv) begin
      case (byte_count)
        2'b00: instruction_reg[7:0] <= rx_byte;
        2'b01: instruction_reg[15:8] <= rx_byte;
        2'b10: instruction_reg[23:16] <= rx_byte;
        2'b11: instruction_reg[31:24] <= rx_byte;
      endcase
      byte_count <= byte_count + 1'b1;
      if (byte_count == 2'b11) write_addr <= write_addr + 1'b1;
    end
  end

  assign mem_we = (rx_dv && byte_count == 2'b11);
  assign led[7:0] = instruction_reg[7:0];
  assign led[15:8] = write_addr;

endmodule

