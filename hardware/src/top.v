module top (
    input clk,
    input RsRx,
    output [15:0] led  // displaying 16 bits of the 32-bit instruction
);

  wire rx_dv;
  wire [7:0] rx_byte;

  reg [31:0] instruction_reg = 32'h0;
  reg [1:0] byte_count = 2'b00;

  uart_rx #(
      .CLKS_PER_BIT(10416)
  ) uart_receiver (
      .clk(clk),
      .rx_serial(RsRx),
      .rx_dv(rx_dv),
      .rx_byte(rx_byte)
  );

  always @(posedge clk) begin
    if (rx_dv) begin
      // shift in bytes: standard RISC-V is little-endian
      // byte 0 goes to [7:0], byte 1 to [15:8], etc.
      case (byte_count)
        2'b00: instruction_reg[7:0] <= rx_byte;
        2'b01: instruction_reg[15:8] <= rx_byte;
        2'b10: instruction_reg[23:16] <= rx_byte;
        2'b11: instruction_reg[31:24] <= rx_byte;
      endcase

      // increment counter; it will wrap around back to 00 after 4 bytes
      byte_count <= byte_count + 1'b1;
    end
  end

  // display the lower half of the instruction (bits 15 to 0)
  assign led = instruction_reg[15:0];

endmodule
