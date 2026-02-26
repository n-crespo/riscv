// Top level wrapper to test the UART receiver on the Basys3 board.
module top (
    input clk,
    input RsRx,
    output [7:0] led
);

  wire rx_dv;
  wire [7:0] rx_byte;

  // instantiate the uart receiver module
  uart_rx #(
      .CLKS_PER_BIT(10416)
  ) uart_receiver (
      .clk(clk),
      .rx_serial(RsRx),
      .rx_dv(rx_dv),
      .rx_byte(rx_byte)
  );

  // map the registered 8-bit output directly to the leds
  assign led = rx_byte;

endmodule
