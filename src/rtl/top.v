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
  wire [31:0] pc_next, pc_plus_4_if, pc_target;
  wire [31:0] pc_if;  // PC in Fetch stage
  reg  [31:0] pc_ex;  // PC in Execute stage
  wire [31:0] instr_raw;  // raw data from memory
  wire [31:0] instr_ex;  // instruction currently executing
  wire        take_jump;  // branch decision

  wire reg_we, alu_src, data_mem_we, branch, jump, jalr_flag;
  wire [31:0] alu_a_in, alu_b_in, alu_result;

  // immediate signals
  wire [31:0] imm_val;
  wire [ 2:0] imm_src;

  // -------------------------------------------------------------------------
  // STAGE 1: FETCH (IF)
  // -------------------------------------------------------------------------

  // Branch/Jump Target: Must use pc_ex (the address of the currently executing instruction)
  assign pc_target    = jalr_flag ? alu_result : (pc_ex + imm_val);

  // Next PC logic: choose between following the program or jumping
  assign pc_plus_4_if = pc_if + 32'd4;
  assign pc_next      = take_jump ? pc_target : pc_plus_4_if;

  pc program_counter (
      .clk(clk),
      .reset(reset),
      .d(pc_next),
      .q(pc_if)
  );

  instr_mem instruction_memory (
      .clk(clk),
      .we(mem_we),
      .addr_a(write_addr),
      .din_a(instruction_reg),
      .addr_b(pc_if),
      .dout_b(instr_raw)
  );


  // -------------------------------------------------------------------------
  // pipeline bridge (logic-only)
  // -------------------------------------------------------------------------

  reg flush_reg;

  always @(posedge clk) begin
    if (reset) begin
      flush_reg <= 1'b1;  // start with a flush to ignore the first garbage cycle
      pc_ex     <= 32'h0;
    end else begin
      flush_reg <= take_jump;  // if we jump now, the NEXT cycle is a NOP
      pc_ex     <= pc_if;  // pc_if is the address of the instr_raw coming out NOW
    end
  end

  // logic-only instruction wire
  assign instr_ex = (flush_reg) ? 32'h00000013 : instr_raw;

  // -------------------------------------------------------------------------
  // STAGE 2: EXECUTE (EX)
  // -------------------------------------------------------------------------

  // directly decode the instruction from the EX register
  wire [ 6:0] opcode = instr_ex[6:0];
  wire [ 4:0] rd = instr_ex[11:7];
  wire [ 2:0] funct3 = instr_ex[14:12];
  wire [ 4:0] rs1 = instr_ex[19:15];
  wire [ 4:0] rs2 = instr_ex[24:20];
  wire [ 6:0] funct7 = instr_ex[31:25];

  // control unit signals
  wire [ 3:0] alu_ctrl;
  wire [ 1:0] result_src;
  wire [31:0] steered_wd;
  reg  [31:0] steered_rd;

  // execution & data path signals
  wire [31:0] reg_rd1, reg_rd2, reg_wd;
  wire alu_zero, alu_lt;
  reg branch_condition_met;

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

  imm_gen immediate_generator (
      .instr  (instr_ex),
      .imm_src(imm_src),
      .imm_out(imm_val)
  );

  control_unit ctrl (
      .opcode(opcode),
      .funct3(funct3),
      .funct7(funct7),
      .reg_we(reg_we),
      .alu_ctrl(alu_ctrl),
      .alu_src(alu_src),
      .imm_src(imm_src),
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
  assign alu_a_in = (opcode == 7'b0010111) ? pc_ex : (opcode == 7'b0110111) ? 32'b0 : reg_rd1;

  // ALU Mux B: selects between rs2 and immediate
  mux2 alu_mux (
      .d0 (reg_rd2),
      .d1 (imm_val),
      .sel(alu_src),
      .out(alu_b_in)
  );

  alu main_alu (
      .a       (alu_a_in),
      .b       (alu_b_in),
      .alu_ctrl(alu_ctrl),
      .out     (alu_result),
      .zero    (alu_zero),
      .lt      (alu_lt)
  );

  // -------------------------------------------------------------------------
  // Memory, Writeback & Control Flow
  // -------------------------------------------------------------------------

  assign take_jump = jump | jalr_flag | branch_condition_met;

  // memory & MIMO logic
  assign is_accel_addr = alu_result[7];
  assign ram_we_wire = data_mem_we & !is_accel_addr;
  assign accel_we_wire = data_mem_we & is_accel_addr;
  assign final_data_rd = is_accel_addr ? accel_dout : steered_rd;

  // logic to steer store data into the correct byte lanes
  assign steered_wd = (funct3 == 3'b010) ? reg_rd2 :  // sw
      (funct3 == 3'b001) ? (reg_rd2[15:0] << (alu_result[1] * 16)) :  // sh
      (reg_rd2[7:0] << (alu_result[1:0] * 8));  // sb

  // shift back and apply sign extension after getting raw word from ram
  wire [ 7:0] selected_byte = data_rd >> (alu_result[1:0] * 8);
  wire [15:0] selected_half = data_rd >> (alu_result[1] * 16);

  always @(*) begin
    case (funct3)
      3'b000:  steered_rd = {{24{selected_byte[7]}}, selected_byte};  // lb
      3'b001:  steered_rd = {{16{selected_half[15]}}, selected_half};  // lh
      3'b100:  steered_rd = {24'b0, selected_byte};  // lbu
      3'b101:  steered_rd = {16'b0, selected_half};  // lhu
      default: steered_rd = data_rd;  // lw
    endcase
  end

  wire [31:0] diff_bits = reg_rd1 ^ reg_rd2;
  wire        fast_zero = (diff_bits == 32'b0);

  // determine branch condition using ALU flags
  always @(*) begin
    if (branch) begin
      case (funct3)
        3'b000:  branch_condition_met = fast_zero;  // beq: rs1 == rs2
        3'b001:  branch_condition_met = !fast_zero;  // bne: rs1 != rs2
        3'b100:  branch_condition_met = alu_lt;  // blt: rs1 < rs2 (signed)
        3'b101:  branch_condition_met = !alu_lt;  // bge: rs1 >= rs2 (signed)
        3'b110:  branch_condition_met = alu_lt;  // bltu: rs1 < rs2 (unsigned)
        3'b111:  branch_condition_met = !alu_lt;  // bgeu: rs1 >= rs2 (unsigned)
        default: branch_condition_met = 1'b0;
      endcase
    end else begin
      branch_condition_met = 1'b0;
    end
  end

  // generate the byte-enable mask
  reg [3:0] byte_en;
  always @(*) begin
    if (ram_we_wire) begin
      case (funct3)
        3'b000:  // sb: select one byte lane
        case (alu_result[1:0])
          2'b00: byte_en = 4'b0001;
          2'b01: byte_en = 4'b0010;
          2'b10: byte_en = 4'b0100;
          2'b11: byte_en = 4'b1000;
        endcase
        3'b001:  // sh: select two byte lanes
        byte_en = (alu_result[1]) ? 4'b1100 : 4'b0011;
        3'b010:  // sw: select all four lanes
        byte_en = 4'b1111;
        default: byte_en = 4'b0000;
      endcase
    end else begin
      byte_en = 4'b0000;
    end
  end

  data_mem ram_blocks (
      .clk (clk),
      .be  (byte_en),
      .addr(alu_result[9:2]),  // the 8-bit word index
      .wd  (steered_wd),       // the data already shifted to the right byte lane
      .rd  (data_rd)           // raw 32-bit word comes out
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
  assign reg_wd = (result_src == 2'b11) ? alu_result :
                  (result_src == 2'b10) ? (pc_ex + 32'd4) :
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
